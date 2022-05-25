packer {
  required_plugins {
    arm-image = {
      version = "= 0.2.5"
      source = "github.com/solo-io/arm-image"
    }
  }
}

source "arm-image" "ubuntu" {
  iso_url = "https://cdimage.ubuntu.com/releases/22.04/release/ubuntu-22.04-preinstalled-server-arm64+raspi.img.xz"
  iso_checksum = "file:https://cdimage.ubuntu.com/releases/22.04/release/SHA256SUMS"
  image_type = ""
  image_mounts = ["/boot/firmware", "/"]
  qemu_binary = "qemu-aarch64-static"
}

build {
  sources = ["source.arm-image.ubuntu"]

  provisioner "shell" {
    inline = [
      "touch /tmp/test",
    ]
  }

}