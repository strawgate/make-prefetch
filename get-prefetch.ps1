param (
  [uri] $URL,
  [string] $Name,
  [string] $Algorithm,
  [switch] $Help
)


#prefetch 29096506ECF09502659AE936B46A31710499E8E2 sha1:29096506ECF09502659AE936B46A31710499E8E2 size:47843632 http://downloadplugins.citrix.com/MANUAL_BES_CACHING_REQUIRED/Citrix Receiver.exe sha256:173A8DB26E162A4FC36316F1B134C2728DC1A873B97670211707E8C35317E372

$File = $null
#Passed URL is a URL
if ($url -like "*://*") {
    $TempStore = [System.IO.Path]::GetTempFileName()
    invoke-webrequest $URL -outfile $TempStore
    $File = get-item $TempStore
} 
#Passed URL is a file
else {
    $File = get-item $url
    $URL = "http://REPLACEME"
    $Name = $File.Name
}

#Calculate Hash and File Size
$SHA1 = (Get-FileHash $File -Algorithm SHA1).hash
$SHA256 = (Get-FileHash $File -Algorithm SHA256).hash
$Size = $File.length

#Combine
$Prefetch = "prefetch $name sha1:$SHA1 size:$Size $URL sha256:$SHA256"

#Output
write-output $Prefetch