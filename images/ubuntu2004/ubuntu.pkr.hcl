source "hyperv-iso" "ubuntu2004" {
    boot_command = [
        "<enter><enter><f6><esc><wait> ",
        "autoinstall ds=nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/",
        "<enter><wait>"
    ]
    boot_wait = "1s"
    cpus = 2
    disk_block_size = 1
    disk_size = 10240
    http_directory = "."
    iso_url = "https://releases.ubuntu.com/20.04.4/ubuntu-20.04.4-live-server-amd64.iso"
    iso_checksum = "28ccdb56450e643bad03bb7bcf7507ce3d8d90e8bf09e38f6bd9ac298a98eaad"
    memory = 2048
    shutdown_command = "echo 'ubuntu' | sudo -S shutdown -P now"
    ssh_username = "ubuntu"
    ssh_password = "ubuntu"
    ssh_timeout = "8h"
    switch_name = "VmNAT"
}

build {
  sources = ["sources.hyperv-iso.ubuntu2004"]

  # TODO: install nginx
  # TODO: install Azure agent
  # TODO: deprovision
}