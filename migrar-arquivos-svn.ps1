param(
    [Parameter(Mandatory = $true)]
    [string]$DiretorioBase,

    [Parameter(Mandatory = $true)]
    [string]$ListaPastas
)

# Destino fixo (chumbado no código, como você pediu)
$Destino = "C:\Users\B43811\Downloads\arquivos_migrar"

# Valida se o diretório base existe
if (-not (Test-Path -Path $DiretorioBase -PathType Container)) {
    Write-Error "O diretório base não existe: $DiretorioBase"
    exit 1
}

# Garante que o destino exista
if (-not (Test-Path -Path $Destino -PathType Container)) {
    New-Item -ItemType Directory -Path $Destino -Force | Out-Null
}

# Converte a string separada por vírgulas em lista de nomes de pastas
$PastasProcuradas = $ListaPastas.Split(",") | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }

if ($PastasProcuradas.Count -eq 0) {
    Write-Error "Nenhuma pasta foi informada na lista."
    exit 1
}

Write-Host "Diretório base: $DiretorioBase"
Write-Host "Destino: $Destino"
Write-Host "Pastas procuradas:"
$PastasProcuradas | ForEach-Object { Write-Host " - $_" }

Write-Host ""
Write-Host "Iniciando busca..." -ForegroundColor Yellow

# Procura recursivamente por diretórios com os nomes informados
$PastasEncontradas = Get-ChildItem -Path $DiretorioBase -Directory -Recurse -ErrorAction SilentlyContinue |
    Where-Object { $PastasProcuradas -contains $_.Name }

if (-not $PastasEncontradas -or $PastasEncontradas.Count -eq 0) {
    Write-Host "Nenhuma das pastas informadas foi encontrada." -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "Pastas encontradas:" -ForegroundColor Green
$PastasEncontradas | ForEach-Object { Write-Host " - $($_.FullName)" }

Write-Host ""
Write-Host "Movendo pastas..." -ForegroundColor Yellow

foreach ($Pasta in $PastasEncontradas) {
    try {
        $DestinoFinal = Join-Path $Destino $Pasta.Name

        # Se por algum motivo já existir uma pasta com o mesmo nome no destino,
        # acrescenta timestamp para evitar erro.
        if (Test-Path $DestinoFinal) {
            $NovoNome = "{0}_{1}" -f $Pasta.Name, (Get-Date -Format "yyyyMMdd_HHmmss")
            $DestinoFinal = Join-Path $Destino $NovoNome
        }

        Move-Item -Path $Pasta.FullName -Destination $DestinoFinal -Force
        Write-Host "Movida: $($Pasta.FullName)  -->  $DestinoFinal" -ForegroundColor Cyan
    }
    catch {
        Write-Host "Erro ao mover '$($Pasta.FullName)': $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Processo concluído." -ForegroundColor Green