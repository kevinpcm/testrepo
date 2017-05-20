function Set-epBulkFolderPermissions
{
    <#
    .SYNOPSIS 
        Will read from pipeline, mailboxes that must contain:
            1. Identity: Mailbox Folder's Distinguished Name 
                ex. CN=User02,OU=contoso.onmicrosoft.com,OU=Microsoft Exchange Hosted Organizations,DC=NAMPR16A006,DC=PROD,DC=OUTLOOK,DC=COM:\Inbox\Child1\Child2
            2. User: The User parameter specifies the user that needs Access Rights over the folder identified in the value, Identity
                ex. User01
            3. AccessRights: The AccessRights parameter specifies the permissions that you want to modify for the user on the mailbox folder.
                ex. Author
    
    .DESCRIPTION
        Use the this function to modify folder-level permissions for users in mailboxes
    
    .EXAMPLE 
        . ./Set_365_folder_perms.ps1
        $SetMailboxes = import-csv ./mbxfolderpermissions.csv
        $SetMailboxes | Set-epBulkFolderPermissions
    #>

    [CmdletBinding()]
    param (
    
    [parameter(Mandatory=$true,ValueFromPipeline=$true)] [psobject] $folderobject
        
          )
    BEGIN
    {
        
    }
    PROCESS
    {

        Set-MailboxFolderPermission -Identity $_.identity -user $_.user -AccessRights $_.accessrights 

    }
}