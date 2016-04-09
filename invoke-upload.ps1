param (
    [string][parameter(Mandatory = $true)][ValidateNotNullOrEmpty()] $File,
    [string][parameter(Mandatory = $true)][ValidateNotNullOrEmpty()] $Server
)

#Add Certification Exception for connecting to the BigFix Server
add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

#Import net assemblies for HTTP Client
Add-Type -AssemblyName System.Web
Add-Type -AssemblyName System.Net.http


#Credit for this function goes to: Mario Majcica
# http://blog.majcica.com/2016/01/13/powershell-tips-and-tricks-multipartform-data-requests/
function Invoke-bffileimport
{
    [CmdletBinding()]
    PARAM
    (
        [string][parameter(Mandatory = $true)][ValidateNotNullOrEmpty()]$InFile,
        [string]$ContentType,
        [Uri][parameter(Mandatory = $true)][ValidateNotNullOrEmpty()]$Uri = "$(Get-BFServer)" + "api/upload" ,
        [System.Management.Automation.PSCredential]$Credential
    )
    BEGIN
    {
        if (-not (Test-Path $InFile))
        {
            $errorMessage = ("File {0} missing or unable to read." -f $InFile)
            $exception =  New-Object System.Exception $errorMessage
			$errorRecord = New-Object System.Management.Automation.ErrorRecord $exception, 'MultipartFormDataUpload', ([System.Management.Automation.ErrorCategory]::InvalidArgument), $InFile
			$PSCmdlet.ThrowTerminatingError($errorRecord)
        }
 
        if (-not $ContentType)
        {
            Add-Type -AssemblyName System.Web
 
            $mimeType = [System.Web.MimeMapping]::GetMimeMapping($InFile)
            
            if ($mimeType)
            {
                $ContentType = $mimeType
            }
            else
            {
                $ContentType = "application/octet-stream"
            }
        }
    }
    PROCESS
    {
        Add-Type -AssemblyName System.Net.Http
 
		$httpClientHandler = New-Object System.Net.Http.HttpClientHandler
 
        if ($Credential)
        {
		    $networkCredential = New-Object System.Net.NetworkCredential @($Credential.UserName, $Credential.Password)
		    $httpClientHandler.Credentials = $networkCredential
        }
 
        $httpClient = New-Object System.Net.Http.Httpclient $httpClientHandler
 
    
        #$httpClient.DefaultRequestHeaders.Authorization = (get-bfconnectheaders)
        $packageFileStream = New-Object System.IO.FileStream @($InFile, [System.IO.FileMode]::Open)
        
		$contentDispositionHeaderValue = New-Object System.Net.Http.Headers.ContentDispositionHeaderValue "form-data"
	    $contentDispositionHeaderValue.Name = "fileData"
		$contentDispositionHeaderValue.FileName = (Split-Path $InFile -leaf)
 
        $streamContent = New-Object System.Net.Http.StreamContent $packageFileStream
        $streamContent.Headers.ContentDisposition = $contentDispositionHeaderValue
        $streamContent.Headers.ContentType = New-Object System.Net.Http.Headers.MediaTypeHeaderValue $ContentType
        
        $content = New-Object System.Net.Http.MultipartFormDataContent
        $content.Add($streamContent)
 
        try
        {
			$response = $httpClient.PostAsync($Uri, $content).Result
 
			if (!$response.IsSuccessStatusCode)
			{
				$responseBody = $response.Content.ReadAsStringAsync().Result
				$errorMessage = "Status code {0}. Reason {1}. Server reported the following message: {2}." -f $response.StatusCode, $response.ReasonPhrase, $responseBody
 
				throw [System.Net.Http.HttpRequestException] $errorMessage
			}
 
			return $response.Content.ReadAsStringAsync().Result
        }
        catch [Exception]
        {
			$PSCmdlet.ThrowTerminatingError($_)
        }
        finally
        {
            if($null -ne $httpClient)
            {
                $httpClient.Dispose()
            }
 
            if($null -ne $response)
            {
                $response.Dispose()
            }
        }
    }
    END { }
}
#Verify File Exists
if (!(test-path $File)) { throw "Invalid file path provided" }
$NewFile = get-item $File

#Get Credentials for upload
$Credentials = Get-Credential

#Perform Upload
$Result = Invoke-BFFileImport -Uri "https://$($Server):52311/api/upload" -InFile $NewFile -Credential $Credentials

if (!(select-xml -content ($Result) -xpath "/BESAPI/FileUpload")) {throw "Unknown response from server" }

#Prepare Prefetch
$URL = (select-xml -content ($Result) -xpath "/BESAPI/FileUpload/URL").node.InnerText
$Name = $NewFile.Name
$SHA1 = (Get-FileHash $NewFile -Algorithm SHA1).hash
$SHA256 = (Get-FileHash $NewFile -Algorithm SHA256).hash
$Size = $NewFile.length

#Print Prefetch
write-output "prefetch $Name sha1:$SHA1 size:$Size $URL sha256:$SHA256"

#Provide extraction commands if the file is an archive
if ($file.Extension -like "bftemp") {
    write-output "move ""__Download/$Name"" ""__Download/$Name.bftemp"

    write-output "extract ""$Name.bftemp"" ""__Download/"
}