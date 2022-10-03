FROM quay.io/kairos/core-ubuntu:v1.0.0

RUN mkdir -p /etc/tailscale && \
    mkdir -p /etc/systemd/system/getty@tty1.service.d && \
    mkdir -p /lib/systemd/system && \
    mkdir -p /usr/bin && \
    ls /etc/tailscale && \
    ls /etc/systemd/system/getty@tty1.service.d && \
    ls /lib/systemd/system && \
    ls /usr/bin
    
ADD ./files/ /

# Install tailscale repo
RUN curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/focal.noarmor.gpg | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
RUN curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/focal.tailscale-keyring.list | sudo tee /etc/apt/sources.list.d/tailscale.list

RUN apt-get update -yqq && \
    apt-get install -yqq tailscale jq qrencode dmidecode

# RUN ln -s '/lib/systemd/system/set-hostname.service' '/etc/systemd/system/multi-user.target.wants/set-hostname.service'
# RUN ln -s '/lib/systemd/system/tailscale-up.service' '/etc/systemd/system/multi-user.target.wants/tailscale-up.service'
RUN systemctl enable --root set-hostname.service
RUN systemctl enable --root tailscale-up.service

RUN export VERSION="jtcressy-tailos-ubuntu"
RUN envsubst '${VERSION}' </etc/os-release