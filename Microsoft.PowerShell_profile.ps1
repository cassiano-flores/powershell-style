#******************************************************************************
# Import all modules and configs for PowerShell
#******************************************************************************
$profileDir = Split-Path -Parent $PROFILE
. "$profileDir\find-line-endings.ps1"

#******************************************************************************

function Prompt {

  # define o titulo da janela
  $CmdPromptUser = [Security.Principal.WindowsIdentity]::GetCurrent();
  # $host.ui.RawUI.WindowTitle = "PowerShell @ $($CmdPromptUser.Name.split("\")[1])"

  # nome do usuario e computador
  $UserName = $CmdPromptUser.Name.split("\")[1]
  $ComputerName = $env:COMPUTERNAME

  # git
  $isGitRepo = (Test-Path .git)
  $gitBranch = ''
  $gitRemoteName = ''
  $gitState = ''

  if ($isGitRepo) {
    $gitBranch = (git branch --show-current)  # branch atual
    $gitRemoteName = git config --get branch.$gitBranch.remote  # nome do remoto da branch atual

    # estados especiais
    if (Test-Path .git\REBASE_HEAD) {
      $gitState = 'REBASING'
    } elseif (Test-Path .git\MERGE_HEAD) {
      $gitState = 'MERGING'
    } elseif (Test-Path .git\CHERRY_PICK_HEAD) {
      $gitState = 'CHERRY-PICKING'
    } elseif (Test-Path .git\REVERT_HEAD) {
      $gitState = 'REVERTING'
    }
  }

  # diretorio e data/hora
  $CmdPromptCurrentFolder = $pwd.Path
  $DateTime = Get-Date -Format 'HH:mm:ss'

  # monta a linha
  $promptText = "$UserName@$ComputerName $CmdPromptCurrentFolder"

  # se tiver em alguma estado eh de um jeito, se nao eh de outro
  if ($isGitRepo) {

    if ($gitState -ne '' -and $gitBranch -ne '') {
      $promptText += " ($gitBranch|$gitState)"
    } elseif ($gitRemoteName -ne '' -and $gitBranch -ne '') {
      $promptText += " ($gitRemoteName/$gitBranch)"
    }

  } else {
    $promptText += " "
  }

  # espaço para alinhar a hora na direita
  $consoleWidth = $host.UI.RawUI.WindowSize.Width
  $textLength = $promptText.Length + $DateTime.Length

  if ($textLength -lt $consoleWidth) {
    $spaces = " " * ($consoleWidth - $textLength - 1)
  } else {
    $spaces = " "
  }

  # === monta o prompt superior ===
  Write-HostColor     -Text "`n$UserName@$ComputerName " -HexColor "#13A10E"
  Write-HostColor     -Text "$CmdPromptCurrentFolder "   -HexColor "#C19C00"
  if ($isGitRepo) {
    Write-HostColor   -Text "("                          -HexColor "#FFFFFF"

    if ($gitState -ne '') {
      Write-HostColor -Text "$gitBranch"                 -HexColor "#3A96DD"
      Write-HostColor -Text "|"                          -HexColor "#FFFFFF"
      Write-HostColor -Text "$gitBranch"                 -HexColor "#D10B0E"
    } else {
      Write-HostColor -Text "$gitRemoteName"             -HexColor "#D10B0E"
      Write-HostColor -Text "/"                          -HexColor "#FFFFFF"
      Write-HostColor -Text "$gitBranch"                 -HexColor "#3A96DD"
    }
    Write-HostColor   -Text ")"                          -HexColor "#FFFFFF"
  }
  Write-HostColor     -Text "$spaces$DateTime"           -HexColor "#FFFFFF" -NewLine $false

  # === monta o prompt inferior ===
  return "> "
}

function Write-HostColor {
  param (
    [string]$Text,
    [string]$HexColor,
    [bool]$NewLine = $true
  )

  # converte o hexadecimal para RGB
  $r = [Convert]::ToInt32($HexColor.Substring(1, 2), 16)
  $g = [Convert]::ToInt32($HexColor.Substring(3, 2), 16)
  $b = [Convert]::ToInt32($HexColor.Substring(5, 2), 16)

  # define a cor usando ANSI escape codes
  $ansiColor = "`e[38;2;${r};${g};${b}m"
  $resetColor = "`e[0m"

  # escreve o texto com a cor e quebra de linha
  if ($NewLine) {
    Write-Host -NoNewline "$ansiColor$Text$resetColor"
  } else {
    Write-Host "$ansiColor$Text$resetColor"
  }
}
