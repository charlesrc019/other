<#-------------------------------------------------------------------------------------------------------------------

.SYNOPSIS
PIC SELECT
Randomly select a amount of photos

.NOTES
Author: Charles Christensen (github.com/charlesrc19)
Required Dependencies: none
Optional Dependencies: none

-------------------------------------------------------------------------------------------------------------------#>

# Initialize parameters.
$SOURCE_DIR = ""
$DEST_DIR = ""
$GBS_TO_SELECT = 1

$valid_exts = @("jpg","jpeg")
$pics = @()
$already = New-Object System.Collections.Generic.HashSet[string]

# Initialize libraries.
[reflection.assembly]::LoadWithPartialName("System.Drawing") | Out-Null

# Function. Analyze photo based on EXIF dimensions.
function Photo-Analyze([string]$path, [string]$filename) {

    # Check if it is a valid file.
    $valid = $false
    $ext = $filename.Split(".")[-1].ToLower()
    foreach ($valid_ext in $valid_exts) {
        if ($ext -eq $valid_ext) {
            $valid = $true
        }
    }
    if (-not $valid) {
        return
    }

    # Load dimension info.
    $wide = $false
    try {
        $pic = New-Object System.Drawing.Bitmap("$path\$filename")
        try {
            if ($pic.Width -gt $pic.Height) {
                $wide = $true
            }
        }
        catch {
            throw
        }
        finally {
            $pic.Dispose()
        }
    }
    catch {
        return
    }

    # Add valid photos to array.
    if ($wide) {
        $global:pics += "$path\$filename"
        Write-Host "$path\$filename"
    }
    return
}

# Function.
function Photo-Select() {
    while ($true) {

        # Check that we haven't maxed out the size.
        $size = (gci $DEST_DIR | measure Length -s).sum / 1Gb
        if ($size -gt $GBS_TO_SELECT) {
            break
        }

        # Choose a random photo and copy it.
        while ($true) {
            $filepath = Get-Random -InputObject $pics
            if ($already.Add($filepath)) {
                Copy-Item -Path $filepath -Destination $DEST_DIR -Force
                Write-Host $size GB
                break
            }
        }
    }
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
        Photo-Analyze $path $file.Name
    }
}

# Main.
cls
Write-Host "PicSelect started."
Write-Host -ForegroundColor Yellow "(Please wait. We're scanning all your photos, and that can take a while.)"
Write-Host ""
Directory-Scan $SOURCE_DIR
Photo-Select
Write-Host "Done!"
