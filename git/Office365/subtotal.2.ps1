$report = Get-MoveRequest -ResultSize 5 | Get-MoveRequestStatistics | 
    Select-Object -Property 
@{n = "DatebaseName"; e = {$_.targetdatabase.name}}, 
@{n = 'total'; e = {($_.totalmailboxsize / 1GB)}
}
$report | Group-Object -Property DatebaseName | 
    Select-Object -Property 
@{n = "DatebaseName"; e = {$_.Name}}, 
@{n = "Sum"; e = {($PSItem.group | Measure-Object -Property total -sum).Sum}
} |
    Sort-Object -Property Sum -Descending |
    Out-GridView -Title "Size Per Database"