<#-------------------------------------------------------------------------------------------------------------------

.SYNOPSIS
PIC SELECT
Randomly select a amount of photos

.NOTES
Author: Charles Christensen (github.com/charlesrc19)
Required Dependencies: ExifTool, ImgMagik
Optional Dependencies: none

-------------------------------------------------------------------------------------------------------------------#>

# Initialize parameters.
$SOURCE_DIR = ""
$DEST_DIR = ""
$DEST_WIDTH = 1920
$DEST_HEIGHT = 1200
$GBS_TO_SELECT = 8
$EXIFTOOL_LOC = "C:\Users\User\Downloads\exiftool.exe"
$IMGMAGIKCONVERT_LOC = "C:\Users\User\Downloads\convert.exe"

$valid_exts = @("jpg","jpeg")
$pics = @()
$used_pics = New-Object System.Collections.Generic.HashSet[string]
$used_names = New-Object System.Collections.Generic.HashSet[string]

# Initialize libraries.
[reflection.assembly]::LoadWithPartialName("System.Drawing") | Out-Null

# Function. Analyze photo based on EXIF dimensions.
function Photo-Analyze([string]$path) {

    # Check if it is a valid file.
    $valid = $false
    $ext = $path.Split(".")[-1].ToLower()
    foreach ($valid_ext in $valid_exts) {
        if ($ext -eq $valid_ext) {
            $valid = $true
        }
    }
    if (-not $valid) {
        return
    }

    # Analyze file dimenstions and orientation.
    $data = & $EXIFTOOL_LOC $path -ImageWidth -ImageHeight -Orientation
    [int32]$width = $data[0].Split()[-1]
    [int32]$height = $data[1].Split()[-1]
    try {
        $orientation = $data[2].Split()[-2]
        if ( (($orientation / 90) % 2) -eq 1) {
            $tmp = $width
            $width = $height
            $height = $tmp
        }
    }
    catch { }

    # Save data for horozontal images.
    if ($width -gt $height) {
        Write-Host $path
        $ratio = [math]::Round(($width / $height),2)
        $global:pics += [PSCustomObject]@{
            Path    = $path
            Width   = $width
            Height  = $height
        }
        return $true
    }

    return $false
}

# Function. Select a random photo and random photo destinaton.
function Photo-Select() {
    while ($true) {

        # Check that we haven't maxed out the size.
        $size = (gci $DEST_DIR | measure Length -s).sum / 1Gb
        if ($size -gt $GBS_TO_SELECT) {
            break
        }
        Write-Progress -Activity "Selecting random images..." -PercentComplete (($size / $GBS_TO_SELECT) * 100)

        # Base case. Already used all pics.
        if ($global:pics.Length -eq $global:used_pics.Count) {
            Write-Host "All avalible pictures have been used!"
            break
        }

        # Choose a random photo.
        while ($true) {
            $pic = Get-Random -InputObject $pics
            if ($global:used_pics.Add($pic.Path)) {

                # Create a random name.
                while ($true) {
                    $name = ( -join ((0x30..0x39) + (0x41..0x5A) | Get-Random -Count 12  | % {[char]$_}) )
                    if ($global:used_names.Add($name)) {

                        # Adjust, move, and sanitize photo.
                        $dest_path = "$DEST_DIR\$name.jpg"
                        [string]$dims = "$DEST_WIDTH" + "x" + "$DEST_HEIGHT"
                        & $IMGMAGIKCONVERT_LOC $($pic.Path) -resize $dims^ -gravity center -extent $dims $dest_path
                        & $EXIFTOOL_LOC -All= -overwrite_original $dest_path | Out-Null

                        break
                    }
                }

                break
            }
        }
    }
    Write-Progress -Activity "Selecting random images..." -Status "Complete" -PercentComplete 100
}

# Function. Scan directories for files. Recurse into subdirectories.
function Directory-Scan([string]$path) {

    # Check that we have entered a valid directory.
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
        $new_dir = $path + "\" + $dir.Name
        Directory-Scan $new_dir
    }

    # Process files in directory.
    foreach ($file in $files) {
        Photo-Analyze $file.FullName | Out-Null
    }
}

# Main.
cls
Write-Host "PicSelect started."
Write-Host -ForegroundColor Yellow "(Please wait. We're scanning all your photos, and that can take a while.)"
Write-Host ""
Directory-Scan $SOURCE_DIR
Write-Host ""
Photo-Select
Write-Host ""
Write-Host "Done!"
