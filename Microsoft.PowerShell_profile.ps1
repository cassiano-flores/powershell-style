function prompt {

    # define o titulo da janela
    $CmdPromptUser = [Security.Principal.WindowsIdentity]::GetCurrent();
    # $host.ui.RawUI.WindowTitle = "PowerShell @ $($CmdPromptUser.Name.split("\")[1])"

    # nome do usuario e computador
    $UserName = $CmdPromptUser.Name.split("\")[1]
    $ComputerName = $env:COMPUTERNAME

    # git branch e remote
    $gitBranch = ''
    $gitRemoteName = ''
    if (Test-Path .git) {
        $gitBranch = (git branch --show-current)  # branch atual
        $gitRemoteName = git config --get branch.$gitBranch.remote  # nome do remoto da branch atual
    }

    # diretorio e data/hora
    $CmdPromptCurrentFolder = $pwd.Path
    $DateTime = Get-Date -Format 'HH:mm:ss'

    # monta a linha
    $promptText = "$UserName@$ComputerName $CmdPromptCurrentFolder"
    if ($gitRemoteName -ne '' -and $gitBranch -ne '') {
        $promptText += " ($gitRemoteName/$gitBranch)"
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
    if ($gitRemoteName -ne '' -and $gitBranch -ne '') {
        Write-HostColor -Text "("                          -HexColor "#FFFFFF"
        Write-HostColor -Text "$gitRemoteName"             -HexColor "#D10B0E"
        Write-HostColor -Text "/"                          -HexColor "#FFFFFF"
        Write-HostColor -Text "$gitBranch"                 -HexColor "#3A96DD"
        Write-HostColor -Text ")"                          -HexColor "#FFFFFF"
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
