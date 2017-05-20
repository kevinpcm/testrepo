$OutFile = ".\365PermissionExport.csv"
"DisplayName" + "," + "Alias" + "," + "PrimarySMTP" + "," + "FullAccess" + "," + "SendAs" + "," + "SendonBehalf" | Out-File $OutFile -Force -encoding ascii

$Mailboxes = import-csv .\metlifeWithAlias.csv
# $Mailboxes = Get-Mailbox -ResultSize:Unlimited 
ForEach ($Mailbox in $Mailboxes) 
{ 
       $SendAs = Get-RecipientPermission $Mailbox.PrimarySmtpAddress | ? {$_.AccessRights -match "SendAs" -and $_.Trustee -ne "NT AUTHORITY\SELF"} | % {$_.trustee} 
       $FullAccess = Get-MailboxPermission $Mailbox.PrimarySmtpAddress | ? {$_.AccessRights -eq "FullAccess" -and !$_.IsInherited} | % {$_.User} 
       $sendbehalf=Get-Mailbox $Mailbox.PrimarySmtpAddress | select-object -ExpandProperty GrantSendOnBehalfTo 
       if (!$SendAs -and !$FullAccess -and !$sendbehalf){continue}
       $Mailbox.DisplayName + "," + $Mailbox.Alias + "," + $Mailbox.primarysmtpaddress + "," + $FullAccess + "," + $SendAs + "," + $sendbehalf | Out-File $OutFile -Append -encoding ascii
 }  