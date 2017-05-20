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
(Invoke-WebRequest -outfile c:\scripts\configs4.xml -Method POST -Uri $config).content
$import     = "?type=import&category=configuration&key="
$file       = "&file-name=//configs33.xml"
$put        = $domain + $import + $key + $file
(Invoke-WebRequest -Method Post -Uri $put -Verbose)

curl -k --form file=@"./config33.xml" "https://palo.sentara1.com/api/?type=import&category=configuration&key=LUFRPT0zZVZrejZUeEFuOUcvVmZsb1ZPMlFicEV3bzg9ckRGaEtpeGFXRklUa3FFL1d6NGhLbVpmcVdheUtqaFdKZ2NrODJrbEVsST0="


https://palo.sentara1.com/api/?type=keygen&user=install&password=Tote2830
https://palo.sentara1.com/api/?type=import&category=configuration&key=<key>



scp import configuration from administrator@10.20.110.50: c: /scripts/configs.xml