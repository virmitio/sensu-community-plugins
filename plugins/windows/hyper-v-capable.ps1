<#
  This will run the systeminfo command and parse the results for Hyper-V hardware capability.
  
  OK        - Hyper-V is or can be installed on system.
  Warning   - Unable to determine.  System does not support Hyper-V. (Causing systeminfo to not check related hardware info.)
  Critical  - Some virtualization components are not available.  They may be disabled or nonexistant on this hardware.
#>

$sysinfo = (systeminfo /fo csv);
$hv_index = $sysinfo[0].Substring(1,$sysinfo[0].Length-2).Replace('","','@').split('@').IndexOf('Hyper-V Requirements');
$out_text = ($sysinfo[1].Substring(1,$sysinfo[1].Length-2).Replace('","','@').split('@')[$hv_index]);
$exit_code = 3;
if ($hv_index -lt 0)
    {$out_text = "Hyper-V not available/installed on this system."; $exit_code = 1;}
if ($out_text.Contains("A hypervisor has been detected"))
    {$out_text = "Hyper-V installed and firmware enabled."; $exit_code = 0;}
else
{
    $line_items = $out_text.Split(',');
    $complete = $true;
    $line_items | ForEach-Object {$complete = $complete -and ($_.Trim().EndsWith('Yes'))};
    if ($complete) {$out_text = "Hyper-V capable, not installed."; $exit_code = 0}
    else {$out_text = "Virtualization not available, incomplete, or disabled. -- " + $out_text.Replace(',','; '); $exit_code = 2;}
}

Write-Output $out_text;
exit $exit_code;
