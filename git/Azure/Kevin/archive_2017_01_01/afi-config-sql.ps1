Write-Output "SQL DSC CONFIG BEGINS!"
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
            Address = '10.21.100.10'
            InterfaceAlias = 'Ethernet'
            AddressFamily = 'IPv4'
        }
        xComputer Rename
        {
            Name = 'localhost'
            DomainName = 'go.local'
            Credential = $DomCred
            # JoinOU     = "OU=Comp,DC=gokevin8,DC=com"
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