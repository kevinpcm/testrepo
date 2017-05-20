$domain     =  "https://pa.sentara1.com/api/"
$creds      =  "?type=keygen&user=install&password=Tote2830"
$post       =  $domain + $creds
[xml]$XmlDoc= (Invoke-WebRequest -Method POST -Uri $post).content
$key        = $XmlDoc.response.result.key
$req        =  "?type=export&category=configuration&key="
$config     = $domain + $req + $key
(Invoke-WebRequest -outfile c:\scripts\configs.xml -Method POST -Uri $config).content



$domain     =  "https://palo.sentara1.com/api/"
$creds      =  "?type=keygen&user=install&password=Tote2830"
$post       =  $domain + $creds
[xml]$XmlDoc= (Invoke-WebRequest -Method POST -Uri $post).content
$key        = $XmlDoc.response.result.key
$req        =  "?type=export&category=configuration&key="
$config     = $domain + $req + $key
$fileExport = "config.xml"
$fileImport = "config.xml"
$path4files = "C:\scripts\"
$xmlExport  = $path4files + $fileExport
$xmlImport  = $path4files + $fileImport
(Invoke-WebRequest -outfile $xmlExport -Method POST -Uri $config).content
$import     = "?type=op&cmd=<upload><config><name>" 
$import2    = "</name></config></upload>&key="
$put        = $domain + $import + $fileImport + $import2 + $key
(Invoke-RestMethod -Method GET -Uri $put -Verbose -ContentType 'application/xml')



$domain     =  "https://palo.sentara1.com/api/"
$creds      =  "?type=keygen&user=install&password=Tote2830"
$post       =  $domain + $creds
[xml]$XmlDoc= (Invoke-WebRequest -Method POST -Uri $post).content
$key        = $XmlDoc.response.result.key
$req        =  "?type=export&category=configuration&key="
$config     = $domain + $req + $key
$fileExport = "config.xml"
$fileImport = "BBBB.xml"
$path4files = "C:\scripts\"
$xmlExport  = $path4files + $fileExport
$xmlImport  = $path4files + $fileImport
(Invoke-WebRequest -outfile $xmlExport -Method POST -Uri $config).content
$import     = "?type=import&category=configuration&key="
$import2    = "</name></config></upload>&key="
$put        = $domain + $import + $key
(Invoke-RestMethod -Method Post -Uri $put -InFile $xmlImport -Verbose -ContentType "multipart/form-data")




https://palo.sentara1.com/api/?type=op&cmd=<upload><config><name>config.xml</name></config></upload>&key=LUFRPT0zZVZrejZUeEFuOUcvVmZsb1ZPMlFicEV3bzg9ckRGaEtpeGFXRklUa3FFL1d6NGhLbVpmcVdheUtqaFdKZ2NrODJrbEVsST0=

curl -k --form file=@"./config.xml" "https://palo.sentara1.com/api/?type=import&category=configuration&key=LUFRPT0zZVZrejZUeEFuOUcvVmZsb1ZPMlFicEV3bzg9ckRGaEtpeGFXRklUa3FFL1d6NGhLbVpmcVdheUtqaFdKZ2NrODJrbEVsST0="



https://palo.sentara1.com/api/?type=op&cmd=<upload><config><name>config33.xml</name></config></upload>&key=$key



https://palo.sentara1.com/api/?type=keygen&user=install&password=Tote2830
https://palo.sentara1.com/api/?type=import&category=configuration&key=<key>



scp import configuration from administrator@10.20.110.50: c: /scripts/configs.xml