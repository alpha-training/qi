\l qi.q

/ ===========================
/ Minimal static + WebSocket server for your UI
/ ===========================

/ --- CONFIG ---
/ If you launch q from the project root, this relative path is fine.
\d .ui

ROOT: `:ui;

/ Optionally set absolute path, e.g. .ui.ROOT: `:/Users/you/project/ui

/ --- STATE ---
.ws.clients: ()                  / list of connected WS handles

/ --- MIME types ---
.mime: (`html`htm`js`mjs`css`json`map`png`jpg`jpeg`gif`svg`ico`txt)!(
  ("text/html";"text/html";"application/javascript";"application/javascript";
   "text/css";"application/json";"application/json";
   "image/png";"image/jpeg";"image/jpeg";"image/gif";"image/svg+xml";"image/x-icon";"text/plain"))

mimeFromPath:{[p]
  e: lower -1_ "." vs raze string p;
  $[e in key .mime; .mime e; "application/octet-stream"]
 }

/ --- helpers ---
fileBytes:{[p]
  / return raw bytes or :: if not found
  @[read1; p; {::}]
 }

/ Serve a single file with correct Content-Type
serveFile:{[path]
  0N!(`serveFile;path);
  if[`ERR~b:@[read1;p:.qi.path path;`ERR];
    :"HTTP/1.1 404 Not Found\r\nContent-Length:0\r\n\r\n"];
  if[not count ct:.mime last` vs last` vs p;
   ct:"application/octet-stream"];
  /    dbg;
  header:"HTTP/1.1 200 OK\r\nContent-Type: ",ct,"\r\nContent-Length: ",string[count b],"\r\nCache-Control: no-store\r\n\r\n";
  header,"c"$b
 }

/ --- HTTP router (GET/HEAD/…): .z.ph is called with the request path string ---
/ We keep it simple: serve / -> /ui/index.html; /ui/* -> from disk
.z.ph:{[x]
 0N!(`.z.ph;x 0);
 p:min[path?";?"]#path:x 0;
 if[any p~/:("";"/";"/ui");
  -1"return 1";
   show r:serveFile(ROOT;`index.html);
   /`:tst.html 0: r;
   :r];
 serveFile p
 }

/ --- WebSocket lifecycle: .z.ws[h; m]
/ m is a byte atom for control codes or a message payload
.z.ws:{[h;m]
  / open: 10h, close: 127h, text: 1h (binary: 0h)
  $[10h~m;       / open
      if[not h in .ws.clients; .ws.clients,: h];
      .h.w[h] .j.j enlist `type`msg!(`meta;"connected");
      :();

    127h~m;      / close
      .ws.clients: .ws.clients except h;
      :();

    1h~type m;   / text message from UI
      msg: -8!m; / parse JSON (string to dict)
      / Handle a few UI -> server commands
      if[`res in key msg; / resolution change from Tab 2
        / TODO: your resample logic; push fresh table afterwards
        / .ws.pushTable[d];  / where d is columnar dict
        :()];

      if[`procCmd in key msg; / tab1 process action
        / TODO: route to your control logic
        :()];

      :()  / ignore otherwise
  ]
 }

.ws.handles:{h where"w"=(-38!h:.z.H)`p}
.z.ws:{0N!`ws;show x;}

/ --- Broadcast utilities ---
.ws.send:{neg[.ws.handles`]@\:x}

wsMeta:{[s] .ws.send .j.j enlist `type`msg!(`meta;s) }
wsProcs:{[rows] .ws.send .j.j enlist `type`rows!(`procs;rows) }   / rows: enlist of dicts (one per proc)
wsLog:{[proc;line] .ws.send .j.j enlist `type`proc`line!(`log;proc;line) }

/ --- Plot API (what your UI consumes on Tab 2) ---
/ Expect a *plain table* t with a time column plus any series columns
/ We convert to *columnar JSON dict*: col -> list
colDict:{[t] (cols t)!value each flip t }

plot:{[t;snap:0b]
  d: colDict t;
  .ws.send .j.j enlist `type`data`snap!(`table;d;snap)
  }

/ incremental rows to append (schema must match previous)
plotAppend:{[t]
  d: colDict t;
  .ws.send .j.j enlist `type`data!(`append;d)
  }

/ --- Example: send processes list every N ms (optional demo) ---
/ Uncomment to periodically push dummy process data
/ .proc.tick:{
/   rows: (enlist each `proc`host`port`status`cpu`heap`lag)!enlist each
/     ("rdb1";"localhost";5012;"ok"; 12.3; "1.2G"; "3ms");
/   wsProcs flip rows;
/  }
/ \t 5000 .proc.tick  / run every 5 seconds

/ --- SECURITY NOTES ---
/ - This script does not implement auth/TLS. In a bank you’ll usually front it with Nginx:
//      TLS, Basic/Auth headers, and IP allow-lists.
//      Proxy both HTTP and WS to q:5010.
/ - Keep \p bound to localhost if you only expose via proxy: e.g. run with \p 127.0.0.1 5010
