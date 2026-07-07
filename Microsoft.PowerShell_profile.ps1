#******************************************************************************
# Import all modules and configs for PowerShell
#******************************************************************************

$profileDir = Split-Path -Parent $PROFILE

. "$profileDir\find-line-endings.ps1"
. "$profileDir\open-path.ps1"
. "$profileDir\optimize-rad.ps1"

#******************************************************************************
# ANSI Escape (compatível com PowerShell 5.1 e 7)
#******************************************************************************

$Esc = [char]27

#******************************************************************************
# Escreve texto colorido usando ANSI TrueColor
#******************************************************************************

function Write-HostColor {
    param(
        [Parameter(Mandatory)]
        [string]$Text,

        [Parameter(Mandatory)]
        [string]$HexColor,

        [switch]$NoNewline
    )

    $r = [Convert]::ToInt32($HexColor.Substring(1,2),16)
    $g = [Convert]::ToInt32($HexColor.Substring(3,2),16)
    $b = [Convert]::ToInt32($HexColor.Substring(5,2),16)

    $ansi  = "${Esc}[38;2;${r};${g};${b}m"
    $reset = "${Esc}[0m"

    Write-Host "${ansi}${Text}${reset}" -NoNewline:$NoNewline
}

#******************************************************************************
# Git
#******************************************************************************

function Get-Branch {

    $branch = git branch --show-current 2>$null

    if (![string]::IsNullOrWhiteSpace($branch)) {
        return $branch.Trim()
    }

    if (Test-Path ".git\rebase-merge\head-name") {
        return (Get-Content ".git\rebase-merge\head-name").Split("/")[-1]
    }

    return ""
}

function Get-State {

    if (Test-Path ".git\REBASE_HEAD") {
        return "REBASING"
    }

    if (Test-Path ".git\MERGE_HEAD") {
        return "MERGING"
    }

    if (Test-Path ".git\CHERRY_PICK_HEAD") {
        return "CHERRY-PICKING"
    }

    if (Test-Path ".git\REVERT_HEAD") {
        return "REVERTING"
    }

    return ""
}

#******************************************************************************
# Prompt
#******************************************************************************

function Prompt {

    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()

    $UserName     = $identity.Name.Split("\")[1]
    $ComputerName = $env:COMPUTERNAME
    $CurrentPath  = $pwd.Path
    $DateTime     = Get-Date -Format "HH:mm:ss"

    # $Host.UI.RawUI.WindowTitle = "PowerShell @ $UserName"

    $isGitRepo = $false

    git rev-parse --is-inside-work-tree *> $null
    if ($LASTEXITCODE -eq 0) {
        $isGitRepo = $true
    }

    $gitBranch = ""
    $gitRemote = ""
    $gitState  = ""

    if ($isGitRepo) {
        $gitBranch = Get-Branch
        $gitState  = Get-State

        if ($gitBranch) {
            $gitRemote = git config --get branch.$gitBranch.remote 2>$null
        }
    }

    #----------------------------------------------------------------------
    # Calcula exatamente o texto que será exibido
    #----------------------------------------------------------------------

    $leftText = "$UserName@$ComputerName $CurrentPath "

    if ($isGitRepo) {

        if ($gitState) {
            $leftText += "($gitBranch|$gitState)"
        }
        elseif ($gitRemote -and $gitBranch) {
            $leftText += "($gitRemote/$gitBranch)"
        }
    }

    $consoleWidth = $Host.UI.RawUI.WindowSize.Width

    # -1 evita que o último caractere da hora pule para a linha seguinte
    $padding = [Math]::Max(
        1,
        $consoleWidth - $leftText.Length - $DateTime.Length - 1
    )

    $spaces = " " * $padding

    #----------------------------------------------------------------------
    # Linha superior
    #----------------------------------------------------------------------

    Write-HostColor -Text "`n$UserName@$ComputerName " -HexColor "#13A10E" -NoNewline
    Write-HostColor -Text "$CurrentPath "              -HexColor "#C19C00" -NoNewline

    if ($isGitRepo) {

        Write-HostColor -Text "(" -HexColor "#FFFFFF" -NoNewline

        if ($gitState) {

            Write-HostColor -Text $gitBranch -HexColor "#3A96DD" -NoNewline
            Write-HostColor -Text "|"         -HexColor "#FFFFFF" -NoNewline
            Write-HostColor -Text $gitState  -HexColor "#D10B0E" -NoNewline

        }
        elseif ($gitRemote -and $gitBranch) {

            Write-HostColor -Text $gitRemote -HexColor "#D10B0E" -NoNewline
            Write-HostColor -Text "/"        -HexColor "#FFFFFF" -NoNewline
            Write-HostColor -Text $gitBranch -HexColor "#3A96DD" -NoNewline

        }

        Write-HostColor -Text ")" -HexColor "#FFFFFF" -NoNewline
    }

    Write-HostColor -Text "$spaces$DateTime" -HexColor "#FFFFFF"

    #----------------------------------------------------------------------
    # Linha inferior
    #----------------------------------------------------------------------

    return "> "
}