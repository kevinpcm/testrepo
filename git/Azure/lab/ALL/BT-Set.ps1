<#
.NOTES
	Company:		BitTitan, Inc.
	Title:			Set-AllMailboxPermissions.PS1
	Author:			SUPPORT@BITTITAN.COM
	Requirements: 
	
	Version:		1.00
	Date:			January 18, 2017

	Exchange Version:	Exchange Online
    Windows Version:	O365

	Disclaimer: 		This script is provided ‘AS IS’. No warrantee is provided either expresses or implied.

	Copyright: 		Copyright© 2017 BitTitan. All rights reserved.
	
.Synopsis
   Gets the Mailbox permissions from the specified MailboxPerms.csv file and uses them to set paermissions. 


.INPUTS
    Office365Username - Mandatory - Administrator login ID for the tenant we are querying
    Office365Password - Mandatory - Administrator login password for the tenant we are querying
    PermissionsFile - Mandatory - File with the permissions for the new mailboxes.


.OUTPUTS
   Creates a CSV of the permissions details. 

.EXAMPLE
    .\BT-Set.ps1 -Office365Username admin@xxxxxx.onmicrosoft.com -Office365Password Password123 -PermissionsFile c:\Files\InputFile.csv
    .\BT-Set.ps1 -Office365Username admin@sent.onmicrosoft.com -Office365Password Tote2830 -PermissionsFile c:\scripts\InputFile.csv
	Runs the script and sets permissions.
#>


#Accept input parameters
Param(
	[Parameter(Position=0, 
        Mandatory=$true, 
        ValueFromPipeline=$true,
        HelpMessage="Provide the Admin Username for the Office365 Tenant")]
    [ValidateNotNullOrEmpty()]
    [string] $Office365Username,

	[Parameter(Position=1, 
        Mandatory=$true, 
        ValueFromPipeline=$true,
        HelpMessage="Provide the Password for the Admin Username for the Office365 Tenant")]
    [ValidateNotNullOrEmpty()]
    [string] $Office365Password,
    	
	[Parameter(Position=2, 
        Mandatory=$true, 
        ValueFromPipeline=$true,
        HelpMessage="Specify the path for the CSV file that specifies the Mailbox Permissions and settings that you want to configure.")]
    [ValidateNotNullOrEmpty()]
    [string] $PermissionsFile,

    [Parameter(Position=3, 
        Mandatory=$false, 
        ValueFromPipeline=$true,
        HelpMessage="Specify the new Domain for the Mailbox Permission setting.")]
    [ValidateNotNullOrEmpty()]
    [string] $DomainChange
)

$ErrorActionPreference = "Stop"

#Constant Variables
$OutputFile = "MailboxPerms.csv"   #The CSV Output file that is created, change for your purposes


#Main
Function Main {

	#Remove all existing Powershell sessions
	Get-PSSession | Remove-PSSession
	
	#Call ConnectTo-ExchangeOnline function with correct credentials
	ConnectTo-ExchangeOnline -Office365AdminUsername $Office365Username -Office365AdminPassword $Office365Password			
	
    #Read Input files with headers
    if (Test-Path -Path $PermissionsFile)
    {
	    $rows = import-csv $PermissionsFile
        if (0 -eq $rows.Count)
        {
            Write-Error "The Permissions CSV file is empty." -ErrorAction Stop
        }
    }
    else 
    {
        Write-Error "The path to the Permissions CSV file is not valid." -ErrorAction Stop
    }


	foreach ($row in $rows)
    {
        if ($row.ObjectType -eq "UserMailbox")
        {
            if ($DomainChange -ne "")
            {
                #Replace the Domain Name and assign permissions

                $newDomainMailbox = $row.UserPrincipalName -replace $row.UserPrincipalName.Split("@")[1], $DomainChange
                $newDomainPermissions = $row.ObjectWithAccess -replace $row.ObjectWithAccess.Split("@")[1], $DomainChange

                try 
                {
                    Add-MailboxPermission -Identity $newDomainMailbox -User $newDomainPermissions -AccessRights $row.AccessType
                }
                catch
                {
                    throw
                }
            }
            else
            {
                try
                {
                    #Set the Right Permissions
                    Add-MailboxPermission -Identity $row.UserPrincipalName -User $row.ObjectWithAccess -AccessRights $row.AccessType
                }catch
                {
                    throw
                }
            }
        }
    }

    Write-Host "Permissions from MailboxPerms CSV file have been set. Script is DONE."

	
	#Clean up session
	Get-PSSession | Remove-PSSession
}



<#
.Synopsis
   ConnectTo-ExchangeOnline

.DESCRIPTION
   Function ConnectTo-ExchangeOnline - Connects to Exchange Online Remote PowerShell using the tenant credentials

.EXAMPLE
   ConnectTo-ExchangeOnline -Office365AdminUsername "admin@exch.0nmicrosoft.com" -Office365AdminPassword "p@s$w0rD#01"


#>
function ConnectTo-ExchangeOnline
{   
	Param( 
		[Parameter(
		    Mandatory=$true,
		    Position=0)]
        [ValidateNotNullOrEmpty()]
		[String]$Office365AdminUsername,

		[Parameter(
		Mandatory=$true,
		Position=1)]
        [ValidateNotNullOrEmpty()]
		[String]$Office365AdminPassword
    )
		
	#Encrypt password for transmission to Office365
	$SecureOffice365Password = ConvertTo-SecureString -AsPlainText $Office365AdminPassword -Force    
	
	#Build credentials object
	$Office365Credentials  = New-Object System.Management.Automation.PSCredential $Office365AdminUsername, $SecureOffice365Password
	
	#Create remote Powershell session and Import the Session
    try
    {
	    $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell -Credential $Office365credentials -Authentication Basic -AllowRedirection 
        if ($null -ne $Session)
        {
            Import-PSSession $Session -AllowClobber | Out-Null
        }   	

    }
    catch
    {
        throw
    }
}


# Start script
. Main