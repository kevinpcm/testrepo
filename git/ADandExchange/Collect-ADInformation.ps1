<### Collect Active Directory information
# Author: James Brennan, EnPointe
#
# Version 1.1
#
### Requires the following modules:
### ActiveDirectory, DNSServer, GroupPolicy, BestPractices
#
# 051016 JB Added parameters to specify forest and collected data
#>
Param(
   [string]$ADForest,
   [switch]$getAll,
   [switch]$getDC,
   [switch]$getAD,
   [switch]$getDNS,
   [switch]$getDHCP,
   [switch]$getSites,
   [switch]$getGPO,
   [switch]$getReplication,
   [switch]$getMissingSubnets
)
#
Import-Module ActiveDirectory
Import-Module GroupPolicy

# Get AD Forest Obejct
Function Get-ActiveDirectoryForestObject {
Param ([string]$ForestName, [System.Management.Automation.PsCredential]$Credential)

    #if forest is not specified, get current context forest
    If (!$ForestName)     
    {        $ForestName = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest().Name.ToString()    
    }        

    If ($Credential)     
    {        
        $credentialUser = $Credential.UserName.ToString()
        $credentialPassword = $Credential.GetNetworkCredential().Password.ToString()
        $adCtx = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext("forest", $ForestName, $credentialUser, $credentialPassword )
    }    
    Else     
    {        
        $adCtx = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext("forest", $ForestName)    
    }        

    $output = ([System.DirectoryServices.ActiveDirectory.Forest]::GetForest($adCtx))    

    Return $output
}

### Extracted from DNSFunctions.ps1
###############################################################################

Function Export-DNSServerIPConfiguration {
param($Domain)

    # Get the DNS configuration of each child DC
    $DNSReport = @()

    ForEach ($DomainEach in $Domain) {
        # Get a list of DCs without using AD Web Service
        $DCs = netdom query /domain:$DomainEach dc |
            Where-Object {$_ -notlike "*accounts*" -and $_ -notlike "*completed*" -and $_}

        ForEach ($dc in $DCs) {

            # Forwarders
            $dnsFwd = Get-WMIObject -ComputerName $("$dc.$DomainEach") `
                -Namespace root\MicrosoftDNS -Class MicrosoftDNS_Server `
                -ErrorAction SilentlyContinue

            # Primary/Secondary (Self/Partner)
            # http://msdn.microsoft.com/en-us/library/windows/desktop/aa393295(v=vs.85).aspx
            $nic = Get-WMIObject -ComputerName $("$dc.$DomainEach") -Query `
                "Select * From Win32_NetworkAdapterConfiguration Where IPEnabled=TRUE" `
                -ErrorAction SilentlyContinue

            $DNSReport += 1 | Select-Object `
                @{name="DC";expression={$dc}}, `
                @{name="Domain";expression={$DomainEach}}, `
                @{name="DNSHostName";expression={$nic.DNSHostName}}, `
                @{name="IPAddress";expression={$nic.IPAddress}}, `
                @{name="DNSServerAddresses";expression={$dnsFwd.ServerAddresses}}, `
                @{name="DNSServerSearchOrder";expression={$nic.DNSServerSearchOrder}}, `
                @{name="Forwarders";expression={$dnsFwd.Forwarders}}, `
                @{name="BootMethod";expression={$dnsFwd.BootMethod}}, `
                @{name="ScavengingInterval";expression={$dnsFwd.ScavengingInterval}}

        } # End ForEach

    }

    $DNSReport | Format-Table -AutoSize -Wrap
    $DNSReport | Export-CSV $logfile-DC_DNS_IP_Report.csv -NoTypeInformation
}

# Enumerate all DCs in each domain supplied
# For each DC collect all relevant DNS server and client IP configuration information
# Uses NETDOM to query a list of domain controllers in case you are targeting a legacy environment
#
# Export-DNSServerIPConfiguration -Domain 'contoso.com','na.contoso.com','eu.contoso.com'


###############################################################################

Function Export-DNSServerZoneReport {
param($Domain)

    # This report assumes that all DCs are running DNS.
    $Report = @()

    ForEach ($DomainEach in $Domain) {
        # Get a list of DCs without using AD Web Service
        # You may see RiverBed devices returned in this list.
        $DCs = netdom query /domain:$DomainEach dc |
            Where-Object {$_ -notlike "*accounts*" -and $_ -notlike "*completed*" -and $_}

        ForEach ($dc in $DCs) {

            $DCZones = $null
            Try {
                $DCZones = Get-DnsServerZone -ComputerName $("$dc.$DomainEach") |
                    Select-Object @{Name="Domain";Expression={$DomainEach}}, @{Name="Server";Expression={$("$dc.$DomainEach")}}, ZoneName, ZoneType, DynamicUpdate, IsAutoCreated, IsDsIntegrated, IsReverseLookupZone, ReplicationScope, DirectoryPartitionName, MasterServers, NotifyServers, SecondaryServers

                ForEach ($Zone in $DCZones) {
                    If ($Zone.ZoneType -eq 'Primary') {
                        $ZoneAging = Get-DnsServerZoneAging -ComputerName $("$dc.$DomainEach") -ZoneName $Zone.ZoneName |
                            Select-Object ZoneName, AgingEnabled, NoRefreshInterval, RefreshInterval, ScavengeServers
                        Add-Member -InputObject $Zone -MemberType NoteProperty -Name AgingEnabled -Value $ZoneAging.AgingEnabled
                        Add-Member -InputObject $Zone -MemberType NoteProperty -Name NoRefreshInterval -Value $ZoneAging.NoRefreshInterval
                        Add-Member -InputObject $Zone -MemberType NoteProperty -Name RefreshInterval -Value $ZoneAging.RefreshInterval
                        Add-Member -InputObject $Zone -MemberType NoteProperty -Name ScavengeServers -Value $ZoneAging.ScavengeServers
                    } Else {
                        Add-Member -InputObject $Zone -MemberType NoteProperty -Name AgingEnabled -Value $null
                        Add-Member -InputObject $Zone -MemberType NoteProperty -Name NoRefreshInterval -Value $null
                        Add-Member -InputObject $Zone -MemberType NoteProperty -Name RefreshInterval -Value $null
                        Add-Member -InputObject $Zone -MemberType NoteProperty -Name ScavengeServers -Value $null
                    }
                }

            $Report += $DCZones
        } Catch {
            Write-Warning "Error connecting to $dc.$DomainEach."
        }

        } # End ForEach

    }

    $Report | Export-CSV -Path $logfile-DNS_Zones.csv -NoTypeInformation -Force -Confirm:$false
}

# Enumerate all DCs in each domain supplied
# For each DC collect all DNS zones hosted on that server
# Export a CSV file of all data
# Uses NETDOM to query a list of domain controllers in case you are targeting a legacy environment
#
# Export-DNSServerZoneReport -Domain 'contoso.com','na.contoso.com','eu.contoso.com'

### Copied from Find_missing_subnets_in_ActiveDirectory.ps1
###############################################################################
Function Find-Missing-Subnets {
<# START:Find_missing_subnets_in_ActiveDirectory
  This script will get all the missing subnets from the NETLOGON.LOG file from each
  Domain Controller in the Domain. It does this by copying all the NETLOGON.LOG files
  locally and then parsing them all to create a CSV output of unique IP Addresses.
  The CSV file is sorted by IP Address to make it easy to group them into subnets.

  Script Name: Find_missing_subnets_in_ActiveDirectory.ps1
  Release 1.2
  
  Syntax examples:

  - To execute the script in the current Domain:
      Find_missing_subnets_in_ActiveDirectory.ps1

    This script was derived from the AD-Find_missing_subnets_in_ActiveDirectory.ps1
  script written by Francois-Xavier CAT.
   - Report the AD Missing Subnets from the NETLOGON.log
     http://www.lazywinadmin.com/2013/10/powershell-report-ad-missing-subnets.html

  Changes:
  - Stripped down the code to remove the e-mail functionality. This is a nice to
    have feature and can be added back in for a future release. I felt that it was
    more important to focus on ensuring the core functionality of the script was
    working correctly and efficiently.

  Improvements:
  - Reordered the Netlogon.log collection to make it more efficient.
  - Implemented a fix to deal with the changes to the fields in the Netlogon.log
    file from Windows 2012 and above:
    - http://www.jhouseconsulting.com/2013/12/13/a-change-to-the-fields-in-the-netlogon-log-file-from-windows-2012-and-above-1029
  - Tidied up the way it writes the CSV file.
  - Changed the write-verbose and write-warning messages to write-host to vary the
    message colors and improve screen output.
  - Added a "replay" feature so that you have the ability to re-create the CSV
    from collected log files.
#>
#-------------------------------------------------------------
param($TrustedDomain)
#-------------------------------------------------------------

# Set this to the last number of lines to read from each NETLOGON.log file.
# This allows the report to contain the most recent and relevant errors.
[Int]$LogsLines = "200"

# Set this to $True to remove txt and log files from the output folder.
$Cleanup = $False

# Set this to $True if you have not removed the log files and want to replay
# them to create a CSV.
$ReplayLogFiles = $False

#-------------------------------------------------------------

# PATH Information 
# Date and Time Information
$DateFormat = Get-Date -Format "yyyyMMdd_HHmmss"
$ScriptPathOutput = ".\$Logfile-Subnets"
$OutputFile = "$logfile-AD-Sites-MissingSubnets.csv"

$CombineAndProcess = $False

IF ($ReplayLogFiles -eq $False)
{
  IF (-not(Test-Path -Path $ScriptPathOutput))
  {
    Write-Host -ForegroundColor green "Creating the Output Folder: $ScriptPathOutput"
    New-Item -Path $ScriptPathOutput -ItemType Directory | Out-Null
  }

  if ([String]::IsNullOrEmpty($TrustedDomain)) {
    # Get the Current Domain Information
    $domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
  } else {
    $context = new-object System.DirectoryServices.ActiveDirectory.DirectoryContext("domain",$TrustedDomain)
    Try {
      $domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetDomain($context)
    }
    Catch [exception] {
      write-host -ForegroundColor red $_.Exception.Message
      Exit
    }
  }

  Write-Host -ForegroundColor green "Domain: $domain"

  # Get the names of all the Domain Contollers in $domain
  Write-Host -ForegroundColor green "Getting all Domain Controllers from $domain ..."
  $DomainControllers = $domain | ForEach-Object -Process { $_.DomainControllers } | Select-Object -Property Name

  # Gathering the NETLOGON.LOG for each Domain Controller
  Write-Host -ForegroundColor green "Processing each Domain controller..."
  FOREACH ($dc in $DomainControllers)
  {
    $DCName = $($dc.Name)

    # Get the Current Domain Controller in the Loop
    Write-Host -ForegroundColor green "Gathering the log from $DCName..."

    IF (Test-Connection -Cn $DCName -BufferSize 16 -Count 1 -ea 0 -quiet) {

      # NETLOGON.LOG path for the current Domain Controller
      $path = "\\$DCName\admin`$\debug\netlogon.log"

      # Testing the $path
      IF ((Test-Path -Path $path) -and ((Get-Item -Path $path).Length -ne $null))
      {
        # Copy the NETLOGON.log locally for the current DC
        Write-Host -ForegroundColor green "- Copying the $path file..."
        $TotalTime = measure-command {Copy-Item -Path $path -Destination $ScriptPathOutput\$($dc.Name)-$DateFormat-netlogon.log}
        $TotalSeconds = $TotalTime.TotalSeconds
        Write-Host -ForegroundColor green "- Copy completed in $TotalSeconds seconds."

        IF ((Get-Content -Path $path | Measure-Object -Line).lines -gt 0)
        {
          # Export the $LogsLines last lines of the NETLOGON.log and send it to a file
          ((Get-Content -Path $ScriptPathOutput\$DCName-$DateFormat-netlogon.log -ErrorAction Continue)[-$LogsLines .. -1]) | 
            Foreach-Object {$_ -replace "\[\d{1,5}\] ", ""} |
            Out-File -FilePath "$ScriptPathOutput\$DCName.txt" -ErrorAction 'Continue' -ErrorVariable ErrorOutFileNetLogon
          Write-Host -ForegroundColor green "- Exported the last $LogsLines lines to $ScriptPathOutput\$DCName.txt."
        }#IF
        ELSE {Write-Host -ForegroundColor green "- File Empty."}

      } ELSE {Write-Host -ForegroundColor red "- $DCName is not reachable via the $path path."}

    } ELSE {Write-Host -ForegroundColor red "- $DCName is not reachable or offline."}

    $CombineAndProcess = $True

  }#FOREACH

} ELSE {

  Write-Host -ForegroundColor green "Replaying the log files..."
  IF (Test-Path -Path $ScriptPathOutput)
  {
    IF ((Get-ChildItem $scriptpathoutput\*.log | Measure-Object).Count -gt 0)
    {
      $LogFiles = Get-ChildItem $scriptpathoutput\*.log

      ForEach ($LogFile in $LogFiles)
      {
        $DCName = $LogFile.Name -Replace("-\d{7,8}_\d{6}-netlogon.log")
        Write-Host -ForegroundColor green "Processing the log from $DCName..."
        IF ((Get-Content -Path "$ScriptPathOutput\$($LogFile.Name)" | Measure-Object -Line).lines -gt 0)
        {
          # Export the $LogsLines last lines of the NETLOGON.log and send it to a file
          ((Get-Content -Path "$ScriptPathOutput\$($LogFile.Name)" -ErrorAction Continue)[-$LogsLines .. -1]) | 
                    Foreach-Object {$_ -replace "\[\d{1,5}\] ", ""} |
                    Out-File -FilePath "$ScriptPathOutput\$DCName.txt" -ErrorAction 'Continue' -ErrorVariable ErrorOutFileNetLogon
          Write-Host -ForegroundColor green "- Exported the last $LogsLines lines to $ScriptPathOutput\$DCName.txt."
        } ELSE {Write-Host -ForegroundColor green "- File Empty."}
        $CombineAndProcess = $True
      }#ForEach
    } ELSE {Write-Host -ForegroundColor red "There are no log files to process."}
  } ELSE {Write-Host -ForegroundColor red "The $ScriptpathOutput folder is missing."}
}#IF

IF ($CombineAndProcess)
{

  # Combine all the TXT file in one
  $FilesToCombine = Get-Content -Path "$ScriptPathOutput\*.txt" -Exclude "*All_Export.txt" -ErrorAction SilentlyContinue |
    Foreach-Object {$_ -replace "\[\d{1,5}\] ", ""}

  if ($FilesToCombine)
  {
    $FilesToCombine | Out-File -FilePath $ScriptPathOutput\$dateformat-All_Export.txt

    # Convert the TXT file to a CSV format
    Write-Host -ForegroundColor green "Importing exported data to a CSV format..."
    $importString = Import-Csv -Path $scriptpathOutput\$dateformat-All_Export.txt -Delimiter ' ' -Header Date,Time,Domain,Error,Name,IPAddress

    # Get Only the entries for the Missing Subnets
    $MissingSubnets = $importString | Where-Object {$_.Error -like "*NO_CLIENT_SITE*"}
    Write-Host -ForegroundColor green "Total of NO_CLIENT_SITE errors found within the last $LogsLines lines across all log files: $($MissingSubnets.count)"
    # Get the other errors from the log
    $OtherErrors = Get-Content $scriptpathOutput\$dateformat-All_Export.txt | Where-Object {$_ -notlike "*NO_CLIENT_SITE*"} | Sort-Object -Unique
    Write-Host -ForegroundColor green "Total of other Error(s) found within the last $LogsLines lines across all log files: $($OtherErrors.count)"

    # Export to a CSV File
    $UniqueIPAddresses = $importString | Select-Object -Property Date, Name, IPAddress, Domain, Error | 
    Sort-Object -Property IPAddress -Unique
    $UniqueIPAddresses | Export-Csv -notype -path "$OutputFile"
    # Remove the quotes
    (get-content "$OutputFile") |% {$_ -replace '"',""} | out-file "$OutputFile" -Fo -En ascii
    Write-Host -ForegroundColor green "$($UniqueIPAddresses.count) unique IP Addresses exported to $OutputFile."

  }#IF File to Combine
  ELSE {Write-Host -ForegroundColor red "No .txt files to process."}

  IF ($Cleanup)
  {
    Write-Host -ForegroundColor green "Removing the .txt and .log files..."
    Remove-item -Path $ScriptpathOutput\*.txt -force
    Remove-Item -Path $ScriptPathOutput\*.log -force
  }

}
Write-Host -ForegroundColor green "Script Completed."
} # END:Find_missing_subnets_in_ActiveDirectory

###############################################################################
Function Get-PrivilegedGroupChanges {
Param(
    $Server = (Get-ADDomainController -Discover | Select-Object -ExpandProperty HostName),
    $Hour = 24
)
    $ProtectedGroups = Get-ADGroup -Filter 'AdminCount -eq 1' -Server $Server
    $Members = @()

    ForEach ($Group in $ProtectedGroups) {
        $Members += Get-ADReplicationAttributeMetadata -Server $Server `
            -Object $Group.DistinguishedName -ShowAllLinkedValues |        
         Where-Object {$_.IsLinkValue} | 
         Select-Object @{name='GroupDN';expression={$Group.DistinguishedName}}, `
            @{name='GroupName';expression={$Group.Name}}, *
    }

    $Members |
        Where-Object {$_.LastOriginatingChangeTime -gt (Get-Date).AddHours(-1 * $Hour)}
}


### Collect Active Directory Information
# Collect Domain Controller Information
Write-Output "Collecting Forest and Domain Information..."
$DCs = @() #Initialize the DC array
$Forest = Get-ActiveDirectoryForestObject ($ADForest)
$DomainList = $forest.domains
# LogfileName
$LogFile=$DomainList.Name
# Domain List
$DomainList | % {
  $DCs += $_.DomainControllers | select Name
}
# Closest domain controller
$closestDC = (Get-ADDomainController -DomainName $Forest -Discover).Name
#
#### Collect Domain Controller information
if ($getAll -eq $true -or $getDC -eq $true) 
{
   Write-Output "Collecting Domain Controller Information..."
   $DCs | % { 
   $DCName = $_.name
   $PingHost = Test-Connection -computername $DCName -quiet
   echo "DC Name: $DCName"
   if (!$Pinghost) { write-host "Return Ping: $Pinghost" -foreground Red } else { echo "Return Ping: $Pinghost" }
   try
   {
     $ErrorActionPreference = "Stop"; #Throw a terminating error for a non-terminating error (can't contact server)
     Get-WmiObject win32_logicaldisk -computername $DCName | Where-Object { $_.DriveType -eq 3 } | select @{label="Drive";expression={$_.deviceid}}, @{label="Free Space (%)";expression={[Math]::Round(($_.FreeSpace/$_.Size)*100, 0)}} | colorize-row | fl
   }
   catch
   { #write the error message to the console
     'Error: {0}' -f $_.Exception.Message
   }
   finally { #reset the error action back to continue to keep running the script
   $ErrorActionPreference = "Continue"; #Reset the error action pref to default
   # Collect event logs
   Get-EventLog SYSTEM -Newest 5000 -Computer $DCName | Where-Object {$_.entrytype -match "Error" -or $_.entrytype -match "Warning"} |Export-csv $LogFile-$DCName-SYSTEM.csv
   }
  }
}
#
### Active Directory
if ($getAll -eq $true -or $getAD -eq $true) 
{
   Write-Output "Collecting AD Information..."

    $ADForestInfo =  Get-ADForest 
    
    $ApplicationPartitions=@{Name ="ApplicationPartitions";Expression ={$ADForestInfo.ApplicationPartitions}}
    $CrossForestReferences=@{Name ="CrossForestReferences";Expression ={$ADForestInfo.CrossForestReferences}}
    $DomainNamingMaster=@{Name ="DomainNamingMaster";Expression ={$ADForestInfo.DomainNamingMaster}}
    $Domains=@{Name ="Domains";Expression ={$ADForestInfo.Domains}}
    $ForestMode=@{Name ="ForestMode";Expression ={$ADForestInfo.ForestMode}}
    $GlobalCatalogs=@{Name ="GlobalCatalogs";Expression ={$ADForestInfo.GlobalCatalogs}}
    $Name=@{Name ="Name";Expression ={$ADForestInfo.Name}}
    $PartitionsContainer=@{Name ="PartitionsContainer";Expression ={$ADForestInfo.PartitionsContainer}}
    $RootDomain=@{Name ="RootDomain";Expression ={$ADForestInfo.RootDomain}}
    $SchemaMaster=@{Name ="SchemaMaster";Expression ={$ADForestInfo.SchemaMaster}}
    $Sites=@{Name ="Sites";Expression ={$ADForestInfo.Sites}}
    $SPNSuffixes=@{Name ="SPNSuffixes";Expression ={$ADForestInfo.SPNSuffixes}}
    $UPNSuffixes=@{Name ="UPNSuffixes";Expression ={$ADForestInfo.UPNSuffixes}}


   $ADForestInfo | Select $ApplicationPartitions,$CrossForestReferences,$DomainNamingMaster,$Domains,$ForestMode,$GlobalCatalogs,$Name,$PartitionsContainer,$RootDomain,$SchemaMaster,$Sites,$SPNSuffixes,$UPNSuffixes | Export-CSV $LogFile-ADForest.csv -NoTypeInformation
   Get-ADDomain | Export-CSV $LogFile-ADDomain.csv -NoTypeInformation
   Get-ADUser -server $closestDC -filter * -properties * | Export-CSV $LogFile-ADUsers.csv -NoTypeInformation
   Get-ADComputer -server $closestDC -filter * -properties * | Export-CSV $LogFile-ADComputers.csv -NoTypeInformation
   Get-ADGroup -server $closestDC -filter * -properties * | Export-CSV $LogFile-ADGroups.csv -NoTypeInformation
   #
   Get-ADUser -server $closestDC -filter 'AdminCount -eq 1' -Properties MemberOf | Select DistinguishedName,Enabled,GivenName,Name,SamAccountName,SID,Surname,ObjectClass,@{name="MemberOf";expression={$_.memberof -join "'n"}},ObjectGUID,UserPrincipalName|Export-Csv $logfile-ADUsers-Admin.csv -NoTypeInformation
   Get-ADGroup -server $closestDC -filter 'AdminCount -eq 1' -Properties Members | Select DistinguishedName,GroupCategory,GroupScope,Name,SamAccountName,ObjectClass,@{name="Members";expression={$_.members -join "'n"}},ObjectGUID,SID |Export-Csv $logfile-ADGroups-Admin.csv -NoTypeInformation
   Get-PrivilegedGroupChanges -Hour (365*24) | Export-Csv $LogFile-PrivGrpMemberChange.csv -NoTypeInformation
}
# 
### Collect AD Sites and Subnets
if ($getAll -eq $true -or $getSites -eq $true) 
{
   Write-Output "Collecting Site Information..."
   If (!$ADForest)
   {
      [array] $ADSites = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest().Sites
   }
   else
   {
      $adCtx = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext("forest", $ADForest)
      [array] $ADSites = [System.DirectoryServices.ActiveDirectory.Forest]::GetForest($adCtx).Sites
   }

   $ADSiteFile=$LogFile+'-ADSites.txt'
   # Header
   Add-Content $ADSiteFile “Domains!SiteName!Subnets!Servers!AdjacentSites!SiteLink!InterSiteTopologyGenerator!Options”

   ForEach ($Site in $ADSites)
    {
        $SiteName = $Site.Name
        $SiteDomains = $Site.Domains
        $SiteSubnets = $Site.Subnets
        $SiteServers = $Site.Servers
        $SiteAdjacentSites = $Site.AdjacentSites
        $SiteSiteLinks = $Site.SiteLinks
        $SiteInterSiteTopologyGenerator = $Site.InterSiteTopologyGenerator
        $SiteOptions = $Site.Options

        # Array for IP Subnets
        $IPSubnets += $SiteSubnets

        Add-Content $ADSiteFile “$SiteDomains!$SiteName!$SiteSubnets!$SiteServers!$SiteAdjacentSites!$SiteSiteLink!$SiteInterSiteTopologyGenerator!$SiteOptions”
    }
   # Export array to CSV
   $IPSubnets|Select Site,Name,Location |Export-CSV $LogFile-IPSubnets.csv -NoTypeInformation
   # Site Links
   Get-ADObject -Filter 'objectClass -eq "siteLink"' -Searchbase (Get-ADRootDSE).ConfigurationNamingContext -Property Options, Cost, ReplInterval, SiteList, Schedule | Select-Object Name, @{Name="SiteCount";Expression={$_.SiteList.Count}}, Cost, ReplInterval, @{Name="Schedule";Expression={If($_.Schedule){If(($_.Schedule -Join " ").Contains("240")){"NonDefault"}Else{"24x7"}}Else{"24x7"}}}, Options | Format-Table * -AutoSize | Out-File $LogFile-ADSiteLinks.txt
}
#
### Check Replication
if ($getAll -eq $true -or $getReplication -eq $true) 
{
   Write-Output "Collecting DCDiag and Replication Information..."
   dcdiag /a /c /v /f:$logfile-dcdiag.log
   repadmin /showrepl * /csv >$logfile-showrepl.csv
}
#
### GPO
if ($getAll -eq $true -or $getGPO -eq $true) 
{
   Write-Output "Collecting Group Policy Information..."
   Get-GPO -server $closestDC -all | export-csv $logfile-AllGPO.csv
   Get-GPOReport -server $closestDC -All -ReportType html > $logfile-GPO.htm
   
   ### GPO Links
   $AllADOU=get-ADOrganizationalUnit -server $closestDC -Filter * -Properties * | sort-object Canonicalname
   ForEach ($ADOU in $AllADOU)
   {
      $GPOLinks=Get-GPInheritance $ADOU.DistinguishedName
      ForEach ($GPOLink in $GPOLinks)
      {
         ForEach ($GPOID in $GPOLink.GpoLinks)
         {
            $ADOU.CanonicalName+"!"+$ADOU.ObjectGUID+"!"+$GPOID.DisplayName+"!Link!"+$GPOID.Enabled+"!"+$GPOID.Enforced+"!"+$GPOID.GpoId | Out-File $logfile-GPOLinks.txt -Append
         }
         ForEach ($GPOID in $GPOLink.InheritedGpoLinks)
         {
            $ADOU.CanonicalName+"!"+$ADOU.ObjectGUID+"!"+$GPOID.DisplayName+"!Inherit!"+$GPOID.Enabled+"!"+$GPOID.Enforced+"!"+$GPOID.GpoId | Out-File $logfile-GPOLinks.txt -Append
         }
      } 
   }
}
#
### Collect DHCP Export
if ($getAll -eq $true -or $getDHCP -eq $true) 
{
   Write-Output "Collecting DHCP Information..."
   netsh.exe dhcp server dump > $logfile-DHCPdump.txt
}
#
### DNS
if ($getAll -eq $true -or $getDNS -eq $true) 
{
   Write-Output "Collecting DNS Information..."
   Import-Module DNSServer
   # Requires Domain to be entered
   Export-DNSServerIPConfiguration -Domain $DomainList
   Export-DNSServerZoneReport -Domain $DomainList
}
#
### Best Practices
if ($getAll -eq $true -or $getBPA -eq $true) 
{
   Write-Output "Collecting BPA..."
   Import-Module BestPractices
   Invoke-Bpamodel -ModelId Microsoft/Windows/DirectoryServices
   Get-Bparesult -ModelID Microsoft/Windows/DirectoryServices | Where { $_.Severity -ne "Information" } | Set-BpaResult -Exclude $true| Export-CSV -Path $logfile-BPA-DC.csv
}
#
### Missing Subnets
if ($getAll -eq $true -or $getMissingSubnets -eq $true) 
{
   Write-Output "Collecting Missing Subnets..."
   Find-Missing-Subnets -TrustedDomain $DomainList.Name
}
#
### Finished
Write-Output "Finished"