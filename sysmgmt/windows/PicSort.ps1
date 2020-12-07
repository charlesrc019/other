<#-------------------------------------------------------------------------------------------------------------------

.SYNOPSIS
PIC SORT
Sort pictures into an organized directory structure based on their timestamp

.NOTES
Author: Charles Christensen (github.com/charlesrc19)
Required Dependencies: System.Drawing
Optional Dependencies: none

-------------------------------------------------------------------------------------------------------------------#>

# Initialize parameters.
$SOURCE_DIR = "D:\old"
$DEST_DIR = "D:\new"
$notimg_dir = "$SOURCE_DIR\PicSort\not_image"
$notime_dir = "$SOURCE_DIR\PicSort\not_timestamped"
$valid_exts = @(".jpg",".jpeg",".avi",".mp4", ".3gp", ".mov",".png",".mpo","mpg")
$dir_count = 0
$sort_count = 0
$err_count = 0
$bsp_count = 0

# Initialize libraries.
[reflection.assembly]::LoadWithPartialName("System.Drawing") | Out-Null

# Function. Move photo based on EXIF timestamp.
function Photo-Move([string]$path, [string]$filename) {

    Write-Progress -Activity "$path\$filename" -PercentComplete 42

    # Check if it is a valid file.
    $valid = $false
    foreach ($valid_ext in $valid_exts) {
        if ($filename -match $valid_ext) {
            $valid = $true
        }
    }
    if (-not $valid) {
        Directory-Check $notimg_dir
        Move-Item -Path "$path\$filename" -Destination "$notimg_dir\$filename" -Force
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
            $file = Get-Item "$path\$filename"
            $timestamp = $file.LastWriteTime
        }
        catch {
            Directory-Check $notime_dir
            Move-Item -Path "$path\$filename" -Destination "$notime_dir\$filename" -Force
            $global:err_count++
            return
        }
    }

    # Extract timestamp info and create folder structure.
    $year = $timestamp.ToString("yyyy")
    $month = $timestamp.ToString("MM")
    $daystamp = $timestamp.ToString("dd_HHmmss")
    $extra = ""
    $ext = $filename.Split(".")[-1].ToLower()

    # Move photo, rename if needed, and move to cache if failed.
    Directory-Check "$DEST_DIR\$year\$month"
    while (Test-Path "$DEST_DIR\$year\$month\$daystamp$extra.$ext") {
        if ($extra -eq "") {
            $extra = "B"
        }
        else {
            $extra = [char]([byte]([char]$extra) + 1)
        }
    }
    try {
        Move-Item -Path "$path\$filename" -Destination "$DEST_DIR\$year\$month\$daystamp$extra.$ext" 
        $global:sort_count++
    }
    catch {
        Directory-Check $notime_dir
        Move-Item -Path "$path\$filename" -Destination "$notime_dir\$filename" -Force
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
function Directory-Scan([string]$path) {

    Write-Progress -Activity "$path" -PercentComplete 10

    # Check that we have entered a valid directory.
    $global:dir_count++
    if ((-not (Test-Path $path)) -or (-not ((Get-Item $path).PSIsContainer))) {
        Write-Host "Invalid directory. <$path>"
        return
    }

    # Extract and sort directory children.
    $dirs = @()
    $files = @()
    $children = Get-ChildItem -Path $path -Force
    foreach ($child in $children) {
        if ($child.PSIsContainer) {
            $dirs += $child
        }
        else {
            $files += $child
        }
    }

    # Recurse into subdirectories.
    foreach ($dir in $dirs) {
        $new_dir = $path + "\" + $dir.Name
        Directory-Scan $new_dir
    }

    # Process files in directory.
    foreach ($file in $files) {
        Photo-Move $path $file.Name
    }
}

# Main.
Write-Host "PicSort started."
Write-Host -ForegroundColor Yellow "(Please wait. We're going through all your photos, and that can take a while.)"
Write-Host ""
Directory-Check $DEST_DIR
Directory-Scan $SOURCE_DIR
Write-Progress -Activity "Done" -PercentComplete 100
Write-Host "Directories Scanned: $dir_count"
Write-Host "Pictures Sorted: $sort_count"
Write-Host "Files w/ Errors: $err_count"
