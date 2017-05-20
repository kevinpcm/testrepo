$vms = "gokevin8-dsc01", "gokevin8-dsc02"
$ipdc = "10.20.110.10"
$checkpointname = "DSC"
$DC = "gokevin8-dc01"
foreach ($vm in $vms){
    $checkpoint   = Get-SCVMCheckpoint -VM $vm | where {$_.Name -eq $checkpointname}
    $cn           = $checkpoint.name   
    Restore-SCVMCheckpoint -VMCheckpoint $checkpoint
    StartVMAndWait -vm $vm
    }
    function StartVMAndWait($vm){
            Start-SCVirtualMachine -VM $vm
            $scvm = Get-SCVirtualMachine -Name $vm
            Write-Output $scvm.VirtualMachineState
            do {Start-Sleep -milliseconds 100} 
                until ( $scvm.VirtualMachineState -ne "PowerOff")
            }
$securePassword = ConvertTo-SecureString "Tote2830" -AsPlainText -force
$domain     = New-Object System.Management.Automation.PsCredential -ArgumentList "gokevin8\administrator",$securePassword
New-PSSession -ComputerName $ipdc -Credential $domain -Verbose 
$TargetSess = (Get-PSSession -ComputerName $ipdc -Credential $domain  | where {$_.State -eq 'opened'})
    $ScriptBlock =
        {
        $removevms = $using:vms
        foreach ($vm in $removevms){ 
            $advm = ""
            try{
                $advm = Get-ADComputer -Identity $vm
            } catch {
                Write-Output "No existing AD account found"
            }
            if ($advm -ne ""){
                Write-Output "Remove existing AD account..."
                Remove-ADObject -Identity $advm -Recursive -Confirm:$false
            }        

        }         
        }
Invoke-Command -Session (Get-PSSession -ComputerName $ipdc -Credential $domain  | where {$_.State -eq 'opened'}) -scriptblock $ScriptBlock -Verbose
    
       