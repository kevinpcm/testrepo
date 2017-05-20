
function Create-AzureServiceRdgFile {

##########################################################################################################
<#
.SYNOPSIS
    Creates a Remote Desktop Connection Manager 2.7 group file (.rdg) containing all the VMs from a 
    cloud service
    
.DESCRIPTION
    Uses the Azure PowerShell cmdlets to obtain remote connectivity information for each VM in a cloud 
    service. Uses this information to create a .rdg file for the targeted cloud service. This file can then 
    be opened in Remote Desktop Connection Manager 2.7 to provide consolidated RDP access...

    Remote Desktop Connection Manager 2.7 can be found here:

    http://www.microsoft.com/en-gb/download/details.aspx?id=44989

     
.EXAMPLE
    Create-AzureServiceRdgFile -ServiceName FredCLoud -FolderPath "c:\users\fred\rdg_files\" -Verbose

    Create's a Remote Desktop Configuration Manager configuration file caled FREDCLOUD.rdg in the 
    c:\users\fred\rdg_files directory for all the VMs in the FredCloud cloud service. Provides verbose
    output.

.EXAMPLE
    Get-AzureService | ForEach-Object {

        Create-AzureServiceRdgFile -ServiceName $_.ServiceName -FolderPath "c:\users\fred\rdg_files\" -Verbose

    }

    Get's each cloud service in the current Azure subscription. Create's a configuration file called 
    <ServiceName>.rdg for each service in the cloud service. Saves each .rdg file to "c:\users\fred\rdg_files" 
    directory so they can be loaded by Remote Desktop Connection Manager. Provides verbose output.

.NOTES
    THIS CODE-SAMPLE IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED 
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR 
    FITNESS FOR A PARTICULAR PURPOSE.

    This sample is not supported under any Microsoft standard support program or service. 
    The script is provided AS IS without warranty of any kind. Microsoft further disclaims all
    implied warranties including, without limitation, any implied warranties of merchantability
    or of fitness for a particular purpose. The entire risk arising out of the use or performance
    of the sample and documentation remains with you. In no event shall Microsoft, its authors,
    or anyone else involved in the creation, production, or delivery of the script be liable for 
    any damages whatsoever (including, without limitation, damages for loss of business profits, 
    business interruption, loss of business information, or other pecuniary loss) arising out of 
    the use of or inability to use the sample or documentation, even if Microsoft has been advised 
    of the possibility of such damages, rising out of the use of or inability to use the sample script, 
    even if Microsoft has been advised of the possibility of such damages. 

#>
##########################################################################################################

#Requires -Version 3
#Requires -RunAsAdministrator
#Requires -Modules Azure

#Version: 1.1
<# 
   - 18/09/2015
     * fixed an issue picking up RDP settings from a new cloud deployments
#>

#Define and validate mandatory parameters
[CmdletBinding()]
Param(
      #The Cloud Service name, e.g. IANCLOUD
      [parameter(Mandatory,Position=1,ValueFromPipeLine)]
      [ValidateScript({Get-AzureService -ServiceName $_})] 
      [String]$ServiceName,

      #The location of the output file, e.g. c:\windows\temp\
      [parameter(Mandatory,Position=2)]
      [ValidateScript({Test-Path -Path $_ -PathType Container})]
      [String]$FolderPath
      )

#Cloud service name to upper case
$ServiceName = $ServiceName.ToUpper()

#Define a here-string for our rdg file xml structure
Write-Verbose "$(Get-Date -f T) - Populating master XML template for $ServiceName service"
[XML]$RdgFile = @"
<?xml version="1.0" encoding="utf-8"?>
<RDCMan schemaVersion="1">
    <version>2.2</version>
    <file>
        <properties>
            <name>Azure - $ServiceName</name>
            <expanded>True</expanded>
            <comment>RDP connections for Azure cloud service - $ServiceName</comment>
            <logonCredentials inherit="FromParent" />
            <connectionSettings inherit="FromParent" />
            <gatewaySettings inherit="FromParent" />
            <remoteDesktop inherit="FromParent" />
            <localResources inherit="FromParent" />
            <securitySettings inherit="FromParent" />
            <displaySettings inherit="FromParent" />
        </properties>
    </file>
</RDCMan>
"@

#Get the VMs for service in question
Write-Verbose "$(Get-Date -f T) - Getting the VM instances for $($ServiceName)"
$VMs = Get-AzureVM -ServiceName $ServiceName

#Get the service FQDN
$ServiceFqdn = (($VMs | Select-Object -First 1).DNSName -Split "/")[2]
Write-Verbose "$(Get-Date -f T) - Service FQDN set to $($ServiceFqdn)"

#Loop through the VMs
foreach ($VM in $VMs) {

    #Get the RDP endpoint information
    $VmPort = (Get-AZureVm -ServiceName $ServiceName -Name $VM.InstanceName  | Get-AzureEndpoint -Name RDP).Port

    #Check we have a port
    if ($VmPort) {

        Write-Verbose "$(Get-Date -f T) - $(($VM).InstanceName) RDP port is $VmPort"

    }   #End of if ($VmPort)
    else {
        
        #Try and get the remote desktop port for a client OS
        $VmPort = (Get-AZureVm -ServiceName $ServiceName -Name $VM.InstanceName  | Get-AzureEndpoint -Name "Remote Desktop").Port
        
        if ($VmPort) {

            Write-Verbose "$(Get-Date -f T) - $(($VM).InstanceName) Remote Desktop port is $VmPort"

        }   #End of 1st inner if ($VmPort)
        else {

            #Try and get the remote desktop port for a client OS
            $VmPort = (Get-AZureVm -ServiceName $ServiceName -Name $VM.InstanceName  | Get-AzureEndpoint -Name "RemoteDesktop").Port
        
            if ($VmPort) {

                Write-Verbose "$(Get-Date -f T) - $(($VM).InstanceName) RemoteDesktop port is $VmPort"

            }   #End of 2nd inner if ($VmPort)
            else {

                $VmPort = 3389
                Write-Verbose "$(Get-Date -f T) - $(($VM).InstanceName) default port is $VmPort"

            } #End of 2nd inner else ($VmPort)

        }   #End of 1st inner else ($VmPort)

    }   #End of else ($VmPort)


#Define a here-string for our rdg file xml server node
Write-Verbose "$(Get-Date -f T) - Populating server XML configuration for $(($VM).InstanceName)"
[XML]$ServerNode = @"
<server>
    <name>$ServiceFqdn</name>
    <displayName>$(($VM).InstanceName)</displayName>
    <comment>RDP configuration for $(($VM).InstanceName)</comment>
    <logonCredentials inherit="FromParent" />
    <connectionSettings inherit="None">
        <connectToConsole>True</connectToConsole>
        <startProgram />
        <workingDir />
        <port>$VmPort</port>
    </connectionSettings>
    <gatewaySettings inherit="FromParent" />
    <remoteDesktop inherit="FromParent" />
    <localResources inherit="FromParent" />
    <securitySettings inherit="FromParent" />
    <displaySettings inherit="FromParent" />
</server>
"@

    #Create an import template for the server node
    Write-Verbose "$(Get-Date -f T) - Creating $(($VM).InstanceName) server configuration template for XML append"
    $ImportNode = $RdgFile.ImportNode($ServerNode.Server,$true)

    #Append the template to our existing XML document
    Write-Verbose "$(Get-Date -f T) - Appending $(($VM).InstanceName) server configuration template to master XML $ServiceName template"
    $RdgFile.RDCMan.File.AppendChild($ImportNode) | Out-Null

}   #End of foreach ($VM in $VMs)
        
    #Update the NetCfg file with parameter values
    Write-Verbose "$(Get-Date -f T) - Exporting master XML template to remote desktop group file"
    Set-Content -Value $RdgFile.InnerXml -Path "$($FolderPath)\$($ServiceName).rdg"

    #Error handling
    if (!$?) {

        #Write Error and exit
        Write-Error "Unable to create $RdgFileFile" -ErrorAction Stop

    }   #End of if (!$?)
    else {

        #Troubleshooting message
        Write-Verbose "$(Get-Date -f T) - $($ServiceName).rdg successfully created"

    }   #End of else (!$?)


}   #End of function Create-AzureServiceRdgFile


##########################################################################################################