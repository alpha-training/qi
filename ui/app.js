// ====== WebSocket (single channel for simplicity) ======
const loc = window.location;
const WS_URL = (loc.protocol === 'https:' ? 'wss://' : 'ws://') + loc.host + '/ws/main';
const ws = new WebSocket(WS_URL);

const statusLamp = document.getElementById('statusLamp');
ws.onopen = () => { statusLamp.className = 'lamp on'; send({type:'hello', ui:'canvas'}); };
ws.onclose = () => { statusLamp.className = 'lamp err'; };
ws.onerror = () => { statusLamp.className = 'lamp err'; };

function send(obj){ if (ws.readyState === 1) ws.send(JSON.stringify(obj)); }

// ====== Tab Manager ======
const Tab = (() => {
  let current = 1;
  const panes = document.querySelectorAll('[data-pane]');
  const tabs  = document.querySelectorAll('.tab');
  const badges = { 1: document.getElementById('tab1Badge'),
                   2: document.getElementById('tab2Badge'),
                   3: null };

  function show(n){
    current = n;
    tabs.forEach(b => b.classList.toggle('active', +b.dataset.tab===n));
    panes.forEach(p => p.classList.toggle('show', +p.dataset.pane===n));
    const bdg = badges[n]; if (bdg){ bdg.classList.remove('on'); bdg.textContent=''; }
    location.hash = `#tab${n}`;
    if (n === 2 && window.__queuedPlot) { setupFromTable(window.__queuedPlot); window.__queuedPlot = null; }
  }

  tabs.forEach(b => b.addEventListener('click', () => show(+b.dataset.tab)));

  if (location.hash && /^#tab[123]$/.test(location.hash)) show(+location.hash.slice(4));
  else show(1);

  // keyboard: g + 1/2/3
  let gArmed = false;
  window.addEventListener('keydown', (e) => {
    if (e.key === 'g') { gArmed = true; return; }
    if (gArmed && ['1','2','3'].includes(e.key)) { show(+e.key); gArmed = false; }
  });

  return {
    show, current: () => current,
    mark(n){ const bdg=badges[n]; if (bdg){ bdg.textContent='new'; bdg.classList.add('on'); } }
  };
})();

// ====== Toast ======
function toast(msg){
  const t = document.createElement('div');
  t.className = 'toast'; t.textContent = msg;
  document.body.appendChild(t);
  setTimeout(()=>{ t.remove(); }, 2200);
}

// ====== Technical Analysis (Tab 2) ======
let chart, candleSeries, lineSeriesByCol = {}, lastTable = null, timeKey = null;
const elChart = document.getElementById('chart');
const elSeriesBox = document.getElementById('seriesBox');
const elMeta = document.getElementById('meta');
const elRes = document.getElementById('res');

chart = LightweightCharts.createChart(elChart, { height: elChart.clientHeight });
const timeScale = chart.timeScale();

function autoChecked(col){
  return /^(close|bb[ul]|bbm|rsi|macd|signal)$/i.test(col);
}
function toSec(v){ return v>1e12 ? Math.floor(v/1000) : v; }

function toCandles(tbl, tKey){
  const t = tbl[tKey], len = t.length;
  const out = new Array(len);
  for (let i=0;i<len;i++)
    out[i] = { time: toSec(t[i]), open: tbl.open[i], high: tbl.high[i], low: tbl.low[i], close: tbl.close[i] };
  return out;
}
function toLine(tbl, tKey, col){
  const t = tbl[tKey], y = tbl[col], len = Math.min(t.length, y.length), out = new Array(len);
  for (let i=0;i<len;i++) out[i] = { time: toSec(t[i]), value: y[i] };
  return out;
}
function appendInto(tbl, delta){
  Object.keys(delta).forEach(k => {
    const arr = tbl[k], add = delta[k];
    if (Array.isArray(arr) && Array.isArray(add)) arr.push(...add);
  });
}
function toggleSeries(col, on){
  if (on) {
    if (!lineSeriesByCol[col]) lineSeriesByCol[col] = chart.addLineSeries({ lineWidth: 1 });
    lineSeriesByCol[col].setData(toLine(lastTable, timeKey, col));
  } else {
    if (lineSeriesByCol[col]) { lineSeriesByCol[col].setData([]); lineSeriesByCol[col] = null; }
  }
}

function setupFromTable(tbl){
  lastTable = tbl;
  const cols = Object.keys(tbl);
  timeKey = cols.find(c => /^(t|time|timestamp)$/i.test(c)) || cols[0];

  const hasOHLC = ['open','high','low','close'].every(k => cols.includes(k));
  if (hasOHLC) {
    if (!candleSeries) candleSeries = chart.addCandlestickSeries();
    candleSeries.setData(toCandles(tbl, timeKey));
  }

  // rebuild checkboxes
  elSeriesBox.innerHTML = '';
  cols.filter(c => c !== timeKey).forEach(col => {
    const id = 'chk_'+col;
    const wr = document.createElement('label');
    wr.innerHTML = `<input type="checkbox" id="${id}" ${autoChecked(col) ? 'checked':''}> ${col}`;
    elSeriesBox.appendChild(wr);
    const chk = wr.querySelector('input');
    chk.addEventListener('change', () => toggleSeries(col, chk.checked));
    if (chk.checked) toggleSeries(col, true);
  });

  elMeta.textContent = `Rows: ${tbl[timeKey].length}  |  Columns: ${cols.length}`;
  timeScale.fitContent();
}

elRes.addEventListener('change', () => {
  send({ type:'res', value: elRes.value }); // server can resample and push a fresh snapshot
});

// ====== Cmd & Control (Tab 1) ======
const procBody = document.getElementById('procBody');
const logArea  = document.getElementById('logArea');
const logSource= document.getElementById('logSource');
const btnFollow= document.getElementById('btnFollow');
const btnClear = document.getElementById('btnClear');
let following = false;

btnFollow.addEventListener('click', () => { following = !following; btnFollow.textContent = following ? 'Unfollow' : 'Follow'; });
btnClear.addEventListener('click', () => { logArea.textContent=''; });

function renderProcs(rows){
  procBody.innerHTML = '';
  logSource.innerHTML = '';
  rows.forEach(r => {
    // dropdown sources
    const opt = document.createElement('option');
    opt.value = r.proc; opt.textContent = r.proc;
    logSource.appendChild(opt);

    // table row
    const tr = document.createElement('tr');
    tr.innerHTML = `
      <td>${r.proc}</td>
      <td>${r.host}</td>
      <td>${r.port}</td>
      <td>${r.status}</td>
      <td>${r.cpu?.toFixed?.(1) ?? ''}</td>
      <td>${r.heap ?? ''}</td>
      <td>${r.lag ?? ''}</td>
      <td class="row-actions">
        <button data-cmd="ping" data-proc="${r.proc}">Ping</button>
        <button data-cmd="gc" data-proc="${r.proc}">GC</button>
        <button data-cmd="rotate" data-proc="${r.proc}">Rotate</button>
        <button data-cmd="restart" data-proc="${r.proc}">Restart</button>
      </td>
    `;
    procBody.appendChild(tr);
  });
}
procBody.addEventListener('click', (e) => {
  const t = e.target;
  if (t.tagName === 'BUTTON' && t.dataset.cmd) {
    send({ type:'procCmd', cmd:t.dataset.cmd, proc:t.dataset.proc });
    toast(`${t.dataset.cmd} → ${t.dataset.proc}`);
  }
});

// ====== Message Router ======
ws.onmessage = (ev) => {
  const msg = JSON.parse(ev.data);
    console.log("received msg");
    console.log(msg.type);
  switch (msg.type) {
    case 'meta':
      toast(msg.msg || 'meta');
      break;

    // Tab 2: plotting
    case 'table': {
      const snap = !!msg.snap;
      if (Tab.current() === 2) {
        setupFromTable(msg.data);
      } else {
        window.__queuedPlot = msg.data;
        Tab.mark(2);
        toast('Chart updated (Tab 2)');
        if (snap) { Tab.show(2); setupFromTable(msg.data); }
      }
      break;
    }
    case 'append': {
      if (!lastTable) { window.__queuedPlot = msg.data; Tab.mark(2); break; }
      appendInto(lastTable, msg.data);
      // refresh visible series
      Object.keys(lineSeriesByCol).forEach(col => lineSeriesByCol[col] && lineSeriesByCol[col].setData(toLine(lastTable, timeKey, col)));
      if (candleSeries && ['open','high','low','close'].every(k => lastTable[k])) {
        candleSeries.setData(toCandles(lastTable, timeKey));
      }
      if (Tab.current() !== 2) Tab.mark(2);
      break;
    }

    // Tab 1: processes & logs
    case 'procs': {
      // msg.rows: [{proc,host,port,status,cpu,heap,lag}]
      renderProcs(msg.rows || []);
      break;
    }
    case 'log': {
      // msg.proc, msg.line
      const selected = logSource.value;
      if (!selected || selected === msg.proc) {
        logArea.textContent += `[${msg.proc}] ${msg.line}\n`;
        if (following) logArea.scrollTop = logArea.scrollHeight;
      }
      break;
    }

    default:
      // ignore
      break;
  }
};