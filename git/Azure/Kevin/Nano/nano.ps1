# add nano to DNS or HOSTS file
$ip         = '10.20.110.85'
$hostname   = 'gokevin8-core'
$current=(get-item WSMan:\localhost\Client\TrustedHosts).value
$current+=,$hostname
set-item WSMan:\localhost\Client\TrustedHosts –value $current
Set-Item WSMan:\localhost\Client\TrustedHosts $hostname -Force
$securePass = ConvertTo-SecureString "Tote2830" -AsPlainText -force
$local      = New-Object System.Management.Automation.PsCredential -ArgumentList ("localhost\administrator",$securePass)
$domain     = New-Object System.Management.Automation.PsCredential -ArgumentList ("administrator@gokevin8.com",$securePass)
New-PSSession -ComputerName $hostname -Credential $local -Verbose
Enter-PSSession -ComputerName $hostname
Set-DnsClientServerAddress -InterfaceIndex 3 -ServerAddresses 8.8.8.8
$sess = New-CimInstance -Namespace root/Microsoft/Windows/WindowsUpdate -ClassName MSFT_WUOperationsSession
Invoke-CimMethod -InputObject $sess -MethodName ApplyApplicableUpdates 
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Install-Module -Name DockerMsftProvider -Force
Install-Package -Name docker -ProviderName DockerMsftProvider -Force
$hostname   = 'gokevin8-core'
Restart-Computer -ComputerName $hostname

# after reboot
$hostname   = 'gokevin8-core'
$securePass = ConvertTo-SecureString "Tote2830" -AsPlainText -force
$local      = New-Object System.Management.Automation.PsCredential -ArgumentList ("localhost\administrator",$securePass)
$domain     = New-Object System.Management.Automation.PsCredential -ArgumentList ("administrator@gokevin8.com",$securePass)
New-PSSession -ComputerName $hostname -Credential $local -Verbose
Enter-PSSession -ComputerName $hostname
Start-Service docker
# docker pull microsoft/nanoserver
docker pull microsoft/windowsservercore
docker pull microsoft/iis

docker run -it -p 80:80 microsoft/iis:latest powershell

set DOCKER_CERT_PATH=%USERPROFILE%\.docker\machine\machines\default
set DOCKER_HOST=tcp://10.20.110.85:2376
set DOCKER_MACHINE_NAME=default
set DOCKER_TLS_VERIFY=1