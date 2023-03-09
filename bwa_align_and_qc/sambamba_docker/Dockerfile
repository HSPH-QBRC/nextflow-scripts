FROM ubuntu:jammy-20230301

RUN apt-get update && apt-get install -y wget

RUN wget https://github.com/biod/sambamba/releases/download/v0.8.2/sambamba-0.8.2-linux-amd64-static.gz

RUN gunzip sambamba-0.8.2-linux-amd64-static.gz && \
    mv sambamba-0.8.2-linux-amd64-static /opt/ && \
    chmod +x /opt/sambamba-0.8.2-linux-amd64-static
