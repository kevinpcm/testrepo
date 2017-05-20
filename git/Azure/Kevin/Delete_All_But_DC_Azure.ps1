Login-AzureRmAccount
Save-AzureRmProfile -Path .\profile1.json -Force
Select-AzureRmProfile -Path .\profile1.json
Get-AzureRmVM | ? {$_.name -ne 'godc01'} | Remove-AzureRmVM -Force

Get-AzureRmNetworkInterface | ? {$_.name -ne 'godc01nic1'} | Remove-AzureRmNetworkInterface -Force

Get-AzureRmPublicIpAddress | ? {($_.name -ne 'godc01pip1' -and $_.name -ne 'goVirtualNetworkGatewayPublicIP')} | Remove-AzureRmPublicIpAddress -Force

