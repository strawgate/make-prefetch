param (
  [uri] $URL,
  [string] $Name,
  [string] $Algorithm,
  [switch] $Help
)



$SHA1 = (Get-FileHash $Setup -Algorithm SHA1).hash
$SHA256 = (Get-FileHash $Setup -Algorithm SHA256).hash
$Size = $Setup.length
