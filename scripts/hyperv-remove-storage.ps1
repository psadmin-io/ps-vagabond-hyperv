param (
    [parameter (Mandatory=$true)]
    [string]$VmName,
    [parameter (Mandatory=$true)]
    [string]$StoragePath
)

try {
  $NewDrive = "${StoragePath}\${VmName}_data.vhdx"
  Write-Host "  Storage Drive: ${NewDrive}"

  if ( Test-Path $NewDrive ){

    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    Write-Host "  IsAdmin: " $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    # Controller 1 is /dev/sdb
    remove-item $NewDrive -ErrorAction SilentlyContinue
  }
  Write-Host "Configuration of Storage finished"
}
catch {
  Write-Host "Failed to remove VM's Second Hard Drive: $_"
}