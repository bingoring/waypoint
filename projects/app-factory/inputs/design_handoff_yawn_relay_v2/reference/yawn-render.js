// Yawn! 캐릭터·타일 부품 조합 렌더러 v2. h = (tag, props, ...children) — React.createElement 또는 문자열 SVG 빌더.
// 모든 도형은 64×64 그리드. 정지 프레임은 o.f(프레임 번호)를 주면 애니메이션 없이 그린다.
window.YawnRender = function (h) {
  const INK = '#17151d';
  const ARCH = [
    { id: 'office', name: '직장인', skin: '#f0c6a0', hair: '#2a2420', hs: 'side', outfit: '#3d4a66', outfit2: '#2e3850', acc: 'tie', glasses: true, quirk: 'drool' },
    { id: 'student', name: '학생', skin: '#f3cfae', hair: '#1c1a1e', hs: 'bob', outfit: '#5e6b5a', outfit2: '#4a5547', acc: 'collar', quirk: 'bubble' },
    { id: 'grandma', name: '할머니', skin: '#e9bf9c', hair: '#cfcac4', hs: 'bun', outfit: '#7a5c7e', outfit2: '#5f4763', acc: 'brooch', glasses: true, quirk: 'glasses' },
    { id: 'hiker', name: '등산복 아저씨', skin: '#d9a07a', hair: '#3a2a20', hs: 'cap', cap: '#c9b58a', cap2: '#a8946a', outfit: '#c2563f', outfit2: '#9c4332', acc: 'zip', quirk: 'open' },
    { id: 'college', name: '대학생', skin: '#f1c9a4', hair: '#4a3426', hs: 'messy', outfit: '#4f6f78', outfit2: '#3c565e', acc: 'hood', quirk: 'bubble' },
    { id: 'parent', name: '아이 엄마', skin: '#e4b08c', hair: '#2b211c', hs: 'pony', outfit: '#8a7a5a', outfit2: '#6d6046', acc: 'strap', quirk: 'drool' },
  ];
  const KID = { id: 'kid', name: '까치발 아이', skin: '#f3cfae', hair: '#2a2420', hs: 'messy', outfit: '#4b6a8a', outfit2: '#3a5470', acc: 'collar', quirk: 'open' };
  const POS = { d: { el: [26, 26], er: [38, 26], m: [32, 33] }, l: { el: [20.5, 25.5], er: [28.5, 25.5], m: [21, 32.5] }, r: { el: [35.5, 25.5], er: [43.5, 25.5], m: [43, 32.5] } };
  const ROT = { r: 0, d: 90, l: 180, u: 270 };
  const DV = { u: [0, -1], d: [0, 1], l: [-1, 0], r: [1, 0] };
  const LIGHT = '#e9e6dd', YEL = '#ffcf5a';
  const SK = (w) => ({ stroke: INK, strokeWidth: w == null ? 2 : w, strokeLinejoin: 'round', strokeLinecap: 'round' });
  const L = (k, d, w, c, x) => h('path', Object.assign({ key: k, d, stroke: c || INK, strokeWidth: w || 1.9, fill: 'none', strokeLinecap: 'round', strokeLinejoin: 'round' }, x || {}));
  const Ci = (k, cx, cy, r, fill, x) => h('circle', Object.assign({ key: k, cx, cy, r, fill }, x || {}));
  const El = (k, cx, cy, rx, ry, fill, x) => h('ellipse', Object.assign({ key: k, cx, cy, rx, ry, fill }, x || {}));
  const G = (k, x, ...c) => h('g', Object.assign({ key: k }, x || {}), ...c);
  const wrap = (o, kids, defs) => h('svg', { width: o.size || 64, height: o.size || 64, viewBox: '0 0 64 64', x: o.x, y: o.y, style: { overflow: 'visible', display: 'block' } }, defs ? h('defs', null, defs) : null, kids);
  const arm = (k, x1, y1, x2, y2, col, skin) => [L(k + 'o', `M${x1} ${y1} L${x2} ${y2}`, 9), L(k + 'i', `M${x1} ${y1} L${x2} ${y2}`, 5.5, col), Ci(k + 'h', x2, y2 - 1.5, 4, skin, SK(1.8))];
  const zs = { fontFamily: 'Gaegu, cursive', fontWeight: 700, fill: '#eef2ff', stroke: INK, strokeWidth: 0.9, paintOrder: 'stroke' };
  const zz = (side, f, an) => {
    const x1 = side > 0 ? 6 : 48, x2 = side > 0 ? 2 : 54, dy = f ? -4 : 0;
    return [h('text', { key: 'z1', x: x1, y: 12 + dy, fontSize: 13, style: an ? { ...zs, animation: 'yr-z 2.6s linear infinite', transformBox: 'fill-box' } : zs }, 'z'),
      h('text', { key: 'z2', x: x2, y: 4 + dy, fontSize: 9, style: an ? { ...zs, animation: 'yr-z 2.6s 1.3s linear infinite', transformBox: 'fill-box' } : zs }, 'z')];
  };
  const soundArcs = (k, col, n) => G(k, null, ...[0, 1, 2, 3].map(q => G('d' + q, { transform: `rotate(${q * 90} 32 32)` },
    ...[70, 81, 92].slice(0, n || 3).map((x, j) => L('a' + j, `M${x} 23 Q${x + 6} 32 ${x} 41`, 2.2, col, { opacity: [0.9, 0.6, 0.32][j] })))));
  const ripples = (k, col) => G(k, null, ...[24, 44, 64].map((r, j) => Ci('r' + j, 32, 32, r, 'none', { stroke: col, strokeWidth: [3, 2.4, 1.8][j], opacity: [0.9, 0.6, 0.35][j] })));

  function P(o) {
    const kind = o.kind || 'B';
    if (kind === 'G') return CAT(o);
    const a = o.a || 0, A = kind === 'J' ? KID : ARCH[a % 6], st = o.st || 'awake';
    const uid = (o.uid || 'p') + '-' + a, sf = o.sf || 1, side = o.side || 1, exp = o.exp || 0;
    const stat = o.f != null, f = o.f || 0, an = !stat;
    const yf = st === 'yawn' ? (stat ? f : 1) : -1;
    const sleepy = st === 'asleep' || st === 'nod' || st === 'lean';
    const frontal = (st !== 'awake' && st !== 'drowsy') || kind === 'P';
    const fd = frontal ? 'd' : (o.dir || 'd');
    const skin = A.skin, hair = A.hair, S = SK(2);
    const under = [], back = [], body = [], hd = [], F = [], front = [], top = [];
    const lifted = yf === 1 || yf === 2, lift = lifted ? 'translate(0px,-4px)' : 'none';

    if (yf === 0) back.push(...arm('a', 17, 47, 12, 28, A.outfit, skin), ...arm('b', 47, 47, 52, 28, A.outfit, skin));
    if (lifted) back.push(...arm('a', 17, 47, 9, 14, A.outfit, skin), ...arm('b', 47, 47, 55, 14, A.outfit, skin));
    if (A.acc === 'hood') back.push(El('hd', 32, 37, 17, 8, A.outfit2, S));

    if (kind === 'J') {
      body.push(h('path', { key: 'b', d: 'M14 63 C14 49 21 42 32 42 C43 42 50 49 50 63 Z', fill: A.outfit, ...S }));
      if (st === 'awake' || st === 'glare') body.push(h('rect', { key: 'nk', x: 28.5, y: 30, width: 7, height: 13, fill: skin, ...SK(1.8) }));
    } else body.push(h('path', { key: 'b', d: 'M10 63 C10 47 18 40.5 32 40.5 C46 40.5 54 47 54 63 Z', fill: A.outfit, ...S }));
    if (A.acc === 'tie') {
      body.push(h('path', { key: 'sh', d: 'M25.5 41.5 L32 50 L38.5 41.5 Z', fill: '#efeae0', ...SK(1.4) }));
      body.push(h('path', { key: 'ti', d: 'M30.6 42.5 L33.4 42.5 L32.8 45 L34.2 54 L32 57 L29.8 54 L31.2 45 Z', fill: '#9a4040', ...SK(1.2) }));
    } else if (A.acc === 'collar') body.push(h('path', { key: 'co', d: 'M25 41.5 L32 48.5 L39 41.5 L36 40.8 L32 44.5 L28 40.8 Z', fill: '#efeae0', ...SK(1.4) }));
    else if (A.acc === 'brooch') body.push(L('cd', 'M32 42 L32 63', 1.3), Ci('br', 39, 49, 2.2, '#e2bd55', SK(1.2)));
    else if (A.acc === 'zip') body.push(L('z', 'M32 41 L32 63 M26 41.5 Q32 45 38 41.5', 1.4));
    else if (A.acc === 'hood') body.push(L('hs', 'M29 44 L28.5 52 M35 44 L35.5 52', 1.6, '#efeae0'));
    else if (A.acc === 'strap') body.push(L('st', 'M13 52 L45 41.5', 4.5, '#5a4632'));

    if (kind === 'P') {
      front.push(El('pg', 32, 44, 11, 6, '#9fd0ff', { opacity: 0.3 }));
      front.push(h('rect', { key: 'ph', x: 27, y: 43.5, width: 10, height: 7, rx: 1.5, fill: '#d3ecff', ...SK(1.5) }));
      front.push(Ci('h1', 26.5, 49, 3.2, skin, SK(1.5)), Ci('h2', 37.5, 49, 3.2, skin, SK(1.5)));
    }
    if (kind === 'C') {
      front.push(h('rect', { key: 'cu', x: 41, y: 43, width: 9, height: 11, rx: 2, fill: '#f3eee3', ...SK(1.5) }));
      front.push(h('rect', { key: 'cs', x: 41.8, y: 46.5, width: 7.4, height: 3.5, fill: '#8a5a3c' }));
      front.push(h('rect', { key: 'cl', x: 40.3, y: 41.5, width: 10.4, height: 2.6, rx: 1, fill: '#3a3030', ...SK(1.2) }));
      front.push(Ci('ch', 40.5, 51, 3.2, skin, SK(1.5)));
      if (st === 'awake') front.push(L('stm', 'M44 39 q-2 -3 0 -6 M47.5 39 q-2 -3 0 -6', 1.3, '#cfd6e4', { opacity: 0.7 }));
    }
    if (kind === 'Y') {
      front.push(El('yb', 32, 53, 13, 8, '#e9dcc4', S), L('yf', 'M21 50 Q32 55 43 50', 1.3, '#b9a887'));
      front.push(Ci('yh', 24, 49, 6.5, '#f7d9be', SK(1.6)), h('path', { key: 'yc', d: 'M17.6 47.5 Q24 39.5 30.4 47.5 Z', fill: '#bfd4e6', ...SK(1.4) }));
      const cry = sleepy ? 'sleep' : (o.cry || 'cry');
      if (cry === 'sleep') front.push(L('ye', 'M20.8 49.8 q1.3 1.2 2.6 0 M25 49.8 q1.3 1.2 2.6 0', 1.3), L('ym', 'M23 52.6 q1 .8 2 0', 1.2));
      else if (cry === 'pre') {
        front.push(L('ybr', 'M20.4 46.6 l2.6 1 M27.6 46.6 l-2.6 1', 1.2), L('ye', 'M20.8 49 q1.3 -.9 2.6 0 M25 49 q1.3 -.9 2.6 0', 1.3));
        front.push(L('ym', 'M22.4 53 q.8 -.9 1.6 0 q.8 .9 1.6 0', 1.2), L('yq', 'M14.5 46 l-2.5 -1.2 M14 50 l-3 0 M14.5 54 l-2.5 1.2', 1.4, LIGHT));
      } else {
        front.push(L('ye', 'M20.6 48.6 l2.6 1.2 M27.6 48.6 l-2.6 1.2', 1.4), El('ym', 24, 52.6, 2.3, 2, '#6a1f2c', SK(1)));
        front.push(G('yw', an ? { style: { animation: 'yr-pulse .7s ease-in-out infinite', transformBox: 'fill-box', transformOrigin: 'right' } } : null, L('w', 'M14 44 q-3.5 5 0 10 M9.5 41.5 q-5.5 7.5 0 15', 1.8, LIGHT)));
        front.push(L('yt', 'M19.6 51 q-1.4 2.6 0 3.6', 1.1, '#8fd3ff'));
      }
      front.push(Ci('yhd', 44, 52, 3.2, skin, SK(1.5)));
    }
    if (o.hand) {
      const r = o.hand === 'r', d = r ? 'M44 51 Q54 57 62 55' : 'M20 51 Q10 57 2 55';
      front.push(L('hn', d, 8), L('hn2', d, 5, A.outfit), Ci('hnh', r ? 62 : 2, 55, 3.6, skin, SK(1.6)));
    }
    if (st === 'refuse') {
      front.push(L('ra', 'M17 47 L9 29', 9), L('ra2', 'M17 47 L9 29', 5.5, A.outfit), El('rp', 8, 25, 4.5, 5.5, skin, SK(1.8)));
      front.push(L('rm', 'M1 19 Q-1.5 25 1 31 M-3 21 Q-5 25 -3 29', 1.4, LIGHT));
    }

    // head
    const hc = 'hc-' + uid, hairShapes = [];
    const base = { d: [['e', 32, 13, 17, 8.5]], l: [['e', 42, 19, 12, 13], ['e', 30, 12, 16, 6]], r: [['e', 22, 19, 12, 13], ['e', 34, 12, 16, 6]], u: [['r']] }[fd];
    base.forEach((b, j) => hairShapes.push(b[0] === 'e' ? El('hb' + j, b[1], b[2], b[3], b[4], hair) : h('rect', { key: 'hb' + j, x: 0, y: 0, width: 64, height: 64, fill: hair })));
    if (A.hs === 'bob') ({ d: [[16, 12, 5.5, 22], [42.5, 12, 5.5, 22]], l: [[36, 12, 12, 24]], r: [[16, 12, 12, 24]], u: [] })[fd].forEach((q, j) => hairShapes.push(h('rect', { key: 'bb' + j, x: q[0], y: q[1], width: q[2], height: q[3], fill: hair })));
    if (A.hs === 'cap') hairShapes.push(El('cap', 32, fd === 'u' ? 22 : 13, 18, fd === 'u' ? 16 : 9.5, A.cap));
    if (fd === 'u') hd.push(Ci('e1', 17.8, 27, 3.2, skin, SK(1.6)), Ci('e2', 46.2, 27, 3.2, skin, SK(1.6)));
    if (A.hs === 'pony') { const pp = { d: [45, 13], l: [46.5, 27], r: [17.5, 27], u: [32, 41] }[fd]; hd.push(El('po', pp[0], pp[1], 4.2, 7, hair, S)); }
    hd.push(Ci('hf', 32, 25, 14, skin), G('hr', { clipPath: `url(#${hc})` }, ...hairShapes), Ci('ho', 32, 25, 14, 'none', SK(2.2)));
    if (A.hs === 'bun') hd.push(Ci('bun', 32, 9.5, 5.5, hair, { ...S, style: { transform: lift } }));
    if (A.hs === 'messy') hd.push(h('path', { key: 'mess', d: 'M20.5 15 L22 7.5 L26.5 12 L30 4.5 L34 11 L39 6 L42.5 14', fill: hair, ...SK(1.8) }));
    if (A.hs === 'cap') { const v = { d: [32, 15.5, 13, 3.6], l: [16.5, 16, 7, 3], r: [47.5, 16, 7, 3], u: [32, 9.5, 11, 3] }[fd]; hd.push(El('vis', v[0], v[1], v[2], v[3], A.cap2, { ...SK(1.6), style: { transform: lift } })); }
    if (kind === 'E') {
      const band = { d: 'M17 25 A15 15 0 0 1 47 25', u: 'M17 25 A15 15 0 0 1 47 25', l: 'M25 11.5 Q41 8.5 45.5 21', r: 'M39 11.5 Q23 8.5 18.5 21' }[fd];
      const cups = { d: [13, 44], u: [13, 44], l: [41.5], r: [15.5] }[fd];
      hd.push(L('hpb', band, 5.6), L('hpb2', band, 3.2, '#4a5060'));
      cups.forEach((x, j) => hd.push(h('rect', { key: 'hpc' + j, x, y: 19, width: 7, height: 12.5, rx: 3, fill: '#4a5060', ...SK(1.6) }), L('hpl' + j, `M${x + 2.2} 22 L${x + 2.2} 28.5`, 1.2, '#7c8496')));
    }

    // face
    let glY = 0, glR = 0;
    if (fd !== 'u') {
      const p = POS[fd], el = p.el, er = p.er, m = p.m;
      if (yf >= 0) {
        if (yf === 0 || yf === 3) F.push(L('ey', 'M22.5 26.5 Q25.5 27.8 28.5 26.5 M35.5 26.5 Q38.5 27.8 41.5 26.5', 2));
        else F.push(L('br', 'M22 19 Q25.5 16.5 29 18.5 M35 18.5 Q38.5 16.5 42 19', 1.8), L('ey', 'M22.5 22.5 L28 25.5 L22.5 27.5 M41.5 22.5 L36 25.5 L41.5 27.5', 2.1));
        if (kind !== 'K') {
          const mo = [[6, 7.5, 36.5], [8.5, 13, 39], [8.5, 12.5, 39], [4.5, 4, 34.5]][yf];
          F.push(El('mo', 32, mo[2], mo[0], mo[1], '#6a1f2c', S));
          if (yf === 1 || yf === 2) F.push(El('to', 32, 47, 5.5, 4, '#e2787f'));
        }
        if (an) {
          F.push(h('path', { key: 't1', d: 'M19 23 q-2.2 3 0 4.6 q2.2 -1.6 0 -4.6', fill: '#8fd3ff', ...SK(1), style: o.loop ? {} : { animation: `yr-tearL ${520 * sf}ms both` } }));
          F.push(h('path', { key: 't2', d: 'M45 23 q-2.2 3 0 4.6 q2.2 -1.6 0 -4.6', fill: '#8fd3ff', ...SK(1), style: o.loop ? {} : { animation: `yr-tearR ${520 * sf}ms both` } }));
        } else if (yf >= 1) {
          const dx = yf === 2 ? 7 : 0, dy = yf === 2 ? 5 : 0;
          F.push(h('path', { key: 't1', d: `M${19 - dx} ${23 - dy} q-2.2 3 0 4.6 q2.2 -1.6 0 -4.6`, fill: '#8fd3ff', ...SK(1) }), h('path', { key: 't2', d: `M${45 + dx} ${23 - dy} q-2.2 3 0 4.6 q2.2 -1.6 0 -4.6`, fill: '#8fd3ff', ...SK(1) }));
        }
        glY = lifted ? -5 : -2;
      } else if (sleepy) {
        F.push(L('ey', 'M22.5 26 Q25.5 28.5 28.5 26 M35.5 26 Q38.5 28.5 41.5 26', 2));
        const q = st !== 'asleep' || kind === 'K' || kind === 'T' ? 'none' : kind === 'N' ? 'snore' : A.quirk;
        if (q === 'snore') {
          const big = stat ? f === 1 : true, r = big ? 7 : 3.5;
          F.push(Ci('sn', 37 + r * 0.4, 30, r, '#bfe9ff', { fillOpacity: 0.9, ...SK(1.2), style: an ? { animation: 'yr-snot 1.3s ease-in-out infinite', transformBox: 'fill-box', transformOrigin: 'left' } : {} }));
        }
        if (q === 'open' || q === 'glasses' || q === 'snore') F.push(El('mo', 32, 33.5, 3, 3.6, '#6a1f2c', SK(1.6)));
        else if (st === 'nod') F.push(L('mo', 'M30 33.5 L34 33.5', 1.8));
        else F.push(L('mo', 'M29 33 Q32 35 35 33', 1.8));
        if (q === 'drool') F.push(h('path', { key: 'dr', d: 'M34.5 34 q1.8 4 0 6.5 q-1.8 -2.5 0 -6.5', fill: '#9fd8ff', ...SK(1), style: an ? { animation: 'yr-drool 2.6s ease-in-out infinite', transformBox: 'fill-box', transformOrigin: 'top' } : (f ? { transform: 'scaleY(1.25)', transformBox: 'fill-box', transformOrigin: 'top' } : {}) }));
        if (q === 'bubble') F.push(Ci('sb', 36.5, 30, stat ? (f ? 4.6 : 2.2) : 4, '#bfe9ff', { fillOpacity: 0.85, ...SK(1), style: an ? { animation: 'yr-snot 2.6s ease-in-out infinite', transformBox: 'fill-box', transformOrigin: 'left' } : {} }));
        glY = 5; glR = 14;
      } else if (st === 'refuse') {
        F.push(L('br', 'M22 20 L29 22.5 M42 20 L35 22.5', 2.2), Ci('e1', 26, 26.5, 2, INK), Ci('e2', 38, 26.5, 2, INK), L('mo', 'M28.5 34.5 Q32 31.5 35.5 34.5', 2));
      } else if (st === 'glare') {
        F.push(L('br', 'M19.5 16.5 L29 20.5 M44.5 16.5 L35 20.5', 2.6));
        F.push(Ci('e1', 25.5, 26, 6, '#fff', SK(1.8)), Ci('e2', 38.5, 26, 6, '#fff', SK(1.8)), Ci('p1', 25.5, 26, 1.5, INK), Ci('p2', 38.5, 26, 1.5, INK));
        F.push(L('vn', 'M20.5 24 L22.5 25 M43.5 24 L41.5 25', 0.9), L('mo', 'M26.5 35.5 L28.5 34 L30.5 35.5 L32.5 34 L34.5 35.5 L36.5 34', 1.8));
        F.push(h('path', { key: 'sw', d: 'M47 13 q-2.5 3.5 0 5.2 q2.5 -1.7 0 -5.2', fill: '#8fd3ff', ...SK(1) }));
      } else if (st === 'startle' || st === 'turn') {
        const big = st === 'startle';
        F.push(L('br', big ? 'M19.5 15.5 Q24.5 11.5 29.5 14.5 M34.5 14.5 Q39.5 11.5 44.5 15.5' : 'M22 19.5 Q25.5 17.5 29 19 M35 19 Q38.5 17.5 42 19.5', 2));
        F.push(Ci('e1', 25.5, 25, big ? 5.2 : 3.6, '#fff', SK(1.7)), Ci('e2', 38.5, 25, big ? 5.2 : 3.6, '#fff', SK(1.7)), Ci('p1', 25.5, 25, 1.3, INK), Ci('p2', 38.5, 25, 1.3, INK));
        F.push(big ? El('mo', 32, 34.5, 2.8, 3.6, '#6a1f2c', SK(1.6)) : L('mo', 'M30 34 L34 34', 1.8));
      } else if (kind === 'P') {
        F.push(El('gl', 32, 30, 12, 9, '#a9d6ff', { opacity: 0.32 }), El('e1', el[0], el[1] + 1.5, 2.2, 1.4, INK), El('e2', er[0], er[1] + 1.5, 2.2, 1.4, INK));
        F.push(L('ld', `M${el[0] - 3} ${el[1] - 0.2} L${el[0] + 3} ${el[1] - 0.2} M${er[0] - 3} ${er[1] - 0.2} L${er[0] + 3} ${er[1] - 0.2}`, 1.5), L('mo', 'M30.5 34 L33.5 34', 1.6));
      } else if (kind === 'M') {
        const off = { d: [0, 1], l: [-1.2, 0], r: [1.2, 0] }[fd];
        [el, er].forEach((e, j) => {
          F.push(Ci('w' + j, e[0], e[1], 3.9, '#fff', SK(1.5)), Ci('q' + j, e[0] + off[0], e[1] + off[1] + (st === 'drowsy' ? 1.4 : 0), 1.9, INK));
          if (st === 'drowsy') F.push(h('path', { key: 'lid' + j, d: `M${e[0] - 3.9} ${e[1] + 0.3} A3.9 3.9 0 0 1 ${e[0] + 3.9} ${e[1] + 0.3} Z`, fill: skin, ...SK(1.5) }));
        });
        F.push(st === 'drowsy' ? L('mo', `M${m[0] - 2.5} ${m[1] + 0.5} Q${m[0]} ${m[1] + 2} ${m[0] + 2.5} ${m[1] + 0.5}`, 1.7) : L('mo', `M${m[0] - 2} ${m[1]} L${m[0] + 2} ${m[1]}`, 1.8));
      } else if (kind === 'O') {
        [el, er].forEach((e, j) => F.push(L('sq' + j, `M${e[0] - 3} ${e[1] + 0.6} Q${e[0]} ${e[1] - 1.8} ${e[0] + 3} ${e[1] + 0.6}`, 2.2)));
        F.push(L('sqs', `M${el[0] - 4.6} ${el[1] - 2.4} l-1.6 -1 M${er[0] + 4.6} ${er[1] - 2.4} l1.6 -1`, 1.1));
        F.push(L('mo', `M${m[0] - 2.4} ${m[1] + 0.4} Q${m[0]} ${m[1] - 1} ${m[0] + 2.4} ${m[1] + 0.4}`, 1.7));
      } else {
        if (o.blink) F.push(L('ey', `M${el[0] - 2.4} ${el[1] + 0.4} L${el[0] + 2.4} ${el[1] + 0.4} M${er[0] - 2.4} ${er[1] + 0.4} L${er[0] + 2.4} ${er[1] + 0.4}`, 2));
        else {
          const blink = an ? { style: { animation: `yr-blink ${3.2 + (a % 3) * 0.7}s ${(a % 4) * 0.4}s infinite`, transformBox: 'fill-box', transformOrigin: 'center' } } : null;
          F.push(G('ey', blink, El('a', el[0], el[1], 2.2, 2.7, INK), El('b', er[0], er[1], 2.2, 2.7, INK)));
        }
        if (kind === 'C') F.push(L('br', `M${el[0] - 3} ${el[1] - 4.8} L${el[0] + 3} ${el[1] - 3.6} M${er[0] - 3} ${er[1] - 3.6} L${er[0] + 3} ${er[1] - 4.8}`, 1.8), L('mo', `M${m[0] - 3} ${m[1]} Q${m[0] + 1} ${m[1] + 1.6} ${m[0] + 3.5} ${m[1] - 1}`, 1.8));
        else F.push(L('mo', `M${m[0] - 2.4} ${m[1]} L${m[0] + 2.4} ${m[1]}`, 1.8));
      }
      if (kind === 'K') {
        if (yf >= 0) {
          const mk = [[10.5, 8.5, 36], [13, 12, 38.5], [14.5, 13, 39], [11, 9, 37]][yf];
          F.push(L('ml', 'M19.5 27 L22 34 M44.5 27 L42 34', 1.2));
          F.push(El('mk', 32, mk[2], mk[0], mk[1], '#eef1f4', S));
          F.push(L('mf', `M${32 - mk[0] + 3} ${mk[2] - 3} Q32 ${mk[2]} ${32 + mk[0] - 3} ${mk[2] - 3} M${32 - mk[0] + 2.5} ${mk[2] + 3} Q32 ${mk[2] + 6} ${32 + mk[0] - 2.5} ${mk[2] + 3}`, 1.2, '#9aa2ad'));
          if (yf === 1 || yf === 2) F.push(L('mp', 'M15 37 l-4 0 M16 31 l-3.5 -2 M49 37 l4 0 M48 31 l3.5 -2', 1.4, LIGHT));
        } else {
          const mx = fd === 'l' ? 24 : fd === 'r' ? 40 : 32;
          F.push(G('mk', { clipPath: `url(#${hc})` }, h('rect', { x: mx - 12, y: 28.5, width: 24, height: 12, rx: 4, fill: '#eef1f4', ...SK(1.6) }), L('mkf', `M${mx - 8} 32.5 L${mx + 8} 32.5 M${mx - 8} 36 L${mx + 8} 36`, 1, '#b9c0c9')));
          if (fd === 'd' || st !== 'awake') F.push(L('el', 'M20 31 L18.5 26 M44 31 L45.5 26', 1.2));
        }
      }
      if (fd === 'l') F.push(L('no', 'M18.6 27 q-2.4 1.3 0 2.6', 1.6));
      if (fd === 'r') F.push(L('no', 'M45.4 27 q2.4 1.3 0 2.6', 1.6));
      if (A.glasses && st !== 'glare') {
        const fr = frontal, gy = fr ? 26 : el[1], ex = fr ? [25.5, 38.5] : [el[0], er[0]];
        F.push(G('gls', { style: { transform: `translate(0px,${glY}px) rotate(${glR}deg)`, transformOrigin: '32px 26px' } },
          Ci('a', ex[0], gy, 4.6, 'rgba(255,255,255,.18)', { stroke: INK, strokeWidth: 1.6 }), Ci('b', ex[1], gy, 4.6, 'rgba(255,255,255,.18)', { stroke: INK, strokeWidth: 1.6 }),
          L('c', `M${ex[0] + 4.6} ${gy} L${ex[1] - 4.6} ${gy}`, 1.6)));
      }
    }
    if (kind === 'O') {
      // 근시: 안경을 이마 위에. 꾸벅·잠들면 떨어진다
      let gy = 0, gr = 0, gx = 0;
      if (st === 'nod') { gy = [6, 14, 24][stat ? f : 2]; gr = side * [12, 26, 44][stat ? f : 2]; gx = side * [1, 3, 6][stat ? f : 2]; }
      else if (st === 'asleep' || st === 'lean') { gy = 31; gr = side * 64; gx = side * 8; }
      else if (yf >= 0) gy = lifted ? -4 : -1;
      const cx = fd === 'l' ? [21, 29.5] : fd === 'r' ? [34.5, 43] : [26, 38];
      const gl = G('ogl', { style: { transform: `translate(${gx}px,${gy}px) rotate(${gr}deg)`, transformOrigin: '32px 14px' } },
        Ci('a', cx[0], 14, 4.2, 'rgba(200,230,255,.35)', { stroke: INK, strokeWidth: 1.7 }), Ci('b', cx[1], 14, 4.2, 'rgba(200,230,255,.35)', { stroke: INK, strokeWidth: 1.7 }),
        L('c', `M${cx[0] + 4.2} 14 L${cx[1] - 4.2} 14`, 1.7), L('d', `M${cx[0] + 1} 12.5 l1.6 -1.2`, 1, '#ffffff'));
      if (st === 'asleep' || st === 'lean' || (st === 'nod' && (stat ? f : 2) === 2)) front.push(gl); else hd.push(gl);
    }

    if (st !== 'asleep' && kind === 'M') {
      const left = Math.max(0, 2 - exp);
      top.push(G('bdg', null, h('rect', { x: 47, y: 1, width: 15, height: 11, rx: 5.5, fill: '#f4f1ea', stroke: INK, strokeWidth: 1.3 }),
        Ci('a', 51.5, 6.5, 2, left >= 1 ? INK : 'none', { stroke: INK, strokeWidth: 1.1 }), Ci('b', 57.5, 6.5, 2, left >= 2 ? INK : 'none', { stroke: INK, strokeWidth: 1.1 })));
    }
    if (st !== 'asleep' && kind === 'S') {
      top.push(G('bdg', null, Ci('a', 55, 7, 6.5, '#f4f1ea', { stroke: INK, strokeWidth: 1.3 }),
        L('b', 'M51.6 7.5 A3.5 3.5 0 1 1 55 10.5', 1.4), L('c', 'M49.8 6.2 L51.6 8.6 L53.6 6.6', 1.3)));
    }
    if (kind === 'E' && st === 'awake' && !o.bounce) top.push(G('note', null, El('a', 52, 11.5, 2.4, 1.8, LIGHT, SK(1)), L('b', 'M54.2 11 L54.2 3 Q58 3.8 58.5 7', 1.4, LIGHT)));
    if (o.bounce) {
      top.push(L('bin', 'M-2 18 Q-6 25 -2 32 M-9 15 Q-14 25 -9 35', 2, LIGHT, { opacity: 0.8 }));
      top.push(L('bsc', 'M10 14 l-6 -5 M9 36 l-6 5 M6 25 l-7 0', 2, YEL));
      top.push(G('bst', null, L('a', 'M12 25 l-3 -3 M12 25 l-3 3', 1.6, YEL)));
    }
    if (st === 'startle') {
      top.push(h('text', { key: 'ex', x: 50, y: 11, fontSize: 20, style: { fontFamily: 'Gaegu, cursive', fontWeight: 700, fill: YEL, stroke: INK, strokeWidth: 1, paintOrder: 'stroke' } }, '!'));
      top.push(L('sh', 'M9 6 l4 4 M4 15 l5 1.5 M55 18 l5 -1', 1.6, LIGHT));
    }
    if (st === 'turn') top.push(L('tn', 'M18 -1 Q32 -9 46 -1', 2, LIGHT), L('tn2', 'M42 -5 L46 -1 L41 0.5', 2, LIGHT));
    if (kind === 'Y' && o.waves && !sleepy) top.push(an ? G('vib', { style: { animation: 'yr-pulse .7s ease-in-out infinite', transformBox: 'fill-box', transformOrigin: 'center' } }, soundArcs('sa', LIGHT, 3)) : soundArcs('sa', LIGHT, 3));
    if (st === 'asleep' && kind === 'N') {
      const big = stat ? f === 1 : true;
      if (o.waves || (an && big)) top.push(an ? G('vib', { style: { animation: 'yr-pulse 1.3s ease-in-out infinite', transformBox: 'fill-box', transformOrigin: 'center' } }, soundArcs('sa', LIGHT, o.waves ? 3 : 1)) : soundArcs('sa', LIGHT, 3));
      else if (!big) top.push(L('vib', 'M9 24 q-3 4 0 8 M55 24 q3 4 0 8', 1.4, LIGHT, { opacity: 0.6 }));
      if (big) top.push(h('text', { key: 'snt', x: 32, y: -2, textAnchor: 'middle', fontSize: 14, style: { fontFamily: 'Gaegu, cursive', fontWeight: 700, fill: '#fffaf0', stroke: INK, strokeWidth: 1, paintOrder: 'stroke' } }, '드르렁'));
    }
    if (st === 'asleep' && kind === 'T') {
      const t = o.fly, dv = DV[o.flyDir || 'r'];
      const tx = t == null ? 0 : dv[0] * 64 * t - (t ? 6 * t : 0), ty = t == null ? 0 : dv[1] * 64 * t - 14 * Math.sin(Math.PI * t);
      if (t != null && t > 0) top.push(L('trj', `M46 -2 Q${46 + dv[0] * 32} ${-14 + dv[1] * 32} ${46 + dv[0] * 64 - 6} ${-2 + dv[1] * 64}`, 1.6, LIGHT, { strokeDasharray: '1.5 4', opacity: 0.7 }));
      top.push(G('tk', an && t == null ? { style: { animation: 'yr-pulse 2s ease-in-out infinite', transformBox: 'fill-box', transformOrigin: 'left bottom' } } : { transform: `translate(${tx} ${ty})` },
        h('path', { d: 'M38 -9 h22 a6 6 0 0 1 6 6 v4 a6 6 0 0 1 -6 6 h-14 l-6 5 l1 -5 h-3 a6 6 0 0 1 -6 -6 v-4 a6 6 0 0 1 6 -6 z', fill: '#fffaf0', stroke: INK, strokeWidth: 1.4, strokeLinejoin: 'round' }),
        L('s', 'M38 -1 q2 -4 4 0 t4 0 t4 0 M53 -4 l3 3 m0 -3 l-3 3 M58.5 -3.5 q2 -2 3 0 q-1 2 -3 3', 1.3)));
    }
    if ((st === 'asleep' || st === 'lean') && kind !== 'N' && kind !== 'T') top.push(...zz(side, stat ? f : 0, an));
    if (o.step) {
      top.push(G('stp', { transform: `rotate(${ROT[o.dir || 'r']} 32 32)` },
        L('ch', 'M66 27 L71 32 L66 37', 2.2, LIGHT, { opacity: 0.85 }),
        El('f1', 76, 28, 2.6, 1.8, LIGHT, { opacity: 0.45 }), El('f2', 82, 35, 2.6, 1.8, LIGHT, { opacity: 0.3 })));
    }

    let ht = 'none';
    if (st === 'asleep') ht = `translate(${side * 3}px,5px) rotate(${side * 26}deg)`;
    else if (st === 'nod') { const k = stat ? f : 2; ht = `translate(${side * [1, 2, 3][k]}px,${[1.5, 3, 5][k]}px) rotate(${side * [8, 18, 26][k]}deg)`; }
    else if (st === 'lean') ht = `translate(${side * 7}px,6px) rotate(${side * 34}deg)`;
    else if (kind === 'P') ht = 'translate(0px,2.5px)';
    else if (kind === 'J' && (st === 'awake' || st === 'glare')) ht = 'translate(0px,-7px)';
    const headG = G('head', { style: { transform: ht, transformOrigin: '32px 40px', transition: an ? `transform ${200 * sf}ms cubic-bezier(.5,-0.4,.6,1.5)` : undefined } }, ...hd, ...F);

    let ws = {};
    const so = { transformOrigin: '32px 63px' };
    if (yf >= 0) ws = stat ? { transform: [`scale(.95,1.12)`, `scale(.88,1.3)`, `scale(1.1,.86)`, `scale(.97,1.04)`][f], ...so } : { animation: o.loop ? 'yr-yawnloop 2.4s infinite' : `yr-yawn ${520 * sf}ms both`, ...so };
    else if (st === 'refuse') ws = an ? { animation: `yr-shake ${350 * sf}ms`, ...so } : { transform: 'translateX(-4px) rotate(-4deg)', ...so };
    else if (st === 'startle') ws = { transform: 'translateY(-3px) scale(1.04,1.04)', ...so };
    else if (st === 'asleep' || st === 'lean') ws = an ? { animation: 'yr-breathe 2.6s ease-in-out infinite', ...so } : (f ? { transform: 'scale(1.025,.97)', ...so } : {});

    let person = G('ws', { style: ws }, ...back, ...body, headG, ...front);
    if (kind === 'W') {
      const k = o.walk;
      const legs = k === 0 ? ['M28 44 L23.5 61', 'M36 44 L39 61'] : k === 1 ? ['M28 44 L31 61', 'M36 44 L33 61'] : ['M28 44 L27.5 61', 'M36 44 L36.5 61'];
      legs.forEach((d, j) => under.push(L('lo' + j, d, 8.5), L('li' + j, d, 5.5, '#2f3542')));
      legs.forEach((d, j) => { const e = d.split(' ').slice(-2).map(Number); under.push(El('sh' + j, e[0] + 1, e[1] + 0.5, 4, 2.3, '#2a2420', SK(1.4))); });
      const sway = st === 'asleep' ? `rotate(${side * 7} 47 -4)` : '';
      under.push(L('strap', 'M47 -16 L47 -8', 2.4, '#8b93a0'), Ci('ring', 47, -4, 4.2, 'none', { stroke: INK, strokeWidth: 4 }), Ci('ring2', 47, -4, 4.2, 'none', { stroke: '#c9ccd4', strokeWidth: 2 }));
      person = G('wp', { transform: sway }, L('arm', 'M42 32 L47 1', 8), L('arm2', 'M42 32 L47 1', 5, A.outfit), Ci('hand', 47, 0, 3.4, skin, SK(1.6)), ...under.slice(0), G('sc', { transform: 'translate(5 -10) scale(.84)' }, person));
      under.length = 0;
    }
    const outer = G('t' + (o.tapK || 0), o.tapK ? { style: { animation: `yr-tap ${120 * sf}ms`, transformOrigin: '32px 63px' } } : null, ...under, person, ...top);
    return wrap(o, outer, h('clipPath', { id: hc }, Ci('c', 32, 25, 14)));
  }

  function CAT(o) {
    const st = o.st || 'awake', stat = o.f != null, f = o.f || 0, an = !stat;
    const yf = st === 'yawn' ? (stat ? f : 1) : -1;
    const fur = '#9b948a', fur2 = '#6f6a62', S = SK(2);
    const k = [], top = [];
    if (o.wave) k.push(ripples('wv', '#f2a7c3'));
    const glare = st === 'glare';
    const tail = st === 'asleep' ? null : glare ? 'M51 50 Q63 46 59 32' : (stat ? f % 2 : 0) ? 'M51 50 Q64 50 62 38' : 'M51 50 Q61 44 57 34';
    if (tail) k.push(L('tlo', tail, glare ? 12 : 7.5), L('tli', tail, glare ? 9 : 4.5, fur, an && st === 'awake' ? { style: { animation: 'yr-pulse 1.8s ease-in-out infinite', transformBox: 'fill-box', transformOrigin: 'left bottom' } } : null));
    k.push(L('hdl', 'M19 41 Q19 30 26 30 M45 41 Q45 30 38 30', 2.4, '#5a3e28'));
    if (st === 'asleep') {
      k.push(El('cb', 32, 40, 16, 8, fur, S), L('cst', 'M26 34.5 l1 3 M32 33 l0 3 M38 34.5 l-1 3', 1.4, fur2));
      k.push(Ci('ch', 23, 38.5, 8.5, fur, S), h('path', { key: 'ce1', d: 'M16.5 34 L16 27.5 L21 31 Z', fill: fur, ...SK(1.6) }), h('path', { key: 'ce2', d: 'M25.5 31 L29 26.5 L30 32.5 Z', fill: fur, ...SK(1.6) }));
      k.push(L('cey', 'M19 39 q1.5 1.3 3 0 M24.5 39 q1.5 1.3 3 0', 1.4), L('ctl', 'M47 42 Q50 48 40 47.5 Q30 47 28 44', 4.5, fur, { stroke: fur }), L('ctlo', 'M47 42 Q50 48 40 47.5 Q30 47 28 44', 1.4));
    } else {
      const ly = yf === 1 || yf === 2 ? -3 : 0;
      const ears = (yf >= 1 && yf <= 2) || glare ? ['M22.5 25 L13 19 L21.5 17.5 Z', 'M41.5 25 L51 19 L42.5 17.5 Z'] : ['M22 25 L21 13 L29 20 Z', 'M42 25 L43 13 L35 20 Z'];
      const g = [];
      ears.forEach((d, j) => g.push(h('path', { key: 'e' + j, d, fill: fur, ...SK(1.8) })));
      g.push(Ci('hd', 32, 30, 12, fur, S), L('fs', 'M28.5 20.5 l1 3.5 M32 19.5 l0 4 M35.5 20.5 l-1 3.5', 1.4, fur2));
      if (yf >= 0) {
        if (yf === 0 || yf === 3) g.push(L('ey', 'M24.5 29 q2.5 1 5 0 M34.5 29 q2.5 1 5 0', 1.8));
        else g.push(L('ey', 'M24.5 26.5 L29 28.5 L24.5 30 M39.5 26.5 L35 28.5 L39.5 30', 1.8));
        const mo = [[4, 4, 36], [6.5, 8, 38], [6.5, 7.5, 38], [3, 2.4, 35]][yf];
        g.push(El('mo', 32, mo[2], mo[0], mo[1], '#6a1f2c', SK(1.8)));
        if (yf === 1 || yf === 2) g.push(El('tg', 32, mo[2] + 4.5, 3.6, 2.6, '#e2787f'), L('fg', `M28.5 ${mo[2] - 6} l.8 2 M35.5 ${mo[2] - 6} l-.8 2`, 1.4, '#fff'));
        if (stat && yf === 2) g.push(h('path', { key: 't1', d: 'M17 24 q-2 2.7 0 4.2 q2 -1.5 0 -4.2', fill: '#8fd3ff', ...SK(1) }), h('path', { key: 't2', d: 'M47 24 q-2 2.7 0 4.2 q2 -1.5 0 -4.2', fill: '#8fd3ff', ...SK(1) }));
      } else if (glare) {
        g.push(L('br', 'M23 24.5 L29.5 27 M41 24.5 L34.5 27', 2.2));
        g.push(El('e1', 27, 29.5, 3.8, 3.8, '#e6ec86', SK(1.5)), El('e2', 37, 29.5, 3.8, 3.8, '#e6ec86', SK(1.5)), El('p1', 27, 29.5, 0.6, 3, INK), El('p2', 37, 29.5, 0.6, 3, INK));
        g.push(h('path', { key: 'ns', d: 'M30.5 34 L33.5 34 L32 35.8 Z', fill: '#d98a8a', ...SK(1) }));
        g.push(h('path', { key: 'mo', d: 'M27.5 37 Q32 35.5 36.5 37 L36 40 Q32 41.5 28 40 Z', fill: '#6a1f2c', ...SK(1.5) }), L('fg', 'M29.5 37 l.6 2 M34.5 37 l-.6 2', 1.3, '#fff'));
        g.push(L('hs', 'M15 22 l-4 -2 M14 27 l-4.5 0 M49 22 l4 -2 M50 27 l4.5 0', 1.6, LIGHT));
      } else {
        g.push(El('e1', 27, 29.5, 3.1, 3.4, '#d6dc7a', SK(1.4)), El('e2', 37, 29.5, 3.1, 3.4, '#d6dc7a', SK(1.4)), El('p1', 27, 29.5, 0.9, 2.6, INK), El('p2', 37, 29.5, 0.9, 2.6, INK));
        g.push(h('path', { key: 'ns', d: 'M30.5 34 L33.5 34 L32 35.8 Z', fill: '#d98a8a', ...SK(1) }), L('mo', 'M29.5 37 q1.25 1.4 2.5 0 q1.25 1.4 2.5 0', 1.3));
      }
      g.push(L('wh', 'M24 34 l-7 -1 M24 36.5 l-7 1.5 M40 34 l7 -1 M40 36.5 l7 1.5', 1, LIGHT));
      k.push(G('head', { style: { transform: `translate(0px,${ly}px)` } }, ...g));
      k.push(El('pw1', 25, 41.5, 3.6, 2.6, fur, SK(1.6)), El('pw2', 39, 41.5, 3.6, 2.6, fur, SK(1.6)));
    }
    k.push(h('path', { key: 'bag', d: 'M11 42 L53 42 L56.5 63 L7.5 63 Z', fill: '#a8734a', ...S }), L('bagl', 'M9.5 51 L54.5 51', 1.6, '#7f5434'));
    if (st === 'asleep' && an) top.push(...zz(1, 0, true));
    else if (st === 'asleep') top.push(...zz(1, f, false));
    return wrap(o, G('cat', null, ...k, ...top));
  }

  function tile(type, o) {
    o = o || {};
    const S = SK(1.6), st = o.st || 'idle', n = o.n == null ? 2 : o.n, uid = o.uid || type;
    const bg = (c) => h('rect', { key: 'bg', x: 3, y: 3, width: 58, height: 58, rx: 10, fill: c || '#252a35' });
    const badge = (v, dim) => G('bd', null, Ci('a', 54, 9, 9, dim ? '#6b7080' : YEL, S), h('text', { x: 54, y: 13.2, textAnchor: 'middle', style: { fontFamily: 'IBM Plex Mono, monospace', fontWeight: 600, fontSize: 12, fill: INK } }, String(v)));
    let kids = [], defs = null;
    if (type === 'window') {
      defs = h('linearGradient', { id: 'wg-' + uid, x1: 0, y1: 0, x2: 1, y2: 1 }, h('stop', { offset: 0, stopColor: '#2e5a6e' }), h('stop', { offset: 1, stopColor: '#1c3341' }));
      kids = [h('rect', { key: 'w', x: 4, y: 4, width: 56, height: 56, rx: 8, fill: `url(#wg-${uid})`, stroke: 'rgba(160,215,235,.5)', strokeWidth: 1.5 }),
        L('s', (o.m || '/') === '/' ? 'M10 54 L54 10 M24 58 L58 24' : 'M10 10 L54 54 M24 6 L58 40', 3, '#c7ecf7', { opacity: 0.85 })];
    } else if (type === 'pole') {
      defs = h('radialGradient', { id: 'pg-' + uid, cx: '38%', cy: '35%', r: '70%' }, h('stop', { offset: 0, stopColor: '#ffffff' }), h('stop', { offset: 0.45, stopColor: '#c3ccd6' }), h('stop', { offset: 1, stopColor: '#6f7a88' }));
      kids = [bg()];
      if (st !== 'idle') kids.push(L('in', 'M32 62 L32 44', 2, 'rgba(236,228,205,.6)', { strokeDasharray: '2 4' }));
      if (st === 'split') kids.push(L('sp', 'M22 32 L6 32 M10 28 L5.5 32 L10 36 M42 32 L58 32 M54 28 L58.5 32 L54 36', 2.6, YEL));
      if (st === 'blocked') kids.push(L('sp', 'M22 32 L8 32 M42 32 L58 32 M54 28 L58.5 32 L54 36', 2.6, YEL), L('x', 'M3 27 L3 37', 3.2, LIGHT), L('x2', 'M-1 27.5 L7 36.5 M7 27.5 L-1 36.5', 2.2, '#e2787f'));
      kids.push(El('sh', 32, 35, 10, 4, 'rgba(0,0,0,.35)'), Ci('p', 32, 32, 9, `url(#pg-${uid})`, S), L('hl', 'M28.5 26 q2 -2 4.5 -1.5', 1.6, '#fff'));
      if (st === 'idle') kids.push(L('sp', 'M46 10 l0 8 M42 14 l8 0', 1.6, '#fff'));
    } else if (type === 'door') {
      // 승객 칸 위에 얹는 「문 표시」 레이어: 문틀 + 상인방 + 남은 박자 배지. 배경 없음 — 좌석·승객이 비친다.
      const open = st === 'open';
      kids.push(h('rect', { key: 'fr', x: 2.5, y: 2.5, width: 59, height: 59, rx: 10, fill: 'none', stroke: '#56627a', strokeWidth: 3.6 }));
      kids.push(h('rect', { key: 'fr2', x: 0.8, y: 0.8, width: 62.4, height: 62.4, rx: 11.5, fill: 'none', stroke: INK, strokeWidth: 1.2 }));
      kids.push(h('rect', { key: 'lt', x: 16, y: -1.5, width: 32, height: 6, rx: 2.5, fill: '#56627a', ...SK(1.3) }), Ci('ltl', 32, 1.5, 1.6, open ? YEL : '#2a3140'));
      if (open) {
        kids.push(h('rect', { key: 'glow', x: 10, y: 5, width: 44, height: 55, rx: 4, fill: YEL, opacity: 0.16 }));
        kids.push(h('rect', { key: 'l', x: 3, y: 5, width: 8, height: 55, rx: 2, fill: '#56627a', ...S }), h('rect', { key: 'r', x: 53, y: 5, width: 8, height: 55, rx: 2, fill: '#56627a', ...S }));
        kids.push(L('ar', 'M15 10 l-4 -3 M15 10 l-4 3 M49 10 l4 -3 M49 10 l4 3', 1.6, LIGHT));
      } else kids.push(badge(n));
    } else if (type === 'alarm') {
      const ring = st === 'ring', off = st === 'off';
      const body = G('clk', ring ? { transform: `rotate(${o.f ? 9 : -9} 32 38)` } : null,
        L('lg', 'M23 49 l-3 5 M41 49 l3 5', 2.4),
        h('path', { key: 'b1', d: 'M17 25 A7 7 0 0 1 28 18 Z', fill: off ? '#8c8778' : '#d6b04a', ...S }),
        h('path', { key: 'b2', d: 'M47 25 A7 7 0 0 0 36 18 Z', fill: off ? '#8c8778' : '#d6b04a', ...S }),
        L('hm', 'M32 20 L32 16 M29 16 L35 16', 1.8),
        Ci('f', 32, 37, 14, off ? '#a8a395' : '#efe8d6', SK(2.2)), Ci('f2', 32, 37, 10.5, 'none', { stroke: '#cfc6ae', strokeWidth: 1 }),
        L('hd', 'M32 37 L32 29.5 M32 37 L37.5 39.5', 2), Ci('c', 32, 37, 1.6, INK));
      kids = [bg()];
      if (ring) kids.push(L('rg', 'M9 16 l-4 -3 M7 26 l-5 0 M55 16 l4 -3 M57 26 l5 0 M13 8 l-2 -4 M51 8 l2 -4', 2, YEL));
      kids.push(body);
      if (!off && !ring) kids.push(badge(n));
      if (off) kids.push(L('zz', 'M46 50 l6 0 l-6 6 l6 0', 1.4, '#a9adb8'));
    } else if (type === 'tunnel') {
      kids = [bg('#0e1117'), h('path', { key: 'p', d: 'M10 58 L10 32 A22 22 0 0 1 54 32 L54 58 Z', fill: '#05060a', stroke: '#5a6070', strokeWidth: 3 }),
        L('br', 'M10 40 L4 40 M54 40 L60 40 M14 22 L9 18 M50 22 L55 18', 2, '#5a6070'), L('tr', 'M18 58 L28 36 M46 58 L36 36', 1.6, '#3a3f4c'),
        Ci('l1', 32, 22, 1.8, YEL), Ci('l2', 22, 30, 1.4, YEL, { opacity: 0.6 }), Ci('l3', 42, 30, 1.4, YEL, { opacity: 0.6 })];
      if (o.n != null) kids.push(badge(o.n, st === 'dark'));
    }
    return wrap(o, G(type, null, ...kids), defs);
  }

  // 노선 색 20개: oklch → hex. 라이트는 흰 번호(대비 4.5:1↑), 다크는 #14161C 번호.
  function oklch(Lv, C, H) {
    const hr = H * Math.PI / 180, a = C * Math.cos(hr), b = C * Math.sin(hr);
    const l = (Lv + 0.3963377774 * a + 0.2158037573 * b) ** 3, m = (Lv - 0.1055613458 * a - 0.0638541728 * b) ** 3, s = (Lv - 0.0894841775 * a - 1.2914855480 * b) ** 3;
    const rgb = [4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s, -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s, -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s];
    return '#' + rgb.map(x => { x = Math.max(0, Math.min(1, x)); return Math.round(255 * (x <= 0.0031308 ? 12.92 * x : 1.055 * x ** (1 / 2.4) - 0.055)).toString(16).padStart(2, '0'); }).join('');
  }
  const HUES = [[190, 'A'], [80, 'A'], [35, 'A'], [270, 'A'], [120, 'A'], [330, 'A'], [240, 'A'], [55, 'A'], [150, 'A'], [0, 'A'], [215, 'B'], [100, 'B'], [15, 'B'], [295, 'B'], [135, 'B'], [350, 'B'], [255, 'B'], [65, 'B'], [170, 'B'], [310, 'B']];
  const LINE_COLORS = HUES.map(([hh, t], i) => ({ n: i + 1, hue: hh, light: t === 'A' ? oklch(0.5, 0.1, hh) : oklch(0.4, 0.085, hh), dark: t === 'A' ? oklch(0.76, 0.11, hh) : oklch(0.68, 0.1, hh) }));

  const GIMMICKS = [
    { n: 1, key: 'basic', name: '기본', icon: s => P({ a: 0, dir: 'd', size: s, uid: 'i1', f: 0 }) },
    { n: 2, key: 'phone', name: '휴대폰', icon: s => P({ a: 4, kind: 'P', size: s, uid: 'i2', f: 0 }) },
    { n: 3, key: 'coffee', name: '커피', icon: s => P({ a: 0, kind: 'C', dir: 'd', size: s, uid: 'i3', f: 0 }) },
    { n: 4, key: 'window', name: '창문 반사', icon: s => tile('window', { size: s, uid: 'i4' }) },
    { n: 5, key: 'wide', name: '말똥말똥', icon: s => P({ a: 1, kind: 'M', dir: 'd', size: s, uid: 'i5', f: 0 }) },
    { n: 6, key: 'looker', name: '두리번', icon: s => P({ a: 3, kind: 'S', dir: 'd', size: s, uid: 'i6', f: 0 }) },
    { n: 7, key: 'snorer', name: '코골이', icon: s => P({ a: 3, kind: 'N', st: 'asleep', size: s, uid: 'i7', f: 1 }) },
    { n: 8, key: 'baby', name: '우는 아기', icon: s => P({ a: 5, kind: 'Y', dir: 'd', size: s, uid: 'i8', f: 0 }) },
    { n: 9, key: 'talker', name: '잠꼬대', icon: s => P({ a: 4, kind: 'T', st: 'asleep', size: s, uid: 'i9', f: 0 }) },
    { n: 10, key: 'mask', name: '마스크', icon: s => P({ a: 1, kind: 'K', dir: 'd', size: s, uid: 'i10', f: 0 }) },
    { n: 11, key: 'pole', name: '기둥', icon: s => tile('pole', { size: s, uid: 'i11', st: 'split' }) },
    { n: 12, key: 'door', name: '출입문', icon: s => tile('door', { size: s, uid: 'i12', n: 3 }) },
    { n: 13, key: 'cat', name: '고양이', icon: s => CAT({ size: s, f: 0 }) },
    { n: 14, key: 'standing', name: '서서 가는 승객', icon: s => P({ a: 0, kind: 'W', dir: 'd', size: s, uid: 'i14', f: 0 }) },
    { n: 15, key: 'couple', name: '커플', icon: s => h('svg', { width: s, height: s, viewBox: '0 0 64 64', style: { overflow: 'visible', display: 'block' } },
      G('a', { transform: 'translate(-6 4) scale(.8)' }, P({ a: 4, dir: 'd', size: 64, uid: 'i15a', f: 0, hand: 'r' })), G('b', { transform: 'translate(19 4) scale(.8)' }, P({ a: 1, dir: 'd', size: 64, uid: 'i15b', f: 0, hand: 'l' }))) },
    { n: 16, key: 'myopic', name: '근시', icon: s => P({ a: 4, kind: 'O', dir: 'd', size: s, uid: 'i16', f: 0 }) },
    { n: 17, key: 'tiptoe', name: '까치발 아이', icon: s => P({ kind: 'J', dir: 'd', size: s, uid: 'i17', f: 0 }) },
    { n: 18, key: 'earphone', name: '이어폰', icon: s => P({ a: 1, kind: 'E', dir: 'd', size: s, uid: 'i18', f: 0 }) },
    { n: 19, key: 'tunnel', name: '터널', icon: s => tile('tunnel', { size: s, uid: 'i19' }) },
    { n: 20, key: 'alarm', name: '알람 시계', icon: s => tile('alarm', { size: s, uid: 'i20', n: 3 }) },
  ];
  return { INK, ARCH, KID, P, CAT, tile, LINE_COLORS, GIMMICKS, oklch, ripples, soundArcs };
};
