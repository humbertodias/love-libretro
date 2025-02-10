FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt update -y && apt install -y automake autoconf libtool build-essential make cmake
WORKDIR /builder
#COPY . .
#RUN make all