# Wrapper que dispara el ciclo diario de ForestaleNews via Claude Code headless.
# Pensado para ser invocado por el Programador de tareas de Windows.

$ErrorActionPreference = "Continue"
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

$root = "C:\ForestaleNewsSite"
$promptPath = Join-Path $root "daily_cycle_prompt.md"
$runLogPath = Join-Path $root "run_log.txt"
$stamp = Get-Date -Format "yyyy-MM-dd_HHmm"
$logPath = Join-Path $root ("last_run_" + $stamp + ".log")

function Add-WrapperLine([string]$text) {
    $line = "[" + (Get-Date -Format "yyyy-MM-dd HH:mm:ss") + "] WRAPPER - " + $text
    Add-Content -Path $runLogPath -Value $line -Encoding utf8
}

Set-Location $root

try {
    if (-not (Test-Path $promptPath)) {
        Add-WrapperLine "no se encontro daily_cycle_prompt.md en $promptPath - no se invoco claude."
        exit 1
    }

    $prompt = Get-Content -Raw -Encoding UTF8 $promptPath
    if ([string]::IsNullOrWhiteSpace($prompt)) {
        Add-WrapperLine "daily_cycle_prompt.md existe pero se leyo vacio - no se invoco claude."
        exit 1
    }

    Add-WrapperLine ("arranca (prompt: " + $prompt.Length + " caracteres, log: " + (Split-Path $logPath -Leaf) + ")")

    $prompt | & claude -p --dangerously-skip-permissions --permission-mode bypassPermissions *>&1 |
        Out-String -Stream | Tee-Object -FilePath $logPath -Append | Out-Null
    $claudeExit = $LASTEXITCODE

    if (Test-Path $logPath) {
        Get-Content $logPath -Raw | Out-File -FilePath $logPath -Encoding utf8
    }

    $logSize = (Get-Item $logPath -ErrorAction SilentlyContinue).Length
    Add-WrapperLine ("termino - exit code claude: " + $claudeExit + ", tamano del log: " + $logSize + " bytes")
}
catch {
    Add-WrapperLine ("EXCEPCION en el wrapper - " + $_.Exception.Message)
    throw
}
