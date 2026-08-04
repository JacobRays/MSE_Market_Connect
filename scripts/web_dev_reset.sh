#!/usr/bin/env bash
set -Eeuo pipefail
DST="web/index.html"
[[ -f "$DST" ]] && cp -a "$DST" "${DST}.bak.$(date +%Y%m%d_%H%M%S)"
cat > "$DST" << 'HTML'
<!DOCTYPE html>
<html>
  <head>
    <base href="/" />
    <meta charset="UTF-8">
    <meta content="IE=Edge" http-equiv="X-UA-Compatible">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>MSE Market Connect</title>
    <link rel="manifest" href="manifest.json">
    <link rel="icon" type="image/png" href="favicon.png"/>
    <script>var serviceWorkerVersion = null;</script>
    <script defer src="flutter.js"></script>
  </head>
  <body>
    <script>
      window.addEventListener('load', async function() {
        try {
          const engineInitializer = await _flutter.loader.loadEntrypoint({
            serviceWorker: { serviceWorkerVersion: serviceWorkerVersion },
          });
          const appRunner = await engineInitializer.initializeEngine();
          await appRunner.runApp();
        } catch (e) {
          console.error('Flutter bootstrap failed', e);
          const pre = document.createElement('pre');
          pre.style.cssText = 'color:#fff;background:#000;padding:16px;white-space:pre-wrap;font:12px/1.4 monospace;';
          pre.textContent = (e && (e.stack || e.message)) ? (e.stack || e.message) : String(e);
          document.body.innerHTML = '';
          document.body.appendChild(pre);
        }
      });
    </script>
  </body>
</html>
HTML
echo "Reset web/index.html. Now do this once in your browser:
- DevTools > Application > Service Workers: Unregister
- Application > Storage: Clear site data (all)
- Hard refresh (Ctrl+Shift+R) or open in a private window."
