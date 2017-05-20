$adfsSecurityEventDate = Get-Date "16-Jan-2017 16:00:00" -format "yyyy-MM-ddTHH:mm:ss.000000000Z"
$adfsServer = "se-c-af01.sentara1.com"
$eventLogName = "Security"
$eventFilter = "*[System/TimeCreated[@SystemTime > '" + $adfsSecurityEventDate + "']]"
$adfsRelatedEvents = Get-WinEvent -ComputerName $adfsServer -LogName $eventLogName -FilterXPath $eventFilter
$adfsRelatedEvents | ?{$_.Id -eq "299" -Or $_.Id -eq "500" -Or $_.Id -eq "501"} | FL Id, MachineName, LogName, TimeCreated, Message

