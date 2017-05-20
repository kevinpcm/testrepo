Get-MoveRequest -ResultSize Unlimited | Get-MoveRequestStatistics |
    Select displayname, Status, @{name = "UPN" ; expression = { (get-mailbox $_.DistinguishedName).UserPrincipalName }}, CompletionTimestamp |
    Export-Csv MoveRequestStats_04_23_2017.csv -NoTypeInformation