<#
.NOTES
	Company:		BitTitan, Inc.
	Title:			Get-AllMailboxPermissions.PS1
	Author:			SUPPORT@BITTITAN.COM
	Requirements: 
	
	Version:		1.00
	Date:			January 18, 2017

	Exchange Version:	Exchange Online
    Windows Version:	O365

	Disclaimer: 		This script is provided ‘AS IS’. No warrantee is provided either expresses or implied.

	Copyright: 		Copyright© 2017 BitTitan. All rights reserved.
	
.Synopsis
   Gets the Mailbox permissions for the specified Users and exports them as a CSV file. 


.INPUTS
    Office365Username - Mandatory - Administrator login ID for the tenant we are querying
    Office365Password - Mandatory - Administrator login password for the tenant we are querying
    UserIDFile - Optional - Path and File name of file full of UserPrincipalNames we want the Mailbox Permissions for.  Seperated by New Line, no header.

.OUTPUTS
   Creates a CSV of the permissions details. 

.EXAMPLE
    .\Get-AllMailboxPermissions.ps1 -Office365Username "admin@xxxxxx.onmicrosoft.com" -Office365Password "Password123" -InputFile "c:\Files\InputFile.txt"
    .\BT-Get.ps1 -Office365Username admin@sent.onmicrosoft.com -Office365Password Tote2830 -useridfile .\InputFile.csv
	Runs the script and exports the permissions CSV file.
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
        Mandatory=$false, 
        ValueFromPipeline=$true,
        HelpMessage="Specify the path for the CSV file that specifies the users for which you want to get Mailbox Permissions. If you do not specify a CSV file, all Users will be used.")]
    [ValidateNotNullOrEmpty()]
    [string] $UserIDFile
)

$ErrorActionPreference = "Stop"

#Constant Variables
$OutputFile = "MailboxPerms.csv"   #The CSV Output file that is created, change for your purposes


<#
.Synopsis
   Function - Main - Performs the core tasks

.EXAMPLE
   . Main
#>
Function Main {

	#Remove all existing Powershell sessions
	Get-PSSession | Remove-PSSession
	
	#Call ConnectTo-ExchangeOnline function with correct credentials
	ConnectTo-ExchangeOnline -Office365AdminUsername $Office365Username -Office365AdminPassword $Office365Password			
	
	#Prepare Output file with headers
    try
    {
	    Out-File -FilePath $OutputFile -InputObject "UserPrincipalName,ObjectWithAccess,ObjectType,AccessType,Inherited,AllowOrDeny" -Encoding UTF8
    }
    catch
    {
        throw
    }
	
	#Check if we have been passed an input file path
	if ($userIDFile)
	{
        if (Test-Path -Path $userIDFile)
        {
		    #We have an input file, read it into memory
		    $objUsers = import-csv -Header "UserPrincipalName" $UserIDFile

            if ( ($null -eq $objUsers) -or (0 -eq $objUsers.Count) )
            {
                Write-Host "The Recipient File was empty. Will get mailboxes from source." -ErrorAction SilentlyContinue -ForegroundColor DarkYellow

                #No input file found, gather all UserPrincipalNames from Office 365
		        $objUsers = get-mailbox -ResultSize Unlimited | select UserPrincipalName

                if ( ($null -eq $objUsers) -or (0 -eq $objUsers.Count) )
                {
                    Write-Error "Could not retrieve Mailbox data from source. Stopping script." -ErrorAction Stop
                }
            }
        }
        else
        {
             Write-Host "The Recipient File was not found. Will get mailboxes from source." -ErrorAction SilentlyContinue -ForegroundColor DarkYellow

            #No input file found, gather all UserPrincipalNames from Office 365
		    $objUsers = get-mailbox -ResultSize Unlimited | select UserPrincipalName

            if ( ($null -eq $objUsers) -or (0 -eq $objUsers.Count) )
            {
                Write-Error "Could not retrieve Mailbox data from source. Stopping script" -ErrorAction Stop
            }
        }
	}
	else
	{
		#No input file found, gather all UserPrincipalNames from Office 365
		$objUsers = get-mailbox -ResultSize Unlimited | select UserPrincipalName

        if ( ($null -eq $objUsers) -or (0 -eq $objUsers.Count) )
        {
            Write-Error "Could not retrieve Mailbox data from source. Stopping script." -ErrorAction Stop
        }

	}
	
	#Iterate through all users	
	Foreach ($objUser in $objUsers)
	{	
        if ($null -eq $objUser)
        {
             Write-Host "The Recipient was null. Continuing..." -ErrorAction SilentlyContinue -ForegroundColor DarkYellow
        }

		#Connect to the users mailbox -- this cmdlet returns an MailboxAcePresentationObject class instance
		$objUserMailbox = get-mailboxpermission -Identity $($objUser.UserPrincipalName) | Select User,AccessRights,Deny,IsInherited
        if ($null -eq $objUserMailbox)
        {
             Write-Host "The Mailbox Permissions for the Recipient was null. Continuing..." -ErrorAction SilentlyContinue -ForegroundColor DarkYellow
             continue
        }
		
		#Prepare UserPrincipalName variable
		$strUserPrincipalName = $objUser.UserPrincipalName
		
		#Loop through each permission
		foreach ($objPermission in $objUserMailbox)
		{			
			#Get the remaining permission details (We're only interested in real users, not built in system accounts/groups)
			if (($objPermission.user.tolower().contains("\domain admin")) -or ($objPermission.user.tolower().contains("\enterprise admin")) -or ($objPermission.user.tolower().contains("\organization management")) -or ($objPermission.user.tolower().contains("\administrator")) -or ($objPermission.user.tolower().contains("\exchange servers")) -or ($objPermission.user.tolower().contains("\public folder management")) -or ($objPermission.user.tolower().contains("nt authority")) -or ($objPermission.user.tolower().contains("\exchange trusted subsystem")) -or ($objPermission.user.tolower().contains("\discovery management")) -or ($objPermission.user.tolower().contains("s-1-5-21")))
			{
                # DO NOTHING
            }
			else 
			{
				$objRecipient = (get-recipient $($objPermission.user)  -EA SilentlyContinue) 

                if ($null -eq $objRecipient)
                {
                    Write-Host "The Recipient Permissions was null. Continuing..." -ErrorAction SilentlyContinue -ForegroundColor DarkYellow
                    continue
                }
				
                if ($objRecipient.RecipientType -eq "UserMailbox")
                {

					$strUserWithAccess = $($objRecipient.PrimarySMTPAddress)
					$strObjectType = $objRecipient.RecipientType

				    $strAccessType = $($objPermission.AccessRights) -replace ",",";"
				
				    if ($objPermission.Deny -eq $true)
				    {
					    $strAllowOrDeny = "Deny"
				    }
				    else
				    {
					    $strAllowOrDeny = "Allow"
				    }
				
				    $strInherited = $objPermission.IsInherited
								
				    #Prepare the user details in CSV format for writing to file
				    $strUserDetails = "$strUserPrincipalName,$strUserWithAccess,$strObjectType,$strAccessType,$strInherited,$strAllowOrDeny"
				
				    Write-Host $strUserDetails
				
				    #Append the data to file
				    Out-File -FilePath $OutputFile -InputObject $strUserDetails -Encoding UTF8 -append

				}
				
			}
		}

        Write-Host "Permissions have been saved to the MailboxPerms CSV file. Script is DONE."

	}
	
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
        else
        {
           
        }   	

    }
    catch
    {
       
        throw
    }
}


# Start script
. Main