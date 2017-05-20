Write-Output "DSC CONFIG BEGINS!"
configuration dsc
{
        param(             
        [Parameter(Mandatory)]            
        [pscredential]$DomCred            
        ) 
  
    # Import-DscResource -ModuleName xRemoteDesktopAdmin
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
            Address = '10.31.1.4'
            InterfaceAlias = 'Ethernet'
            AddressFamily = 'IPv4'
        }

        WindowsFeature FileandStorageServices	
        { 	
            Ensure =  "Present"
            Name   =  "FileAndStorage-Services"
        } 	
        WindowsFeature FileandiSCSIServices	
        { 	
            Ensure =  "Present"
            Name   =  "File-Services"
        } 	
        WindowsFeature FileServer	
        { 	
            Ensure =  "Present"
            Name   =  "FS-FileServer"
        } 	
        WindowsFeature SMB10CIFSFileSharingSupport	
        { 	
            Ensure =  "Present"
            Name   =  "FS-SMB1"
        } 	
        WindowsFeature ASPNETFramework45	
        { 	
            Ensure =  "Present"
            Name   =  "NET-Framework-45-ASPNET"
        } 	
        WindowsFeature NETFramework45	
        { 	
            Ensure =  "Present"
            Name   =  "NET-Framework-45-Core"
        } 	
        WindowsFeature NETFramework45Features	
        { 	
            Ensure =  "Present"
            Name   =  "NET-Framework-45-Features"
        } 	
        WindowsFeature NETFramework35includesNET20and30	
        { 	
            Ensure =  "Present"
            Name   =  "NET-Framework-Core"
        } 	
        WindowsFeature NETFramework35Features	
        { 	
            Ensure =  "Present"
            Name   =  "NET-Framework-Features"
        } 	
        WindowsFeature WCFServices	
        { 	
            Ensure =  "Present"
            Name   =  "NET-WCF-Services45"
        } 	
        WindowsFeature TCPPortSharing	
        { 	
            Ensure =  "Present"
            Name   =  "NET-WCF-TCP-PortSharing45"
        } 	
        WindowsFeature WindowsPowerShell40	
        { 	
            Ensure =  "Present"
            Name   =  "PowerShell"
        } 	
        WindowsFeature WindowsPowerShellISE	
        { 	
            Ensure =  "Present"
            Name   =  "PowerShell-ISE"
        } 	
        WindowsFeature WindowsPowerShell	
        { 	
            Ensure =  "Present"
            Name   =  "PowerShellRoot"
        } 	
        WindowsFeature WindowsPowerShell20Engine	
        { 	
            Ensure =  "Present"
            Name   =  "PowerShell-V2"
        } 	
        WindowsFeature RemoteServerAdministrationTools	
        { 	
            Ensure =  "Present"
            Name   =  "RSAT"
        } 	
        WindowsFeature ActiveDirectoryAdministrativeCenter	
        { 	
            Ensure =  "Present"
            Name   =  "RSAT-AD-AdminCenter"
        } 	
        WindowsFeature ADDSTools	
        { 	
            Ensure =  "Present"
            Name   =  "RSAT-ADDS"
        } 	
        WindowsFeature ADDSSnapInsandCommandLineTools	
        { 	
            Ensure =  "Present"
            Name   =  "RSAT-ADDS-Tools"
        } 	
        WindowsFeature ADLDSSnapInsandCommandLineTools	
        { 	
            Ensure =  "Present"
            Name   =  "RSAT-ADLDS"
        } 	
        WindowsFeature ActiveDirectorymoduleforWindowsPowerShell	
        { 	
            Ensure =  "Present"
            Name   =  "RSAT-AD-PowerShell"
        } 	
        WindowsFeature ADDSandADLDSTools	
        { 	
            Ensure =  "Present"
            Name   =  "RSAT-AD-Tools"
        } 	
        WindowsFeature RoleAdministrationTools	
        { 	
            Ensure =  "Present"
            Name   =  "RSAT-Role-Tools"
        } 	
        WindowsFeature GraphicalManagementToolsandInfrastructure	
        { 	
            Ensure =  "Present"
            Name   =  "Server-Gui-Mgmt-Infra"
        } 	
        WindowsFeature ServerGraphicalShell	
        { 	
            Ensure =  "Present"
            Name   =  "Server-Gui-Shell"
        } 	
        WindowsFeature StorageServices	
        { 	
            Ensure =  "Present"
            Name   =  "Storage-Services"
        } 	
        WindowsFeature UserInterfacesandInfrastructure	
        { 	
            Ensure =  "Present"
            Name   =  "User-Interfaces-Infra"
        } 	
        WindowsFeature ApplicationDevelopment	
        { 	
            Ensure =  "Present"
            Name   =  "Web-App-Dev"
        } 	
        WindowsFeature ASP	
        { 	
            Ensure =  "Present"
            Name   =  "Web-ASP"
        } 	
        WindowsFeature ASPNET45	
        { 	
            Ensure =  "Present"
            Name   =  "Web-Asp-Net45"
        } 	
        WindowsFeature CommonHTTPFeatures	
        { 	
            Ensure =  "Present"
            Name   =  "Web-Common-Http"
        } 	
        WindowsFeature DefaultDocument	
        { 	
            Ensure =  "Present"
            Name   =  "Web-Default-Doc"
        } 	
        WindowsFeature DirectoryBrowsing	
        { 	
            Ensure =  "Present"
            Name   =  "Web-Dir-Browsing"
        } 	
        WindowsFeature RequestFiltering	
        { 	
            Ensure =  "Present"
            Name   =  "Web-Filtering"
        } 	
        WindowsFeature HealthandDiagnostics	
        { 	
            Ensure =  "Present"
            Name   =  "Web-Health"
        } 	
        WindowsFeature HTTPErrors	
        { 	
            Ensure =  "Present"
            Name   =  "Web-Http-Errors"
        } 	
        WindowsFeature HTTPLogging	
        { 	
            Ensure =  "Present"
            Name   =  "Web-Http-Logging"
        } 	
        WindowsFeature ISAPIExtensions	
        { 	
            Ensure =  "Present"
            Name   =  "Web-ISAPI-Ext"
        } 	
        WindowsFeature ISAPIFilters	
        { 	
            Ensure =  "Present"
            Name   =  "Web-ISAPI-Filter"
        } 	
        WindowsFeature IIS6ManagementConsole	
        { 	
            Ensure =  "Present"
            Name   =  "Web-Lgcy-Mgmt-Console"
        } 	
        WindowsFeature IIS6MetabaseCompatibility	
        { 	
            Ensure =  "Present"
            Name   =  "Web-Metabase"
        } 	
        WindowsFeature IIS6ManagementCompatibility	
        { 	
            Ensure =  "Present"
            Name   =  "Web-Mgmt-Compat"
        } 	
        WindowsFeature IISManagementConsole	
        { 	
            Ensure =  "Present"
            Name   =  "Web-Mgmt-Console"
        } 	
        WindowsFeature ManagementTools	
        { 	
            Ensure =  "Present"
            Name   =  "Web-Mgmt-Tools"
        } 	
        WindowsFeature NETExtensibility45	
        { 	
            Ensure =  "Present"
            Name   =  "Web-Net-Ext45"
        } 	
        WindowsFeature Performance	
        { 	
            Ensure =  "Present"
            Name   =  "Web-Performance"
        } 	
        WindowsFeature Security	
        { 	
            Ensure =  "Present"
            Name   =  "Web-Security"
        } 	
        WindowsFeature WebServerIIS	
        { 	
            Ensure =  "Present"
            Name   =  "Web-Server"
        } 	
        WindowsFeature StaticContentCompression	
        { 	
            Ensure =  "Present"
            Name   =  "Web-Stat-Compression"
        } 	
        WindowsFeature StaticContent	
        { 	
            Ensure =  "Present"
            Name   =  "Web-Static-Content"
        } 	
        WindowsFeature WebServer	
        { 	
            Ensure =  "Present"
            Name   =  "Web-WebServer"
        } 	
        WindowsFeature WebSocketProtocol	
        { 	
            Ensure =  "Present"
            Name   =  "Web-WebSockets"
        } 	
        WindowsFeature WindowsAuthentication	
        { 	
            Ensure =  "Present"
            Name   =  "Web-Windows-Auth"
        } 	
        WindowsFeature IIS6WMICompatibility	
        { 	
            Ensure =  "Present"
            Name   =  "Web-WMI"
        } 	
        WindowsFeature WoW64Support	
        { 	
            Ensure =  "Present"
            Name   =  "WoW64-Support"
        }
        xComputer Rename
        {
            Name = 'localhost'
            DomainName = 'sentaradirectory.onmicrosoft.com'
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
            DomainName = "sentaradirectory.onmicrosoft.com"             
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