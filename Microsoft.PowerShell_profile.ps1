#******************************************************************************
# Import all modules and configs for PowerShell
#******************************************************************************
$profileDir = Split-Path -Parent $PROFILE
. "$profileDir\find-line-endings.ps1"
. "$profileDir\open-path.ps1"

#******************************************************************************

function Prompt {

  # define o titulo da janela
  $CmdPromptUser = [Security.Principal.WindowsIdentity]::GetCurrent();
  # $host.ui.RawUI.WindowTitle = "PowerShell @ $($CmdPromptUser.Name.split("\")[1])"

  # nome do usuario e computador
  $UserName = $CmdPromptUser.Name.split("\")[1]
  $ComputerName = $env:COMPUTERNAME

  # git
  $isGitRepo   = (Test-Path .git)
  $isREBASING  = (Test-Path .git\REBASE_HEAD)
  $isMERGING   = (Test-Path .git\MERGE_HEAD)
  $isCHERRY    = (Test-Path .git\CHERRY_PICK_HEAD)
  $isREVERTING = (Test-Path .git\REVERT_HEAD)
  $gitBranch   = ""
  $gitRemote   = ""
  $gitState    = ""

  # diretorio e data/hora
  $CmdPromptCurrentFolder = $pwd.Path
  $DateTime = Get-Date -Format "HH:mm:ss"

  # monta a linha
  $promptText = "$UserName@$ComputerName $CmdPromptCurrentFolder"

  if ($isGitRepo) {
    $gitBranch = Get-Branch
    $gitRemote = git config --get branch.$gitBranch.remote  # nome do remoto da branch atual
    $gitState  = Get-State
  
    # se tiver em alguma estado eh de um jeito, se nao eh de outro
    if ($gitState -ne "" -and $gitBranch -ne "") {
      $promptText += " ($gitBranch|$gitState)"
    } elseif ($gitRemote -ne "" -and $gitBranch -ne "") {
      $promptText += " ($gitRemote/$gitBranch)"
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

    if ($gitState -eq "") {
      Write-HostColor -Text "$gitRemote"                 -HexColor "#D10B0E"
      Write-HostColor -Text "/"                          -HexColor "#FFFFFF"
      Write-HostColor -Text "$gitBranch"                 -HexColor "#3A96DD"
    } else {
      Write-HostColor -Text "$gitBranch"                 -HexColor "#3A96DD"
      Write-HostColor -Text "|"                          -HexColor "#FFFFFF"
      Write-HostColor -Text "$gitState"                  -HexColor "#D10B0E"
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

# retorna branch atual
function Get-Branch {
  $branch = (git branch --show-current)

  if ($branch -eq $null) {
    if ($isREBASING) {
      $branch = (Get-Content .git\rebase-merge\head-name)
      $branch = $branch.split("/")[-1]
    } elseif ($isMERGING) {
      $branch = (Get-Content .git\MERGE_HEAD)
      $branch = $branch.split("/")[-1]
    } elseif ($isCHERRY) {
      $branch = (Get-Content .git\CHERRY_PICK_HEAD)
      $branch = $branch.split("/")[-1]
    } elseif ($isREVERTING) {
      $branch = (Get-Content .git\REVERT_HEAD)
      $branch = $branch.split("/")[-1]
    } else {
      $branch = ""
    }
  }

  return $branch
}

# estados especiais do git
function Get-State {
  $state = ""

  if ($isREBASING) {
    $state = "REBASING"
  } elseif ($isMERGING) {
    $state = "MERGING"
  } elseif ($isCHERRY) {
    $state = "CHERRY-PICKING"
  } elseif ($isREVERTING) {
    $state = "REVERTING"
  }

  return $state
}
