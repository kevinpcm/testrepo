Get-PSSession | Remove-PSSession
Get-Job | where {$_.State -eq 'Completed'}| Remove-Job
    $securePassword = ConvertTo-SecureString "PAMSamich" -AsPlainText -force
    $local      = New-Object System.Management.Automation.PsCredential -ArgumentList "localhost\administrator",$securePassword
    $domain     = New-Object System.Management.Automation.PsCredential -ArgumentList "gokevin8\administrator",$securePassword
    $compname   = import-csv C:\scripts\computername.csv
    $a          = "c:\users\administrator\documents\dsc\"
    $c          = ".ps1"
ForEach ($ip in $compname) {
    $ipremote   = $ip.computername
    $cname      = "job" + "$ipremote"
    $d          = "$a" + "localhost"+"$c"
New-PSSession -ComputerName $ip.computername -Credential $local -Verbose 
    $TargetSess = (Get-PSSession -ComputerName $ipremote -Credential $local  | where {$_.State -eq 'opened'})
Copy-Item  -Verbose -Path C:\scripts\config.ps1 -Destination $d  -Force -ToSession $TargetSess
    $ScriptBlock =
    {
    $domcred = $using:domain
    .\dsc\localhost.ps1 -credential $local        
    }
Write-Output "CNAME..."$cname
Invoke-Command -Session (Get-PSSession -ComputerName $ipremote -Credential $local  | where {$_.State -eq 'opened'}) -scriptblock $ScriptBlock -AsJob -JobName $cname -Verbose # -argumentlist $domcred
    }