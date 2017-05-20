$report = Get-MoveRequest -ResultSize 10| Get-MoveRequestStatistics | 
    Select-Object -Property @{n = "DatebaseName"; e = {$_.targetdatabase.name}}, totalmailboxsize
$report | Group-Object -Property DatebaseName | Select-Object -Property @{n = "DatebaseName"; e = {$_.Name}}, @{n = "Sum"; e = {($PSItem.group | Measure-Object -Property totalmailboxsize -sum).Sum}} |
    Sort-Object -Property Sum -Descending |
    Out-GridView -Title "Size Per Database"