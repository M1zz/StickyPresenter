// StickyPresenter 웹 체험: 슬라이드 위에 노트와 타이머 위젯을 띄워 본다.
// 규칙은 앱과 같다. 입력 해석은 TimerCore.parseTimerInput · parsePomodoroInput,
// 곧 끝남 구간은 TimerWidgetView.warningThreshold, 색은 NoteColor · PomodoroPhase · warningRed · finishedRed.
(() => {
  const root = document.getElementById("demo");
  if (!root) return;
  const T = JSON.parse(root.dataset.text);
  const MAX = 99 * 3600 + 59 * 60 + 59;
  const NOTE = ["#FFF2B3", "#FFD1DB", "#C7F2C7", "#C7E0FF", "#E0CCFF", "#FFE0B8"];
  const FOCUS = "#E84D3D", REST = "#29AD87", WARN = "#F2423A", DONE = "#FF385E";

  function parse(raw) {
    const t = raw.trim().toLowerCase();
    if (!t) return 0;
    const c = t.match(/^(\d+):(\d{1,2})(?::(\d{1,2}))?$/);
    let s = 0;
    if (c) s = c[3] === undefined ? +c[1] * 60 + +c[2] : +c[1] * 3600 + +c[2] * 60 + +c[3];
    else {
      [[/(\d+)\s*hours?/g, 3600], [/(\d+)\s*hr/g, 3600], [/(\d+)\s*h(?![a-z])/g, 3600],
       [/(\d+)\s*minutes?/g, 60], [/(\d+)\s*mins?/g, 60], [/(\d+)\s*m(?![a-z])/g, 60],
       [/(\d+)\s*seconds?/g, 1], [/(\d+)\s*secs?/g, 1], [/(\d+)\s*s(?![a-z])/g, 1]]
        .forEach(([re, mul]) => { for (const m of t.matchAll(re)) s += +m[1] * mul; });
      if (!s && /^\d+(\.\d+)?$/.test(t)) s = parseFloat(t) * 60;
    }
    return s > 0 && s <= MAX ? Math.round(s) : 0;
  }
  function parsePomo(raw) {
    const p = raw.split("/");
    if (p.length !== 2) return null;
    const f = parse(p[0]), b = parse(p[1]);
    return f && b ? { f, b } : null;
  }
  const words = s => [[Math.floor(s / 3600), T.h], [Math.floor(s % 3600 / 60), T.m], [s % 60, T.s]]
    .filter(([v]) => v).map(([v, u]) => u.replace("%d", v)).join(" ");
  const clock = s => {
    const h = Math.floor(s / 3600), m = Math.floor(s % 3600 / 60), x = s % 60, p = n => String(n).padStart(2, "0");
    return h ? `${h}:${p(m)}:${p(x)}` : `${p(m)}:${p(x)}`;
  };
  const threshold = t => t < 300 ? 10 : t < 600 ? 60 : t < 1800 ? 120 : t < 3600 ? 180 : 300;

  root.innerHTML = `
    <div class="sp-stage">
      <div class="sp-slide" aria-hidden="true"><b>${T.slide}</b><i></i><i></i><i></i></div>
      <div class="sp-note" style="--note:${NOTE[0]}">
        <textarea aria-label="${T.noteLabel}" spellcheck="false">${T.note}</textarea>
      </div>
      <div class="sp-widget" role="timer" aria-live="off">
        <svg viewBox="0 0 100 100" aria-hidden="true"><rect class="track" x="7" y="7" width="86" height="86" rx="18" pathLength="1"/><rect class="ring" x="7" y="7" width="86" height="86" rx="18" pathLength="1"/></svg>
        <div class="sp-time">00:00</div><div class="sp-phase"></div>
      </div>
    </div>
    <div class="sp-controls">
      <form class="sp-form">
        <input type="text" inputmode="text" autocomplete="off" placeholder="5:30  ·  1h 20m  ·  45s  ·  10" aria-label="${T.input}">
        <button type="submit" class="chip sp-go">${T.start}</button>
      </form>
      <p class="sp-preview muted small" aria-live="polite">&nbsp;</p>
      <div class="demo-chips">${["15s", "45s", "5:30", "1h 20m", "25/5"].map((x, i) => `<button type="button" class="chip${i ? "" : " hint"}" data-in="${x}">${x}</button>`).join("")}</div>
      <div class="sp-row"><button type="button" class="chip sp-toggle" disabled>${T.pause}</button><button type="button" class="chip sp-reset" disabled>${T.reset}</button></div>
      <div class="sp-colors" role="group" aria-label="${T.colorLabel}">${NOTE.map((c, i) => `<button type="button" style="--c:${c}" aria-label="${T.colors[i]}" aria-pressed="${!i}"></button>`).join("")}</div>
      <p class="sp-status" aria-live="assertive"></p>
      <p class="muted small">${T.footnote}</p>
    </div>`;

  const $ = s => root.querySelector(s);
  const input = $("input"), preview = $(".sp-preview"), widget = $(".sp-widget"), ring = $(".ring"),
    time = $(".sp-time"), phaseEl = $(".sp-phase"), toggle = $(".sp-toggle"), reset = $(".sp-reset"), status = $(".sp-status");
  const st = { target: 0, left: 0, running: false, pomo: null, phase: "f", cycle: 1, endAt: 0, said: "" };

  function showPreview() {
    const v = input.value, p = parsePomo(v), s = parse(v);
    preview.textContent = !v.trim() ? " " : p ? `↻ ${T.focus} ${words(p.f)} · ${T.rest} ${words(p.b)}`
      : s ? `→ ${words(s)}` : T.invalid;
  }
  function render() {
    const done = !st.pomo && st.target && st.left === 0;
    const warn = !done && st.left > 0 && st.left <= threshold(st.target);
    const color = done ? DONE : warn ? WARN : st.pomo ? (st.phase === "f" ? FOCUS : REST) : "var(--sp-ink)";
    widget.style.setProperty("--ring", color);
    widget.style.setProperty("--ink", warn ? WARN : "var(--sp-ink)");
    ring.style.strokeDasharray = `${st.target ? st.left / st.target : 0} 1`;
    time.textContent = clock(st.left);
    phaseEl.textContent = st.pomo ? `${st.phase === "f" ? T.focus : T.rest} · #${st.cycle}` : "";
    widget.classList.toggle("done", !!done);
    widget.classList.toggle("on", st.left > 0);
    reset.disabled = !st.target;
    toggle.disabled = !st.target || !!done;
    toggle.textContent = st.running || !st.target ? T.pause : T.resume;
    const say = done ? T.done : warn ? T.almost : "";
    if (say !== st.said) status.textContent = st.said = say;
  }
  function tick() {
    if (!st.running) return;
    st.left = Math.max(0, Math.ceil((st.endAt - performance.now()) / 1000));
    if (st.left === 0 && st.pomo) {            // 뽀모도로는 끝나지 않고 집중과 휴식을 오간다
      st.phase = st.phase === "f" ? "r" : "f";
      if (st.phase === "f") st.cycle++;
      st.target = st.left = st.phase === "f" ? st.pomo.f : st.pomo.b;
      st.endAt = performance.now() + st.left * 1000;
    } else if (st.left === 0) st.running = false;
    render();
  }
  function start(raw) {
    const p = parsePomo(raw), s = p ? p.f : parse(raw);
    if (!s) { showPreview(); input.focus(); return; }
    Object.assign(st, { pomo: p, phase: "f", cycle: 1, target: s, left: s, running: true, endAt: performance.now() + s * 1000 });
    root.dataset.used = "1"; $(".hint")?.classList.remove("hint");
    render();
  }

  // 좁은 화면에서도 글이 잘리지 않게 노트 높이를 글에 맞춘다.
  const ta = $("textarea"), fit = () => { ta.style.height = "auto"; ta.style.height = ta.scrollHeight + "px"; };
  ta.addEventListener("input", fit);
  if (window.ResizeObserver) new ResizeObserver(fit).observe($(".sp-stage")); else fit();

  setInterval(tick, 250);
  input.addEventListener("input", showPreview);
  $(".sp-form").addEventListener("submit", e => { e.preventDefault(); start(input.value); });
  root.addEventListener("click", e => {
    const chip = e.target.closest("[data-in]");
    if (chip) { input.value = chip.dataset.in; showPreview(); start(chip.dataset.in); }
    const dot = e.target.closest(".sp-colors button");
    if (dot) {
      root.querySelectorAll(".sp-colors button").forEach(b => b.setAttribute("aria-pressed", b === dot));
      $(".sp-note").style.setProperty("--note", dot.style.getPropertyValue("--c"));
    }
  });
  toggle.addEventListener("click", () => {
    if (!st.target || (!st.pomo && st.left === 0)) return;
    st.running = !st.running;
    if (st.running) st.endAt = performance.now() + st.left * 1000;
    render();
  });
  reset.addEventListener("click", () => {
    Object.assign(st, { running: false, phase: "f", cycle: 1 });
    st.target = st.left = st.pomo ? st.pomo.f : st.target;
    render();
  });
  render();
})();
