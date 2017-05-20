<#
CSV should look like this (Header is DefaultFolder):

DefaultFolder
Clutter
DeletedItems
Drafts
Inbox
JunkEmail
Journal
Outbox
SentItems
RssSubscriptions
SyncIssues
ConversationHistory

User running script must be a member of Organization Management??


#>
param (
    [String]$RetentionPolicy    = "Corporate Retention Policy",
    [String]$DefaultPolicyTag   = "Corp Default Policy Tag",
    [String]$TagPrefixMail      = "Corp Retention Tag ",
    [String]$TagPrefixNonMail   = "Corp Retention Tag ",
    [String]$TagSuffixNonMail   = " Forever",
    [String]$PreventPersonalTag = "MyRetentionPolicies",
    [String]$RoleAssignment     = "Default Role Assignment Policy",
       [INT]$AgeLimit           = 1,
    [String]$DPTAction          = "PermanentlyDelete",
    [String]$RPTAction          = "PermanentlyDelete",
    [String]$RPTActionForever   = "DeleteAndAllowRecovery",
    [String]$MailCSV            = "defaultfolders.csv",
    [String]$NonMailCSV         = "calcontactstasksnotes.csv"
    
)
if(!(Test-Path $MailCSV)){
    Write-Output "$TheCSV not found!"
    Break
}
if(!(Test-Path $NonMailCSV)){
    Write-Output "$NonMailCSV not found!"
    Break
}
$Mail    = Import-Csv $MailCSV
$NonMail = Import-Csv $NonMailCSV
Enable-OrganizationCustomization -ErrorAction Ignore
# Create Default Policy Tag for any user-created folders
if (Get-RetentionPolicy $RetentionPolicy -ErrorAction Ignore) {
    $ForLinks = Get-RetentionPolicy $RetentionPolicy
}
else {
    New-RetentionPolicy -name $RetentionPolicy
    $ForLinks = Get-RetentionPolicy $RetentionPolicy
}
if (!(Get-RetentionPolicyTag $DefaultPolicyTag -ErrorAction Ignore)) {
    New-RetentionPolicyTag -Name $DefaultPolicyTag -Type all -AgeLimitForRetention $AgeLimit -RetentionAction $DPTAction -RetentionEnabled $True
}
if (!($ForLinks.RetentionPolicyTagLinks -match $DefaultPolicyTag)) {
    $TagList = (Get-RetentionPolicy $RetentionPolicy).RetentionPolicyTagLinks
    $TagList.Add((Get-RetentionPolicyTag $DefaultPolicyTag).DistinguishedName)
    Set-RetentionPolicy $RetentionPolicy -RetentionPolicyTagLinks $TagList
}
# Create Retention Policies for Default Mail Folders
foreach ($row in $Mail) {
    $Folder = $row.defaultfolder
    $Tag    = $TagPrefixMail + $Folder
    if (!(Get-RetentionPolicyTag $Tag -ErrorAction Ignore)) {
        New-RetentionPolicyTag -Name $Tag -Type $Folder -AgeLimitForRetention $AgeLimit -RetentionAction $RPTAction -RetentionEnabled $True
    }
    if (!($ForLinks.RetentionPolicyTagLinks -match $Tag)) {
        $TagList = (Get-RetentionPolicy $RetentionPolicy).RetentionPolicyTagLinks
        $TagList.Add((Get-RetentionPolicyTag $Tag).DistinguishedName)
        Set-RetentionPolicy $RetentionPolicy -RetentionPolicyTagLinks $TagList
    }
}
# Create Retention Policies for Default Non-Mail Folders
foreach ($row in $NonMail) {
    $Folder = $row.defaultfolder
    $Tag    = $TagPrefixNonMail + $Folder + $TagSuffixNonMail
    if (!(Get-RetentionPolicyTag $Tag -ErrorAction Ignore)) {
        New-RetentionPolicyTag -Name $Tag -Type $Folder -RetentionAction $RPTActionForever -RetentionEnabled $false
    }
    if (!($ForLinks.RetentionPolicyTagLinks -match $Tag)) {
        $TagList = (Get-RetentionPolicy $RetentionPolicy).RetentionPolicyTagLinks
        $TagList.Add((Get-RetentionPolicyTag $Tag).DistinguishedName)
        Set-RetentionPolicy $RetentionPolicy -RetentionPolicyTagLinks $TagList
    }    
}
if (Get-ManagementRoleAssignment -RoleAssignee $RoleAssignment -Role $UserRole -ErrorAction Ignore) {
    Get-ManagementRoleAssignment -RoleAssignee $RoleAssignment -Role $UserRole | Remove-ManagementRoleAssignment -confirm:$false         
}