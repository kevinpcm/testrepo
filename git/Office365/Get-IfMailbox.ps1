# Start Transcript of PowerShell Session
Start-Transcript -Path '.\HDS_ifMailbox.txt' -Append

# Error Log
$Outfile = ($(get-date -Format yyyy-MM-dd_HH-mm-ss) + "-if_MailboxUPN-log.txt")

# List of users
$users = Get-Content ./9457.txt

foreach ($user in $users) {
    $check = (Get-Mailbox -identity $user -ErrorAction SilentlyContinue) 
    if ($check) {
        Out-File -FilePath $Outfile -InputObject "$($user),$($_.Exception.message)" -Encoding utf8 -Append
    }
}