# SETUP EN MÁQUINA NUEVA — ForestaleNews

Este archivo es para una instancia de Claude Code corriendo en OTRA computadora
(idealmente un escritorio que quede siempre prendido), con la misma cuenta de
Claude que Lautaro ya usa. El objetivo: dejar el ciclo diario de ForestaleNews
corriendo ahí de forma autónoma, sin depender de la notebook original.

Repo de referencia (ya tiene todo el código, prompts y aprendizajes de la
primera implementación): https://github.com/lautaforestale-code/forestalenews

Si estás leyendo esto como una instancia nueva de Claude Code: seguí los pasos
en orden. Cada uno indica si lo podés hacer vos solo o si necesitás que Lautaro
haga algo primero (login, confirmar algo visualmente, etc.). No asumas nada
sobre el estado de la máquina — verificá cada cosa antes de seguir.

═══════════════════════════════════════════════════════════════
PASO 1 — HERRAMIENTAS BASE
═══════════════════════════════════════════════════════════════
Verificá si ya están instalados: `git --version`, `gh --version`,
`node --version`, `claude --version`.

Si falta `git` o `gh`: instalalos con winget (funcionó bien en la máquina
original):
  winget install --id Git.Git -e --source winget --accept-package-agreements --accept-source-agreements --silent
  winget install --id GitHub.cli -e --source winget --accept-package-agreements --accept-source-agreements --silent

Nota: después de instalar, el PATH de la sesión actual de PowerShell NO se
actualiza solo. Antes de usar `git`/`gh` en el mismo proceso, corré:
  $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

Si falta `node`: instalalo también con winget (`winget install OpenJS.NodeJS`)
o pedile a Lautaro que lo instale.

Si falta `claude` (Claude Code CLI): Lautaro tiene que loguearse él mismo con
su cuenta — no es algo que puedas automatizar vos. Guialo a instalar Claude
Code normalmente (claude.ai/code) y hacer login con la misma cuenta que usa en
la otra máquina.

═══════════════════════════════════════════════════════════════
PASO 2 — CLONAR EL REPO
═══════════════════════════════════════════════════════════════
git clone https://github.com/lautaforestale-code/forestalenews.git C:\ForestaleNewsSite

(Si el path C:\ForestaleNewsSite no te sirve, cualquier carpeta está bien —
pero usá SIEMPRE la misma ruta absoluta consistentemente en los pasos
siguientes, sobre todo en el registro de la tarea programada.)

═══════════════════════════════════════════════════════════════
PASO 3 — AUTENTICAR GITHUB CLI
═══════════════════════════════════════════════════════════════
gh auth login --hostname github.com --git-protocol https --web

Esto va a imprimir un código de un solo uso y una URL
(https://github.com/login/device). Pasáselo a Lautaro para que lo confirme en
su navegador — la cuenta de GitHub ya existe (lautaforestale-code), no hay que
crear una nueva.

Después, CRÍTICO (si no se hace, el push falla en silencio en cada corrida
automática):
  gh auth setup-git

Y configurá identidad de git si hace falta:
  git config --global user.email "lautaforestale@gmail.com"
  git config --global user.name "Lautaro Forestale"

═══════════════════════════════════════════════════════════════
PASO 4 — MCP DE PLAYWRIGHT, CON PERFIL PERSISTENTE EXPLÍCITO
═══════════════════════════════════════════════════════════════
Instalá el paquete si no está global:
  npm install -g @playwright/mcp

Buscá la ruta real del cli.js instalado (algo como
C:\Users\<usuario>\AppData\Roaming\npm\node_modules\@playwright\mcp\cli.js —
ajustalo al usuario real de esta máquina) y la ruta de node.exe
(`(Get-Command node).Source`).

Registrá el MCP con un perfil persistente EXPLÍCITO — esto es el error más
caro que cometimos en la primera implementación: sin `--user-data-dir`
explícito, cada sesión puede terminar en un perfil distinto o chocar con
otra sesión concurrente. Elegí una carpeta fija, por ejemplo
C:\ForestaleNewsSite\browser-profile, y NO la subas nunca al repo (tiene
cookies de sesión reales — verificá que esté en .gitignore).

  claude mcp add playwright -s user -- "<ruta a node.exe>" "<ruta a cli.js>" --user-data-dir "C:\ForestaleNewsSite\browser-profile" --browser chrome

IMPORTANTE: esto requiere reiniciar la sesión de Claude Code (o abrir una
nueva) para que el MCP quede disponible con esta config. Si `claude mcp list`
no muestra "playwright" como Connected después de registrarlo, avisale a
Lautaro que hay que reabrir la sesión.

═══════════════════════════════════════════════════════════════
PASO 5 — LOGIN MANUAL EN LAS TRES CUENTAS (Lautaro tiene que hacerlo)
═══════════════════════════════════════════════════════════════
El perfil nuevo arranca sin ninguna sesión guardada. Abrí una ventana de
Chrome real (NO controlada por Playwright) apuntando a esa misma carpeta de
perfil, para que Lautaro pueda loguearse a mano sin el riesgo de que Google
bloquee el login por detectar automatización:

  Start-Process "C:\Program Files\Google\Chrome\Application\chrome.exe" -ArgumentList "--user-data-dir=C:\ForestaleNewsSite\browser-profile", "--new-window", "https://gemini.google.com/app"

Repetí para https://chat.qwen.ai y https://chat.deepseek.com (podés abrirlas
como pestañas nuevas de la misma ventana, sin repetir --new-window).

Pedile a Lautaro que se loguee con lautaforestale@gmail.com en las tres.
DeepSeek puede pedir captcha — eso lo tiene que resolver él, no vos.

Ojo con Gemini específicamente: si el perfil de Google tiene multi-cuenta
guardada (Capilux, etc.), verificá con el MCP después de loguearse que la
cuenta ACTIVA en Gemini sea "Lautaro Forestale" — si no, hay que cambiarla
manualmente haciendo clic en el selector de cuenta.

Una vez logueadas las tres, cerrá esa ventana de Chrome manual (ya cumplió su
función) y verificá con el MCP (navegando a los tres sitios) que las sesiones
persistieron en el perfil.

═══════════════════════════════════════════════════════════════
PASO 6 — VERIFICAR LOS CHATS FIJOS DE QWEN Y DEEPSEEK
═══════════════════════════════════════════════════════════════
El pipeline depende de dos chats específicos y persistentes:
- Qwen: "FORESTALENEWS" — tiene el prompt maestro v9.3-qwen cargado en su
  historial. URL de referencia (de la otra cuenta/máquina):
  https://chat.qwen.ai/c/4ae2532b-4c8a-459d-8b2f-d5d0efc404d6
  Esa URL específica pertenece a la sesión de la OTRA máquina — en esta cuenta
  nueva (si es la misma cuenta de Qwen, la URL debería funcionar igual; si es
  una cuenta distinta, no va a existir). Verificá primero si esa URL carga el
  chat correcto. Si no, buscá en el historial de Qwen un chat pinneado
  llamado "FORESTALENEWS" y anotá su URL real para actualizar
  daily_cycle_prompt.md (Paso 2).
- DeepSeek: "FORESTALENEWSHTML" — mismo criterio. URL de referencia:
  https://chat.deepseek.com/a/chat/s/4bcabb75-24b0-48d3-9d50-1dd236d3ffbe

Si no encontrás alguno de los dos chats con ese nombre exacto, PARÁ y
avisale a Lautaro — no crees uno nuevo por tu cuenta, el prompt maestro ya
tiene que estar cargado en el historial para que Fase 1B/1C funcionen bien.

Actualizá las URLs en daily_cycle_prompt.md (Pasos 2 y 5) si cambiaron.

═══════════════════════════════════════════════════════════════
PASO 7 — PROBAR EL CICLO COMPLETO UNA VEZ, A MANO
═══════════════════════════════════════════════════════════════
Antes de programar nada, corré el ciclo una vez de forma manual para validar
que todo el pipeline funciona en esta máquina:

  cd C:\ForestaleNewsSite
  Get-Content -Raw -Encoding UTF8 .\daily_cycle_prompt.md | & claude -p --dangerously-skip-permissions --permission-mode bypassPermissions

Esto tarda entre 25 y 50 minutos. Mientras corre, NO uses vos (la instancia
que está leyendo este archivo) ninguna herramienta de navegador — vas a
chocar con el mismo perfil y vas a arruinar la prueba.

Si el ciclo del día de hoy ya existe (poco probable en una máquina nueva),
va a hacer SKIP — es el comportamiento correcto, no lo fuerces.

═══════════════════════════════════════════════════════════════
PASO 8 — TAREA PROGRAMADA DE WINDOWS
═══════════════════════════════════════════════════════════════
Ajustá las rutas si tu carpeta del repo no es C:\ForestaleNewsSite, y creá
run_daily_cycle.ps1 (copiá el de la máquina original, ajustando el path
$root al de esta máquina), después:

  $Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument '-NoProfile -ExecutionPolicy Bypass -File "C:\ForestaleNewsSite\run_daily_cycle.ps1"'
  $Trigger = New-ScheduledTaskTrigger -Daily -At 10:00
  $Settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -DontStopOnIdleEnd -ExecutionTimeLimit (New-TimeSpan -Hours 2)
  $Principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Limited
  Register-ScheduledTask -TaskName "ForestaleNews Ciclo Diario" -Action $Action -Trigger $Trigger -Settings $Settings -Principal $Principal -Force

Como esta máquina queda siempre prendida, no hace falta configurar
suspensión ni temporizadores de reactivación — esa es justamente la ventaja
de correrlo acá.

═══════════════════════════════════════════════════════════════
PASO 9 — DAR DE BAJA LA TAREA EN LA MÁQUINA VIEJA
═══════════════════════════════════════════════════════════════
Para no publicar el mismo día dos veces desde dos máquinas distintas,
avisale a Lautaro que hay que desactivar (no hace falta borrar) la tarea
programada "ForestaleNews Ciclo Diario" en la notebook original:

  Disable-ScheduledTask -TaskName "ForestaleNews Ciclo Diario"

═══════════════════════════════════════════════════════════════
RESUMEN DE LO QUE YA SABEMOS QUE FALLA SI NO SE HACE BIEN
═══════════════════════════════════════════════════════════════
- Sin --user-data-dir explícito en el MCP → sesiones se pierden o chocan.
- Sin `gh auth setup-git` → el push falla en silencio, la publicación no sale.
- Loguear las cuentas DENTRO de un navegador controlado por Playwright/MCP →
  Google lo bloquea ("Es posible que no sean seguros este navegador"). El
  login siempre tiene que pasar en un Chrome NO controlado (Start-Process
  normal), apuntando al mismo --user-data-dir.
- El visor de código de DeepSeek trunca respuestas largas — hay que usar el
  botón "Continuar" cuando aparece, y extraer con el botón "Copiar" +
  portapapeles, nunca confiar en el innerText del bloque de código solo
  (está virtualizado).
- Dos procesos usando el mismo --user-data-dir al mismo tiempo chocan — nunca
  correr una prueba manual mientras la tarea programada también podría estar
  corriendo.
