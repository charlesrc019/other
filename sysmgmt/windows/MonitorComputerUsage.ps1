# Initialize variables.
$LIMITED_HRS = @(0,1,2,3)
$LIMITED_APPS = @("vlc","wmplayer","Microsoft.Photos","msedge","chrome","firefox","brave","chromium","opera","iexplore","taskmgr","mmc","IGCC","cmd","WinStore.App","powershell_ise","powershell")
$SLEEP_SECS = 1
$SWITCHCHK_SECS = 60 * 2
$URL = 'http://www.chris-eng.com/api/ComputerUsage/status.txt'

# Main.
$hr = $null
$switch_limit = $false
$secs = $SWITCHCHK_SECS
while ($true) {

    # Check time limits.
    $time_limit = $false
    $hr = (Get-Date).Hour
    foreach ($limited_hr in $LIMITED_HRS) {
        if ($hr -eq $limited_hr) {
            $time_limit = $true
        }
    }

    # Check kill switch.
    if ((-not $time_limit) -and ($secs -ge $SWITCHCHK_SECS)) {
        $secs = 0

        # Create request.
        $rqst = [system.Net.WebRequest]::Create($URL)
        $resp = $null
        try {
            $resp = $rqst.GetResponse()
        } 
        catch [System.Net.WebException] {
            $resp = $_.Exception.Response
        }

        # Eval response.
        if ($resp.StatusCode -ne "OK") {
            $switch_limit = $false
        }
        else {
            $switch_limit = $true
        }
    }
    
    # Implement limits.
    if ($time_limit -or $switch_limit) {
        foreach ($limited_app in $LIMITED_APPS) {
            #Stop-Process -Name $limited_app -Force -ErrorAction SilentlyContinue
        }
    }

    # Delay.
    Start-Sleep -Seconds $SLEEP_SECS
    $secs += $SLEEP_SECS

}
