param (
    [Parameter(ParameterSetName='Local', mandatory=$true)]
    [ValidateScript({(Test-Path $_) -and -not (get-item $_).PSIsContainer})]
    [string] $Path,
    [Parameter(ParameterSetName='Network', mandatory=$true)]
    [uri] $URL,
    [Parameter(ParameterSetName='Local', mandatory=$true)]
    [Parameter(ParameterSetName='Network', mandatory=$true)]
    [string] $Name
)

switch ($PsCmdlet.ParameterSetName) 
{ 
    "Local"  {
        Write-Host $d; 

        $URL = "http://REPLACEME"
        
        break
    } 

    "Network"  {
        $Path = [System.IO.Path]::GetTempFileName()

        invoke-webrequest $URL -outfile $Path

        $File = get-item $Path
    } 
} 

$File = get-item $Path

#Calculate Hash and File Size
$SHA1 = (Get-FileHash $File -Algorithm SHA1).hash
$SHA256 = (Get-FileHash $File -Algorithm SHA256).hash
$Size = $File.length

#Combine
$Prefetch = "prefetch $Name sha1:$SHA1 size:$Size $URL sha256:$SHA256"

#Output
write-output $Prefetch

$prefetch | Clip