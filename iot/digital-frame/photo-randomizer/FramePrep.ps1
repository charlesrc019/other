<#-------------------------------------------------------------------------------------------------------------------
    
    .SYNOPSIS
    FRAME PREP
    Randomize JPG photos for uploading to a digital picture frame.

    .NOTES
    Author: Charles Christensen (github.com/charlesrc19)
    Required Dependencies: WinSCP binaries, FTPES account
    Optional Dependencies: none

-------------------------------------------------------------------------------------------------------------------#>

#--------------------------------------------------------------------------------------
# SETTINGS
#--------------------------------------------------------------------------------------

# Initialize global variables.
$EXIFTOOL_BIN = "exiftool.exe"

#--------------------------------------------------------------------------------------
# FUNCTIONS
#--------------------------------------------------------------------------------------

# https://www.reddit.com/r/PowerShell/comments/77oeuz/getrandomdate/
Function Get-RandomDate {
    [cmdletbinding()]

    param(
        [DateTime]
        $Min = (Get-Date).AddMonths(-12),

        [DateTime]
        $Max = [DateTime]::Now
    )

    Begin{
        If(!$Min -or !$Max){
            Write-Warning "Unable to parse entered string for Min or Max parameter. Proper example: `"06/23/1996 14:06:03.297`""
            Write-Warning "Time will default to midnight if omitted"
            Break
        }
    }

    Process{
        $randomTicks = Get-Random -Minimum $Min.Ticks -Maximum $Max.Ticks
        New-Object DateTime($randomTicks)
    }
}

# https://blogs.technet.microsoft.com/poshchap/2017/07/28/generate-a-random-alphanumeric-password/
function Get-RandomAlphanum {

    $c = $null

    for ($i = 1; $i -lt 11; $i++) {

        $a = Get-Random -Minimum 1 -Maximum 3

        switch ($a) {
            1 {$b = Get-Random -Minimum 48 -Maximum 58}
            2 {$b = Get-Random -Minimum 65 -Maximum 91}
        }

        [string]$c += [char]$b

    }

    $c
}

#--------------------------------------------------------------------------------------
# MAIN
#--------------------------------------------------------------------------------------

# Determine grandparent folder.
$bin_loc = $PSScriptRoot
$tmp = $bin_loc.Split("\")[-1]
$photos_loc = $bin_loc.Substring(0, $bin_loc.Length-($tmp.Length+1))

# Collect all old photos.
$photos = Get-ChildItem -Path "$photos_loc\*" -Include *.jpg,*.jpeg
$names = New-Object System.Collections.Generic.HashSet[string]
foreach ($photo in $photos) {
    $names.Add($photo.Name) | Out-Null
}

# Loop through each photo to prep.
$count = 0
foreach ($photo in $photos) {

    # Copy with generic filename.
    $is_unique = $false
    $name = ""
    while (-not $is_unique) {
        $name = Get-RandomAlphanum
        $name += ".jpg"
        $is_unique = $names.Add($name)
    }
    Copy-Item -Path "$photos_loc\$($photo.Name)" -Destination "$photos_loc\$name" -Force
    Remove-Item -Path "$photos_loc\$($photo.Name)" -Force

    # Remove all EXIF data.
    Start-Process "$bin_loc\$EXIFTOOL_BIN" -ArgumentList "-all= '..\$($photo.Name)' -overwrite_original" -Wait -NoNewWindow

    # Reset file timestamps.
    $date = Get-RandomDate
    $file = Get-ChildItem -Path "$photos_loc\$name"
    $file.CreationTime = $date
    $file.LastWriteTime = $date
    $file.LastAccessTime = $date

    # Update status info.
    Write-Host "- $($photo.Name) >> $name"
    $count++
}
Write-Host "Total: $count"
