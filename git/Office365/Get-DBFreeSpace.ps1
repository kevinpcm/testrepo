Get-MailboxDatabase -Status | 
    select name, @{Name = "DB Size Gb"; Expression = {$_.DatabaseSize.ToGb()}}, @{Name = "Available New Mbx Space Gb"; Expression = {$_.AvailableNewMailboxSpace.ToGb()}} | 
    Out-GridView -Title $(get-date -Format yyyy-MM-dd_HH-mm-ss)