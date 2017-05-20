    $templateFile = "azuredeploy.json"
    $parameterFile = "azuredeploy.parameters.json"
    New-AzureRmResourceGroupDeployment -ResourceGroupName 'gorg' -TemplateFile $templateFile -TemplateParameterFile $parameterFile -Name