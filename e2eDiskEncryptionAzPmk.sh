#######################################################################################################################################
# Basic commands to create an Azure VM with host based encryption enabled with PMK in Azure CLI.
# Support documentation here -> https://docs.microsoft.com/en-us/azure/virtual-machines/linux/disks-enable-host-based-encryption-cli.
#
# Bruna Moreira Bruno, October 2022
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

