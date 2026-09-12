// WO-0000: task tracker fixture for live evaluations
import { createServer } from "node:http";
import { randomUUID } from "node:crypto";

const tasks = new Map();
const PORT = Number(process.env.PORT ?? 3117);

function send(res, status, body) {
  const payload = JSON.stringify(body);
  res.writeHead(status, { "content-type": "application/json", "content-length": Buffer.byteLength(payload) });
  res.end(payload);
}
async function readJson(req) {
  const chunks = [];
  for await (const c of req) chunks.push(c);
  const raw = Buffer.concat(chunks).toString("utf8");
  if (!raw) return {};
  return JSON.parse(raw);
}

export function handle(req, res) {
  const url = new URL(req.url ?? "/", "http://localhost");
  if (url.pathname === "/health") return send(res, 200, { status: "ok" });
  const m = url.pathname.match(/^\/api\/v1\/tasks(?:\/([^/]+))?$/);
  if (!m) return send(res, 404, { error: "not found" });
  const id = m[1];
  if (req.method === "GET" && !id) return send(res, 200, { tasks: [...tasks.values()] });
  if (req.method === "GET" && id) { const t = tasks.get(id); return t ? send(res, 200, t) : send(res, 404, { error: "task not found" }); }
  if (req.method === "POST" && !id) {
    readJson(req).then((body) => {
      const title = typeof body.title === "string" ? body.title.trim() : "";
      if (!title) return send(res, 400, { error: "title is required" });
      const task = { id: randomUUID(), title, done: false, createdAt: new Date().toISOString() };
      tasks.set(task.id, task); send(res, 201, task);
    }).catch(() => send(res, 400, { error: "invalid json" }));
    return;
  }
  if (req.method === "PATCH" && id) {
    const t = tasks.get(id); if (!t) return send(res, 404, { error: "task not found" });
    readJson(req).then((body) => { if (typeof body.done === "boolean") t.done = body.done; send(res, 200, t); }).catch(() => send(res, 400, { error: "invalid json" }));
    return;
  }
  if (req.method === "DELETE" && id) return tasks.delete(id) ? send(res, 204, {}) : send(res, 404, { error: "task not found" });
  return send(res, 405, { error: "method not allowed" });
}

if (process.argv[1]?.endsWith("server.js")) {
  createServer(handle).listen(PORT, () => console.error(`live-fixture listening on ${PORT}`));
}
