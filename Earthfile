VERSION 0.6

IMPORT github.com/kairos-io/kairos

FROM alpine
ARG ISO_NAME=edgenode
ARG LUET_VERSION=0.33.0
ARG KAIROS_VERSION=v1.4.0
ARG OSBUILDER_IMAGE=quay.io/kairos/osbuilder-tools:v0.3.3
ARG MICROK8S_CHANNEL=latest

ARG REGISTRY=ghcr.io
ARG IMAGE_NAME=jtcressy-home/edge-images
ARG IMAGE=${REGISTRY}/${IMAGE_NAME}:latest_kairos${KAIROS_VERSION}_microk8sv${MICROK8S_CHANNEL}

ARG BASE_IMAGE=quay.io/kairos/core-ubuntu-22-lts:${KAIROS_VERSION}
ARG BASE_IMAGE_NAME=$(echo $BASE_IMAGE | grep -o [^/]*: | rev | cut -c2- | rev)
ARG BASE_IMAGE_TAG=$(echo $BASE_IMAGE | grep -o :.* | cut -c2-)

all:
  BUILD --platform=linux/amd64 +docker
  BUILD --platform=linux/arm64 +docker
  BUILD +iso


VERSION:
  COMMAND
  FROM alpine
  RUN apk add git
  COPY . ./
  RUN echo $(git describe --exact-match --tags || echo "v0.0.0-$(git log --oneline -n 1 | cut -d" " -f1)") > VERSION
  SAVE ARTIFACT VERSION VERSION

tailscale:
  FROM ghcr.io/tailscale/tailscale:latest
  SAVE ARTIFACT /usr/local/bin/tailscale tailscale
  SAVE ARTIFACT /usr/local/bin/tailscaled tailscaled

docker:
  DO +VERSION
  ARG VERSION=$(cat VERSION)

  FROM $BASE_IMAGE
  RUN apt-get update && apt-get autoclean && DEBIAN_FRONTENT=noninteractive apt-get install iptables-persistent jq qrencode dmidecode console-data -y
  RUN snap download microk8s --channel=$MICROK8S_CHANNEL --target-directory /opt/microk8s/snaps --basename microk8s
  RUN snap download core --target-directory /opt/microk8s/snaps --basename core

  COPY scripts/cloudinit /opt/microk8s/scripts

  RUN chmod +x /opt/microk8s/scripts/*

  COPY overlay/files /
  COPY overlay/files-ubuntu /

  RUN setupcon --save

  RUN mkdir -p /opt/tailscale
  COPY +tailscale/tailscale /usr/bin/tailscale
  COPY +tailscale/tailscaled /usr/sbin/tailscaled

  RUN systemctl enable set-hostname.service
  RUN systemctl enable tailscale-logind.service
  RUN systemctl enable tailscaled.service

  ENV OS_ID=edgenode
  ENV OS_VERSION=${VERSION}_kairos${KAIROS_VERSION}_microk8sv${MICROK8S_CHANNEL}
  ENV OS_NAME=$OS_ID:${OS_VERSION}
  ENV OS_REPO=${$REGISTRY}/${IMAGE_NAME}
  ENV OS_LABEL=${OS_VERSION}
  DO kairos+OSRELEASE --HOME_URL=https://github.com/jtcressy-home/edge-images --BUG_REPORT_URL=https://github.com/jtcressy-home/edge-images/issues --GITHUB_REPO=jtcressy-home/edge-images --VARIANT=${VARIANT} --FLAVOR=${FLAVOR} --OS_ID=${OS_ID} --OS_LABEL=${OS_LABEL} --OS_NAME=${OS_NAME} --OS_REPO=${OS_REPO} --OS_VERSION=${OS_VERSION}

  SAVE IMAGE $IMAGE
  SAVE IMAGE --push ${REGISTRY}/${IMAGE_NAME}:latest_kairos${KAIROS_VERSION}_microk8sv${MICROK8S_CHANNEL}
  SAVE IMAGE --push ${REGISTRY}/${IMAGE_NAME}:${VERSION}_kairos${KAIROS_VERSION}_microk8sv${MICROK8S_CHANNEL}

docker-rootfs:
  FROM +docker
  SAVE ARTIFACT /. rootfs

kairos:
  FROM alpine
  RUN apk add git
  WORKDIR /kairos
  RUN git clone https://github.com/kairos-io/kairos /kairos && cd /kairos && git checkout "$KAIROS_VERSION"
  SAVE ARTIFACT /kairos/

iso:
  ARG OSBUILDER_IMAGE
  ARG IMG=docker:${IMAGE}
  ARG overlay=overlay/files-iso
  FROM $OSBUILDER_IMAGE
  RUN zypper in -y jq docker
  WORKDIR /build
  COPY . ./
  RUN mkdir -p overlay/files-iso
  COPY overlay/files-iso/ ./$overlay/
  COPY +docker-rootfs/rootfs /build/image
  RUN /entrypoint.sh --name $ISO_NAME --debug build-iso --date=false dir:/build/image --overlay-iso /build/${overlay} --output /build

  RUN sha256sum $ISO_NAME.iso > $ISO_NAME.iso.sha256
  SAVE ARTIFACT /build/$ISO_NAME.iso $ISO_NAME.iso AS LOCAL build/$ISO_NAME-amd64.iso
  SAVE ARTIFACT /build/$ISO_NAME.iso.sha256 $ISO_NAME.iso.sha256 AS LOCAL build/$ISO_NAME-amd64.iso.sha256

rpi-image:
  ARG OSBUILDER_IMAGE
  FROM $OSBUILDER_IMAGE
  ARG MODEL=rpi64
  ARG IMAGE_NAME=${ISO_NAME}-arm64-rpi.img
  WORKDIR /build
  ENV STATE_SIZE="6200"
  ENV RECOVERY_SIZE="4200"
  ENV SIZE="15200"
  ENV DEFAULT_ACTIVE_SIZE="2000"
  COPY --platform=linux/arm64 +docker-rootfs/rootfs /build/image

  WITH DOCKER --allow-privileged
    RUN /build-arm-image.sh --model $MODEL --directory "/build/image" /build/$IMAGE_NAME
  END
  RUN xz -v /build/$IMAGE_NAME
  SAVE ARTIFACT /build/$IMAGE_NAME.xz img AS LOCAL build/$IMAGE_NAME.xz
  SAVE ARTIFACT /build/$IMAGE_NAME.sha256 img-sha256 AS LOCAL build/$IMAGE_NAME.sha256