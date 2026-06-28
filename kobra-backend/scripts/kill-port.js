// Libera el puerto del backend (por defecto 3000, o $PORT) antes de
// arrancar, matando cualquier proceso que ya lo tenga ocupado. Evita el
// típico "Error: listen EADDRINUSE" cuando queda una instancia anterior
// corriendo (por ejemplo, una sesión de terminal olvidada).
const { execSync } = require('child_process');

const PORT = process.env.PORT || 3000;

function matarEnWindows() {
  let salida;
  try {
    salida = execSync(`netstat -ano -p tcp`, { encoding: 'utf8' });
  } catch {
    return;
  }

  const pids = new Set();
  for (const linea of salida.split('\n')) {
    const partes = linea.trim().split(/\s+/);
    if (partes.length < 5) continue;
    const [, direccionLocal, , estado, pid] = partes;
    if (!direccionLocal?.endsWith(`:${PORT}`)) continue;
    if (estado !== 'LISTENING') continue;
    if (pid && pid !== '0') pids.add(pid);
  }

  for (const pid of pids) {
    try {
      execSync(`taskkill /F /PID ${pid}`, { stdio: 'ignore' });
      console.log(`[kill-port] Puerto ${PORT} liberado (PID ${pid}).`);
    } catch {
      // El proceso ya no existe o no se pudo matar: seguimos igual.
    }
  }
}

function matarEnPosix() {
  let pids;
  try {
    pids = execSync(`lsof -ti tcp:${PORT}`, { encoding: 'utf8' }).trim();
  } catch {
    return;
  }
  if (!pids) return;

  for (const pid of pids.split('\n').filter(Boolean)) {
    try {
      execSync(`kill -9 ${pid}`, { stdio: 'ignore' });
      console.log(`[kill-port] Puerto ${PORT} liberado (PID ${pid}).`);
    } catch {
      // Ya no existe: seguimos igual.
    }
  }
}

if (process.platform === 'win32') {
  matarEnWindows();
} else {
  matarEnPosix();
}
