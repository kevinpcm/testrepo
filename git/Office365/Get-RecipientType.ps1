
$File      = "C:\scripts\UPNs.txt"
$OutFile   = "C:\scripts\" + $(get-date -Format yyyy-MM-dd_HH-mm-ss) + "-Output.txt"
$ErrorLog  = "C:\scripts\" + $(get-date -Format yyyy-MM-dd_HH-mm-ss) + "-errorlog.txt"
$Content   = Get-Content $File
$ErrorsHap = $false
Out-File -FilePath $OutFile -InputObject "Email,RecipientType" -Encoding utf8
$Content | % {
        $Row     = $_
        $DataOut = Get-User -id $Row | Select @{name = "upn"; expression = {$Row}}, RecipientType
    if (!($DataOut)) {
        Out-File -FilePath $ErrorLog -InputObject $Row -Append
        $ErrorsHappened = $true
    }
    $User = $DataOut.upn
    $RT   = $DataOut.RecipientType
    $Report = "$User,$RT"
    Out-File -FilePath $OutFile -InputObject $Report -Append -Encoding utf8
}
if ($ErrorsHap) {
    Write-Warning "Errors logged to $ErrorLog"
}