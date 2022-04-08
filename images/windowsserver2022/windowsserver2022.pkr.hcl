source "hyperv-iso" "windows-server-2022" {
    iso_url = "https://software-static.download.prss.microsoft.com/sg/download/888969d5-f34g-4e03-ac9d-1f9786c66749/SERVER_EVAL_x64FRE_en-us.iso"
    iso_checksum = "3e4fa6d8507b554856fc9ca6079cc402df11a8b79344871669f0251535255325"

    floppy_files = ["autounattend.xml"]
    vm_name = "packer-win2022"
    boot_wait = "5s"
    disk_size = "10240"
    headless = true
    winrm_password = "packer"
    winrm_username = "Administrator"
    communicator = "winrm"
    winrm_use_ssl = true
    winrm_insecure = true
    winrm_timeout = "4h"
    shutdown_timeout = "30m"
    disable_shutdown = true 
    skip_compaction = true
    switch_name = "VmNAT"
    generation = 1
    use_fixed_vhd_format = true
    differencing_disk = false
}

build {
  sources = ["sources.hyperv-iso.windows-server-2022"]
  
  provisioner "powershell" {
    scripts = [
      "scripts/setup.ps1",
      "scripts/add-web-server.ps1",
      "scripts/sysprep.ps1"
    ]
  }
}