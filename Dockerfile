FROM caddy:2.10.2 AS caddy

FROM debian:trixie-slim
# upgrade: github lexmount/moli
ARG MOLI_VERSION=v1.1.25
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl libfontconfig1 fonts-dejavu-core fonts-liberation fonts-noto-cjk \
 && curl -fsSL https://github.com/lexmount/moli/releases/download/${MOLI_VERSION}/moli-x86_64-unknown-linux-gnu.tar.gz | tar xz -C /tmp \
 && mv /tmp/moli-*/moli /usr/local/bin/moli && rm -rf /tmp/moli-* \
 && apt-get purge -y curl && apt-get autoremove -y && rm -rf /var/lib/apt/lists/*
COPY --from=caddy /usr/bin/caddy /usr/local/bin/caddy
COPY Caddyfile /etc/caddy/Caddyfile
COPY railway-start /usr/local/bin/railway-start
CMD ["/usr/local/bin/railway-start"]
