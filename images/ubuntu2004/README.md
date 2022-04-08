# Ubuntu 20.04 Server

WIP 

### Create the Image

Follow the steps in the top level [README](../../README.md) to configure and deploy the builder VM. Inside the builder VM, open PowerShell as Administrator and run the following commands to build an image from the `ubuntu2004` sample in this repo.


``` powershell
# Clone the repo
git clone https://github.com/Azure-Samples/nested-virtualization-image-builder --config core.autocrlf=input

# Build a sample Ubuntu 20.04 image
cd .\nested-virtualization-image-builder\images\ubuntu2004\
packer build .\ubuntu2004.pkr.hcl

# Convert outputted vhdx to vhd
Convert-VHD -Path '.\output-ubuntu2004\Virtual Hard Disks\packer-ubuntu2004.vhdx'  -DestinationPath '.\output-ubuntu2004\Virtual Hard Disks\packer-ubuntu2004.vhd' -VHDType Fixed

# Use Managed Identity for azcopy
azcopy login --identity

# Use Managed Identity for azure-cli
az login --identity

$storageAccount = az deployment group show -g builder -n storage --query 'properties.outputs.storageAccount.value' -o tsv

# Copy local vhd to blob
azcopy copy '.\output-ubuntu\Virtual Hard Disks\ubuntu2004.vhd' "https://$storageAccount.blob.core.windows.net/images/win2022.vhd"

# Register the image
az image create -g builder -n ubuntu2004 --os-type Linux --source "https://$storageAccount.blob.core.windows.net/images/ubuntu2004.vhd"

```

### Create the VM

```shell
# Create the VM
$IMAGE_ID=$(az image show -g builder -n ubuntu2004 --query id -o tsv)
az vm create -n ubuntu2004 -g builder --image $IMAGE_ID --generate-ssh-keys --admin-password Password#1234 --nsg default
```

### Verify the Nginx Server

WIP

### Clean up

```shell
az group delete -n builder
```
