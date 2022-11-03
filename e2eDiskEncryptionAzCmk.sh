#######################################################################################################################################
# Basic commands to create an Azure VM with host based encryption enabled with Azure CLI.
# Support documentation here -> https://docs.microsoft.com/en-us/azure/virtual-machines/linux/disks-enable-host-based-encryption-cli.
#
# Bruna Moreira Bruno, August 2022
######################################################################################################################################

#env variables
subscriptionID=cdf87418-9a1f-4f2e-bb5f-e65b02fec6ed
rgName=myrg
location=eastus
keyVaultName=mykeyvaultbrmoreir
keyName=mykey
diskEncryptionSetName=mydiskEncryptionSet
vmName=myvm
image=UbuntuLTS 
vmSize=Standard_D1_v2  

#login to azure and check if the right subscription is selected.
az login

az account set --subscription $subscriptionID

az account show --subscription $subscriptionID -o table

#prerequites

#register and check if encryption at host feature is enabled for you subscription (this will take a few minutes).
az feature register --namespace Microsoft.Compute --name EncryptionAtHost

az feature show --namespace Microsoft.Compute --name EncryptionAtHost

#create rg
az group create --location $location --name $rgName

#create key vault 
az keyvault create -n $keyVaultName \
-g $rgName \
-l $location \
--enable-purge-protection true \
--retention-days '7' #Soft delete data retention days. It accepts >=7 and <=90. Default value: 90

#create CMK                  
az keyvault key create --vault-name $keyVaultName -n $keyName --protection software

#add Azure RBAC so you can use your Azure key vault with your disk encryption set. This could be Key Vault Administrator, Owner, or Contributor roles. In this example the scope is set at resource level. More information here - https://docs.microsoft.com/en-us/cli/azure/role/assignment?view=azure-cli-latest#az-role-assignment-create.
#If you are owner or contributed at a high-level (inherited), then ignore this step. 
az role assignment create --assignee "brmoreir@microsoft.com" \
--role "Key Vault Administrator" \
--scope "/subscriptions/cdf87418-9a1f-4f2e-bb5f-e65b02fec6ed/resourceGroups/myrg/providers/Microsoft.KeyVault/vaults/mykeyvaultbrmoreir"

#create disk encryption set
keyVaultKeyUrl=$(az keyvault key show --vault-name $keyVaultName --name $keyName --query [key.kid] -o tsv)

az disk-encryption-set create -n $diskEncryptionSetName -l $location -g $rgName --key-url $keyVaultKeyUrl --enable-auto-key-rotation false

#Grant the DiskEncryptionSet resource access to the key vault
desIdentity=$(az disk-encryption-set show -n $diskEncryptionSetName -g $rgName --query [identity.principalId] -o tsv)

az keyvault set-policy -n $keyVaultName \
-g $rgName \
--object-id $desIdentity \
--key-permissions wrapkey unwrapkey get

#create VM with encryption at host enabled with CMK
diskEncryptionSetId=$(az disk-encryption-set show -n $diskEncryptionSetName -g $rgName --query [id] -o tsv)

#show list of VMs available per location
az vm list-skus --location $location --size Standard_D --all --output table #standard_D is just an example here. It can be replaced.

az vm create -g $rgName \
-n $vmName \
-l $location \
--encryption-at-host \
--image $image \
--size $vmSize \
--generate-ssh-keys \
--os-disk-encryption-set $diskEncryptionSetId \
--data-disk-sizes-gb 128 128 \
--data-disk-encryption-sets $diskEncryptionSetId $diskEncryptionSetId

#Check the status of encryption at host for a VM
az vm show -n $vmName \
-g $rgName \
--query [securityProfile.encryptionAtHost] -o tsv