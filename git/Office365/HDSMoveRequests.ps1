
Get-Content .\HDSupns.txt | New-MoveRequest $_ -TargetDatabase DB201 -SuspendWhenReadyToComplete:$false -AllowLargeItems:$true -BadItemLimit 50 -WhatIf