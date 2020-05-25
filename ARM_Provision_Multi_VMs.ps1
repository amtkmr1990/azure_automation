


# This script is intended to Create ARM based VMs 


 $username = <username>
    
 $pass= ConvertTo-SecureString <password> -AsPlainText -Force
 $Cred = New-Object System.Management.Automation.PsCredential($username,$pass)
    
 Login-AzureRmAccount -credential $Cred


 Select-AzureRmSubscription -SubscriptionName <subscriptionname>


$credvm = Get-Credential
$NumberOfVM = '3';
$ResourceGroupName = <resource>
$Location = "North Central US"
$PublisherName = "Redhat"
$ImageOffer = "RHEL"
$ImageSkus = "7.2"
#$Ostype = "Windows"

## Storage
$StorageName = <storagename>
$StorageType = "Standard_LRS"



# Resource Group, if resource group has been created comment this out.
New-AzureRmResourceGroup -Name $ResourceGroupName -Location $Location


## Network
$InterfaceName = "NIC"
$Subnet1Name = "Subnet1"
$VNetName = "Vnet"
$VNetAddressPrefix = "10.0.0.0/16"
$VNetSubnetAddressPrefix = "10.0.0.0/24"

## Compute
$vmSize = "Standard_A4"

# Network
$SubnetConfig = New-AzureRmVirtualNetworkSubnetConfig -Name $Subnet1Name -AddressPrefix $VNetSubnetAddressPrefix
$VNet = New-AzureRmVirtualNetwork -Name $VNetName -ResourceGroupName $ResourceGroupName -Location $Location -AddressPrefix $VNetAddressPrefix -Subnet $SubnetConfig


$i = 1;

Do 
{ 
    $i; 
    $vmName="Namenode"+$i
    $vmconfig=New-AzureRmVMConfig -VMName $vmName -VMSize $vmSize

    $vm=Set-AzureRmVMOperatingSystem -VM $vmconfig -Windows -ComputerName $vmName -Credential $credvm -ProvisionVMAgent -EnableAutoUpdate

    $OSDiskName = $vmName + "osDisk"
    
    # Storage
    $StorageAccount = New-AzureRmStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageName$i -Type $StorageType -Location $Location
    
    ## Setup local VM object
    $vm = Set-AzureRmVMSourceImage -VM $vm -PublisherName $PublisherName -Offer $ImageOffer -Skus $ImageSkus -Version "latest"
    $PIp = New-AzureRmPublicIpAddress -Name $InterfaceName$i -ResourceGroupName $ResourceGroupName -Location $Location -AllocationMethod Dynamic
    $Interface = New-AzureRmNetworkInterface -Name $InterfaceName$i -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $VNet.Subnets[0].Id -PublicIpAddressId $PIp.Id
    $VirtualMachine = Add-AzureRmVMNetworkInterface -VM $vm -Id $Interface.Id
    $OSDiskUri = $StorageAccount.PrimaryEndpoints.Blob.ToString() + "vhds/" + $OSDiskName + ".vhd"
    $VirtualMachine = Set-AzureRmVMOSDisk -VM $VirtualMachine -Name $OSDiskName -VhdUri $OSDiskUri -CreateOption FromImage

    ## Create the VM in Azure
    New-AzureRmVM -ResourceGroupName $ResourceGroupName -Location $Location -VM $VirtualMachine
    $i +=1
} 
Until ($i -gt $NumberOfVM) 


