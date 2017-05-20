$templateFile       = 'C:\scripts\git\Azure\RMS\PaloAlto\azure\vmseries-simple-template\azureDeploy2.json'
$templateParameter  = 'C:\scripts\git\Azure\RMS\PaloAlto\azure\vmseries-simple-template\azureDeploy.parameters2.json'
$secureString       = convertto-securestring "Tote2830" -asplaintext -force
New-AzureRmResourceGroupDeployment -Name PaloAltoTest -ResourceGroupName GORG -TemplateFile $templateFile `
         -TemplateParameterFile $templateParameter `
         -vmName "PA2" `
         -vmSize "Standard_D3" `
         -location "eastus2" `
         -virtualNetworkName "paVNET" `
         -virtualNetworkAddressPrefix "10.33.0.0/16" `
         -subnet0Name "Mgmt" `
         -subnet1Name "Untrust" `
         -subnet2Name "Trust" `
         -subnet0Prefix "10.33.1.0/24" `
         -subnet1Prefix "10.33.2.0/24" `
         -subnet2Prefix "10.33.3.0/24" `
         -subnet0StartAddress "10.33.1.10" `
         -subnet1StartAddress "10.33.2.10" `
         -subnet2StartAddress "10.33.3.10" `
         -storageAccountNewOrExisting "new" `
         -newStorageAccount "gopaloalto" `
         -existingStorageAccountRG "" `
         -sshkey "" `
         -storageAccountType "Standard_LRS" `
         -adminUserName "install" `
         -adminPassword $secureString `
         -authenticationType "password" `
         -srcIPInboundNSG "10.33.1.200" `
         -dnsNameForPublicIP "paloaltodns"

