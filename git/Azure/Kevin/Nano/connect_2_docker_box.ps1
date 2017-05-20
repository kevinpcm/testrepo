$ip         = '10.20.110.85'
$hostname   = 'gokevin8-core'
$current=(get-item WSMan:\localhost\Client\TrustedHosts).value
$current+=,$ip,$hostname
set-item WSMan:\localhost\Client\TrustedHosts –value $current
Set-Item WSMan:\localhost\Client\TrustedHosts $hostname -Force
$securePass = ConvertTo-SecureString "Tote2830" -AsPlainText -force
$local      = New-Object System.Management.Automation.PsCredential -ArgumentList ("localhost\administrator",$securePass)
$domain     = New-Object System.Management.Automation.PsCredential -ArgumentList ("administrator@gokevin8.com",$securePass)
New-PSSession -ComputerName $hostname -Credential $local -Verbose
Enter-PSSession -ComputerName $hostname