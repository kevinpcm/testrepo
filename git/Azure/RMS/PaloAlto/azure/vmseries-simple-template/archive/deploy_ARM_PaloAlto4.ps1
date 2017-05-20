$templateFile       = 'C:\scripts\git\Azure\RMS\PaloAlto\azure\vmseries-simple-template\azureDeploy.json'
$templateParameter  = 'C:\scripts\git\Azure\RMS\PaloAlto\azure\vmseries-simple-template\azureDeploy.parameters4.json'
$secureString       = convertto-securestring "Tote2830" -asplaintext -force
New-AzureRmResourceGroupDeployment -Name PaloAltoTest2 -ResourceGroupName GORG -TemplateFile $templateFile `
         -TemplateParameterFile $templateParameter `
         -vmName "PA22" `
         -vmSize "Standard_D3" `
         -location "eastus2" `
         -virtualNetworkName "paVNET" `
         -virtualNetworkAddressPrefix "" `
         -subnet0Name "" `
         -subnet1Name "" `
         -subnet2Name "" `
         -subnet0Prefix "" `
         -subnet1Prefix "" `
         -subnet2Prefix "" `
         -subnet0StartAddress "" `
         -subnet1StartAddress "" `
         -subnet2StartAddress "" `
         -storageAccountNewOrExisting "existing" `
         -newStorageAccount "" `
         -existingStorageAccountRG "gosa01" `
         -sshkey "" `
         -storageAccountType "Standard_LRS" `
         -baseurl "https://raw.githubusercontent.com/saurabhtrekker/UI1/master" `
         -adminUserName "install" `
         -adminPassword $secureString `
         -authenticationType "password" `
         -srcIPInboundNSG "" `
         -dnsNameForPublicIP "paloaltodns2"

