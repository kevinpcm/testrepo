$pass = get-content C:\scripts\Password.txt | convertto-securestring
$cred = new-Object -type System.Management.Automation.PSCredential -arg "admin@sent.onmicrosoft.com",$pass
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri "https://outlook.office365.com/powershell-liveid/" -Credential $cred -Authentication Basic -AllowRedirection
Import-PSSession $Session -AllowClobber
$service.Url = New-Object -TypeName System.Uri('https://outlook.office365.com/EWS/Exchange.asmx')
$rootFolder = [Microsoft.Exchange.WebServices.Data.Folder]::Bind($service,'MsgFolderRoot')
$folderView = [Microsoft.Exchange.WebServices.Data.FolderView]100
$folderView.Traversal='Deep'
$rootFolder.Load()

#Load EWS API
$ewsDll = 'C:\Program Files (x86)\Microsoft\Exchange\Web Services\2.1\Microsoft.Exchange.WebServices.dll'
[Reflection.Assembly]::LoadFile($ewsDll) | out-null

#Get Date 1 daysago
$today=(get-date).AddDays(-1).ToShortDateString()

#Get Mailboxes
$MailboxToProcess = Get-Mailbox | Where {$_.RetentionPolicy -eq "DeleteAllONEDay7"} | Select -ExpandProperty  WindowsEmailAddress

$service = New-Object Microsoft.Exchange.WebServices.Data.ExchangeService($ExchangeVersion)
$service.Credentials = New-Object System.Net.NetworkCredential("admin@sent.onmicrosoft.com",$pass)

    
        # Write-Verbose "Started running $($MyInvocation.MyCommand)"
        # [string[]]$FolderExclusions = @("/Calendar","/Sync Issues","/Sync Issues/Conflicts","/Sync Issues/Local Failures","/Sync Issues/Server Failures","/Recoverable Items","/Deletions","/Purges","/Versions","/Calendar Logging")
 
    
    

        # Write-Verbose ("Mailbox: "+$MailboxToProcess.PrimarySMTPAddress)
 
        $FolderNames=$MailboxToProcess| Get-MailboxFolderStatistics | Where-Object {!($FolderExclusions -icontains $_.FolderPath)} |
                Select-Object -ExpandProperty FolderPath | ForEach-Object{$_ -replace ("/","")}


        Foreach ($FolderName in $FolderNames)
        {         
            $FolderName=$FolderName -replace ("Top Of Information Store","")
        }                 
    
    {
        Write-Verbose "Stopped running $($MyInvocation.MyCommand)"
    }  

$deletedFolder = [Microsoft.Exchange.Webservices.Data.WellKnownFolderName]::DeletedItems

$fvFolderView = new-object Microsoft.Exchange.WebServices.Data.FolderView(1)
$SfSearchFilterDeleted = new-object Microsoft.Exchange.WebServices.Data.SearchFilter+IsEqualTo([Microsoft.Exchange.WebServices.Data.FolderSchema]::DisplayName,"Deleted Items")

$service.AutodiscoverUrl("admin@domain.onmicrosoft.com",{$true})
$ivItemView = New-Object Microsoft.Exchange.WebServices.Data.ItemView(1000)

foreach($mailbox in $mailboxesPolicy1){
$folderId = new-object Microsoft.Exchange.Webservices.Data.FolderId([Microsoft.Exchange.Webservices.Data.WellKnownFolderName]::MsgFolderRoot,$mailbox)
$iUserID = new-object Microsoft.Exchange.WebServices.Data.ImpersonatedUserId([Microsoft.Exchange.WebServices.Data.ConnectingIdType]::SmtpAddress,$mailbox)
$service.ImpersonatedUserId = $iUserID

$findFolderResultsDeleted = $service.FindFolders($folderid,$SfSearchFilterDeleted,$fvFolderView)

$fiDeletedItems = $service.FindItems($findFolderResultsDeleted.Id,$ivItemView)

foreach($Item in $fiDeletedItems.Items){
    if ($Item.DateTimeReceived -le $today)
     {
    $Item.Delete([Microsoft.Exchange.WebServices.Data.DeleteMode]::HardDelete)
     }
}
}

Get-PSSession | Remove-PSSession