<#-------------------------------------------------------------------------------------------------------------------

.SYNOPSIS
PIC SORT
Sort pictures into an organized directory structure based on their timestamp

.NOTES
Author: Charles Christensen (github.com/charlesrc19)
Required Dependencies: MediaInfo CLI
Optional Dependencies: none

-------------------------------------------------------------------------------------------------------------------#>

# Initialize parameters.
$SOURCE_DIR = "D:\All"
$DEST_DIR = "D:\All"
$DELETE_DUPS = $true
$MEDIAINFO_PATH = "C:\Users\crc19\Downloads\mediainfo"

$valid_exts = @("jpg","jpeg","gif","png","mpo","raw","mp4", "3gp", "mov","avi","mpg")
$notimg_dir = "$SOURCE_DIR\PicSort\INVALID_IMG"
$notime_dir = "$SOURCE_DIR\PicSort\INVALID_TIMESTAMP"
$dir_count = 0
$sort_count = 0
$err_count = 0

# Initialize libraries.
[reflection.assembly]::LoadWithPartialName("System.Drawing") | Out-Null

# Function. Move photo based on EXIF timestamp.
function Photo-Move([string]$path, [string]$filename) {

    # Check if it is a valid file.
    $valid = $false
    $ext = $filename.Split(".")[-1].ToLower()
    foreach ($valid_ext in $valid_exts) {
        if ($ext -eq $valid_ext) {
            $valid = $true
        }
    }
    if (-not $valid) {
        Directory-Check $notimg_dir
        Move-Item -LiteralPath "$path\$filename" -Destination "$notimg_dir\$filename" -Force
        $global:err_count++
        return
    }

    # Load EXIF info, if possible. Move into cache if not.
    $timestamp = $null
    try {
        $pic = New-Object System.Drawing.Bitmap("$path\$filename")
        try {
            $bytes = $pic.GetPropertyItem(36867).Value
            $string = [System.Text.Encoding]::ASCII.GetString($bytes)
            $timestamp = [datetime]::ParseExact($string,"yyyy:MM:dd HH:mm:ss`0",$Null)
        }
        catch {
            throw
        }
        finally {
            $pic.Dispose()
        }
    }
    catch {
        try {
            try {
                $data = Invoke-Expression "$MEDIAINFO_PATH\MediaInfo.exe $path\$filename --full --output=JSON" | ConvertFrom-Json
                $string = [string]$data.media.track.Where{$_.'@Type' -eq 'General'}.Encoded_Date
                $arr = $string.Split()[1,-1]
                $string = $arr -join " "
                $timestamp = [datetime]::ParseExact($string,"yyyy-MM-dd HH:mm:ss",$Null)
            }
            catch {
                $file = Get-Item "$path\$filename"
                $timestamp = $file.LastWriteTime
            }
            if ($timestamp -eq $null) {
                throw
            }
        }
        catch {
            Directory-Check $notime_dir
            Move-Item -LiteralPath "$path\$filename" -Destination "$notime_dir\$filename" -Force
            $global:err_count++
            return
        }
    }

    # Extract timestamp info and create folder structure.
    $year = $timestamp.ToString("yyyy")
    $month = $timestamp.ToString("MM")
    $daystamp = $timestamp.ToString("dd_HHmmss")
    $extra = ""

    # Move photo, rename if needed, and move to cache if failed.
    Directory-Check "$DEST_DIR\$year\$month"
    $overflow = $false

    if (-not $DELETE_DUPS) {
        while (Test-Path "$DEST_DIR\$year\$month\$daystamp$extra.$ext") {
            if ($extra -eq "") {
                $extra = "B"
            }
            else {
                $extra = [char]([byte]([char]$extra) + 1)
                if ($extra -notmatch '^[a-z0-9]+$') {
                    $overflow = $true
                    break
                }
            }
        }
    }
    try {
        if ($overflow) {
            throw
        }
        Move-Item -LiteralPath "$path\$filename" -Destination "$DEST_DIR\$year\$month\$daystamp$extra.$ext" -Force
        $global:sort_count++
    }
    catch {
        Directory-Check $notime_dir
        Move-Item -LiteralPath "$path\$filename" -Destination "$notime_dir\$filename" -Force
        $global:err_count++
    }  
}

# Function. Check that directory exists, and make it if needed.
function Directory-Check([string]$dir) {
    if (-not (Test-Path $dir)) {
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
    }
}

# Function. Scan directories for files. Recurse into subdirectories.
function Directory-Scan([string]$path, [bool]$base=$false) {

    # Check that we have entered a valid directory.
    $global:dir_count++
    if ((-not (Test-Path $path)) -or (-not ((Get-Item $path).PSIsContainer))) {
        Write-Host "Invalid directory. <$path>"
        return
    }

    # Extract and sort directory children.
    $dirs = @()
    $files = @()
    $children = Get-ChildItem -LiteralPath $path -Force | Sort
    foreach ($child in $children) {
        if ($child.PSIsContainer) {
            $dirs += $child
        }
        else {
            $files += $child
        }
    }

    # Recurse into subdirectories.
    $index = 0
    foreach ($dir in $dirs) {
        $index++
        if ($base) {
            Write-Progress -Activity $path\$dir -PercentComplete (($index / $dirs.Count) * 90)
        }
        $new_dir = $path + "\" + $dir.Name
        Directory-Scan $new_dir
    }

    # Process files in directory.
    foreach ($file in $files) {
        Photo-Move $path $file.Name
    }
    if ($base) {
        Write-Progress -Activity $path -PercentComplete 100
    }
}

# Main.
cls
Write-Host "PicSort started."
Write-Host -ForegroundColor Yellow "(Please wait. We're going through all your photos, and that can take a while.)"
Write-Host ""
Directory-Check $DEST_DIR
Directory-Scan $SOURCE_DIR $true
Write-Progress -Activity "Done" -PercentComplete 100
Write-Host "Directories Scanned: $dir_count"
Write-Host "Pictures Sorted: $sort_count"
Write-Host "Files w/ Errors: $err_count"
Write-Host ""
