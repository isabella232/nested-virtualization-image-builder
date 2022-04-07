source "hyperv-iso" "ubuntu2004" {
    iso_url = "http://releases.ubuntu.com/20.04/ubuntu-20.04.4-live-server-amd64.iso"
    iso_checksum = "28ccdb56450e643bad03bb7bcf7507ce3d8d90e8bf09e38f6bd9ac298a98eaad"

    switch_name = "VmNAT"

    ssh_username = "ubuntu123"
    ssh_password = "ubuntu"
    ssh_timeout = "30m"

    http_port_min = 8000
    http_port_max = 8000

    http_directory = "."

    cpus = 2
    memory = 2048
    disk_block_size = 1
    disk_size = 10240
    
    boot_wait = "5s"
    boot_command = [
      "<enter><enter><f6><esc><wait>",
      "autoinstall ds=nocloud-net;seedfrom=http://{{ .HTTPIP }}:{{ .HTTPPort }}/",
      "<enter><wait>",
    ]

    shutdown_command = "echo 'ubuntu' | sudo -S shutdown -P now"
}

build {
  sources = ["sources.hyperv-iso.ubuntu2004"]
}
