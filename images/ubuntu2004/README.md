# Ubuntu 20.04 Server

We use packer with cloud-init to create an Ubuntu 20.04 vhdx, which requires [user-data and meta-data files](https://ubuntu.com/server/docs/install/autoinstall-quickstart).

We must also configure the VM using post-install scripts to be suitable to run on [Azure](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/create-upload-ubuntu).

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
azcopy copy '.\output-ubuntu2004\Virtual Hard Disks\packer-ubuntu2004.vhd' "https://$storageAccount.blob.core.windows.net/images/ubuntu2004.vhd"

# Register the image
az image create -g builder -n ubuntu2004 --os-type Linux --source "https://$storageAccount.blob.core.windows.net/images/ubuntu2004.vhd"

```

### Create the VM

``` powershell
# Create the VM
$IMAGE_ID=$(az image show -g builder -n ubuntu2004 --query id -o tsv)
az vm create -n ubuntu2004 -g builder --image $IMAGE_ID --admin-password Password#1234 --nsg default
```

### Verify the Nginx Server

``` powershell
# create nsg rule that allows http traffic
az network nsg rule create --resource-group builder --nsg-name default -n AllowHttpRule --priority 501 --protocol "*" --destination-port-ranges 80 --access Allow

# get ubuntu vm IP
$IP=(az vm list-ip-addresses --resource-group builder --name ubuntu2004 --query "[].virtualMachine.network.publicIpAddresses[0].ipAddress" --output tsv)

# curl IP to see nginx 
curl http://$IP
```

### Clean up

```shell
az group delete -n builder
```
