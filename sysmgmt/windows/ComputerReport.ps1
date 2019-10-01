# Collect system data.
$System = Get-WMIObject -class Win32_ComputerSystem
$BIOS = Get-WMIObject -class Win32_BIOS
$Processor = Get-WMIObject -class Win32_Processor
$OS = Get-WMIObject -class Win32_OperatingSystem
$Processes = Get-WMIObject -class Win32_Process

# Organize data.
$Uptime = (Get-Date) - [datetime]::parseexact($OS.LastBootUpTime.split('.')[0],"yyyyMMddHHmmss",[System.Globalization.CultureInfo]::InvariantCulture)
$SystemInfo = [pscustomobject] @{
    Hostname = $System.Name
    Owner = $System.PrimaryOwnerName
    Manufacturer = $System.Manufacturer
    Model = $System.Model
    SerialNumber = $BIOS.SerialNumber
    ProcessorType = $Processor.Name
    ProcessorCores = $Processor.NumberOfCores
    Memory = ([string]( $System.TotalPhysicalMemory / (1024*1024*1024) )).split('.')[0] + " GB"
    BIOSVersion = $BIOS.SMBIOSBIOSVersion
    OSVersion = "Microsoft Windows " + $OS.Version
    Domain = $System.Domain
    LastBootTime = [datetime]::parseexact($OS.LastBootUpTime.split('.')[0],"yyyyMMddHHmmss",[System.Globalization.CultureInfo]::InvariantCulture)
    Uptime = "{0:00}d {1:00}h {2:00}m {3:00}s" -f $Uptime.Days,$Uptime.Hours,$Uptime.Minutes,$Uptime.Seconds
    ActiveProcesses = $Processes.Count
    }
$SystemProcesses = $Processes | Select ProcessId,Name,CreationDate,CommandLine | Sort-Object CreationDate | Format-Table -Property ProcessId,Name,CreationDate,CommandLine

# Write data to file.
$InformationFile = "$env:USERPROFILE\Desktop\SystemInformation.txt"
$SystemInfo > $InformationFile
$SystemProcesses >> $InformationFile