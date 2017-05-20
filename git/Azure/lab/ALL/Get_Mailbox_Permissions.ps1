Set-ADServerSettings -ViewEntireForest $true
$OutFile = "C:\scripts\PermissionExport.csv" 
"DisplayName" + "," + "Alias" + "," + "Primary SMTP" + "," + "Full Access" + "," + "Send As" + "," + "Send on Behalf" | Out-File $OutFile -Force 

$mailboxes = "C:\scripts\SamAccountName.csv"

$mailboxes | ForEach-Object {Get-Mailbox $("$_") | ?{$_.recipienttype -eq 'SharedMailbox'} | Select-Object Identity, Alias, DisplayName, DistinguishedName, primarysmtpaddress}
 
ForEach ($Mailbox in $mailboxes) 
{ 
       $SendAs = Get-ADPermission $Mailbox.DistinguishedName | ? {$_.ExtendedRights -like "Send-As" -and $_.User -notlike "NT AUTHORITY\SELF" -and !$_.IsInherited} | % {$_.User} 
       $FullAccess = Get-MailboxPermission $Mailbox.Identity | ? {$_.AccessRights -eq "FullAccess" -and !$_.IsInherited} | % {$_.User} 
       $sendbehalf=Get-Mailbox $Mailbox.Identity | select-object -expand grantsendonbehalfto | select-object -expand rdn | % {$_.User} 
       if (!$SendAs -and !$FullAccess -and !$sendbehalf){continue}
       $Mailbox.DisplayName + "," + $Mailbox.Alias + "," + $Mailbox.primarysmtpaddress + "," + $FullAccess + "," + $SendAs + "," + $sendbehalf | Out-File $OutFile -Append 
 }