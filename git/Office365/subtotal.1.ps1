Get-MailboxDatabase -Status | sort name | select name, @{Name = 'DB Size (Gb)'; Expression = {$_.DatabaseSize.ToGb()}}, @{Name = 'Available New Mbx Space Gb'; Expression = {$_.AvailableNewMailboxSpace.ToGb()}} | Out-GridView -Title "test"

get-moverequest -movestatus Failed|get-moverequeststatistics|select @{n = "upn"; e = {(Get-mailbox $_.distiuishedname).Userprincipalname}}, DisplayName, SyncStage, Failure*, Message, PercentComplete, largeitemsencountered, baditemsencountered|ft -autosize

Set-ADUser -Identity BB03 -add @{publicDelegates = {(Get-ADUser BB02).distinguishedname}}