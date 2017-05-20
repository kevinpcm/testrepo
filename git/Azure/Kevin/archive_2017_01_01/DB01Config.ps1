configuration DB01
{
    param(             
        [Parameter(Mandatory)]            
        [pscredential]$DomCred,
        [pscredential]$FileCred            
    )    
    Import-DSCResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xRemoteDesktopAdmin
    Import-DscResource -ModuleName xNetworking
    Import-DscResource -ModuleName xComputerManagement
    Import-DSCResource -ModuleName xSQLServer

    Node $AllNodes.Nodename
    {
        LocalConfigurationManager            
        {            
            ActionAfterReboot = 'ContinueConfiguration'            
            ConfigurationMode = 'ApplyOnly'            
            RebootNodeIfNeeded = $true            
        }            
            
        xComputer Rename
        {
            Name = 'DB01'
            DomainName = 'igeeklabs.com'
            Credential = $DomCred
            DependsOn = '[xDNSServerAddress]SetDNS','[xIPAddress]NewIPAddress'
        }

        WindowsFeature DotNet
        {
            Ensure = "Present"
            Name = "NET-Framework-Core"
        }

        xRemoteDesktopAdmin DB01
        {
            Ensure = 'Present'
        }

        xFirewall AllowRDPUserModeTCP
        {
            Name = 'RemoteDesktop-UserMode-In-TCP'
            Ensure = 'Present'
            Enabled = 'True'
            Profile = 'Domain'
        }
        xFirewall AllowRDPUserModeUDP
        {
            Name = 'RemoteDesktop-UserMode-In-UDP'
            Ensure = 'Present'
            Enabled = 'True'
            Profile = 'Domain'
        }
        xFirewall AllowRDPShadowModeTCP
        {
            Name = 'RemoteDesktop-Shadow-In-TCP'
            Ensure = 'Present'
            Enabled = 'True'
            Profile = 'Domain'
        }


        xDhcpClient DisabledDhcpClient
        {
            State = 'Disabled'
            InterfaceAlias = 'Ethernet'
            AddressFamily ='IPv4'
        }

        xIPAddress NewIPAddress
        {
            IPAddress = '192.168.66.35'
            InterfaceAlias = 'Ethernet'
            PrefixLength = '24'
            AddressFamily = 'IPv4'
        }

        xDefaultGatewayAddress SetGateway
        {
            Address = '192.168.66.1'
            InterfaceAlias = 'Ethernet'
            AddresSFamily = 'IPv4'
        }

        xDnsServerAddress SetDNS
        {
            Address = '192.168.66.27'
            InterfaceAlias = 'Ethernet'
            AddressFamily = 'IPv4'
        }
        #File SqlSourceDir
        #{
        #    Ensure = "Present"
        #    Type = "Directory"
        #    DestinationPath = "C:\SQLInstall"
        #}

        #File SQLSource
        #{
            #DependsOn = "[File]SqlSourceDir"
            #Ensure = "Present"
            #Credential = $FileCred
            #Type = "Directory"
            #Recurse = $true
            #SourcePath = "\\192.168.66.1\sql2014"
            #DestinationPath = "C:\SQLInstall"    
        #}
        
        xSQLServerSetup DefaultInstance
        {
            DependsOn = "[xIPAddress]NewIPAddress","[xComputer]Rename","[WindowsFeature]DotNet"
            SourcePath = "C:\"
            SourceFolder = "sqlInstall"
            #SourceCredential = $FileCred
            InstanceName = "MSSQLSERVER"
            SetupCredential = $DomCred
            Features = "SQLENGINE,SSMS"

        }
    }
}

# Configuration Data for AD              
$ConfigData = @{             
    AllNodes = @(             
        @{             
            Nodename = "localhost"                    
            DomainName = "igeeklabs.com"             
            RetryCount = 20              
            RetryIntervalSec = 30            
            PsDscAllowPlainTextPassword = $true            
        }            
    )             
}

DB01 -ConfigurationData $ConfigData -DomCred $DomCred -FileCred $FileCred
            
# Make sure that LCM is set to continue configuration after reboot            
#Set-DSCLocalConfigurationManager -Path .\DC01 -Verbose            
            
# Build the domain            
Start-DscConfiguration -Wait -Force -Path .\DB01 -Verbose                  