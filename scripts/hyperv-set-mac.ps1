param (
    [parameter (Mandatory=$true)]
    [string]$VmName,
    [parameter (Mandatory=$true)]
    [string]$MAC
)

try {
  Write-Host "  VM-Machine: $VmName"
  Write-Host "  MAC Address: $MAC"
  $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
  Write-Host "  IsAdmin: " $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
  
  $vmadapter = Get-VMNetworkAdapter -VMName $VmName   
  Set-VMNetworkAdapter -VMNetworkAdapter $vmadapter[1] -StaticMacAddress $MAC
  
  Write-Host "Configuration of MAC Address finished"
}
catch {
  Write-Host "Failed to set VM's MAC Address: $_"
}