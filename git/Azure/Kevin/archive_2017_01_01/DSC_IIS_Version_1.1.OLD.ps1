Get-PSSession | Remove-PSSession
Get-Job | where {$_.State -eq 'Completed'}| Remove-Job
    $securePass = ConvertTo-SecureString "Tote2830" -AsPlainText -force
    $local      = New-Object System.Management.Automation.PsCredential -ArgumentList "localhost\administrator",$securePass
    $domain     = New-Object System.Management.Automation.PsCredential -ArgumentList "gokevin8\administrator",$securePass
    $compname   = import-csv C:\scripts\computername.csv
    $a          = "c:\users\administrator\documents\dsc\"
    $c          = ".ps1"
ForEach ($ip in $compname) 
    {
    $ipremote   = $ip.computername
    $cname      = "job-" + "$ipremote"
    $d          = "$a" + "localhost"+"$c"
New-PSSession -ComputerName $ip.computername -Credential $local -Verbose 
    $TargetSess = (Get-PSSession -ComputerName $ipremote -Credential $local  | where {$_.State -eq 'opened'})
Copy-Item  -Verbose -Path C:\scripts\DSC_IIS_CONFIG_Version_1.1.ps1 -Destination $d  -Force -ToSession $TargetSess
    $ScriptBlock=
    {
    $domcred    = $using:domain
    .\dsc\localhost.ps1 -credential $local        
    }
Write-Output "CNAME..."$cname
Invoke-Command -Session $TargetSess -scriptblock $ScriptBlock -AsJob -JobName $cname -Verbose
    }
