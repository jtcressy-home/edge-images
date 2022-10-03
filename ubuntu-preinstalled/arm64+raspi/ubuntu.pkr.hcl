packer {
  required_plugins {
    arm-image = {
      version = "= 0.2.5"
      source = "github.com/solo-io/arm-image"
    }
  }
}

source "arm-image" "ubuntu" {
  iso_url = "https://cdimage.ubuntu.com/ubuntu-server/jammy/daily-preinstalled/current/jammy-preinstalled-server-arm64+raspi.img.xz"
  iso_checksum = "file:https://cdimage.ubuntu.com/ubuntu-server/jammy/daily-preinstalled/current/SHA256SUMS"
  image_type = ""
  resolv-conf = "delete"
  image_mounts = ["/boot/firmware", "/"]
  qemu_binary = "qemu-aarch64-static"
}

build {
  sources = ["source.arm-image.ubuntu"]

  provisioner "shell" {
    inline = [
      "set -x",
      "echo 'nameserver 1.1.1.1' > /etc/resolv.conf",
      "curl -L -vvv https://api.github.com/repos/jtcressy-home/edged/releases/latest",
      "URL=$(curl -L -s https://api.github.com/repos/jtcressy-home/edged/releases/latest | grep -o -E 'https://(.*)edged-getty(.*)_linux_arm64.deb')",
      "echo $URL",
      "curl -L -s $URL -o edged-getty.deb",
      "dpkg -i edged-getty.deb"
    ]
  }

  provisioner "shell" {
    inline = [
      "set -x",
      "curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/jammy.noarmor.gpg | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null",
      "curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/jammy.tailscale-keyring.list | sudo tee /etc/apt/sources.list.d/tailscale.list",
      "sudo apt-get update",
      "sudo apt-get install -y tailscale"
    ]
  }

}
