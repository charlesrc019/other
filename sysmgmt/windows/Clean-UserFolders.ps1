# Collect info on Documents.
$document_valids = @("Amelia",
                     "Charles",
                     "Dallan",
                     "Jay",
                     "Karla",
                     "Nellie",
                     "Peter",
                     "William",
                     "My Music",
                     "My Pictures",
                     "My Videos",
                     ".sync",
                     "desktop.ini")
$document_files = Get-ChildItem -Path "C:\Users\Christensen\Documents" -Force

# Clean Documents.
foreach ($document_file in $document_files) {
    
    # Check if Document is valid.
    $match = $FALSE
    foreach ($document_valid in $document_valids) {
        if ($document_file.Name -eq $document_valid)
            { $match = $TRUE }
    }
    if ($match)
        { continue }
    
    # Process unvalid Documents.
    if ($document_file.PSIsContainer) {
        $sub_files = Get-ChildItem -Path $document_file.PSPath.split("::")[-1] *.* -Recurse -Force | where { ! $_.PSIsContainer }
        foreach ($sub_file in $sub_files)
            { Move-Item -Path "C:\$($sub_file.PSPath.split(":")[-1])" -Destination "C:\Users\Christensen\Downloads\$($sub_file.Name)" -Force }
        Remove-Item -Path $document_file.PSPath.split(":")[-1] -Recurse -Force
    }
    else
        { Move-Item -Path "C:\$($document_file.PSPath.split(":")[-1])" -Destination "C:\Users\Christensen\Downloads\$($document_file.Name)" -Force }
}

# Collect info and clean Desktop.
$desktop_files = Get-ChildItem -Path "C:\Users\Christensen\Desktop" -Force
foreach ($desktop_file in $desktop_files)
    { Move-Item -Path "C:\$($desktop_file.PSPath.split(":")[-1])" -Destination "C:\Users\Christensen\Downloads\$($desktop_file.Name)" -Force }

# Collect info and clean Downloads.
$download_files = Get-ChildItem -Path "C:\Users\Christensen\Downloads" -Force
$download_cachetime = (Get-Date).AddDays(-30)
foreach ($download_file in $download_files) {
    if ($download_file.LastWriteTime -lt $download_cachetime)
        { Remove-Item -Path "C:\$($download_file.PSPath.split(":")[-1])" -Recurse -Force }
}