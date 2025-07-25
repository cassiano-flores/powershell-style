function Optimize-Rad {
  # priority codes
  # 256 pealtime
  # 128 high
  # 32768 above normal
  # 32 normal
  # 16384 below normal
  # 64 low

  function Set-ProcessPriority {
    param (
      [string]$Name,
      [int]$Priority
    )
    Get-CimInstance Win32_Process -Filter "Name = '$Name'" | ForEach-Object {
      Invoke-CimMethod -InputObject $_ -MethodName SetPriority -Arguments @{ Priority = $Priority }
      Write-Output "Set priority $Priority for process $Name (PID: $($_.ProcessId))"
    }
  }

  # Delphi
  Set-ProcessPriority -Name "bds.exe" -Priority 128
  Set-ProcessPriority -Name "DelphiLsp.exe" -Priority 128
  Set-ProcessPriority -Name "dbkw64_27_0.exe" -Priority 128

  # Low Browser and Microsoft utils
  Set-ProcessPriority -Name "chrome.exe" -Priority 64
  Set-ProcessPriority -Name "klogg.exe" -Priority 64
  Set-ProcessPriority -Name "klogg_crashpad_handler.exe" -Priority 64
  Set-ProcessPriority -Name "ms-teams.exe" -Priority 64

  Write-Output "TREMBO APLICADA COM SUCESSO"
}
