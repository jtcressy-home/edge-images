packer {
  required_plugins {
    arm-image = {
      version = "= 0.2.5"
      source = "github.com/solo-io/arm-image"
    }
  }
}

source "arm-image" "ubuntu" {
  iso_url = "http://cdimage.ubuntu.com/releases/20.04.2/release/ubuntu-20.04.2-preinstalled-server-arm64+raspi.img.xz"
  iso_checksum = "file:http://cdimage.ubuntu.com/releases/20.04.2/release/SHA256SUMS"
  image_type = ""
  image_mounts = ["/boot/firmware", "/"]
  qemu_binary = "qemu-aarch64-static"
}

source "arm-image" "alpine" {
  iso_url = "https://dl-cdn.alpinelinux.org/alpine/v3.16/releases/aarch64/alpine-rpi-3.16.0-aarch64.tar.gz"
  iso_checksum = "file:https://dl-cdn.alpinelinux.org/alpine/v3.16/releases/aarch64/alpine-rpi-3.16.0-aarch64.tar.gz.sha256"
}

build {
  sources = ["source.arm-image.ubuntu"]

  provisioner "shell" {
    inline = [
      "touch /tmp/test",
    ]
  }

}