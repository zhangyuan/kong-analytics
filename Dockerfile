FROM kong:0.13.1-alpine

RUN apk update && apk add gcc g++ zlib zlib-dev unzip && luarocks install lua-zlib

COPY kong/plugins /tmp/plugins

RUN cd /tmp/plugins/analytics && luarocks make