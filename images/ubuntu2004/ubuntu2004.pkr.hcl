source "hyperv-iso" "ubuntu2004" {
    iso_url = "https://releases.ubuntu.com/20.04.4/ubuntu-20.04.4-live-server-amd64.iso"
    iso_checksum = "28ccdb56450e643bad03bb7bcf7507ce3d8d90e8bf09e38f6bd9ac298a98eaad"

    cpus = 2
    disk_block_size = 1
    disk_size = 10240
    memory = 2048

    http_directory = "."

    ssh_username = "ubuntu"
    ssh_password = "ubuntu"
    ssh_timeout = "8h"
    switch_name = "VmNAT"

    boot_command = [
        "<enter><enter><f6><esc><wait> ",
        "autoinstall ds=nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/",
        "<enter><wait>"
    ]
    boot_wait = "5s"
    
    use_fixed_vhd_format = true
    skip_compaction = true

    shutdown_command = "echo 'ubuntu' | sudo -S shutdown -P now"
}

build {
  sources = ["sources.hyperv-iso.ubuntu2004"]

  provisioner "shell" {
    execute_command = "echo 'ubuntu' | sudo -S env {{ .Vars }} {{ .Path }}"
    scripts = [
      "scripts/cloudinit_cleanup.sh"
    ]
  }
}