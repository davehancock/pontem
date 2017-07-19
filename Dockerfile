FROM nginx:1.13.3

ENV FREIGHTER_VERSION 0.6.0

RUN apt-get update && apt-get install --no-install-recommends --no-install-suggests -y \
        procps \
        wget \
        certbot \
        ca-certificates \
    && update-ca-certificates \
    && wget -P /usr/local/bin https://dl.bintray.com/daves125125/Go-Distribution/${FREIGHTER_VERSION}/freighter \
    && chmod +x /usr/local/bin/freighter \
    && rm -rf /var/lib/apt/lists/*

COPY src /app

EXPOSE 80 443

ENTRYPOINT ["/app/configure_pontem.sh"]
