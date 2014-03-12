<#
  First script argument (if present) will be used as the metric scheme.
  If no argument is provided, the hostname will be used.
#>

if ($args.length -gt 0) {$Scheme = $args[0]}
else {$Scheme = (Get-WmiObject Win32_computersystem).Name}

$data = @()

$osdata = Get-WmiObject Win32_OperatingSystem
$pfdata = @(Get-WmiObject Win32_PageFileUsage)

# Get total system-visable RAM
$data += ("system.memory.TotalPhysicalMemoryGB {0:.##}" -f (($osdata.TotalVisibleMemorySize) /1024 /1024))
$data += ("system.memory.FreePhysicalMemoryGB {0:.##}" -f (($osdata.FreePhysicalMemory) /1024 /1024))

# Get Swap/Pagefile info
$pftotal = ($pfdata | Measure-Object -Property AllocatedBaseSize -Sum).Sum /1024
$pfused = ($pfdata | Measure-Object -Property CurrentUsage -Sum).Sum /1024
$data += ("system.memory.TotalSwapGB {0:.##}" -f $pftotal)
$data += ("system.memory.FreeSwapGB {0:.##}" -f ($pftotal - $pfused))

# Get Processors
$procs = @(Get-WmiObject Win32_Processor)
$data += ("system.CPU.PhysicalProcessorCount " + $procs.Count)
$procs | ForEach-Object {$data += ("system.CPU."+$_.DeviceID + ".maxClockGhz {0:.##}" -f ($_.MaxClockSpeed / 1000))}
$data += ("system.CPU.AverageLoadPercent " + ($procs | Measure-Object -Property LoadPercentage -Average).Average)
$data += ("system.CPU.TotalPhysicalCores " + ($procs | Measure-Object -Property NumberOfCores -Sum).Sum)
$data += ("system.CPU.TotalLogicalProcessors " + ($procs | Measure-Object -Property NumberOfLogicalProcessors -Sum).Sum)

<#
  The Get-Date function accepts Unix format strings, but applies the local 
  timezone offset from UTC when returning "second from epoch", so we need 
  to calculate our offset and remove it.
#>
$timestamp = [Math]::Round([Double]::Parse((Get-Date -UFormat "%s")))-([SByte]::Parse((Get-Date -UFormat "%Z"))*60*60)

# Return the data
$data | ForEach-Object {write-output ("" + $Scheme + $_ + " " + $timestamp)}
