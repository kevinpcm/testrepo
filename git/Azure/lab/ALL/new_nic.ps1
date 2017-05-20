$vmname = "test"
$rgname = "gorgsc"
 
$VM = get-azurermvm -ResourceGroupName $rgname -Name $vmname 
$RNIC = Remove-AzureRmVMNetworkInterface -VM $VM -NetworkInterfaceIDs $VM.NetworkInterfaceIDs[0] 
   
$vmnicname = "testnic2"
 
$NIC=get-azurermnetworkinterface -name $vmnicname -ResourceGroupName $rgname
Add-AzureRmvmNetworkInterface -NetworkInterface $NIC -VM $VM 
 
Update-AzureRmVM -ResourceGroupName $rgname -VM $vm  