﻿Write-Output "Workgroup DSC CONFIG BEGINS!"
Start-Sleep -MilliSeconds 60000
configuration dsc
{
        param(             
        [Parameter(Mandatory)]            
        [pscredential]$DomCred            
        ) 
  
    Import-DscResource -ModuleName xNetworking
    Import-DscResource -ModuleName xComputerManagement
    Node $AllNodes.Nodename
    {
        LocalConfigurationManager            
        {            
            ActionAfterReboot = 'ContinueConfiguration'            
            ConfigurationMode = 'ApplyOnly'            
            RebootNodeIfNeeded = $true            
        }
        xDnsServerAddress SetDNS
        {
            Address = $uudns1, $uudns2
            InterfaceAlias = 'Ethernet'
            AddressFamily = 'IPv4'
        }
        xComputer Rename
        {
            Name = 'localhost'
            DependsOn  = '[xDNSServerAddress]SetDNS'
        }
    }
}
# Configuration Data for AD              
$ConfigData = @{             
    AllNodes = @(             
        @{             
            Nodename =  $env:Computername                  
            DomainName = "gokevin8.com"             
            RetryCount = 20              
            RetryIntervalSec = 30            
            PsDscAllowPlainTextPassword = $true            
        }            
    )             
}
dsc -ConfigurationData $ConfigData -DomCred $DomCred -Verbose
            
# Execute the DSC META MOF (LCM)
Set-DSCLocalConfigurationManager -Path c:\scripts\dsc -Verbose -Force                    
# Execute the DSC MOF files
Start-DscConfiguration -Wait -Force  -Path c:\scripts\dsc -Verbose