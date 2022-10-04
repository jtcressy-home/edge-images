FROM quay.io/kairos/core-ubuntu:v1.0.0

RUN mkdir -p /etc/tailscale && \
    mkdir -p /etc/systemd/system/getty@tty1.service.d && \
    mkdir -p /lib/systemd/system && \
    mkdir -p /usr/bin
    
ADD ./files/ /

RUN chmod +x /etc/tailscale/up-args.sh && \
    chmod +x /usr/bin/set-hostname.py

RUN useradd -ms /bin/bash ubuntu && \
    groupadd admin && \
    usermod -aG admin ubuntu && \
    sed -i 's/\%admin ALL=(ALL) ALL/\%admin ALL=(ALL) NOPASSWD:ALL/g' /etc/sudoers && \
    mkdir -p /home/ubuntu/.ssh && \
    echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDsd5k9qXFm08MNwIZ9uf48E+sybjnX10ahYLLBYMkDGCD4hUYcLjKGfeP2VuOWEcv+65bzUq5rDmw1I+JIO3kHUHLHVKxgOusefKbDYcs+mkcovEoCdWl/LEmrjWHh5INaNY1aBprZ0/irW1TQQxMjYbqIbS5pfWfLK/HcLO4fG8Yx79zSRwzlB411OZzQ0Q2xjHXS/wOnAzD9c2v97/B1XGyuVLwDJpzsnUHMXYulPGlF6nORI5Cwgj0aPOsnKUMj9ink1kyQaKEmvo3TJFf2yrxqgLzJ985cgI9FKAjKvKj2R/nCXvjiuOJoDL7TKF2D5BKPOTBC9qER1OdV6e7mvNwpTCfFLy399Cc1tWqtsVksxc7zlu7aiso3IeOeV5aTu8kjWtsoOS1tLmM+DeLJfiDorA4dd5Qd5A9qBuhd1GuzgRhtDeENF5lGtZpCmuSfWszPb5sG9QKHDPZF9nXMzDZ7GysRh/E02EDTJ6YNbaTRKVuuc2cYdMgU4v/z3OrNsFBcZmPV8WyoqCF8wz7x/nHh1cYylVIWvicbWw1yFfvYeuoLCBpwQohWVPFBKBDZmzG/KaIujs65EXNBba9sIbzvH2WFzgD2Y5vSOAEv2G5QTyTZJIHohG9Rw/w2zvMQzCTGZyeGdWT15gxASYd0ZF3ypyw5PSEK7Noad1IRBQ== cardno:10 179 837" >> /home/ubuntu/.ssh/authorized_keys


# Install tailscale repo
RUN curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/focal.noarmor.gpg | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
RUN curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/focal.tailscale-keyring.list | sudo tee /etc/apt/sources.list.d/tailscale.list

RUN apt-get update -yqq && \
    apt-get install -yqq tailscale jq qrencode dmidecode

# RUN ln -s '/lib/systemd/system/set-hostname.service' '/etc/systemd/system/multi-user.target.wants/set-hostname.service'
# RUN ln -s '/lib/systemd/system/tailscale-up.service' '/etc/systemd/system/multi-user.target.wants/tailscale-up.service'
RUN systemctl enable set-hostname.service
RUN systemctl enable tailscale-up.service

RUN export VERSION="jtcressy-tailos-ubuntu"
RUN envsubst '${VERSION}' </etc/os-release