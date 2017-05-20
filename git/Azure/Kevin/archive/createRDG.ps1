

$rdcmanName = "Azure VMs"
$outputFileName = Get-Location | Join-Path -ChildPath "AzureVMs.rdg"

$xml = [xml]'<?xml version="1.0" encoding="utf-8"?>
<RDCMan programVersion="2.7" schemaVersion="3">
  <file>
    <credentialsProfiles />
    <properties>
      <expanded>True</expanded>
      <name>Azure VMs</name>
    </properties>
    <encryptionSettings inherit="None">
      <encryptionMethod>LogonCredentials</encryptionMethod>
      <credentialName></credentialName>
      <credentialData />
    </encryptionSettings>
    <group>
      <properties>
        <expanded>False</expanded>
        <name>groupname</name>
      </properties>
      <server>
        <properties>
          <displayName>displayname</displayName>
          <name>servername</name>
        </properties>
        <connectionSettings inherit="None">
          <connectToConsole>False</connectToConsole>
          <startProgram />
          <workingDir />
          <port>12345</port>
          <loadBalanceInfo></loadBalanceInfo>
        </connectionSettings>
      </server>
    </group>
  </file>
  <connected />
  <favorites />
  <recentlyUsed />
</RDCMan>'

$fileElement =$xml.RDCMan.file
$groupTemplateElement =$xml.RDCMan.file.group
$serverTemplateElement = $groupTemplateElement.server
$fileElement.properties.name = $rdcmanName
function getDisplayName($name){
    $name.Replace("http://", "").Replace("https://","").TrimEnd('/')
}
function addServerElementToGroup($group, $name, $displayName, $port, $loadBalanceInfo){
    $serverElement = $serverTemplateElement.Clone()
    $serverElement.properties.name = getDisplayName $name
    $serverElement.properties.displayName = $displayName

    $serverElement.connectionSettings.port = $port.ToString()
    if ($loadBalanceInfo -ne $null){
        $serverElement.connectionSettings.loadBalanceInfo = $loadBalanceInfo
    }
    $group.AppendChild($serverElement) | out-null 
}
function getGroup($element, $groupName){
    $group = $xml.RDCMan.file.group | ?{ $_.properties.name -eq $groupName} | Select-Object -First 1
    if ($group -eq $null){
        $group = $groupTemplateElement.Clone()
        $group.properties.name = $groupName
        $group.RemoveChild($group.server)
        $element.AppendChild($group) | out-null
    }
    return $group
}
function addServer(){
    param(
		    [Parameter(Mandatory=$True,
		    ValueFromPipeline=$True)]
		    [object[]]$info
	    )
    process{
        $group = getGroup $fileElement $info.ServiceName
        if ($info.RoleName -ne $null) {
            $group = getGroup $group $info.RoleName
        }
        if ($info.Slot -ne $null) {
            $group = getGroup $group $info.Slot
        }
        addServerElementToGroup $group $info.Name $info.DisplayName $info.Port $info.LoadBalanceInfo
    }
}
Get-AzureRmResourceGroup | %{
    $service = $_
    $serviceName = $service.ResourceGroupName

    Get-AzureRmVM -ResourceGroupName $serviceName  | %{
        $vm = $_
        $rdpEndpoints = @($vm.VM.ConfigurationSets.InputEndpoints | ?{$_.LocalPort -eq 3389}) 
        if($rdpEndpoints.Length -gt 0){
            New-Object PSObject -Property @{
                ServiceName = $serviceName
                Name = $vm.DNSName
                DisplayName = $vm.Name
                Port = $rdpEndpoints[0].Port
            }
        }
    }

    $production = @(Get-AzureRmResourceGroupDeployment -ResourceGroupName $serviceName)
    $staging = @(Get-AzureRmResourceGroupDeployment -ResourceGroupName $serviceName)
    $combined = $production + $staging
    $combined | %{
        $deployment = $_
        $deployment.RoleInstanceList | ?{
                ($_.InstanceEndpoints | ?{$_.Port -eq 3389}).Count -gt 0
            } | %{
            $roleInstance = $_
            New-Object PSObject -Property @{
                ServiceName = $serviceName
                Name = $deployment.Url.ToString()
                RoleName = $roleInstance.RoleName
                Slot = $deployment.Slot
                DisplayName = $roleInstance.InstanceName
                Port = 3389
                LoadBalanceInfo = "Cookie: mstshash=" + $roleInstance.RoleName + "#" + $roleInstance.InstanceName
            }
        }
    }
} | addServer # add to the tree

$fileElement.RemoveChild($groupTemplateElement) | out-null

$xml.Save($outputFileName)