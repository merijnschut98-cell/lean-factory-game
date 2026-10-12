// The gemba toolkit at a station: live numbers, investigation tools, talking
// to the operator, and the PDCA actions for problems found here.
import type { Tool } from '../content/types';
import type { StationRt } from '../sim/flow';
import { TAKT } from '../sim/line';
import { QUESTIONS, STATION_TOOLS, TOOLS, type Clue } from '../sim/investigation';
import type { Ctx } from './context';
import { bar, fmtMin, fmtPct, h } from './dom';
import { openA3, openCheck } from './a3Panel';

const STATE_LABEL = { working: 'Working', starved: 'Starved — waiting for parts', blocked: 'Blocked — downstream full', down: 'Down — breakdown' };
const STATE_COLOR = { working: '#3fd16a', starved: '#f2c230', blocked: '#f08a24', down: '#ff3b30' };

function liveBlock(ctx: Ctx, st: StationRt): HTMLElement {
  const measured = ctx.game.observed.has(st.def.id);
  const sh = st.share;
  const wrap = h('div.live');
  wrap.append(
    h('div.state-line', h('span.dot', { style: `background:${STATE_COLOR[st.state]}` }), STATE_LABEL[st.state],
      h('span.muted', ` · ${st.queue.length} waiting in front · ${st.scrapToday} scrapped today`)),
  );
  if (!measured) {
    wrap.append(h('p.muted', 'You have not studied this station yet. Use a tool below — numbers you measure feed your value stream map.'));
    return wrap;
  }
  const time = h('div.timeshare',
    ...(['working', 'starved', 'blocked', 'down'] as const).map((k) =>
      h('i', { style: `width:${Math.max(0, sh[k] * 100)}%;background:${STATE_COLOR[k]}`, title: `${k} ${fmtPct(sh[k])}` })),
  );
  wrap.append(
    h('div.kv',
      h('span', 'Time split'), time,
      h('span', 'Effective cycle'), h('div', bar(st.effectiveCt, Math.max(TAKT, st.effectiveCt) * 1.2,
        st.effectiveCt > TAKT ? '#e5533d' : '#3fae5a', TAKT), h('small', `${Math.round(st.effectiveCt)} s vs takt ${Math.round(TAKT)} s`)),
      h('span', 'OEE'), h('div', `${fmtPct(st.oee)} `, h('small.muted', `A ${fmtPct(st.avail)} · P ${fmtPct(st.perf)} · Q ${fmtPct(st.quality, 1)}`)),
    ),
  );
  return wrap;
}

function clueCard(c: Clue, ctx: Ctx): HTMLElement {
  return h('div.clue', h('span.tool-ico', TOOLS[c.tool].icon),
    h('div', h('p', c.text), h('small.muted', `Found at ${ctx.game.stationName(ctx.game.rt(c.problemId).stationId)}`)));
}

export function openStation(ctx: Ctx, stationId: string, log: HTMLElement[] = []): void {
  const g = ctx.game;
  const st = g.station(stationId);
  if (!st) return;
  const render = () => {
    const body = h('div.station-panel');
    body.append(liveBlock(ctx, st));

    // Known problems here and their PDCA step.
    const known = g.openAt(stationId).filter((r) => r.phase !== 'active');
    if (known.length) {
      const list = h('div.problems');
      for (const r of known) {
        const p = g.problem(r.id);
        const action = r.phase === 'spotted'
          ? h('button.btn.primary', { onclick: () => openA3(ctx, r.id) }, 'Open A3')
          : r.phase === 'checkReady'
            ? h('button.btn.primary', { onclick: () => openCheck(ctx, r.id) }, 'Check results')
            : h('span.chip', `Experiment running · results ${fmtMin(Math.max(0, r.checkAt - g.flow.time))}`);
        list.append(h('div.problem-row', h('div', h('b', p.name), h('ul.symptoms', ...p.symptoms.map((s) => h('li', s)))), action));
      }
      body.append(h('h3', 'Problems you have spotted here'), list);
    }

    // Toolkit.
    const tools = h('div.toolgrid');
    for (const t of STATION_TOOLS) {
      const def = TOOLS[t];
      tools.append(h('button.tool', { onclick: () => useTool(t) },
        h('span.tool-ico', def.icon), h('b', def.label), h('small', `${def.blurb} (${def.minutes} min)`)));
    }
    body.append(h('h3', 'Go & See — what do you want to do?'), tools);

    // Talk to the operator.
    const trust = g.trustAt(stationId);
    const qs = h('div.questions');
    for (const q of QUESTIONS) qs.append(h('button.q', { onclick: () => ask(q.id) }, q.text));
    body.append(
      h('h3', 'Talk to the operator ', h('small.muted', trust < 0 ? '— they’re guarded right now' : '')),
      qs,
    );
    if (log.length) body.append(h('h3', 'Your notes'), h('div.log', ...log.slice().reverse()));
    ctx.modals.setBody(body);
  };

  const useTool = (t: Tool) => {
    const def = TOOLS[t];
    ctx.spendTime(def.minutes, `${def.icon} ${def.label}…`, () => {
      const res = g.useTool(stationId, t);
      const entry = h('div.log-entry', h('b', `${def.icon} ${def.label}`));
      entry.append(h('p.data', toolData(t, st)));
      for (const id of res.spotted) entry.append(h('p.spotted', `You notice something: ${g.problem(id).symptoms[0] ?? g.problem(id).name}`));
      for (const c of res.clues) entry.append(clueCard(c, ctx));
      if (res.hiddenSignal) entry.append(h('p.muted', 'Something feels off here, but a quick look doesn’t show it. Harder data might.'));
      if (!res.spotted.length && !res.clues.length && !res.hiddenSignal) entry.append(h('p.muted', 'Nothing new about the problems here.'));
      log.push(entry);
      reopen();
    });
  };

  const ask = (qid: string) => {
    const q = QUESTIONS.find((x) => x.id === qid)!;
    ctx.spendTime(q.kind === 'open' ? 15 : 3, '🗣 Talking…', () => {
      const res = g.ask(stationId, qid);
      const entry = h(`div.log-entry.talk.${res.kind}`, h('b', `You: “${q.text}”`), h('p', res.reply));
      if (res.clue) entry.append(clueCard(res.clue, ctx));
      if (res.kind === 'blame') entry.append(h('p.coach', 'Coach: blame closes mouths. Ask about the process, not the person.'));
      if (res.kind === 'closed') entry.append(h('p.coach', 'Coach: a closed question gets a yes or no. Try one that starts with “walk me through” or “what”.'));
      log.push(entry);
      reopen();
    });
  };

  const reopen = () => {
    ctx.modals.open(st.def.name, h('div'), { wide: true, kicker: 'Gemba', onClose: () => ctx.refresh() });
    render();
    ctx.save();
  };
  reopen();
}

/** The hard data a tool shows, even when there is no clue. */
function toolData(t: Tool, st: StationRt): string {
  const sh = st.share;
  switch (t) {
    case 'time': {
      const s = st.cycleSamples.slice(-10);
      if (!s.length) return 'No cycles completed while you watched.';
      const mean = s.reduce((a, b) => a + b, 0) / s.length;
      const min = Math.min(...s), max = Math.max(...s);
      return `${s.length} cycles: average ${Math.round(mean)} s (range ${Math.round(min)}–${Math.round(max)} s). Takt is ${Math.round(TAKT)} s. ` +
        `Including stoppages, this station needs ${Math.round(st.effectiveCt)} s per unit.`;
    }
    case 'count':
      return `${st.queue.length} units waiting at the input, ${st.current ? 1 : 0} in process, ${st.scrapToday} in the scrap bin.`;
    case 'defects':
      return st.scrapToday ? `${st.scrapToday} rejects today. First-pass yield here: ${fmtPct(st.quality, 1)}.` : `No rejects in the bin today. First-pass yield: ${fmtPct(st.quality, 1)}.`;
    case 'machine':
      return `${st.breakdownsToday} breakdowns this shift. Down ${fmtPct(sh.down)} of the time recently. Availability ${fmtPct(st.avail)}.`;
    case 'data':
      return `Recent time split — working ${fmtPct(sh.working)}, starved ${fmtPct(sh.starved)}, blocked ${fmtPct(sh.blocked)}, down ${fmtPct(sh.down)}. OEE ${fmtPct(st.oee)}.`;
    case 'docs':
      return `Standard cycle on the work instruction: ${Math.round(st.def.ct)} s. Staffing: ${st.def.operators} operator${st.def.operators > 1 ? 's' : ''}.`;
    default:
      return st.state === 'working'
        ? `The operator is working. ${st.queue.length > 6 ? 'A big pile waits in front of them.' : ''}`
        : `Right now the station is ${st.state}.`;
  }
}
