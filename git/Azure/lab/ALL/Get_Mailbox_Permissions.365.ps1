$OutFile = "C:\scripts\365PermissionExport.txt" 
"DisplayName" + "," + "Alias" + "," + "PrimarySMTP" + "," + "FullAccess" + "," + "SendAs" + "," + "SendonBehalf" | Out-File $OutFile -Force 

$Mailboxes = Get-Mailbox -ResultSize:Unlimited 
ForEach ($Mailbox in $Mailboxes) 
{ 
       $SendAs = Get-RecipientPermission $Mailbox.Identity | ? {$_.AccessRights -match "SendAs" -and $_.Trustee -ne "NT AUTHORITY\SELF"} | % {$_.trustee} 
       $FullAccess = Get-MailboxPermission $Mailbox.Identity | ? {$_.AccessRights -eq "FullAccess" -and !$_.IsInherited} | % {$_.User} 
       $sendbehalf=Get-Mailbox $Mailbox.Identity | select-object -ExpandProperty GrantSendOnBehalfTo 
       if (!$SendAs -and !$FullAccess -and !$sendbehalf){continue}
       $Mailbox.DisplayName + "," + $Mailbox.Alias + "," + $Mailbox.primarysmtpaddress + "," + $FullAccess + "," + $SendAs + "," + $sendbehalf | Out-File $OutFile -Append 
 }  