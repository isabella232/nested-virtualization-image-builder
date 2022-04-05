source "hyperv-iso" "ubuntu2004" {
    iso_url = "http://releases.ubuntu.com/20.04/ubuntu-20.04.4-live-server-amd64.iso"
    iso_checksum = "28ccdb56450e643bad03bb7bcf7507ce3d8d90e8bf09e38f6bd9ac298a98eaad"

    http_directory = "subiquity/http"

    boot_wait = "5s"
    boot_command = [
      "<enter><enter><f6><esc><wait>",
      "autoinstall ds=nocloud-net;seedfrom=http://{{ .HTTPIP }}:{{ .HTTPPort }}/",
      "<enter><wait>"
    ]

    "shutdown_command": "shutdown -P now",

    ssh_username = "root"
    ssh_password = "to_be_disabled"
    ssh_timeout = "30m"

    http_port_min = 8000
    http_port_max = 8000

    boot_command = [
      "<esc><wait>",
      "<esc><wait>",
      "<enter><wait>",
      "/install/vmlinuz<wait>",
      " initrd=/install/initrd.gz",
      " auto-install/enable=true",
      " debconf/priority=critical",
      " preseed/url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg<wait>",
      " -- <wait>",
      "<enter><wait>"
    ]

    shutdown_command = "shutdown -P now"
}

build {
  sources = ["sources.hyperv-iso.ubuntu2004"]

  provisioner "shell" {
    scripts = [
      "postinstall.sh",
      "cloudinit_install.sh"
    ]
    pause_after = "300s"
  }
}
