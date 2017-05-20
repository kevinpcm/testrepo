Write-Output "SQL DSC CONFIG BEGINS!"
configuration dsc
{
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
    }
}

dsc -Verbose
            
# Execute the DSC META MOF (LCM)
Set-DSCLocalConfigurationManager -Path c:\scripts\dsc -Verbose -Force                    
# Execute the DSC MOF files
Start-DscConfiguration -Wait -Force  -Path c:\scripts\dsc -Verbose