Get-PSSession | Remove-PSSession
Get-Job | where {$_.State -eq 'Completed'}| Remove-Job
    $securePass = ConvertTo-SecureString "Tote2830" -AsPlainText -force
    $local      = New-Object System.Management.Automation.PsCredential -ArgumentList "localhost\administrator",$securePass
    $domain     = New-Object System.Management.Automation.PsCredential -ArgumentList "install@go.local",$securePass
    $data       = import-csv .\godc.csv | Where-Object {$_.Function -eq "IIS"} 
        ForEach ($row in $data) 
        {
            $IP         = $row.PrivateIP
            $jobname    = "job---" + "$IP"
            New-PSSession -ComputerName $IP -Credential $local -Verbose 
            $TargetSess = (Get-PSSession -ComputerName $IP -Credential $local  | where {$_.State -eq 'opened'})
            $destination= "c:\scripts\localhost.ps1"
            Copy-Item -Path .\DSC_IIS_CONFIG_Version_1.0.ps1 -Destination $destination -Force -ToSession $TargetSess
                $ScriptBlock =
                {
                $domcred = $using:domain
                cd "C:\scripts"; 
                .\localhost.ps1 -credential $local        
                }
            Invoke-Command -Session $TargetSess -scriptblock $ScriptBlock -AsJob -JobName $jobname -Verbose
        }