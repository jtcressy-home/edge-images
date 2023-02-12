VERSION 0.6

IMPORT github.com/kairos-io/kairos

FROM alpine
ARG ISO_NAME=edgenode
ARG LUET_VERSION=0.33.0
ARG KAIROS_VERSION=v1.5.0
ARG OSBUILDER_IMAGE=quay.io/kairos/osbuilder-tools:v0.5.1
ARG MICROK8S_CHANNEL=latest

ARG REGISTRY=ghcr.io
ARG IMAGE_NAME=jtcressy-home/edge-images
ARG IMAGE=${REGISTRY}/${IMAGE_NAME}:latest_kairos${KAIROS_VERSION}_microk8sv${MICROK8S_CHANNEL}

ARG BASE_IMAGE=quay.io/kairos/core-ubuntu-22-lts:${KAIROS_VERSION}
ARG BASE_IMAGE_NAME=$(echo $BASE_IMAGE | grep -o [^/]*: | rev | cut -c2- | rev)
ARG BASE_IMAGE_TAG=$(echo $BASE_IMAGE | grep -o :.* | cut -c2-)

all:
  BUILD +docker-multiarch
  BUILD +all-iso
  BUILD +all-rpi

all-iso:
  BUILD --platform=linux/amd64 --platform=linux/arm64 +iso

all-rpi:
  BUILD --platform=linux/arm64 +rpi-image

docker-multiarch:
  BUILD --platform=linux/amd64 --platform=linux/arm64 +docker


VERSION:
  COMMAND
  FROM alpine
  RUN apk add git
  COPY .git ./
  RUN echo $(git describe --exact-match --tags || echo "v0.0.0-$(git log --oneline -n 1 | cut -d" " -f1)") > VERSION
  SAVE ARTIFACT VERSION VERSION

tailscale:
  FROM ghcr.io/tailscale/tailscale:latest
  SAVE ARTIFACT /usr/local/bin/tailscale tailscale
  SAVE ARTIFACT /usr/local/bin/tailscaled tailscaled


kairos:
  FROM alpine
  RUN apk add git
  WORKDIR /kairos
  RUN git clone https://github.com/kairos-io/kairos /kairos && cd /kairos && git checkout "$KAIROS_VERSION"
  SAVE ARTIFACT /kairos/

system-grub2:
    # TODO: source the system/grub2* packages from elemental toolkit to see if they solve the arm64 installer's problem
    # error we got in the iso arm64 installer: "did not find efi artifacts under /run/cos/active"
  ARG TARGETPLATFORM
  ARG TARGETARCH
  IF [ "$TARGETARCH" = "amd64" ]
    FROM quay.io/kairos/packages:grub2-efi-system-2.06-150401
    SAVE ARTIFACT /. kairos
    FROM quay.io/costoolkit/releases-teal:grub2-artifacts-system-0.0.3-15
    SAVE ARTIFACT /. costoolkit
  ELSE IF [ "$TARGETARCH" = "arm64" ]
    FROM quay.io/kairos/packages-arm64:grub2-efi-system-2.06-150401
    SAVE ARTIFACT /. kairos
    FROM quay.io/costoolkit/releases-teal-arm64:grub2-artifacts-system-0.0.3-15
    SAVE ARTIFACT /. costoolkit
  END

inspect:
  FROM alpine
  RUN apk add file tree
  COPY +system-grub2/kairos /kairos
  COPY +system-grub2/costoolkit /costoolkit
  RUN --no-cache tree /kairos
  RUN --no-cache tree /costoolkit

docker:
  ARG TARGETPLATFORM
  ARG TARGETARCH
  DO +VERSION
  ARG VERSION=$(cat VERSION)

  ARG FLAVOR=ubuntu-22-lts

  # This WOULD have worked if the kairos earthfile supported a BASE_IMAGE argument
  # FROM kairos+docker --FLAVOR=${FLAVOR} --BASE_IMAGE=./images/${FLAVOR}+build-image
  FROM ./images/ubuntu-22-lts+build-image
  # Instead we need to cherry pick some things from the target kairos+docker...
  # /Begin cherrypick from kairos+docker
  COPY (kairos+framework/framework --FLAVOR=${FLAVOR}) /
  COPY +system-grub2/kairos /
  COPY +system-grub2/costoolkit /usr/share/efi
  # COPY +system-grub2-efi-${TARGETARCH}/package /
  RUN rm -rf /etc/machine-id && touch /etc/machine-id && chmod 444 /etc/machine-id
  
  # IF [ "$FLAVOR" = "ubuntu-22-lts" ]
  COPY +kairos/kairos/overlay/files-ubuntu/ /
  # END

  COPY kairos+build-kairos-agent/kairos-agent /usr/bin/kairos-agent
  
  # IF [ ! -f /sbin/openrc ]
  RUN ls -liah /etc/systemd/system
	RUN systemctl enable cos-setup-rootfs.service && \
	    systemctl enable cos-setup-initramfs.service && \
	    systemctl enable cos-setup-reconcile.timer && \
	    systemctl enable cos-setup-fs.service && \
	    systemctl enable cos-setup-boot.service && \
	    systemctl enable cos-setup-network.service
  # END

  # IF [ "$FLAVOR" = "ubuntu-22-lts" ]
  RUN kernel=$(ls /boot/vmlinuz-* | head -n1) && \
            ln -sf "${kernel#/boot/}" /boot/vmlinuz
  RUN kernel=$(ls /lib/modules | head -n1) && \
        dracut -f "/boot/initrd-${kernel}" "${kernel}" && \
        ln -sf "initrd-${kernel}" /boot/initrd
  RUN kernel=$(ls /lib/modules | head -n1) && depmod -a "${kernel}"
  # END

  IF [ ! -e "/boot/vmlinuz" ]
      # If it's an ARM flavor, we want a symlink here from zImage/Image
      IF [ -e "/boot/Image" ]
          RUN ln -sf Image /boot/vmlinuz
      ELSE IF [ -e "/boot/zImage" ]
          RUN ln -sf zImage /boot/vmlinuz
      ELSE
          RUN kernel=$(ls /lib/modules | head -n1) && \
            ln -sf "${kernel#/boot/}" /boot/vmlinuz
      END
  END
  # /End cherrypick from kairos+docker

  RUN curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/jammy.noarmor.gpg | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null && \
      curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/jammy.tailscale-keyring.list | sudo tee /etc/apt/sources.list.d/tailscale.list


  RUN apt-get update && apt-get autoclean && DEBIAN_FRONTENT=noninteractive apt-get install tailscale iptables-persistent jq qrencode dmidecode console-data -y
  RUN snap download microk8s --channel=$MICROK8S_CHANNEL --target-directory /opt/microk8s/snaps --basename microk8s
  RUN snap download core --target-directory /opt/microk8s/snaps --basename core

  COPY scripts/cloudinit /opt/microk8s/scripts

  RUN chmod +x /opt/microk8s/scripts/*

  COPY overlay/files /
  COPY overlay/files-ubuntu /

  RUN setupcon --save

  RUN mkdir -p /opt/tailscale
  # COPY --platform=${TARGETPLATFORM} +tailscale/tailscale /usr/bin/tailscale
  # COPY --platform=${TARGETPLATFORM} +tailscale/tailscaled /usr/sbin/tailscaled

  RUN systemctl enable set-hostname.service
  RUN systemctl enable tailscale-logind.service
  RUN systemctl enable tailscaled.service

  ENV OS_ID=ubuntu
  ENV OS_VERSION=${VERSION}_kairos${KAIROS_VERSION}_microk8sv${MICROK8S_CHANNEL}
  ENV OS_NAME=$OS_ID:${OS_VERSION}
  ENV OS_REPO=$REGISTRY/$IMAGE_NAME
  ENV OS_LABEL=${OS_VERSION}
  DO kairos+OSRELEASE --HOME_URL=https://github.com/jtcressy-home/edge-images --BUG_REPORT_URL=https://github.com/jtcressy-home/edge-images/issues --GITHUB_REPO=jtcressy-home/edge-images --VARIANT=${VARIANT} --FLAVOR=${FLAVOR} --OS_ID=${OS_ID} --OS_LABEL=${OS_LABEL} --OS_NAME=${OS_NAME} --OS_REPO=${OS_REPO} --OS_VERSION=${OS_VERSION}

  SAVE IMAGE $IMAGE
  SAVE IMAGE --push ${REGISTRY}/${IMAGE_NAME}:latest_kairos${KAIROS_VERSION}_microk8sv${MICROK8S_CHANNEL}
  SAVE IMAGE --push ${REGISTRY}/${IMAGE_NAME}:${VERSION}_kairos${KAIROS_VERSION}_microk8sv${MICROK8S_CHANNEL}

docker-rootfs:
  ARG TARGETPLATFORM
  FROM --platform=$TARGETPLATFORM +docker
  SAVE ARTIFACT /. rootfs

boot-livecd:
  ARG TARGETPLATFORM
  ARG TARGETARCH
  IF [ "$TARGETARCH" = "amd64" ]
    FROM quay.io/kairos/packages:grub2-livecd-0.0.4
    SAVE ARTIFACT /. grub2
    FROM quay.io/kairos/packages:grub2-efi-image-livecd-0.0.4
    SAVE ARTIFACT /. efi
  ELSE IF [ "$TARGETARCH" = "arm64" ]
    # TODO: kairos needs to actually build arm64 artifacts into the livecd images
    #        the arm64 kairos packages are actually completely blank and unusable
    # FROM quay.io/kairos/packages-arm64:grub2-livecd-0.0.4
    FROM quay.io/costoolkit/releases-teal-arm64:grub2-live-0.0.4-2
    SAVE ARTIFACT /. grub2
    # FROM quay.io/kairos/packages-arm64:grub2-efi-image-livecd-0.0.4
    FROM quay.io/costoolkit/releases-teal-arm64:grub2-efi-image-live-0.0.4-2
    SAVE ARTIFACT /. efi
  END

iso:
  ARG TARGETPLATFORM
  ARG TARGETARCH
  ARG OSBUILDER_IMAGE
  ARG overlay=overlay/files-iso
  FROM $OSBUILDER_IMAGE
  RUN zypper in -y jq docker
  WORKDIR /build
  RUN mkdir -p overlay/files-iso
  COPY overlay/files-iso/ ./$overlay/
  COPY +docker-rootfs/rootfs /build/image

  COPY +boot-livecd/grub2 /grub2
  COPY +boot-livecd/efi /efi

  RUN /entrypoint.sh --name $ISO_NAME --debug build-iso --date=false dir:/build/image --overlay-iso /build/${overlay} --output /build

  RUN sha256sum $ISO_NAME.iso > $ISO_NAME.iso.sha256
  SAVE ARTIFACT /build/$ISO_NAME.iso $ISO_NAME.iso AS LOCAL build/$ISO_NAME-$TARGETARCH.iso
  SAVE ARTIFACT /build/$ISO_NAME.iso.sha256 $ISO_NAME.iso.sha256 AS LOCAL build/$ISO_NAME-$TARGETARCH.iso.sha256

rpi-image:
  ARG OSBUILDER_IMAGE
  FROM --platform=linux/arm64 $OSBUILDER_IMAGE
  ARG MODEL=rpi64
  ARG IMG_NAME=${ISO_NAME}-arm64-rpi.img
  WORKDIR /build
  ENV STATE_SIZE="6200"
  ENV RECOVERY_SIZE="4200"
  ENV SIZE="15200"
  ENV DEFAULT_ACTIVE_SIZE="4000"
  COPY --platform=linux/arm64 +docker-rootfs-arm64/rootfs /build/image

  WITH DOCKER --allow-privileged
    RUN /build-arm-image.sh --model $MODEL --directory "/build/image" /build/$IMG_NAME
  END
  RUN xz -v /build/$IMG_NAME
  SAVE ARTIFACT /build/$IMG_NAME.xz img AS LOCAL build/$IMG_NAME.xz
  SAVE ARTIFACT /build/$IMG_NAME.sha256 img-sha256 AS LOCAL build/$IMG_NAME.sha256

local-qemu-setup:
  LOCALLY
  RUN sudo apt-get update -yqq && sudo apt-get install -yqq qemu-system binfmt-support qemu-user-static
  RUN docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
  RUN docker stop earthly-buildkitd || true