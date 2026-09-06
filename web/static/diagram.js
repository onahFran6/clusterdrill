// Diagram tab rebuild: Architecture + Sequence views, ported from a Figma
// Make prototype's React/SVG components (FlowDiagram/SequenceDiagram) into
// plain DOM/SVG - no charting library, no build step, same posture as the
// rest of this app (see app.js's own top-of-file note and the radar-chart
// block it already carries for the closest existing precedent of this
// "server renders JSON, a small vanilla-JS function draws SVG from it"
// split). Loaded on the question page only; app.js calls
// ClusterDrillDiagram.renderArchitecture()/renderSequence() lazily, the first time
// each sub-tab is shown, mirroring the existing renderMermaidIfNeeded()
// lazy-render pattern for the Mermaid fallback path.
//
// Data shapes (produced by lib/generate_diagram.py's render_json()/
// sequence_json(), or hand-authored for the 10 topic primers - see
// build_topic_primers.py):
//   architecture: { title, description, nodes: [{id,label,type,sub?}],
//                   edges: [{from,to,label,animated,command?}] }
//   sequence:     { title, description, actors: [{id,label,type}],
//                   steps: [{from,to,label,command?}] }
//
// Node/edge "type" is one of controller/pod/service/resource/storage/
// policy/external (lib/generate_diagram.py's _KIND_TYPE) - colors for each
// come from CSS custom properties (style.css's --diagram-* tokens) rather
// than hardcoded hex here, so the palette stays in one place.
window.ClusterDrillDiagram = (function () {
  const SVG_NS = "http://www.w3.org/2000/svg";
  const reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  function cssVar(name) {
    return getComputedStyle(document.documentElement).getPropertyValue(name).trim();
  }

  const TYPE_COLOR = {
    controller: () => cssVar("--diagram-controller"),
    pod: () => cssVar("--accent-2"),
    service: () => cssVar("--diagram-service"),
    resource: () => cssVar("--diagram-resource"),
    storage: () => cssVar("--accent"),
    policy: () => cssVar("--fail"),
    external: () => cssVar("--muted"),
  };

  function colorFor(type) {
    const fn = TYPE_COLOR[type] || TYPE_COLOR.external;
    return fn();
  }

  // Generated labels are real kubectl command text, not short curated
  // phrases like the source prototype's - long enough that a naive
  // text-anchor="middle" draw can push well past the SVG viewBox edge (SVG
  // clips there by default, so it isn't "scrollable off-screen", it's just
  // gone). Truncating with an ellipsis and keeping the full text in a
  // native <title> tooltip is simpler and more robust than trying to
  // measure/wrap text without a canvas context.
  function truncate(text, maxChars) {
    if (!text || text.length <= maxChars) return text;
    return text.slice(0, maxChars - 1).trimEnd() + "…";
  }

  function withTitle(node, fullText) {
    const title = el("title", {});
    title.textContent = fullText;
    node.appendChild(title);
    return node;
  }

  function el(tag, attrs) {
    const node = document.createElementNS(SVG_NS, tag);
    for (const k in attrs) {
      if (attrs[k] === undefined || attrs[k] === null) continue;
      node.setAttribute(k, attrs[k]);
    }
    return node;
  }

  function fallbackNote(container, message) {
    container.innerHTML = "";
    const p = document.createElement("p");
    p.className = "diagram-note";
    p.textContent = message;
    container.appendChild(p);
  }

  // --- Architecture view: auto-layout + render -----------------------------
  //
  // The generator emits nodes/edges with no positions (unlike the source
  // prototype, which hand-placed every node per lab) - a small layered
  // ("do this, then that becomes available") layout is computed here from
  // the edge list instead: each node's column is its longest-path distance
  // from a source node (Kahn's algorithm), rows stack nodes within a column
  // top to bottom. This reads left-to-right in creation order, matching the
  // "flowchart LR" orientation the Mermaid fallback already uses.
  const NW = 150, NH = 54, COL_W = 230, ROW_H = 112, PAD = 24;

  function layoutNodes(nodes, edges) {
    const ids = nodes.map((n) => n.id);
    const outgoing = new Map(ids.map((id) => [id, []]));
    const indegree = new Map(ids.map((id) => [id, 0]));
    edges.forEach((e) => {
      if (!outgoing.has(e.from) || !indegree.has(e.to)) return;
      outgoing.get(e.from).push(e.to);
      indegree.set(e.to, indegree.get(e.to) + 1);
    });

    const rank = new Map(ids.map((id) => [id, 0]));
    const queue = ids.filter((id) => indegree.get(id) === 0);
    const visited = new Set(queue);
    const remaining = new Map(indegree);
    while (queue.length) {
      const u = queue.shift();
      outgoing.get(u).forEach((v) => {
        rank.set(v, Math.max(rank.get(v), rank.get(u) + 1));
        remaining.set(v, remaining.get(v) - 1);
        if (remaining.get(v) === 0 && !visited.has(v)) {
          visited.add(v);
          queue.push(v);
        }
      });
    }
    // Any node never reached above is part of a cycle the generator
    // shouldn't produce - place it one column past the current max rather
    // than looping forever, so a bug elsewhere degrades to "slightly odd
    // layout" instead of a hung render.
    let maxRank = 0;
    rank.forEach((r) => { if (r > maxRank) maxRank = r; });
    ids.forEach((id) => { if (!visited.has(id)) rank.set(id, maxRank + 1); });

    const columns = new Map();
    ids.forEach((id) => {
      const r = rank.get(id);
      if (!columns.has(r)) columns.set(r, []);
      columns.get(r).push(id);
    });
    const maxColSize = Math.max(1, ...Array.from(columns.values(), (c) => c.length));
    const vh = PAD * 2 + maxColSize * ROW_H;

    const pos = new Map();
    columns.forEach((colIds, r) => {
      const colHeight = colIds.length * ROW_H;
      const yOffset = (vh - colHeight) / 2;
      colIds.forEach((id, i) => {
        pos.set(id, { x: PAD + r * COL_W, y: yOffset + i * ROW_H + (ROW_H - NH) / 2 });
      });
    });

    const vw = PAD * 2 + (maxRank + 1) * COL_W - (COL_W - NW);
    return { pos, rank, vw, vh };
  }

  // A layered layout still crowds badly if every edge anchors at a node's
  // exact center - a node with 6 incoming edges (a common real shape here:
  // e.g. ConfigMap/Secret/LimitRange/ResourceQuota all reaching one
  // Container) draws all 6 curves converging on one point, and two edges
  // sharing the same (from, to) pair (e.g. envFrom.configMapRef AND
  // env.valueFrom.configMapKeyRef both ConfigMap->Container) draw as one
  // curve exactly on top of the other. Fanning each edge's anchor out
  // across its node's height - by its order among that node's other
  // edges on the same side - fixes both cases at once, including the
  // duplicate-pair case (each copy gets a different position in both the
  // source's outgoing order and the target's incoming order).
  function computeAnchorOrder(edges) {
    const outCount = new Map(), inCount = new Map();
    const outIdx = [], inIdx = [];
    edges.forEach((e, i) => {
      outIdx[i] = outCount.get(e.from) || 0;
      outCount.set(e.from, outIdx[i] + 1);
      inIdx[i] = inCount.get(e.to) || 0;
      inCount.set(e.to, inIdx[i] + 1);
    });
    return { outCount, inCount, outIdx, inIdx };
  }

  // Separate from computeAnchorOrder() because "how far should this edge
  // bow away from the straight line" needs to be indexed per (from, to)
  // pair specifically - the case that most needs it is two edges sharing
  // an identical pair (e.g. ConfigMap->Container via both envFrom and
  // valueFrom), which anchor fan-out alone still leaves visually close
  // together since they start/end in the same small node. Only edges that
  // skip past an intermediate column (rank gap > 1) get a bow at all;
  // direct-neighbor-column edges read fine as straight lines.
  function computeSkipOrder(edges, rank) {
    const skipCount = new Map();
    return edges.map((e) => {
      const gap = Math.abs((rank.get(e.to) || 0) - (rank.get(e.from) || 0));
      if (gap <= 1) return -1; // not a skip edge - bowFor() below leaves it straight
      const key = `${e.from}->${e.to}`;
      const idx = skipCount.get(key) || 0;
      skipCount.set(key, idx + 1);
      return idx;
    });
  }

  function bowFor(skipIdx) {
    if (skipIdx < 0) return 0;
    const sign = skipIdx % 2 === 0 ? 1 : -1;
    const step = Math.floor(skipIdx / 2) + 1;
    return sign * step * 24;
  }

  function anchorFrac(idx, count) {
    if (count <= 1) return 0.5;
    const margin = 0.12;
    return margin + (idx / (count - 1)) * (1 - 2 * margin);
  }

  function edgeGeo(a, b, fromFrac, toFrac, bow) {
    const ax = a.x + NW / 2, ay = a.y + NH * fromFrac;
    const bx = b.x + NW / 2, by = b.y + NH * toFrac;
    const dx = bx - ax, dy = by - ay;
    let x1, y1, x2, y2;
    if (Math.abs(dx) >= Math.abs(dy)) {
      x1 = dx > 0 ? a.x + NW : a.x; y1 = ay;
      x2 = dx > 0 ? b.x : b.x + NW; y2 = by;
    } else {
      x1 = ax; y1 = dy > 0 ? a.y + NH : a.y;
      x2 = bx; y2 = dy > 0 ? b.y : b.y + NH;
    }
    const mx = (x1 + x2) / 2;
    // "bow" nudges the bezier's control points off the straight line, only
    // used for edges that skip past an intermediate column - it curves them
    // up/away rather than drawing straight through whatever node happens to
    // sit in that middle column.
    const my1 = y1 + (bow || 0), my2 = y2 + (bow || 0);
    return {
      x1, y1, x2, y2, midX: (x1 + x2) / 2, midY: (my1 + my2) / 2,
      path: `M${x1},${y1} C${mx},${my1} ${mx},${my2} ${x2},${y2}`,
    };
  }

  function renderArchitecture(container, data) {
    if (!data || !data.nodes || !data.nodes.length) {
      fallbackNote(container, "No architecture diagram available for this item.");
      return;
    }
    container.innerHTML = "";

    if (data.description) {
      const desc = document.createElement("p");
      desc.className = "diagram-desc";
      desc.textContent = data.description;
      container.appendChild(desc);
    }

    const { pos, rank, vw, vh } = layoutNodes(data.nodes, data.edges);
    const anchors = computeAnchorOrder(data.edges || []);
    const skipIdx = computeSkipOrder(data.edges || [], rank);
    const frame = document.createElement("div");
    frame.className = "diagram-svg-frame";
    const svg = el("svg", { viewBox: `0 0 ${vw} ${vh}`, class: "diagram-svg" });

    const defs = el("defs", {});
    ["default", "primary"].forEach((k) => {
      const marker = el("marker", {
        id: `clusterdrill-arr-${k}`, markerWidth: "8", markerHeight: "8", refX: "7", refY: "3", orient: "auto",
      });
      marker.appendChild(el("path", {
        d: "M0,0 L0,6 L8,3 z",
        fill: k === "primary" ? cssVar("--accent") : "rgba(140,155,180,0.6)",
      }));
      defs.appendChild(marker);
    });
    svg.appendChild(defs);

    const nodeById = {};
    data.nodes.forEach((n) => { nodeById[n.id] = Object.assign({}, n, pos.get(n.id)); });

    // Edges first, so nodes paint on top of the lines that touch them.
    (data.edges || []).forEach((edge, i) => {
      const a = nodeById[edge.from], b = nodeById[edge.to];
      if (!a || !b) return;
      const fromFrac = anchorFrac(anchors.outIdx[i], anchors.outCount.get(edge.from) || 1);
      const toFrac = anchorFrac(anchors.inIdx[i], anchors.inCount.get(edge.to) || 1);
      const bow = bowFor(skipIdx[i]);
      const g = edgeGeo(a, b, fromFrac, toFrac, bow);
      const pathId = `clusterdrill-edge-${i}-${Math.random().toString(36).slice(2, 7)}`;
      const active = !!edge.animated;
      const stroke = active ? cssVar("--accent") : "rgba(140,155,180,0.45)";
      const path = el("path", {
        id: pathId, d: g.path, stroke, fill: "none",
        "stroke-width": active ? "1.6" : "1",
        "marker-end": `url(#clusterdrill-arr-${active ? "primary" : "default"})`,
      });
      if (active) path.setAttribute("stroke-dasharray", "6 3");
      svg.appendChild(path);

      if (active && !reducedMotion) {
        const dot = el("circle", { r: "3", fill: cssVar("--accent"), class: "diagram-flow-dot" });
        const anim = el("animateMotion", { dur: "2s", repeatCount: "indefinite" });
        const mpath = el("mpath", {});
        mpath.setAttributeNS("http://www.w3.org/1999/xlink", "href", `#${pathId}`);
        anim.appendChild(mpath);
        dot.appendChild(anim);
        svg.appendChild(dot);
      }

      if (edge.label) {
        const shown = truncate(edge.label, 42);
        const labelW = Math.max(50, shown.length * 5.6 + 12);
        svg.appendChild(el("rect", {
          x: g.midX - labelW / 2, y: g.midY - 9, width: labelW, height: 16, rx: 3,
          fill: "var(--panel)", stroke: "var(--border)",
        }));
        const text = el("text", {
          x: g.midX, y: g.midY + 3.5, "text-anchor": "middle",
          fill: active ? cssVar("--accent") : "var(--muted)", "font-size": "8.5",
          class: "diagram-mono-text",
        });
        text.textContent = shown;
        svg.appendChild(withTitle(text, edge.label));
      }
    });

    // Nodes on top.
    data.nodes.forEach((n) => {
      const p = pos.get(n.id);
      const color = colorFor(n.type);
      const g = el("g", {});
      g.appendChild(el("rect", {
        x: p.x, y: p.y, width: NW, height: NH, rx: 8,
        fill: "var(--panel)", stroke: color, "stroke-width": "1.3",
      }));
      const label = el("text", {
        x: p.x + NW / 2, y: p.y + (n.sub ? 19 : NH / 2 + 4), "text-anchor": "middle",
        fill: color, "font-size": "10.5", "font-weight": "600", class: "diagram-mono-text",
      });
      label.textContent = truncate(n.label, 20);
      g.appendChild(withTitle(label, n.label));
      if (n.sub) {
        const sub = el("text", {
          x: p.x + NW / 2, y: p.y + 33, "text-anchor": "middle",
          fill: "var(--muted)", "font-size": "8", class: "diagram-mono-text",
        });
        sub.textContent = truncate(n.sub, 24);
        g.appendChild(withTitle(sub, n.sub));
      }
      svg.appendChild(g);
    });

    frame.appendChild(svg);
    container.appendChild(frame);
    container.appendChild(buildLegend(data.nodes, data.edges));
  }

  function buildLegend(nodes, edges) {
    const legend = document.createElement("div");
    legend.className = "diagram-legend";
    const seen = new Set();
    nodes.forEach((n) => {
      if (seen.has(n.type)) return;
      seen.add(n.type);
      const item = document.createElement("div");
      item.className = "diagram-legend-item";
      const dot = document.createElement("span");
      dot.className = "diagram-legend-dot";
      dot.style.background = colorFor(n.type);
      const label = document.createElement("span");
      label.textContent = n.type;
      item.appendChild(dot);
      item.appendChild(label);
      legend.appendChild(item);
    });
    const hasAnimated = (edges || []).some((e) => e.animated);
    const hasStatic = (edges || []).some((e) => !e.animated);
    if (hasAnimated) legend.appendChild(lineLegendItem("data flow", { color: "var(--accent)", dashed: true }));
    if (hasStatic) legend.appendChild(lineLegendItem("reference", { color: "rgba(140,155,180,0.45)", dashed: false }));
    return legend;
  }

  // color/dashed default to the Architecture view's "active edge" styling
  // (blue + dashed) so its two existing call sites don't need to change;
  // the Sequence view's call/return legend passes both explicitly since
  // its call=solid-blue/return=dashed-gray pairing is the opposite
  // combination.
  function lineLegendItem(label, { color = "var(--accent)", dashed = true } = {}) {
    const item = document.createElement("div");
    item.className = "diagram-legend-item diagram-legend-item-line";
    const svg = el("svg", { width: "20", height: "8" });
    svg.appendChild(el("line", {
      x1: "0", y1: "4", x2: "14", y2: "4",
      stroke: color,
      "stroke-width": "1.5",
      "stroke-dasharray": dashed ? "4 2" : undefined,
    }));
    const wrap = document.createElement("span");
    wrap.appendChild(svg);
    const text = document.createElement("span");
    text.textContent = label;
    item.appendChild(wrap);
    item.appendChild(text);
    return item;
  }

  // --- Sequence view ---------------------------------------------------------
  const SA_W = 108, SA_H = 34, SA_COL = 158, SA_PAD = 22, SS_H = 46;

  function renderSequence(container, data) {
    if (!data || !data.steps || !data.steps.length) {
      fallbackNote(container, "No sequence available for this item - a topic overview spans several unrelated relationships, not one ordered workflow. Open a specific question's Diagram tab for its step-by-step sequence.");
      return;
    }
    container.innerHTML = "";

    if (data.description) {
      const desc = document.createElement("p");
      desc.className = "diagram-desc";
      desc.textContent = data.description;
      container.appendChild(desc);
    }

    const actors = data.actors || [];
    const colX = (id) => {
      const idx = actors.findIndex((a) => a.id === id);
      return SA_PAD + Math.max(0, idx) * SA_COL + SA_W / 2;
    };
    const vw = SA_PAD * 2 + Math.max(0, actors.length - 1) * SA_COL + SA_W;
    const y0 = 22 + SA_H + 24;
    const vh = y0 + data.steps.length * SS_H + 16;
    const lifeEnd = vh - 12;

    const frame = document.createElement("div");
    frame.className = "diagram-svg-frame";
    const svg = el("svg", { viewBox: `0 0 ${vw} ${vh}`, class: "diagram-svg" });

    const defs = el("defs", {});
    const fwd = el("marker", { id: "clusterdrill-sqa-f", markerWidth: "8", markerHeight: "8", refX: "7", refY: "3", orient: "auto" });
    fwd.appendChild(el("path", { d: "M0,0 L0,6 L8,3 z", fill: cssVar("--accent") }));
    defs.appendChild(fwd);
    const ret = el("marker", { id: "clusterdrill-sqa-r", markerWidth: "8", markerHeight: "8", refX: "7", refY: "3", orient: "auto" });
    ret.appendChild(el("path", { d: "M0,0 L0,6 L8,3 z", fill: "rgba(148,163,184,0.7)" }));
    defs.appendChild(ret);
    svg.appendChild(defs);

    actors.forEach((actor) => {
      const x = colX(actor.id);
      const color = colorFor(actor.type);
      svg.appendChild(el("line", {
        x1: x, y1: 22 + SA_H, x2: x, y2: lifeEnd,
        stroke: color, "stroke-width": "1", "stroke-dasharray": "5 4", opacity: "0.32",
      }));
      svg.appendChild(el("rect", {
        x: x - SA_W / 2, y: 22, width: SA_W, height: SA_H, rx: 6,
        fill: "var(--panel)", stroke: color, "stroke-width": "1.2",
      }));
      const label = el("text", {
        x, y: 22 + SA_H / 2 + 4, "text-anchor": "middle",
        fill: "var(--text)", "font-size": "9.5", "font-weight": "600", class: "diagram-mono-text",
      });
      label.textContent = truncate(actor.label, 16);
      svg.appendChild(withTitle(label, actor.label));
    });

    data.steps.forEach((step, i) => {
      const fx = colX(step.from), tx = colX(step.to);
      const ay = y0 + i * SS_H + SS_H / 2;
      const lx = (fx + tx) / 2;
      const isReturn = !!step.dashed;
      svg.appendChild(el("line", {
        x1: fx, y1: ay, x2: tx, y2: ay,
        stroke: isReturn ? "rgba(148,163,184,0.7)" : cssVar("--accent"),
        "stroke-width": "1.4",
        "stroke-dasharray": isReturn ? "5 3" : undefined,
        "marker-end": `url(#clusterdrill-sqa-${isReturn ? "r" : "f"})`,
      }));
      // Generated step labels are full kubectl command text - can easily be
      // longer than the single column gap between two adjacent actors, so
      // the max length allowed here is derived from that gap's actual pixel
      // width (~5.3px/char at this font-size) rather than a fixed constant,
      // same reasoning as truncate()'s doc comment above.
      const maxChars = Math.max(14, Math.floor((Math.abs(tx - fx) - 12) / 5.3));
      const text = el("text", {
        x: lx, y: ay - 6, "text-anchor": "middle",
        fill: isReturn ? "rgba(148,163,184,0.8)" : "var(--text)", "font-size": "8.5", class: "diagram-mono-text",
      });
      text.textContent = truncate(step.label, maxChars);
      svg.appendChild(withTitle(text, step.label));
    });

    frame.appendChild(svg);
    container.appendChild(frame);

    const legend = document.createElement("div");
    legend.className = "diagram-legend";
    const seen = new Set();
    actors.forEach((a) => {
      if (seen.has(a.type)) return;
      seen.add(a.type);
      const item = document.createElement("div");
      item.className = "diagram-legend-item";
      const dot = document.createElement("span");
      dot.className = "diagram-legend-dot";
      dot.style.background = colorFor(a.type);
      const label = document.createElement("span");
      label.textContent = a.type;
      item.appendChild(dot);
      item.appendChild(label);
      legend.appendChild(item);
    });
    const hasReturn = data.steps.some((s) => s.dashed);
    const hasCall = data.steps.some((s) => !s.dashed);
    if (hasCall) legend.appendChild(lineLegendItem("call", { color: cssVar("--accent"), dashed: false }));
    if (hasReturn) legend.appendChild(lineLegendItem("return", { color: "rgba(148,163,184,0.7)", dashed: true }));
    container.appendChild(legend);
  }

  return { renderArchitecture, renderSequence };
})();
