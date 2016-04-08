param (
    [IO.DirectoryInfo] $inFolder
)

function Invoke-Archive {
    param (
        [IO.DirectoryInfo] $Folder
    )
    .\BFArchive.exe -a "$($Folder.FullName)" "$($Folder.name).bftemp"
}

$Folder = get-item $InFolder

Invoke-Archive -Folder $Folder