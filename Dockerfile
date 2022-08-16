FROM alpine:3.16 AS upx
ENV UPX_VERSION="3.96"
RUN sed -i 's/v3.\d\d/v3.15/' /etc/apk/repositories && \
    apk add bash build-base perl ucl-dev zlib-dev
RUN wget https://github.com/upx/upx/releases/download/v${UPX_VERSION}/upx-${UPX_VERSION}-src.tar.xz && \
    tar xf upx-${UPX_VERSION}-src.tar.xz
WORKDIR ./upx-${UPX_VERSION}-src/
RUN make -C ./src/ && mkdir -p /upx/bin/ && mv ./src/upx.out /upx/bin/upx && \
    mkdir -p /upx/lib/ && cd /usr/lib/ && cp -d ./libgcc_s.so* ./libstdc++.so* ./libucl.so* /upx/lib/

FROM golang:1.18-alpine3.16 AS xray
ENV XRAY_VERSION="1.5.9"
RUN wget https://github.com/XTLS/Xray-core/archive/refs/tags/v${XRAY_VERSION}.tar.gz && \
    tar xf v${XRAY_VERSION}.tar.gz
WORKDIR ./Xray-core-${XRAY_VERSION}/
RUN go mod download -x
RUN env CGO_ENABLED=0 go build -v -o xray -trimpath -ldflags "-s -w" ./main && \
    mv ./xray /tmp/
COPY --from=upx /upx/ /usr/
RUN upx -9 /tmp/xray

FROM alpine:3.16 AS asset
RUN apk add xz
WORKDIR /tmp/
RUN wget "https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat"
RUN wget "https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat"
RUN mkdir -p /asset/etc/xproxy/ && tar cJf /asset/etc/xproxy/assets.tar.xz ./geo*.dat
COPY --from=xray /tmp/xray /asset/usr/bin/

FROM alpine:3.16
COPY --from=asset /asset/ /
ENV XRAY_LOCATION_ASSET=/xproxy/assets
RUN apk add --no-cache iptables ip6tables