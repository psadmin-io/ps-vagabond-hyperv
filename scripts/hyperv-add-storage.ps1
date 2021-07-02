param (
    [parameter (Mandatory=$true)]
    [string]$VmName,
    [parameter (Mandatory=$true)]
    [string]$StoragePath
)

try {
  $NewDrive = "${StoragePath}\${VmName}_data.vhdx"
  Write-Host "  VM-Machine: $VmName"
  Write-Host "  Storage Path: $StoragePath"
  Write-Host "  New Drive: ${NewDrive}"

  if ( -Not ( Test-Path $NewDrive )){

    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    Write-Host "  IsAdmin: " $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    Hyper-V\New-VHD -Dynamic $NewDrive -SizeBytes 120GB
    Hyper-V\Add-VMHardDiskDrive -VMName $vmname -Path $NewDrive -ErrorAction "stop"
  }
  Write-Host "Configuration of Storage finished "
}
catch {
  Write-Host "Failed to set VM's Second Hard Drive: $_"
}