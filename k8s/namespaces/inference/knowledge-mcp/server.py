"""MCP server exposing Open WebUI knowledge-base search to coding agents.

Stdlib only, so it runs on a stock python image with no build step. Speaks the
MCP streamable-HTTP transport in stateless mode (POST /mcp, JSON responses) and
also offers plain JSON endpoints for agents without MCP support (pi):

  GET  /collections                 -> knowledge bases visible to the API key
  POST /search {query, collections?, k?}

Retrieval itself is Open WebUI's: hybrid search over qdrant, embeddinggemma-2
embeddings and zerank-2 reranking, all as configured there.
"""

import hmac
import json
import logging
import os
import urllib.error
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

OPENWEBUI_URL = os.environ["OPENWEBUI_URL"].rstrip("/")
OPENWEBUI_API_KEY = os.environ.get("OPENWEBUI_API_KEY", "")
MCP_TOKEN = os.environ["MCP_TOKEN"]
PORT = int(os.environ.get("PORT", "8000"))
TIMEOUT = float(os.environ.get("UPSTREAM_TIMEOUT", "60"))
MAX_BODY = 1 << 20

PROTOCOL_VERSIONS = ("2025-11-25", "2025-06-18", "2025-03-26")
SERVER_INFO = {"name": "knowledge", "version": "1.0.0"}

TOOLS = [
    {
        "name": "list_knowledge",
        "description": "List the knowledge bases (document collections) available to search.",
        "inputSchema": {"type": "object", "properties": {}, "additionalProperties": False},
        "annotations": {"readOnlyHint": True},
    },
    {
        "name": "search_knowledge",
        "description": (
            "Semantic + keyword search over ingested documents, reranked by relevance. "
            "Returns the most relevant passages with their source. Use it for project "
            "docs, notes and reference material rather than for code in the working tree."
        ),
        "inputSchema": {
            "type": "object",
            "properties": {
                "query": {"type": "string", "description": "What to look for, in natural language."},
                "collections": {
                    "type": "array",
                    "items": {"type": "string"},
                    "description": "Knowledge base names or ids to search; omit to search all of them.",
                },
                "k": {"type": "integer", "minimum": 1, "maximum": 50, "default": 8},
            },
            "required": ["query"],
            "additionalProperties": False,
        },
        "annotations": {"readOnlyHint": True},
    },
]

log = logging.getLogger("knowledge-mcp")


class ToolError(Exception):
    pass


def owui(method, path, body=None):
    if not OPENWEBUI_API_KEY:
        raise ToolError("OPENWEBUI_API_KEY is not configured on the knowledge-mcp server")
    req = urllib.request.Request(
        OPENWEBUI_URL + path,
        method=method,
        data=None if body is None else json.dumps(body).encode(),
        headers={"Authorization": f"Bearer {OPENWEBUI_API_KEY}", "Content-Type": "application/json"},
    )
    try:
        with urllib.request.urlopen(req, timeout=TIMEOUT) as resp:
            return json.load(resp)
    except urllib.error.HTTPError as e:
        detail = e.read().decode(errors="replace")[:500]
        raise ToolError(f"Open WebUI {method} {path} returned {e.code}: {detail}") from e
    except (urllib.error.URLError, TimeoutError) as e:
        raise ToolError(f"Open WebUI unreachable: {e}") from e


def list_knowledge():
    items, page = [], 1
    while True:
        data = owui("GET", f"/api/v1/knowledge/?page={page}")
        batch = data.get("items", [])
        items += [{"id": i["id"], "name": i["name"], "description": i.get("description", "")} for i in batch]
        if not batch or len(items) >= data.get("total", 0):
            return items
        page += 1


def search(query, collections=None, k=8):
    if not isinstance(query, str) or not query.strip():
        raise ToolError("query must be a non-empty string")
    k = max(1, min(int(k or 8), 50))
    known = list_knowledge()
    if collections:
        by_key = {kb["id"]: kb for kb in known} | {kb["name"].lower(): kb for kb in known}
        missing = [c for c in collections if c not in by_key and c.lower() not in by_key]
        if missing:
            names = ", ".join(kb["name"] for kb in known) or "none"
            raise ToolError(f"unknown knowledge base(s): {', '.join(missing)}; available: {names}")
        selected = [by_key.get(c) or by_key[c.lower()] for c in collections]
    else:
        selected = known
    if not selected:
        return []
    data = owui("POST", "/api/v1/retrieval/query/collection",
                {"collection_names": [kb["id"] for kb in selected], "query": query, "k": max(4 * k, 20), "k_reranker": k})
    docs = (data.get("documents") or [[]])[0]
    metas = (data.get("metadatas") or [[]])[0]
    scores = (data.get("distances") or [[]])[0]
    hits = []
    for i, text in enumerate(docs):
        meta = metas[i] if i < len(metas) else {}
        hits.append({
            "score": round(scores[i], 4) if i < len(scores) else None,
            "source": meta.get("source") or meta.get("name") or meta.get("file_id"),
            "text": text,
        })
    return hits


def format_hits(hits):
    if not hits:
        return "No matching passages."
    out = []
    for n, h in enumerate(hits, 1):
        out.append(f"[{n}] {h['source']} (score {h['score']})\n{h['text'].strip()}")
    return "\n\n---\n\n".join(out)


def call_tool(name, args):
    if name == "list_knowledge":
        kbs = list_knowledge()
        text = "\n".join(f"- {kb['name']} ({kb['id']}): {kb['description']}" for kb in kbs) or "No knowledge bases."
        return {"content": [{"type": "text", "text": text}], "structuredContent": {"knowledge": kbs}}
    if name == "search_knowledge":
        hits = search(args.get("query"), args.get("collections"), args.get("k", 8))
        return {"content": [{"type": "text", "text": format_hits(hits)}], "structuredContent": {"results": hits}}
    raise KeyError(name)


def rpc(msg):
    """Handle one JSON-RPC message; returns the response, or None for notifications."""
    mid, method, params = msg.get("id"), msg.get("method"), msg.get("params") or {}
    if mid is None:
        return None

    def ok(result):
        return {"jsonrpc": "2.0", "id": mid, "result": result}

    def err(code, message):
        return {"jsonrpc": "2.0", "id": mid, "error": {"code": code, "message": message}}

    if method == "initialize":
        asked = params.get("protocolVersion")
        return ok({
            "protocolVersion": asked if asked in PROTOCOL_VERSIONS else PROTOCOL_VERSIONS[0],
            "capabilities": {"tools": {"listChanged": False}},
            "serverInfo": SERVER_INFO,
            "instructions": "Search the homelab knowledge bases with search_knowledge; list them with list_knowledge.",
        })
    if method == "ping":
        return ok({})
    if method == "tools/list":
        return ok({"tools": TOOLS})
    if method == "tools/call":
        try:
            return ok(call_tool(params.get("name"), params.get("arguments") or {}))
        except KeyError:
            return err(-32602, f"unknown tool: {params.get('name')}")
        except (ToolError, ValueError, TypeError) as e:
            return ok({"content": [{"type": "text", "text": str(e)}], "isError": True})
    return err(-32601, f"method not found: {method}")


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"
    server_version = "knowledge-mcp"

    def log_message(self, fmt, *args):
        log.info("%s %s", self.address_string(), fmt % args)

    def send_json(self, status, body=None, headers=None):
        payload = b"" if body is None else json.dumps(body).encode()
        self.send_response(status)
        for k, v in (headers or {}).items():
            self.send_header(k, v)
        if body is not None:
            self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    def authorized(self):
        if self.headers.get("Origin"):
            self.send_json(403, {"error": "cross-origin requests are not allowed"})
            return False
        supplied = self.headers.get("Authorization", "")
        if not hmac.compare_digest(supplied.encode(), f"Bearer {MCP_TOKEN}".encode()):
            self.send_json(401, {"error": "unauthorized"}, {"WWW-Authenticate": "Bearer"})
            return False
        return True

    def read_json(self):
        length = int(self.headers.get("Content-Length") or 0)
        if length > MAX_BODY:
            raise ValueError("request body too large")
        return json.loads(self.rfile.read(length) or b"null")

    def do_GET(self):
        if self.path == "/healthz":
            return self.send_json(200, {"status": "ok"})
        if not self.authorized():
            return
        if self.path == "/mcp":
            return self.send_json(405, {"error": "use POST"}, {"Allow": "POST"})
        if self.path == "/collections":
            try:
                return self.send_json(200, {"knowledge": list_knowledge()})
            except ToolError as e:
                return self.send_json(502, {"error": str(e)})
        self.send_json(404, {"error": "not found"})

    def do_DELETE(self):
        if self.authorized():
            self.send_json(405, {"error": "stateless server has no sessions"}, {"Allow": "POST"})

    def do_POST(self):
        if not self.authorized():
            return
        try:
            body = self.read_json()
        except ValueError as e:
            return self.send_json(400, {"jsonrpc": "2.0", "id": None,
                                        "error": {"code": -32700, "message": f"parse error: {e}"}})
        if self.path == "/mcp":
            if not isinstance(body, dict) or body.get("jsonrpc") != "2.0":
                return self.send_json(400, {"jsonrpc": "2.0", "id": None,
                                            "error": {"code": -32600, "message": "invalid request"}})
            resp = rpc(body)
            return self.send_json(202) if resp is None else self.send_json(200, resp)
        if self.path == "/search":
            if not isinstance(body, dict):
                return self.send_json(400, {"error": "expected a JSON object"})
            try:
                return self.send_json(200, {"results": search(body.get("query"), body.get("collections"), body.get("k", 8))})
            except ToolError as e:
                return self.send_json(400, {"error": str(e)})
        self.send_json(404, {"error": "not found"})


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
    ThreadingHTTPServer.daemon_threads = True
    log.info("listening on :%d, upstream %s", PORT, OPENWEBUI_URL)
    ThreadingHTTPServer(("0.0.0.0", PORT), Handler).serve_forever()
