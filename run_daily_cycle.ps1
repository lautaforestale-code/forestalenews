# Wrapper que dispara el ciclo diario de ForestaleNews via Claude Code headless.
# Pensado para ser invocado por el Programador de tareas de Windows.

$ErrorActionPreference = "Continue"
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

$root = "C:\ForestaleNewsSite"
$promptPath = Join-Path $root "daily_cycle_prompt.md"
$logPath = Join-Path $root ("last_run_" + (Get-Date -Format "yyyy-MM-dd_HHmm") + ".log")

$prompt = Get-Content -Raw -Encoding UTF8 $promptPath

Set-Location $root
$prompt | & claude -p --dangerously-skip-permissions --permission-mode bypassPermissions *>&1 |
    Out-String -Stream | Tee-Object -FilePath $logPath -Append | Out-Null
Get-Content $logPath -Raw | Out-File -FilePath $logPath -Encoding utf8
