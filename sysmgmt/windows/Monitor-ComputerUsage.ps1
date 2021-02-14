Function Test-Internet {
    for($i = 0; $i -lt 8; $i++) {
        if(Test-Connection -Quiet -ComputerName "1.1.1.1" -Count 1) {
            return $true
        }
        Start-Sleep -Seconds 1
    }
    return $false
}

Function Test-TimeRange {
    $hours = Get-Date -Format "HH" 
    if ([Int32]$hours -lt 4) {
        return $false
    }
    return $true
}

Function Test-LimitSwitch {
    $url = 'http://charles.chris-eng.com/api/sysmgmt/KarlaC-pc20.limit'
    $req = [system.Net.WebRequest]::Create($url)
    $res = 0
    try {
        $res = $req.GetResponse()
    } 
    catch [System.Net.WebException] {
        $res = $_.Exception.Response
    }
    if ($res.StatusCode -eq "OK") {
        return $true
    }
    return $false
}

Function Test-KillSwitch {
    $url = 'http://charles.chris-eng.com/api/sysmgmt/KarlaC-pc20.kill'
    $req = [system.Net.WebRequest]::Create($url)
    $res = 0
    try {
        $res = $req.GetResponse()
    } 
    catch [System.Net.WebException] {
        $res = $_.Exception.Response
    }
    if ($res.StatusCode -eq "OK") {
        return $true
    }
    return $false
}

$not_connected = $true
$not_validtime = $true
$limit_switch = $true
$kill_switch = $true
$count = 9999
while ($true) {
    if ($count -gt 30) {
        $count = 0
        $not_connected = (-not (Test-Internet))
        $not_validtime = (-not (Test-TimeRange))
        $limit_switch = Test-LimitSwitch
        $kill_switch = Test-KillSwitch
    }
    else {
        $count++
    }
    if ($kill_switch) {
        Stop-Computer -Force
    }
    if ($not_connected -or $not_validtime -or $limit_switch) {
        Stop-Process -Name "vlc" -Force -ErrorAction SilentlyContinue
        Stop-Process -Name "wmplayer" -Force -ErrorAction SilentlyContinue
        Stop-Process -Name "Microsoft.Photos" -Force -ErrorAction SilentlyContinue
        Stop-Process -Name "msedge" -Force -ErrorAction SilentlyContinue
        Stop-Process -Name "chrome" -Force -ErrorAction SilentlyContinue
        Stop-Process -Name "iexplore" -Force -ErrorAction SilentlyContinue
    }
    Start-Sleep -Seconds 5
}