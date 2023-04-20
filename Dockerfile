FROM alpine:latest

# Install packages
RUN apk update
RUN apk add traceroute
RUN apk add nano
RUN apk add nmap-ncat
RUN apk add curl
RUN apk add -U wireguard-tools

# Copy scripts
WORKDIR /app
COPY ./.psk /root/.rvpn/psk
COPY ./scripts /app
RUN chmod +x /app/start.sh