# Initialize variables.
$browsers = @("Mozilla", "Firefox", "Opera", "Internet Explorer")

# Collect list of all restricted browsers.
$apps = Get-WMIObject -Class win32_product
$guids = @()
foreach ($app in $apps) {
    foreach ($browser in $browsers) {
        $tmp = "*" + $browser + "*"
        if ($app.Name -like $tmp) {
            $tmp = $app.Name
            Write-Host "Uninstalling: $tmp"
            msiexec /x $app.IdentifyingNumber /q
            Start-Sleep -s 5
            break
        }
    }
}

# Disable/remove Microsoft Edge.
Remove-Item C:\Windows\SystemApps\Microsoft.MicrosoftEdge_8wekyb3d8bbwe -Recurse -Force -ErrorAction SilentlyContinue
takeown /f C:\Windows\SystemApps\Microsoft.MicrosoftEdge_8wekyb3d8bbwe
icacls C:\Windows\SystemApps\Microsoft.MicrosoftEdge_8wekyb3d8bbwe /grant administrators:f
