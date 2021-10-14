# Purpose: Create a CSV report of applications currently deployed in SCCM.

# Set parameters.
Write-Host "Setting parameters."
$FolderNames = @("Common","Purchased")
$LengthOfRecent = 7
$ServerAddress = "[YOUR_SERVER_ADDRESS]"
$ServerNamespace = "root\SMS\Site_[YOUR_SITE_ID]"
$BoxUsername = "[BOX_FTP_USERNAME]"
$BoxPassword = "[BOX_FTP_PASSWORD]"
$BoxSaveDirectory = "ftp://ftp.box.com/[BOX_DIRECTORY_URL_ENCODED]"

# Command to be run on the local machine.
$RemoteCommand = {

    # Initialize parameters.
    param($ServerNamespace,$FolderNames)
    $Folders = gwmi -Namespace $ServerNamespace -Class SMS_ObjectContainerNode
    $FolderIDs = New-Object System.Collections.Generic.HashSet[int]
    $AppInfo = @()
    $ApplicationInfo = @()

    # Get root folders.
    foreach ($Folder in $Folders) {
        foreach ($FolderName in $FolderNames) {
            if ($Folder.Name -eq $FolderName) {
                $FolderIDs.Add($Folder.ContainerNodeID) >$null
                break
            }
        }
    }

    # Get all subfolders.
    $changed = $true
    while ($changed) {
        $changed = $false
        foreach ($Folder in $Folders) {
            foreach ($FolderID in $FolderIDs) {
                if ($Folder.ParentContainerNodeID -eq $FolderID) {
                    if ($FolderIDs.Add($Folder.ContainerNodeID)) {
                        $changed = $true
                    }
                    break
                }
            }
        }
    }

    # Get application info.
    foreach ($FolderID in $FolderIDs) {
        $InstanceKeys = (Get-WmiObject -Namespace $ServerNamespace -query "select InstanceKey from SMS_ObjectContainerItem where ObjectType='6000' and ContainerNodeID='$FolderID'").InstanceKey
        foreach ($InstanceKey in $InstanceKeys) {
        
            # Get basic application info.
            $AppInfo += (Get-WmiObject -Namespace $ServerNamespace -Query "select * from SMS_ApplicationLatest where ModelName = '$InstanceKey'" | select LocalizedDisplayName,Manufacturer,SoftwareVersion,LastModifiedBy,DateLastModified,NumberOfDeployments)
        
            # Get specific deployment info.
            if ($AppInfo[$AppInfo.Count - 1].NumberOfDeployments -gt 0) {
                $query = "select * from SMS_DeploymentSummary where ApplicationName = '" + $AppInfo[$AppInfo.Count - 1].LocalizedDisplayName + "'"
                foreach ($Deployment in (Get-WmiObject -Namespace $ServerNamespace -Query "$query")) {
            
                    # Extract deployment type.
                    $DeploymentType = ""
                    if ($Deployment.DeploymentIntent -eq 1) {
                        $DeploymentType = "Required"
                    }
                    else {
                        $DeploymentType = "Availible"
                    }
            
                    # Save deployment info.
                    $ApplicationInfo += [pscustomobject] @{
                        ApplicationName = $AppInfo[$AppInfo.Count - 1].LocalizedDisplayName
                        Publisher = $AppInfo[$AppInfo.Count - 1].Manufacturer
                        Version = $AppInfo[$AppInfo.Count - 1].SoftwareVersion
                        ModificationUser = $AppInfo[$AppInfo.Count - 1].LastModifiedBy
                        ModificationDate = [datetime]::parseexact($AppInfo[$AppInfo.Count - 1].DateLastModified.split('.')[0],"yyyyMMddHHmmss",[System.Globalization.CultureInfo]::InvariantCulture)
                        CollectionName = $Deployment.CollectionName
                        DeploymentType = $DeploymentType
                        NumberTargeted = $Deployment.NumberTargeted
                        NumberSuccesses = $Deployment.NumberSuccess
                        NumberErrors = $Deployment.NumberErrors
                        NumberInProgress = $Deployment.NumberInProgress
                        NumberOther = $Deployment.NumberOther
                        NumberUnknown = $Deployment.NumberUnknown
                    }
                }
            }
        }
    }

    return $ApplicationInfo
}

# Execute remote commands.
Write-Host "Creating remote connection."
$Session = New-PSSession -ComputerName $ServerAddress
Write-Host "Launching remote command."
$JobID = [int](Invoke-Command -Session $Session -ScriptBlock $RemoteCommand -ArgumentList $ServerNamespace,$FolderNames -AsJob | Select-Object -Expand Id)

# Get remote data.
Write-Host "Processing..."
while ((Get-Job -Id $JobID).State -ne "Completed") {
    timeout /T 10 >$null
}
$Data = Get-Job -Id $JobID | Receive-Job
Remove-PSSession -Session $Session

# Organize past files.
Write-Host "Organizing past files."
$FileTitle = $MyInvocation.MyCommand.Name.split('.')[0]
$FolderSavePath = $PSScriptRoot + "\" + $FileTitle
$FileSavePath = $FolderSavePath + "\" + $FileTitle + ".0.csv"
if(!(Test-Path -Path $FolderSavePath )){
    New-Item -ItemType directory -Path $FolderSavePath
}
for ($i=$LengthOfRecent-2; $i -ge 0; $i--) {
    $SourceFile = $FolderSavePath + "\" + $FileTitle + "." + $i + ".csv"
    $DestFile = $FolderSavePath + "\" + $FileTitle + "." + $($i + 1) + ".csv"
    if (Test-Path $SourceFile -PathType Leaf) {
        Move-Item -Path $SourceFile -Destination $DestFile -Force
    }
}

# Comparing with past data.
Write-Host "Creating historical comparison."
$CompareFilePath = $FolderSavePath + "\" + $FileTitle + "." + $($LengthOfRecent-1) + ".csv"
if (Test-Path $CompareFilePath -PathType Leaf) {
    $PastData = Import-Csv $CompareFilePath
    foreach ($Row in $Data) {
        $PastRow = $PastData | Where-Object {($_.ApplicationName -eq $Row.ApplicationName) -and ($_.CollectionName -eq $Row.CollectionName)}
        if ($PastRow -eq $null) {
            $Row | Add-Member -MemberType NoteProperty -Name "RecentSuccesses" -Value $Row.NumberSuccesses -Force
            $Row | Add-Member -MemberType NoteProperty -Name "RecentErrors" -Value $Row.NumberErrors -Force
            $Row | Add-Member -MemberType NoteProperty -Name "RecentOther" -Value $Row.NumberOther -Force
            $Row | Add-Member -MemberType NoteProperty -Name "RecentUnknown" -Value $Row.NumberUnknown -Force
        }
        else {
            $RecentSuccesses = $Row.NumberSuccesses - $PastRow.NumberSuccesses
            $RecentErrors = $Row.NumberErrors - $PastRow.NumberErrors
            $RecentOther = $Row.NumberOther - $PastRow.NumberOther
            $RecentUnknown = $Row.NumberUnknown - $PastRow.NumberUnknown
            if ($RecentSuccesses -lt 0) {
                $RecentSuccesses = 0
            }
            if ($RecentErrors -lt 0) {
                $RecentErrors = 0
            }
            if ($RecentOther -lt 0) {
                $RecentOther = 0
            }
            if ($RecentUnknown -lt 0) {
                $RecentUnknown = 0
            }
            $Row | Add-Member -MemberType NoteProperty -Name "RecentSuccesses" -Value $RecentSuccesses -Force
            $Row | Add-Member -MemberType NoteProperty -Name "RecentErrors" -Value $RecentErrors -Force
            $Row | Add-Member -MemberType NoteProperty -Name "RecentOther" -Value $RecentOther -Force
            $Row | Add-Member -MemberType NoteProperty -Name "RecentUnknown" -Value $RecentUnknown -Force
        }
    }
}
Write-Host "Saving report locally."
$Data | ConvertTo-Csv | Select-Object -Skip 1 | Set-Content -Path $FileSavePath

# Upload to Box via FTP.
# Set connection settings.
Write-Host "Saving report to Box."
$BoxSavePath = $BoxSaveDirectory + $FileTitle + ".csv"
[Net.ServicePointManager]::ServerCertificateValidationCallback={$true}
$FTPConnection = [System.Net.FtpWebRequest]::Create($BoxSavePath)
$FTPConnection = [System.Net.FtpWebRequest]$FTPConnection
$FTPConnection.UsePassive = $true
$FTPConnection.UseBinary = $true
$FTPConnection.EnableSsl = $true
$FTPConnection.Credentials = new-object System.Net.NetworkCredential($BoxUsername,$BoxPassword)
$FTPConnection.Method = [System.Net.WebRequestMethods+Ftp]::UploadFile
$rs = $FTPConnection.GetRequestStream()
# Read and upload file.
$reader = New-Object System.IO.FileStream ($FileSavePath, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::Read)
[byte[]]$buffer = new-object byte[] 4096
[int]$count = 0
do
{
    $count = $reader.Read($buffer, 0, $buffer.Length)
    $rs.Write($buffer,0,$count)
} while ($count -gt 0)
$reader.Close()
$rs.Close()

Write-Host "Complete."
