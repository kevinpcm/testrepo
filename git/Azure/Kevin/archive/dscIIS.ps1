configuration ServerConfig {
    Import-DscResource -ModuleName PSDesiredStateConfiguration
       node $AllNodes.NodeName {
          $Node.WindowsFeature.ForEach({
             WindowsFeature $_ {
                Name = $_
                Ensure = 'Present'
                DependsOn = $_.DependsOn
             }
          })
       }}
@{
     AllNodes = @(
        @{
            NodeName = 'localhost'
            WindowsFeature = 'FileAndStorage-Services','File-Services','FS-FileServer','Storage-Services','Web-Server','Web-WebServer','Web-Common-Http','Web-Default-Doc','Web-Dir-Browsing','Web-Http-Errors','Web-Static-Content','Web-Health','Web-Http-Logging','Web-Performance','Web-Stat-Compression','Web-Security','Web-Filtering','Web-Windows-Auth','Web-App-Dev','Web-Net-Ext45','Web-ASP','Web-Asp-Net45','Web-ISAPI-Ext','Web-ISAPI-Filter','Web-WebSockets','Web-Mgmt-Tools','Web-Mgmt-Console','Web-Mgmt-Compat','Web-Metabase','Web-Lgcy-Mgmt-Console','Web-WMI','NET-Framework-Features','NET-Framework-Core','NET-Framework-45-Features','NET-Framework-45-Core','NET-Framework-45-ASPNET','NET-WCF-Services45','NET-WCF-TCP-PortSharing45','RSAT','RSAT-Role-Tools','RSAT-AD-Tools','RSAT-AD-PowerShell','RSAT-ADDS','RSAT-AD-AdminCenter','RSAT-ADDS-Tools','RSAT-ADLDS','FS-SMB1','User-Interfaces-Infra','Server-Gui-Mgmt-Infra','Server-Gui-Shell','PowerShellRoot','PowerShell','PowerShell-V2','PowerShell-ISE','WoW64-Support'

            
       }
   )
}

$credentials = (get-credential)
$TargetSession = New-PSSession -ComputerName gokevin8-dsc01 -Credential $credentials
Copy-Item -ToSession $TargetSession "C:\scripts\" -Destination "C:\scripts\"
Invoke-Command -Session $TargetSession -ScriptBlock {Set-DSCLocalConfigurationManager -ComputerName 'gokevin8-dsc01' -Path 'C:\scripts\' –Verbose}