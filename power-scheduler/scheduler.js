// =============================================================
//  pterodactyl-scripts — power-scheduler/scheduler.js
//  Auto start/stop Pterodactyl servers based on a schedule
//
//  Usage:
//    node scheduler.js          - run scheduler (stays running)
//    node scheduler.js --list   - list all schedules
//    node scheduler.js --test   - test API connection
// =============================================================

const https = require("https");
const http = require("http");
const config = require("./config");

// ── COLORS ────────────────────────────────────────────────────
const C = {
  red:    "\x1b[31m",
  green:  "\x1b[32m",
  yellow: "\x1b[33m",
  cyan:   "\x1b[36m",
  white:  "\x1b[1;37m",
  dim:    "\x1b[2m",
  reset:  "\x1b[0m"
};

// ── HELPERS ───────────────────────────────────────────────────
const log = (msg) => {
  const time = new Date().toISOString().replace("T", " ").slice(0, 19);
  console.log(`[${time}] ${msg}`);
};

const padEnd = (str, len) => String(str).padEnd(len);

// ── API ───────────────────────────────────────────────────────
function apiRequest(endpoint, method = "GET", body = null, client = false) {
  return new Promise((resolve, reject) => {
    const base = client ? "client" : "application";
    const url = new URL(`${config.PANEL_URL}/api/${base}/${endpoint}`);
    const lib = url.protocol === "https:" ? https : http;

    const options = {
      hostname: url.hostname,
      port: url.port || (url.protocol === "https:" ? 443 : 80),
      path: url.pathname + url.search,
      method,
      headers: {
        "Authorization": `Bearer ${config.API_KEY}`,
        "Accept": "application/json",
        "Content-Type": "application/json"
      }
    };

    const req = lib.request(options, (res) => {
      let data = "";
      res.on("data", chunk => data += chunk);
      res.on("end", () => {
        try {
          resolve(data ? JSON.parse(data) : { status: res.statusCode });
        } catch {
          resolve({ status: res.statusCode });
        }
      });
    });

    req.on("error", reject);
    req.setTimeout(10000, () => { req.destroy(); reject(new Error("Timeout")); });

    if (body) req.write(JSON.stringify(body));
    req.end();
  });
}

async function getServers() {
  const data = await apiRequest("servers?per_page=100");
  return data?.data || [];
}

async function getServerResources(identifier) {
  const data = await apiRequest(`servers/${identifier}/resources`, "GET", null, true);
  return data?.attributes || null;
}

async function sendPowerAction(identifier, signal) {
  return await apiRequest(
    `servers/${identifier}/power`,
    "POST",
    { signal },
    true
  );
}

// ── NOTIFY DISCORD ────────────────────────────────────────────
function notifyDiscord(message) {
  if (!config.NOTIFY_DISCORD || !config.DISCORD_WEBHOOK_URL) return;

  const payload = JSON.stringify({ content: message });
  const url = new URL(config.DISCORD_WEBHOOK_URL);
  const lib = url.protocol === "https:" ? https : http;

  const req = lib.request({
    hostname: url.hostname,
    path: url.pathname,
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Content-Length": Buffer.byteLength(payload)
    }
  });

  req.on("error", () => {});
  req.write(payload);
  req.end();
}

// ── SCHEDULE LOGIC ────────────────────────────────────────────
function parseTime(timeStr) {
  const [h, m] = timeStr.split(":").map(Number);
  return { hour: h, minute: m };
}

function matchesSchedule(schedule) {
  const now = new Date();
  const { hour, minute } = parseTime(schedule.time);
  const days = schedule.days; // e.g. [1,2,3,4,5] = Mon-Fri, [] = every day

  const matchTime = now.getHours() === hour && now.getMinutes() === minute;
  const matchDay = days.length === 0 || days.includes(now.getDay());

  return matchTime && matchDay;
}

async function executeSchedule(schedule, servers) {
  const target = servers.find(s => {
    const attr = s.attributes;
    return attr.identifier === schedule.identifier ||
           attr.name.toLowerCase() === schedule.name?.toLowerCase();
  });

  if (!target) {
    log(`${C.yellow}[WARN] Server not found: ${schedule.identifier || schedule.name}${C.reset}`);
    return;
  }

  const attr = target.attributes;
  const name = attr.name;
  const identifier = attr.identifier;

  // Check current state
  const resources = await getServerResources(identifier);
  const currentState = resources?.current_state || "unknown";

  // Skip if already in desired state
  if (schedule.action === "start" && currentState === "running") {
    log(`${C.dim}[SKIP] ${name} already running${C.reset}`);
    return;
  }
  if (schedule.action === "stop" && currentState === "offline") {
    log(`${C.dim}[SKIP] ${name} already offline${C.reset}`);
    return;
  }

  const signal = schedule.action === "start" ? "start"
    : schedule.action === "stop" ? "stop"
    : schedule.action === "restart" ? "restart"
    : "kill";

  log(`${C.cyan}[ACTION] ${schedule.action.toUpperCase()} → ${name} (${identifier})${C.reset}`);

  await sendPowerAction(identifier, signal);

  log(`${C.green}[OK] ${signal} signal sent to: ${name}${C.reset}`);
  notifyDiscord(
    `[power-scheduler] **${name}** — \`${signal}\` triggered at ${new Date().toLocaleTimeString()}`
  );
}

// ── LIST SCHEDULES ────────────────────────────────────────────
function listSchedules() {
  console.log(`\n${C.cyan}${"═".repeat(60)}${C.reset}`);
  console.log(`${C.white}  Power Scheduler — Schedule List${C.reset}`);
  console.log(`${C.cyan}${"═".repeat(60)}${C.reset}\n`);

  if (!config.SCHEDULES || config.SCHEDULES.length === 0) {
    console.log(`  ${C.yellow}No schedules configured.${C.reset}\n`);
    return;
  }

  const dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];

  config.SCHEDULES.forEach((s, i) => {
    const days = s.days.length === 0
      ? "Every day"
      : s.days.map(d => dayNames[d]).join(", ");
    const action = s.action === "start" ? `${C.green}start${C.reset}`
      : s.action === "stop" ? `${C.red}stop${C.reset}`
      : `${C.yellow}${s.action}${C.reset}`;

    console.log(`  ${C.dim}[${i + 1}]${C.reset} ${padEnd(s.identifier || s.name, 36)} ${action}  ${s.time}  ${days}`);
  });

  console.log(`\n  Total: ${config.SCHEDULES.length} schedules\n`);
}

// ── TEST CONNECTION ───────────────────────────────────────────
async function testConnection() {
  log("Testing API connection...");
  try {
    const servers = await getServers();
    log(`${C.green}[OK] Connected! Found ${servers.length} servers.${C.reset}`);
    servers.slice(0, 3).forEach(s => {
      log(`  ${C.dim}→${C.reset} ${s.attributes.name} (${s.attributes.identifier})`);
    });
  } catch (e) {
    log(`${C.red}[ERR] Connection failed: ${e.message}${C.reset}`);
  }
}

// ── MAIN LOOP ─────────────────────────────────────────────────
async function tick() {
  if (!config.SCHEDULES || config.SCHEDULES.length === 0) return;

  let servers;
  try {
    servers = await getServers();
  } catch (e) {
    log(`${C.red}[ERR] Failed to fetch servers: ${e.message}${C.reset}`);
    return;
  }

  for (const schedule of config.SCHEDULES) {
    if (matchesSchedule(schedule)) {
      await executeSchedule(schedule, servers);
    }
  }
}

async function main() {
  const arg = process.argv[2];

  if (arg === "--list") {
    listSchedules();
    return;
  }

  if (arg === "--test") {
    await testConnection();
    return;
  }

  console.log(`\n${C.cyan}${"═".repeat(60)}${C.reset}`);
  console.log(`${C.white}  Pterodactyl Power Scheduler${C.reset}`);
  console.log(`${C.cyan}${"═".repeat(60)}${C.reset}\n`);

  log(`${C.green}Scheduler started. Checking every minute...${C.reset}`);
  log(`Loaded ${config.SCHEDULES?.length || 0} schedules`);

  // Run immediately on start
  await tick();

  // Then run every minute
  setInterval(async () => {
    await tick();
  }, 60 * 1000);
}

main().catch(e => {
  log(`${C.red}[FATAL] ${e.message}${C.reset}`);
  process.exit(1);
});
  
