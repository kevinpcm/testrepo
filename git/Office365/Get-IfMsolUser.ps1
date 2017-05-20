# Start Transcript of PowerShell Session
Start-Transcript -Path '.\HDS_ifMailbox_MSOL_9000.txt' -Append

# Error Log
$Outfile = ($(get-date -Format yyyy-MM-dd_HH-mm-ss) + "-if_MSOL_9457-log.txt")

# List of users
$users = Get-Content ./9457.txt

$ErrorActionPreference = "Stop"
foreach ($user in $users) {
    Try {
        Get-MsolUser -UserPrincipalName $user
        Out-File -FilePath $Outfile -InputObject "$($user),'MsolUser'" -Encoding utf8 -Append
    } 
    Catch {
        Out-File -FilePath $Outfile -InputObject "$($user),'NOTFOUND'" -Encoding utf8 -Append
    }
}