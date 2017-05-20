$OutFile = "C:\scripts\PermissionExport.txt" 
"DisplayName" + "," + "Alias" + "," + "Primary SMTP" + "," + "Full Access" + "," + "Send As" + "," + "Send on Behalf" | Out-File $OutFile -Force 

$List = Import-Csv c:\scripts\sAMAccountname.csv

$Mailboxes = $List | % {Get-Mailbox $_.samaccountname}
ForEach ($Mailbox in $Mailboxes) 
{ 
       $SendAs = Get-ADPermission $Mailbox.DistinguishedName | ? {$_.ExtendedRights -like "Send-As" -and $_.User -notlike "NT AUTHORITY\SELF" -and !$_.IsInherited} | % {$_.User} 
       $FullAccess = Get-MailboxPermission $Mailbox.Identity | ? {$_.AccessRights -eq "FullAccess" -and !$_.IsInherited} | % {$_.User} 
       $sendbehalf=Get-Mailbox $Mailbox.Identity | select-object -expand grantsendonbehalfto | select-object -expand rdn | % {$_.User} 
       if (!$SendAs -and !$FullAccess -and !$sendbehalf){continue}
       $Mailbox.DisplayName + "," + $Mailbox.Alias + "," + $Mailbox.primarysmtpaddress + "," + $FullAccess + "," + $SendAs + "," + $sendbehalf | Out-File $OutFile -Append 
 }  