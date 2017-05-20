function New-PermissionReportObjectArray
{
    <#
    .SYNOPSIS 
        Will output mailboxes that contain:
            1. Identity: Mailbox Folder's Distinguished Name 
                ex. CN=User02,OU=contoso.onmicrosoft.com,OU=Microsoft Exchange Hosted Organizations,DC=NAMPR16A006,DC=PROD,DC=OUTLOOK,DC=COM:\Inbox\Child1\Child2
            2. User: The User that has Access Rights over the folder identified in the value, Identity
                ex. User01
            3. AccessRights: The AccessRights parameter specifies the permissions that the user (value "User") has on the mailbox folder (value "Identity").
                ex. Author
    
    .DESCRIPTION
        Use the this function to Retrieve folder-level permissions for users in mailboxes
    
    .EXAMPLE 
        . ./Get_365_folder_perms.ps1
        $GetMailboxes = Get-Mailbox -resultsize Unlimited
        $GetMailboxes | New-PermissionReportObjectArray | export-csv ./BHFUsersfolderpermissions.csv -nti


        . ./Get_365_folder_perms.ps1
        $GetMailboxes = import-csv ./BHFUsersDN.csv
        $GetMailboxes | New-PermissionReportObjectArray | export-csv ./BHFUsersfolderpermissions.csv -nti

    #>

    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true,
            ValueFromPipeline=$true)]
        [array]$MailboxToProcess
    )
    BEGIN
    {
        Write-Verbose "Started running $($MyInvocation.MyCommand)"
        [string[]]$FolderExclusions = @("/Sync Issues","/Sync Issues/Conflicts","/Sync Issues/Local Failures","/Sync Issues/Server Failures","/Recoverable Items","/Deletions","/Purges","/Versions","/Calendar Logging")
 
    }
    PROCESS
    {
        Write-Verbose "Getting array of all mailbox folder permissions"
        Write-Verbose ("Mailbox: "+$MailboxToProcess.PrimarySMTPAddress)
 
        $FolderNames=$MailboxToProcess| Get-MailboxFolderStatistics | Where-Object {!($FolderExclusions -icontains $_.FolderPath)} |
                Select-Object -ExpandProperty FolderPath | ForEach-Object{$MailboxToProcess.DistinguishedName.ToString() +":"+($_ -replace ("/","\"))}
        $PermissionsList=@()
        Foreach ($FolderName in $FolderNames)
        {         
            Write-Verbose "Getting Permissions On $FolderName"
            $FolderName=$FolderName -replace ("Top Of Information Store","")
            $FolderPermissions=Get-MailboxFolderPermission -Identity $FolderName
            foreach ($FolderPermission in $FolderPermissions)
            {
                $PermissionsObject=New-Object -typename PSObject      
                $PermissionsObject | Add-Member -MemberType NoteProperty -Name "Identity" -Value ([string]$FolderName)                
                $PermissionsObject | Add-Member -MemberType NoteProperty -Name "User" -Value ([string]($FolderPermission.User.ToString()))
                [string[]]$AccessRightsStringArray=@()
                foreach ($Right in $FolderPermission.AccessRights)
                {
                    $AccessRightsStringArray+=$Right.ToString()
                }
                if ($AccessRightsStringArray.Count -eq 0)
                {
                    Write-Verbose "No Access Rights detected"
                    Continue
                }
                if ($AccessRightsStringArray.Count -eq 1)
                {
                    $AccessRightsString=$AccessRightsStringArray[0]
                }else
                {
                    $AccessRightsString=$AccessRightsStringArray -Join ","
                }
                $PermissionsObject | Add-Member -MemberType NoteProperty -Name "AccessRights" -Value ([string]$AccessRightsString)
                $PermissionsList+=$PermissionsObject
            }
        }
                $PermissionsList | ?{!((($_.User -eq "Default") -or ($_.User -eq "Anonymous")) -and (($_.AccessRights -eq "None") -or ($_.AccessRights -eq 'AvailabilityOnly')))} 
    }
    END
    {
        Write-Verbose "Stopped running $($MyInvocation.MyCommand)"
    }  
}