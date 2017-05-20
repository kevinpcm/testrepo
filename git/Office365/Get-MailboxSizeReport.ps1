
$File     = "C:\scripts\UPNsLast.txt"
$OutFile  = "C:\scripts\$(get-date -Format yyyy-MM-dd_HH-mm-ss)-output.csv"
$ErrorLog = "C:\scripts\$(get-date -Format yyyy-MM-dd_HH-mm-ss)-errorlog.csv"

$ErrorsHappened = $false

Out-File -FilePath $OutFile -InputObject "Email,MB" -Encoding utf8
# Out-File -FilePath $ErrorLog -InputObject "Email, Error" -Encoding utf8
Get-Content $File | % {
    $Row = $_
    $DataOut = (Get-MailboxStatistics -id $Row | Select @{name = "upn"; expression = {$Row}}, @{name = "MB"; expression = {[math]::Round(($_.TotalItemSize.ToString().Split("(")[1].Split(" ")[0].Replace(",", "") / 1MB), 2)}}) 2>&1
    if ($($DataOut.Exception.message)) {
        Write-Output "$Row,$($DataOut.Exception.message)"
        $ErrReport = "$Row,$($DataOut.Exception.message)"
        Out-File -FilePath $OutFile -InputObject $ErrReport -Append -NoNewline
        $ErrorsHappened = $true
    }
    $Report = "$($DataOut.upn),$($DataOut.MB)"
    Out-File -FilePath $OutFile -InputObject $Report -Append -Encoding utf8
}
if ($ErrorsHappened) {
    Write-Warning "Errors logged to $ErrorLog"
}