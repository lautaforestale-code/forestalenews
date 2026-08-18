# CICLO DIARIO AUTOMÁTICO — FORESTALENEWS (ejecución sin supervisión)

Esta instancia corre sola, sin nadie mirando. No hay usuario para responder preguntas:
tomá siempre la decisión más razonable y seguí adelante. Nunca uses AskUserQuestion.
Si algo se rompe de verdad, registralo en el log (ver PASO 8) y terminá — no dejes el
proceso colgado esperando una respuesta que nunca va a llegar.

Fecha de hoy: usá la fecha real del sistema en el momento de la ejecución, formato
"DD de MMMM de AAAA" para los prompts, y "AAAA-MM-DD" para nombres de archivo.

Edición del día (dos corridas diarias): este ciclo corre dos veces por día, mañana
y noche. Determiná cuál corresponde según la hora real del sistema al arrancar:
- Antes de las 15:00 → edición "AM".
- Desde las 15:00 en adelante → edición "PM".
El archivo de esta corrida es "[AAAA-MM-DD]-[AM|PM].html" (ver PASO 6). ANTES de
arrancar el PASO 1, fijate si ese archivo puntual (ediciones/[AAAA-MM-DD]-[AM|PM].html)
ya existe y está commiteado. Si ya existe, no hay nada que hacer: registralo en el
log (PASO 8) como SKIP y terminá sin tocar Gemini/Qwen/DeepSeek. Que exista la
edición AM del día no es motivo para saltear la PM (son archivos distintos), y
viceversa — el chequeo de "ya existe" es siempre contra el archivo AM o PM
específico de esta corrida, nunca contra el otro.

Archivos de referencia:
- Prompt maestro completo: C:\Users\Super PC\Downloads\FORESTALE_NEWS_PROMPT_INTEGRADO_v9.txt
- Prompt para adjuntar a Gemini: C:\Users\Super PC\Downloads\FORESTALE_NEWS_GEMINI_PROMPT_v4.txt
- Repo del sitio: C:\ForestaleNewsSite
- Log de corridas: C:\ForestaleNewsSite\run_log.txt

Herramientas: usá los tools `mcp__playwright__*` (MCP "playwright" ya configurado
globalmente). Si no aparecen en tu lista de tools, buscalos con ToolSearch
("select:mcp__playwright__browser_navigate" etc.) antes de arrancar.

═══════════════════════════════════════════════════════════════
PASO 0 — VERIFICACIÓN DE CUENTA
═══════════════════════════════════════════════════════════════
El perfil de Chrome que controla Playwright MCP ya tiene guardadas las sesiones de
Google (multi-cuenta: Lautaro Forestale, Capilux, Capilux Staff), Qwen y DeepSeek.
NO intentes loguearte de cero en ningún sitio — si un login falla o pide credenciales
nuevas, es una señal de que algo se rompió; registralo en el log y terminá ahí
(ver PASO 8), no improvises credenciales.

Antes de tocar Gemini: navegá a gemini.google.com/app y confirmá en el snapshot que
la cuenta activa es "Lautaro Forestale (lautaforestale@gmail.com)" (aparece en el
link de la barra lateral). Si aparece otra cuenta (ej. Capilux), hacé clic en ese
link de cuenta, esperá el selector de cuentas de Google, y elegí el link
"Lautaro Forestale lautaforestale@gmail.com".

IMPORTANTE — chequeo de sesión sin falsos negativos: justo después de navegar a un
chat (Qwen, DeepSeek, o el propio Gemini), la página puede mostrar por un instante
un estado transitorio de "sin cuenta" / placeholders de carga mientras termina de
validar la sesión guardada — eso NO es un logout real. Antes de concluir que una
sesión está deslogueada: esperá con browser_wait_for (~3-5s), sacá un snapshot o
screenshot recién ahí, y si todavía se ve deslogueada hacé un reload y esperá otros
3-5s más antes de mirar de nuevo. Recién si DESPUÉS de esa espera sigue mostrando
botones de "Iniciar sesión"/"Crear cuenta" en vez de la cuenta guardada, es un
logout real y corresponde registrar el ERROR y terminar (ver PASO 8) — no antes.

═══════════════════════════════════════════════════════════════
PASO 1 — GEMINI (Fase 1A externa / colección)
═══════════════════════════════════════════════════════════════
1. En la pestaña de Gemini ya logueada como Lautaro, asegurate de estar en un chat
   nuevo (si no lo estás, navegá de nuevo a gemini.google.com/app).
2. Click en el botón role=button name="Cargas y herramientas" (ícono +).
3. En el menú que aparece, click en role=menuitemcheckbox name="Deep Research".
4. Click en el botón role=button name="Cargar archivo" (o "Archivos").
5. Cuando aparezca el file chooser (Modal state), usá
   mcp__playwright__browser_file_upload con path:
   C:\Users\Super PC\Downloads\FORESTALE_NEWS_GEMINI_PROMPT_v4.txt
6. Escribí en el textbox "Ingresa una instrucción para Gemini" exactamente:
   ejecutá este prompt con el informe del día [FECHA DE HOY]
   y enviá (submit: true).
6.5. IMPORTANTE — Gemini Deep Research no arranca solo: después de enviar el
   mensaje, primero te muestra un PLAN de investigación propuesto (una lista de
   pasos/temas a investigar) y se detiene ahí esperando confirmación. Tenés que
   buscar y clickear el botón que arranca la investigación de verdad (suele decir
   algo como "Empezar investigación" / "Start research" / "Iniciar investigación",
   normalmente al final del plan propuesto). Si después de enviar el mensaje ves
   ese plan pero el botón "Detener respuesta"/"stop" no aparece (señal de que no
   está corriendo nada activamente), es casi seguro que falta este click — buscalo
   con un snapshot antes de asumir que ya arrancó. No sigas al paso 7 sin haber
   confirmado que la investigación está corriendo de verdad.
7. Esperá a que termine. Deep Research tarda varios minutos (10-15 típico).
   Poleá cada 60-90s con browser_wait_for + un chequeo liviano (browser_evaluate
   buscando si el botón "Detener respuesta" / "stop" sigue presente) en vez de
   pedir snapshots completos todo el tiempo — los snapshots de esta página son
   enormes y se truncan.
8. Cuando termine, extraé el texto del informe con browser_evaluate, NO con
   browser_snapshot completo (se trunca / gasta contexto). Patrón que funciona:

   () => {
     const h1s = Array.from(document.querySelectorAll('h1'));
     const target = h1s.find(h => h.textContent.includes('Informe'));
     let node = target, best = target;
     for (let i = 0; i < 8 && node.parentElement; i++) {
       node = node.parentElement;
       // el nivel correcto es el que NO incluye después el texto de "pensamientos"
       // (frases tipo "Aquí está! Lo estoy uniendo todo"). Probá niveles 3-5 primero.
       best = node;
     }
     return best.innerText;
   }

   Verificá con .length y mirando el final del texto que NO haya quedado pegado el
   log de "pensamientos" del research (frases como "Aquí está! Lo estoy uniendo
   todo..."). Si el texto es muy largo, usá el parámetro `filename` de
   browser_evaluate para guardarlo a un archivo en vez de devolverlo inline, y
   después decodificalo (el archivo queda como string JSON-escapado — parseá con
   JSON.parse antes de usarlo, tal como se hizo en el ciclo del 17/8/2026).

═══════════════════════════════════════════════════════════════
PASO 2 — QWEN, FASE 1A (en paralelo con el Paso 1, o después, tu criterio)
═══════════════════════════════════════════════════════════════
1. Navegá a: https://chat.qwen.ai/c/4ae2532b-4c8a-459d-8b2f-d5d0efc404d6
   (chat fijo "FORESTALENEWS" — ya tiene el prompt maestro v9.3-qwen cargado en su
   historial). Si esa URL ya no existe o tira error, DETENÉTE y registralo en el
   log — no crees un chat nuevo por tu cuenta.
2. Escribí en el textarea (selector: textarea.message-input-textarea) exactamente:
   ejecutá fase 1a del [FECHA DE HOY]
   y enviá (submit: true).
3. Esperá a que termine (podés chequear con browser_evaluate buscando si el botón
   "Stop" sigue presente vs. volvió a "Send").

═══════════════════════════════════════════════════════════════
PASO 3 — QWEN, FASE 1B
═══════════════════════════════════════════════════════════════
1. En la misma pestaña/chat de Qwen, escribí:
   te mando el output de gemini, ejecutá fase 1b, verificá toda la información y cruzá datos
   seguido (en el mismo mensaje, con un salto de línea) del texto completo del
   informe de Gemini extraído en el Paso 1. No resumas ni recortes ese texto.
2. Enviá y esperá a que termine (puede tardar varios minutos, la verificación
   cruzada es pesada). Confirmá que el cierre menciona "FIN DE FASE 1B" y que dice
   explícitamente cuántos ítems quedaron Tier 3 y por qué (no debe haber ítems sin
   estado asignado).

═══════════════════════════════════════════════════════════════
PASO 4 — QWEN, FASE 1C
═══════════════════════════════════════════════════════════════
1. Escribí: desarrollá informe
2. Enviá y esperá.
3. Extraé SOLO el cuerpo del informe (desde el título "FASE 1C — INFORME
   FORESTALENEWS — ..." hasta justo antes de la línea "FIN DE FASE 1C"). Usá
   browser_evaluate sobre el contenedor del último mensaje
   ([id^="chat-response-message-"]), no browser_snapshot completo.

═══════════════════════════════════════════════════════════════
PASO 5 — DEEPSEEK (HTML)
═══════════════════════════════════════════════════════════════
1. Navegá a: https://chat.deepseek.com/a/chat/s/4bcabb75-24b0-48d3-9d50-1dd236d3ffbe
   (chat fijo "FORESTALENEWSHTML"). Si no existe, DETENÉTE y registralo en el log.
2. Escribí en el textarea (selector: textarea[placeholder="Mensaje a DeepSeek"]):
   desarrollá el html de este informe del día sin borrar ni una coma
   seguido del informe completo extraído en el Paso 4. Enviá.
3. Esperá a que termine de generar.
4. IMPORTANTE — el visor de código de DeepSeek está virtualizado (innerText no
   trae todo el archivo) y las respuestas largas se cortan a mitad de camino.
   Protocolo de extracción robusto:
   a. Buscá todos los elementos con texto exacto "Copiar" asociados a bloques de
      código (puede haber más de uno si hubo cortes).
   b. Si aparece un botón "Continuar" al pie del último mensaje, hacé click y
      esperá de nuevo — repetí hasta que "Continuar" ya no aparezca.
   c. Una vez que terminó de verdad (sin botón "Continuar", sin botón "Stop"),
      hacé click en cada botón "Copiar" en orden (uno por cada bloque de código
      que se haya generado, típicamente 1 o 2), y después de cada click leé el
      portapapeles con:
      async () => await navigator.clipboard.readText()
      guardando cada resultado con el parámetro `filename` (quedan como JSON
      string escapado).
   d. Concatená los chunks EN ORDEN (chunk1 + chunk2 + ...) después de
      JSON.parse-earlos. Verificá que el resultado empiece con "<!DOCTYPE html>"
      y termine con "</html>". Si no calza, hay un problema — registralo en el
      log y no publiques nada ese día.

═══════════════════════════════════════════════════════════════
PASO 6 — PUBLICAR
═══════════════════════════════════════════════════════════════
1. Guardá el HTML final decodificado en:
   C:\ForestaleNewsSite\ediciones\[AAAA-MM-DD]-[AM|PM].html
2. Regenerá C:\ForestaleNewsSite\index.html:
   - meta refresh y el link "entrar ahora" deben apuntar a la edición que ACABÁS
     de publicar en esta corrida (la más reciente en el tiempo: la PM de un día
     es más nueva que la AM del mismo día, y ambas son más nuevas que cualquier
     edición de un día anterior).
   - la lista de "Archivo" debe tener un <li> por cada archivo en ediciones/,
     ordenados del más nuevo al más viejo (por fecha, y dentro del mismo día PM
     antes que AM), con fecha en español legible más "Edición mañana" o
     "Edición noche" según corresponda (ej. "18 de agosto de 2026 — Edición
     noche").
3. Corré, en C:\ForestaleNewsSite:
   git add -A
   git commit -m "Edición [AM|PM] del [AAAA-MM-DD]"
   git push
   (el remoto y la rama ya deberían estar configurados de una corrida anterior;
   si `git push` falla porque no hay remoto configurado, registralo en el log —
   probablemente falta que Lautaro complete el setup inicial del repo en GitHub).

═══════════════════════════════════════════════════════════════
PASO 7 — CONFIRMACIÓN FINAL
═══════════════════════════════════════════════════════════════
Verificá que el push haya funcionado (git push sin error) y que
ediciones/[AAAA-MM-DD]-[AM|PM].html exista con contenido razonable (>10.000
caracteres, empieza con <!DOCTYPE html>, termina con </html>).

═══════════════════════════════════════════════════════════════
PASO 8 — LOG (siempre, pase lo que pase)
═══════════════════════════════════════════════════════════════
Al terminar (con éxito o con error), agregá una línea a
C:\ForestaleNewsSite\run_log.txt con formato:
[AAAA-MM-DD HH:MM] OK — edición publicada
o
[AAAA-MM-DD HH:MM] ERROR en Paso [N] — [descripción breve y concreta del problema]

No hace falta que el archivo de log tenga ningún formato especial, solo que sea
legible para que Lautaro pueda revisarlo cuando quiera sin tener que leer toda la
transcripción de la corrida.
