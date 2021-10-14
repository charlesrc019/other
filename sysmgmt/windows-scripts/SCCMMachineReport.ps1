# Purpose: Create a CSV report of machines connected to SCCM.
 
# Set parameters.
Write-Host "Setting parameters."
$ServerAddress = "[YOUR_SERVER_ADDRESS]"
$ServerNamespace = "root\SMS\Site_[YOUR_SITE_ID]"
$BoxUsername = "[BOX_FTP_USERNAME]"
$BoxPassword = "[BOX_FTP_PASSWORD]"
$BoxSaveDirectory = "ftp://ftp.box.com/[BOX_DIRECTORY_URL_ENCODED]"

# Command to be run on the local machine.
$RemoteCommand1 = {
    param($ServerNamespace)
    return (Get-WmiObject -Namespace $ServerNamespace -Query "Select * from SMS_G_System_COMPUTER_SYSTEM" | Select ResourceID,Manufacturer,Model,NumberOfProcessors,Name,TimeStamp,UserName)
}
$RemoteCommand2 = {
    param($ServerNamespace)
    return (Get-WmiObject -Namespace $ServerNamespace -Query "Select * from SMS_G_System_X86_PC_MEMORY" | Select ResourceID,TotalPhysicalMemory)
}
$RemoteCommand3 = {
    param($ServerNamespace)
    return (Get-WmiObject -Namespace $ServerNamespace -Query "Select * from SMS_G_System_PROCESSOR" | Select ResourceID,Is64Bit,Name,NormSpeed,NumberOfCores)
}

# Execute remote commands.
Write-Host "Creating remote connection."
$Session = New-PSSession -ComputerName $ServerAddress

Write-Host "Launching remote command 1."
$JobID = [int](Invoke-Command -Session $Session -ScriptBlock $RemoteCommand1 -ArgumentList $ServerNamespace -AsJob | Select-Object -Expand Id)
Write-Host "Processing..."
while ((Get-Job -Id $JobID).State -ne "Completed") {
    timeout /T 10 >$null
}
$GeneralInfo = Get-Job -Id $JobID | Receive-Job

Write-Host "Launching remote command 2."
$JobID = [int](Invoke-Command -Session $Session -ScriptBlock $RemoteCommand2 -ArgumentList $ServerNamespace -AsJob | Select-Object -Expand Id)
Write-Host "Processing..."
while ((Get-Job -Id $JobID).State -ne "Completed") {
    timeout /T 10 >$null
}
$RAMInfo = Get-Job -Id $JobID | Receive-Job

Write-Host "Launching remote command 3."
Write-Host "Processing..."
$JobID = [int](Invoke-Command -Session $Session -ScriptBlock $RemoteCommand3 -ArgumentList $ServerNamespace -AsJob | Select-Object -Expand Id)
while ((Get-Job -Id $JobID).State -ne "Completed") {
    timeout /T 10 >$null
}
$ProcessorInfo = Get-Job -Id $JobID | Receive-Job
Remove-PSSession -Session $Session

# Process data.
Write-Host "Creating data summary."
$MachineInfo = @()
$i = 0
foreach ($Machine in $GeneralInfo) {
    
    Write-Host Compiling $i of $GeneralInfo.Count...

    # Select associated parameters.
    $RAM = $RAMInfo | Where-Object {$_.ResourceID -eq $Machine.ResourceID}
    $Processor = $ProcessorInfo | Where-Object {$_.ResourceID -eq $Machine.ResourceID}

    # Filter parameters.
    $ProcessorBits = ""
    if ($Processor.Is64Bit -eq 1) {
        $ProcessorBits = "64"
    }
    else {
        $ProcessorBits = "32"
    }
    $CurrentStatus = ""
    if ($Machine.UserName -ne $null) {
        $CurrentStatus = "In Use"
    }
    else {
        $CurrentStatus = "Idle"
    }
    $CheckInTimestamp = [datetime]::parseexact($Machine.TimeStamp.split('.')[0],"yyyyMMddHHmmss",[System.Globalization.CultureInfo]::InvariantCulture)
    $CheckInStatus = ""
    if ($CheckInTimestamp -gt (Get-Date).AddDays(-7)) {
        $CheckInStatus = "Active"
    }
    else {
        $CheckInStatus = "Inactive"
    }

    # Compile information into object.
    $MachineInfo += [pscustomobject] @{
        ResourceID = $Machine.ResourceID
        ComputerName = $Machine.Name
        Manufacturer = $Machine.Manufacturer
        Model = $Machine.Model
        RAMinGB = ($RAM.TotalPhysicalMemory / 1048576)
        ProcessorName = $Processor.Name
        ProcessorBits = $ProcessorBits
        ProcessorCount = $Machine.NumberOfProcessors
        ProcessorNumCores = $Processor.NumberOfCores
        ProcessorSpeedinGHZ = ($Processor.NormSpeed / 1000)
        CurrentUser = $Machine.UserName
        CurrentStatus = $CurrentStatus
        CheckInTimestamp = $CheckInTimestamp
        CheckInStatus = $CheckInStatus
    }

    $i += 1
}

Write-Host "Saving report locally."
$FileTitle = $MyInvocation.MyCommand.Name.split('.')[0]
$FolderSavePath = $PSScriptRoot + "\" + $FileTitle
$FileSavePath = $FolderSavePath + "\" + $FileTitle + ".csv"
if(!(Test-Path -Path $FolderSavePath )){
    New-Item -ItemType directory -Path $FolderSavePath > $null
}
$MachineInfo | ConvertTo-Csv | Select-Object -Skip 1 | Set-Content -Path $FileSavePath

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