Get-Content 'C:\scripts\UPNsLAST.txt' | % {
    Get-Mailbox $_ -resultsize Unlimited -erroraction silentlycontinue | select displayname,primarysmtpaddress
} 