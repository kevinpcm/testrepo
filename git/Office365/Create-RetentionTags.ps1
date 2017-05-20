<#

    .SYNOPSIS 
        1.	Enables Organization Customization in tenant, if it hasn’t already been enabled.
        2.	Creates a Retention Policy specified at run-time (or uses one that already exists by the same name)
        3.	Imports from a txt file or directly from pipeline, a list of Outlook Default Folders. For example:
            a.	Mail Folders (such as... Inbox, Sent Items etc.)
            b.	Non-Mail Folders (such as... Calendar, Contacts, Tasks etc.)
        4.	Creates Retention Policy Tags (RPT)
            a.  Name comprised of a TagPrefix + Folder + Suffix (Suffix is auto-generated based on # of days)
            b.	TagPrefix/RetentionAge/Action defined at run-time
            c.  When specifying parameter -ActionRPT, user can tab through the four available choices
            d.	If the RPT already exists, script will silently continue
        5.	Creates a Default Policy Tag (DPT) if specified (not mandatory)
            a.  Name comprised of a TagPrefix + DefaultPolicyTagName + Suffix (Suffix is auto-generated based on # of days)
            b.	TagPrefix/RetentionAge/Action defined at run-time
            c.  When specifying parameter -ActionDPT, user can tab through the four available choices
            d.	If the specified DPT already exists, script will silently continue
            e.  If the Retention Policy specified already has a DPT linked to it, script will output to screen which DPT is linked and continue
        6.	For indefinite RetentionAge/AgeLimit, specify a value of "0" for the parameters, AgeLimitRPT and/or AgeLimitDPT
        7.	The specifed Retention Policy will be automatically linked to any RPTs and a DPT, IF they were created by the script
        8.	If desired, script removes the ability for end-users to create and use Personal Tags (which override DPT & RPTs) by:
            a.	Removing "MyRetentionPolicies" role from the default role assignment policy named, "Default Role Assignment Policy"
            b.	The policy, "Default Role Assignment Policy" is utilized unless the switch, "-CustomRoleAssignmentPolicy" is used to specify another Management Role Assignment Policy

            
    .DESCRIPTION
        There are 3 things this function creates as new:
        1. Retention Policy [One] (if already exists, new RPTs will be linked to it)
        2. Retention Policy Tags [One or More] (created, and then linked to specified Retention Policy)
        3. Default Policy Tag [Zero or One] (Only one DPT can be linked to a single Retention Policy, so the script checks if a DPT is already linked prior to trying to link another)
        
        Summary: 
                Use this function to create retention tags and link them to a new or existing retention policy. 

        Mandatory parameters are: 
                RetentionPolicyName, TagPrefix, AgeLimitRPT, and Folders
                
        Non-Mandatory parameters are: 
                DefaultPolicyTagName, AgeLimitDPT, ActionDPT, ActionRPT, PreventPersonalTags, CustomRoleAssignmentPolicy

    .EXAMPLE    
        "Clutter","DeletedItems","Drafts","Inbox","JunkEmail","Outbox","SentItems","SyncIssues","ConversationHistory" | Add-RetentionPoliciesandTags -RetentionPolicyName "Corp Retention Policy" -DefaultPolicyTagName "DPT" -TagPrefix "Corp" -AgeLimitRPT 83 -AgeLimitDPT 83 -ActionRPT PermanentlyDelete -ActionDPT PermanentlyDelete -PreventPersonalTags
        "Calendar","Contacts","Notes","Tasks","Journal","RssSubscriptions" |  Add-RetentionPoliciesandTags -RetentionPolicyName "Corp Retention Policy" -TagPrefix "Corp" -AgeLimitRPT 0 -PreventPersonalTags
    
    .EXAMPLE
        $Folders = Get-Content .\folders.txt
        $Folders | Add-RetentionPoliciesandTags -RetentionPolicyName "Corporate Policy" -DefaultPolicyTagName "DPT" -TagPrefix "Corporate" -AgeLimitRPT 30 -AgeLimitDPT 30 -ActionDPT PermanentlyDelete -ActionRPT PermanentlyDelete -PreventPersonalTags

    .EXAMPLE    
        "Inbox", "Calendar" | Add-RetentionPoliciesandTags -RetentionPolicyName "Corporate Policy" -DefaultPolicyTagName "DPT" -TagPrefix "Corporate" -AgeLimitRPT 30 -AgeLimitDPT 30 -ActionDPT PermanentlyDelete -ActionRPT PermanentlyDelete -PreventPersonalTags
    
    .EXAMPLE    
        "Inbox", "SentItems" | Add-RetentionPoliciesandTags -RetentionPolicyName "Corporate Policy" -TagPrefix "Corporate" -AgeLimitRPT 30 -ActionRPT DeleteAndAllowRecovery -PreventPersonalTags

    .EXAMPLE    
        $Folders = Get-Content .\folders.txt
        $Folders | Add-RetentionPoliciesandTags -RetentionPolicyName "Corporate Policy" -DefaultPolicyTagName "DPT" -TagPrefix "Corporate" -AgeLimitRPT 0 -AgeLimitDPT 0

    .EXAMPLE    
        "Inbox" | Add-RetentionPoliciesandTags -RetentionPolicyName "Corporate Policy" -DefaultPolicyTagName "DPT" -TagPrefix "Corporate" -AgeLimitRPT 0 -AgeLimitDPT 0 -CustomRoleAssignmentPolicy "Corporate Role Assignment Policy"

    .EXAMPLE     
        Examples of: Mail Folders
        "Clutter","DeletedItems","Drafts","Inbox","JunkEmail","Outbox","SentItems","SyncIssues","ConversationHistory"

        Examples of: Non Mail Folders
        "Calendar","Contacts","Notes","Tasks","Journal","RssSubscriptions"
        
    .EXAMPLE   
        Example of: Text file (header should not be present)
        Inbox
        JunkEmail
        Outbox
        SentItems         
#>

function Add-RetentionPoliciesandTags {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $True)]
        [ValidateNotNullOrEmpty()] [string] $RetentionPolicyName,
        [parameter(Mandatory = $False)]
        [ValidateNotNullOrEmpty()] [string] $DefaultPolicyTagName,
        [parameter(Mandatory = $True)]
        [ValidateNotNullOrEmpty()] [string] $TagPrefix, 
        [parameter(Mandatory = $True)]
        [ValidateNotNullOrEmpty()] [string] $AgeLimitRPT, 
        [parameter(Mandatory = $False)]
        [ValidateNotNullOrEmpty()] [string] $AgeLimitDPT,         
        [parameter(Mandatory = $False)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("MarkAsPastRetentionLimit", "DeleteAndAllowRecovery", "PermanentlyDelete", "MoveToArchive")] [string] $ActionDPT,       
        [parameter(Mandatory = $False)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("MarkAsPastRetentionLimit", "DeleteAndAllowRecovery", "PermanentlyDelete", "MoveToArchive")] [string] $ActionRPT,      
        [parameter(Mandatory = $True, ValueFromPipeline = $True)]
        [ValidateNotNullOrEmpty()] $Folders,
        [parameter(Mandatory = $False)]
        [ValidateNotNullOrEmpty()] [switch] $PreventPersonalTags,
        [parameter(Mandatory = $False)]
        [ValidateNotNullOrEmpty()] [string] $CustomRoleAssignmentPolicy
    )

    BEGIN {
        # Enables Organization Customization
        Enable-OrganizationCustomization -ErrorAction SilentlyContinue

        # Checks AgeLimitRPT and AgeLimitDPT and assigns correct suffix for tags AND assigns value for "RetentionEnabled" for New-RetentionPolicyTag
        if ($AgeLimitDPT -eq "0") {
            $SuffixDPT = " Unlimited"    
            $RetEnabledDPT = [bool]$False
        }
        else {
            if (!($ActionDPT)) {
                Write-Output "Must specify value for ActionDPT when providing a non-zero value for AgeLimitDPT"
                break
            }
            $SuffixDPT = " $AgeLimitDPT Days"
            $RetEnabledDPT = [bool]$True  
        }
        if ($AgeLimitRPT -eq "0") {
            $SuffixRPT = " Unlimited"
            $RetEnabledRPT = [bool]$False
        }
        else {
            if (!($ActionRPT)) {
                Write-Output "Must specify value for ActionRPT when providing a non-zero value for AgeLimitRPT"
                break
            }
            $SuffixRPT = " $AgeLimitRPT Days"
            $RetEnabledRPT = [bool]$True
        }
        # Create Retention Policy if it does not already exist
        if (Get-RetentionPolicy $RetentionPolicyName -ErrorAction SilentlyContinue) {
            $ForLinks = Get-RetentionPolicy $RetentionPolicyName
        }
        else {
            New-RetentionPolicy -name $RetentionPolicyName
            $ForLinks = Get-RetentionPolicy $RetentionPolicyName
        }
        # Create Default Policy Tag for any User-Created Folders if it does not already exist and link to the specified Retention Policy
        $Policy = Get-RetentionPolicy $RetentionPolicyName -ErrorAction SilentlyContinue
        $DPTexists = $policy.RetentionPolicyTagLinks | Get-RetentionPolicyTag -ErrorAction SilentlyContinue | Where-Object {$_.type -eq 'all'}
        if ($DPTexists) {
            Write-Output "The Retention Policy specified, `"$Policy`" already has the Default Policy Tag (DPT) `"$DPTexists`" assigned to it."
        }        
        else {
            if ($DefaultPolicyTagName) {
                $DPTName = "$TagPrefix " + "$DefaultPolicyTagName" + "$SuffixDPT"
                if (!(Get-RetentionPolicyTag $DPTName -ErrorAction SilentlyContinue)) {
                    if ($AgeLimitRPT -eq "0") {
                        New-RetentionPolicyTag -Name $DPTName -Type "all" -RetentionEnabled:$RetEnabledDPT 
                    }
                    else {
                        New-RetentionPolicyTag -Name $DPTName -Type "all" -AgeLimitForRetention $AgeLimitDPT -RetentionAction $ActionDPT -RetentionEnabled:$RetEnabledDPT
                    }                 
                }
                if (!($ForLinks.RetentionPolicyTagLinks -match $DPTName)) {
                    $TagList = (Get-RetentionPolicy $RetentionPolicyName).RetentionPolicyTagLinks
                    $TagList.Add((Get-RetentionPolicyTag $DPTName).DistinguishedName)
                    Set-RetentionPolicy $RetentionPolicyName -RetentionPolicyTagLinks $TagList
                }
            }
        }
    }

    PROCESS {
        # Create Retention Policies for Default Mail Folders if they do not already exist and link to the specified Retention Policy
        $Tag = "$TagPrefix " + $_ + "$SuffixRPT"
        if (!(Get-RetentionPolicyTag $Tag -ErrorAction SilentlyContinue)) {
            Write-Output "Creating RPT: $Tag"
            if ($AgeLimitRPT -eq "0") {
                New-RetentionPolicyTag -Name $Tag -Type $_ -RetentionEnabled:$RetEnabledRPT
            }
            else {
                New-RetentionPolicyTag -Name $Tag -Type $_ -AgeLimitForRetention $AgeLimitRPT -RetentionAction $ActionRPT -RetentionEnabled:$RetEnabledRPT
            }
            
        }
        if (!($ForLinks.RetentionPolicyTagLinks -match $Tag)) {
            $TagList = (Get-RetentionPolicy $RetentionPolicyName).RetentionPolicyTagLinks
            $TagList.Add((Get-RetentionPolicyTag $Tag).DistinguishedName)
            Set-RetentionPolicy $RetentionPolicyName -RetentionPolicyTagLinks $TagList
        }
        
    }

    END {
        # Remove Ability for Users to Create and Use Personal Tags
        if ($PreventPersonalTags) {
            if (!($CustomRoleAssignmentPolicy)) {
                if (Get-ManagementRoleAssignment -RoleAssignee "Default Role Assignment Policy" -Role "MyRetentionPolicies" -ErrorAction SilentlyContinue) {
                    Get-ManagementRoleAssignment -RoleAssignee "Default Role Assignment Policy" -Role "MyRetentionPolicies" | Remove-ManagementRoleAssignment -confirm:$false
                }
            }
            else {
                if (Get-ManagementRoleAssignment -RoleAssignee $CustomRoleAssignmentPolicy -ErrorAction SilentlyContinue) {
                    if (Get-ManagementRoleAssignment -RoleAssignee $CustomRoleAssignmentPolicy -Role "MyRetentionPolicies" -ErrorAction SilentlyContinue) {
                        Get-ManagementRoleAssignment -RoleAssignee $CustomRoleAssignmentPolicy -Role "MyRetentionPolicies" | Remove-ManagementRoleAssignment -confirm:$false
                    }
                }
            }  
        }
    }
}