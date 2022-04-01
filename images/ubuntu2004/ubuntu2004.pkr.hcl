source "hyperv-iso" "ubuntu2004" {
    iso_url = "http://releases.ubuntu.com/20.04/ubuntu-20.04.4-desktop-amd64.iso"
    iso_checksum = "f92f7dca5bb6690e1af0052687ead49376281c7b64fbe4179cc44025965b7d1c"

    cpus = 2
    disk_size = 10240
    disk_block_size = 1
    use_legacy_network_adapter = true
    use_fixed_vhd_format = true
    skip_compaction = true
    differencing_disk = false
    memory = 2048
    switch_name = "VmNAT"
    generation = 1

    ssh_username = "root"
    ssh_password = "to_be_disabled"
    ssh_timeout = "8h"

    http_directory = "."
    http_port_min = 8000
    http_port_max = 8000

    shutdown_command = "shutdown -P now"
}

build {
  sources = ["sources.hyperv-iso.ubuntu2004"]
}
