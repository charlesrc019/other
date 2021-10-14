
<#-------------------------------------------------------------------------------------------------------------------

.SYNOPSIS
DEPLOYMENT SCRIPT BACKUP
Perform a backup of all scripts used to deploy software.

.NOTES
Author: Charles Christensen (github.com/charlesrc19)
Required Dependencies: WinSCP binaries, FTPES account
Optional Dependencies: none

-------------------------------------------------------------------------------------------------------------------#>

# Initialize parameters.
$SOURCE_DIR = ""
$DEST_DIR = ""
$FTPES_HOST = ""
$FTPES_USERNAME = ""
$FTPES_PASSWORD = ""
$FTPES_BINARY_LOC = "...WinSCPdll.net"
$LOG_LOC = "...DeploymentScriptBackup.log"

$included_exts = @("bat", "ps1")
$included_dirs = @("scripts", "licenses")
$excluded_prts = @("test")
$src_dir_div = "\"
$dst_dir_div = "/"
$log = ""

# Load libraries.
Add-Type -Path $FTPES_BINARY_LOC

# Function. Open an FTPES connection.
function ftpesCreate() {
    $options = New-Object WinSCP.SessionOptions -Property @{
        protocol = [WinSCP.Protocol]::Ftp
        hostname = $FTPES_HOST
        username = $FTPES_USERNAME
        password = $FTPES_PASSWORD
        ftpsecure = [WinSCP.FtpSecure]::Explicit
    }
    $session = New-Object WinSCP.Session
    try {
        $session.Open($options)
        return $session
    }
    catch {
        throw
    }
}

# Function. Fetch a list of directory contents from FTPES.
function ftpesFetch([string]$dir) {
    $contents = $null
    try {
        $session = ftpesCreate
        $contents = $session.ListDirectory($dir)
    }
    catch {
        logWrite "FTPES" "Unable to FETCH." "3" $dir
    }
    finally {
        $session.Dispose()
    }
    $contents = $contents.Files | Where-Object Name -ne ".."
    return $contents.Name
}

# Function. Upload a file to FTPES.
function ftpesPut([string]$src_path, [string]$dst_path) {
    try {
        $session = ftpesCreate
        $result = $session.PutFiles($src_path, $dst_path)
        if (-not $result.IsSuccess)
            {throw}
    }
    catch {
        logWrite "FTPES" "Unable to PUT." "3" $dst_path
    }
    finally {
        $session.Dispose()
    }
    
    return
}

# Function. Delete a file from FTPES.
function ftpesDelete([string]$path) {
    Write-Host $path -ForegroundColor Red
    try {
        $session = ftpesCreate
        $result = $session.RemoveFiles($path)
        if (-not $result.IsSuccess)
            {throw}
    }
    catch {
        logWrite "FTPES" "Unable to DELETE." "3" $path
    }
    finally {
        $session.Dispose()
    }
}

# Function. Clear log file and start a new one.
function logStart() {
    Remove-Item $LOG_LOC -Force -ErrorAction SilentlyContinue | Out-Null
    New-Item $LOG_LOC -ItemType File -Force -ErrorAction SilentlyContinue | Out-Null
}

# Function. Write to the log file.
function logWrite([string]$source, [string]$text, $type, [string]$file="") {

    $text = "$text [$file]"

    # Write to log file.
    $time = "$(Get-Date -Format HH:mm:ss).$((Get-Date).Millisecond)+000"
    $date = Get-Date -Format MM-dd-yyyy
    $format = '<![LOG[{0}]LOG]!><time="{1}" date="{2}" component="{3}" context="" type="{4}" thread="" file="{5}">'
    $data = $text, $time, $date, $source, $type, $file
    $entry = $format -f $data
    Add-Content $LOG_LOC $entry

    # Write to screen.
    $entry = "${source}: $text"
    $color = "Gray"
    if ([string]$type -eq "2")
        {$color = "Yellow"}
    elseif ([string]$type -eq "3") 
        {$color = "Red"}
    Write-Host $entry -ForegroundColor $color
}

# Function. Verify if it is valid to backup from the specified directory path.
function localVerify([string]$dir) {
    $curr_dirs = $dir.Split($src_dir_div)
    foreach ($curr_dir in $curr_dirs) {
        foreach ($included_dir in $included_dirs) {
            if ($curr_dir -like $included_dir) {
                return $true
            }
        }
    }
    return $false
}

# Function. Fetch and extract files that need to be recursed on.
function localFetch($dir, $valid_dir) {
    $files = Get-ChildItem -Path $dir -ErrorAction SilentlyContinue
    $filtered_files = @()
    foreach ($file in $files) {
        if ($file.PSIsContainer) 
            {$filtered_files += $file}
        elseif ($valid_dir) {
            foreach ($included_ext in $included_exts) {
                $ext = "*." + $included_ext
                if ($file.Name -like $ext) {
                    $excluded = $false
                    foreach ($excluded_prt in $excluded_prts) {
                        if ($file.Name -match $excluded_prt) {
                            $excluded = $true
                            break
                        }
                    }
                    if (-not $excluded)
                        {$filtered_files += $file}
                    break
                }
            }
        }
    }
    return $filtered_files
}

# Function. Create timestamp of source file.
function srcTimestamp($file, $dir) {
    # Create new source timestamp.
    $src_path = $dir + $src_dir_div + $file
    $src_info = Get-Item -Path $src_path
    $src_timestamp = @($src_info.LastWriteTime.Year.ToString(), $src_info.LastWriteTime.Month.ToString(), $src_info.LastWriteTime.Day.ToString())
    for ($i = 1; $i -lt 3; $i++) {
        if ($src_timestamp[$i].Length -lt 2)
            {$src_timestamp[$i] = "0" + $src_timestamp[$i]}
    }
    $src_timestamp = $src_timestamp[0] + $src_timestamp[1] + $src_timestamp[2]
    return $src_timestamp
}

# Function. Fetch the newest timestamp of the destination files.
function dstTimestamp($file, $prev_files, $dst_dir) {

    # Compare only those files with similar name.
    $prefix = $file.Split(".")[0] + "_*." + $file.Split(".")[-1]
    $match_files = @()
    foreach ($prev_file in $prev_files) {
        if ($prev_file -like $prefix) {
            $match_files += $prev_file
        }
    }

    # If no matching files, create backup.
    if ($match_files.Count -eq 0) 
        {return 0}

    # Extract newest destination timestamp, if any.
    $dst_timestamp = 0
    foreach ($match_file in $match_files) {
        $curr_timestamp = $match_file.Split(".")[0]
        $curr_timestamp = $curr_timestamp.Split("_")[-1]

        # Cleanup mis-dated files.
        if ([string]$curr_timestamp.Length -gt 8) {      
            $tmp = $dst_dir + $dst_dir_div + $file.Split(".")[0] + "_" + $curr_timestamp + "." + $file.Split(".")[-1]
            ftpesDelete $tmp
            continue
        }

        if ([Int32]$curr_timestamp -gt [Int32]$dst_timestamp) 
            {$dst_timestamp = $curr_timestamp}
    }

    return [string]$dst_timestamp
}

# Function. Backup file, if modified.
function backupFile([string]$file, [string]$src_dir, [string]$dst_dir, $dst_files) {

    # Determine if file needs to be backed up.
    $src_timestamp = srcTimestamp $file $src_dir
    $dst_timestamp = dstTimestamp $file $dst_files $dst_dir

    $src_path = $src_dir + $src_dir_div + $file

    if ([Int32]$src_timestamp -gt [Int32]$dst_timestamp) {

        # Backup file.
        $dst_path = $dst_dir + $dst_dir_div + $file.Split(".")[0] + "_" + $src_timestamp + "." + $file.Split(".")[-1]
        logWrite "BACKUP_ENGINE" "New backup needed." "2" $dst_path
        ftpesPut $src_path $dst_path
    }
    else {
        logWrite "BACKUP_ENGINE" "Backup not needed." "1" $src_path
    }


    return
}

# Function. Recursive to step down into directories and back them up as needed.
function backupDirectory([string]$src_dir, [string]$dst_dir, $valid_dir=$false) {

    # Get source directory info.
    if (-not $valid_dir) {
        $valid_dir = localVerify $src_dir
    }
    $src_files = localFetch $src_dir $valid_dir

    # Get destination directory info.
    $dst_files = $null
    if ($valid_dir) {
        $dst_files = ftpesFetch $dst_dir
    }

    # Recurse on all directory children.
    foreach ($src_file in $src_files) {
        
        # Backup directory.
        if ($src_file.PSIsContainer) {
            $new_src_dir = $src_dir + $src_dir_div + $src_file.Name
            $new_dst_dir = $dst_dir + $dst_dir_div + $src_file.Name
            backupDirectory $new_src_dir $new_dst_dir
        }

        # Backup files.
        else {
            backupFile $src_file.Name $src_dir $dst_dir $dst_files
        }

    }

    return
}

# Main.
logStart
logWrite "LOG_ENGINE" "New backup process started." "1"
backupDirectory $SOURCE_DIR $DEST_DIR
logWrite "LOG_ENGINE" "New backup process complete." "1"
