// Yawn! 캐릭터·타일 부품 조합 렌더러 v2. (v4.5: 모든 승객 몸 아래 끝을 둥글게) h = (tag, props, ...children) — React.createElement 또는 문자열 SVG 빌더.
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
  // v4 빌런 외형(새 인물). 다른 빌런은 기존 6외형을 섞어 쓴다(o.a).
  const BALD = { id: 'bald', name: '대머리 승객', skin: '#e6b48e', hair: '#3a2e26', hs: 'bald', outfit: '#6b5b7b', outfit2: '#54476a', acc: 'none', quirk: 'open' };
  const KING = [
    { id: 'king', name: '호통 승객', skin: '#e2ae88', hair: '#3b2c24', hs: 'side', outfit: '#7b3a3a', outfit2: '#5f2b2b', acc: 'none', quirk: 'open' },
    { id: 'king2', name: '호통 승객', skin: '#efc29e', hair: '#2b211c', hs: 'bob', outfit: '#4a4f7a', outfit2: '#3a3e62', acc: 'none', quirk: 'drool' },
  ];
  const POS = { d: { el: [26, 26], er: [38, 26], m: [32, 33] }, l: { el: [20.5, 25.5], er: [28.5, 25.5], m: [21, 32.5] }, r: { el: [35.5, 25.5], er: [43.5, 25.5], m: [43, 32.5] } };
  const ROT = { r: 0, d: 90, l: 180, u: 270 };
  const CW = { u: 'r', r: 'd', d: 'l', l: 'u' };
  const DV = { u: [0, -1], d: [0, 1], l: [-1, 0], r: [1, 0] };
  const LIGHT = '#e9e6dd', YEL = '#ffcf5a';
  // LW: 크기 단계. 기본 1(64–72dp), 작은 칸(lod 's', 44–56dp)에서 1.3 — 모든 외곽선·선이 같이 굵어진다.
  let LW = 1;
  const SK = (w) => ({ stroke: INK, strokeWidth: (w == null ? 2 : w) * LW, strokeLinejoin: 'round', strokeLinecap: 'round' });
  const L = (k, d, w, c, x) => h('path', Object.assign({ key: k, d, stroke: c || INK, strokeWidth: (w || 1.9) * LW, fill: 'none', strokeLinecap: 'round', strokeLinejoin: 'round' }, x || {}));
  const Ci = (k, cx, cy, r, fill, x) => h('circle', Object.assign({ key: k, cx, cy, r, fill }, x || {}));
  const El = (k, cx, cy, rx, ry, fill, x) => h('ellipse', Object.assign({ key: k, cx, cy, rx, ry, fill }, x || {}));
  const G = (k, x, ...c) => h('g', Object.assign({ key: k }, x || {}), ...c);
  const wrap = (o, kids, defs) => h('svg', { width: o.size || 64, height: o.size || 64, viewBox: '0 0 64 64', x: o.x, y: o.y, style: { overflow: 'visible', display: 'block' } }, defs ? h('defs', null, defs) : null, kids);
  const arm = (k, x1, y1, x2, y2, col, skin) => [L(k + 'o', `M${x1} ${y1} L${x2} ${y2}`, 9), L(k + 'i', `M${x1} ${y1} L${x2} ${y2}`, 5.5, col), Ci(k + 'h', x2, y2 - 1.5, 4, skin, SK(1.8))];
  const zs = { fontFamily: 'Gaegu, cursive', fontWeight: 700, fill: '#eef2ff', stroke: INK, strokeWidth: 0.9, paintOrder: 'stroke' };
  const zz = (side, f, an, small) => {
    // v4.7: 고개가 꺾인 쪽 위로 z가 올라온다. side > 0 = 오른쪽으로 꺾임 → 오른쪽 위, side < 0 → 왼쪽 위
    const x1 = side > 0 ? 51 : 6, x2 = side > 0 ? 57 : 2, dy = f ? -4 : 0;
    if (small) return [h('text', { key: 'z1', x: side > 0 ? 52 : 2, y: 12 + dy, fontSize: 18, style: an ? { ...zs, strokeWidth: 1.2, animation: 'yr-z 2.6s linear infinite', transformBox: 'fill-box' } : { ...zs, strokeWidth: 1.2 } }, 'z')];
    return [h('text', { key: 'z1', x: x1, y: 12 + dy, fontSize: 13, style: an ? { ...zs, animation: 'yr-z 2.6s linear infinite', transformBox: 'fill-box' } : zs }, 'z'),
      h('text', { key: 'z2', x: x2, y: 4 + dy, fontSize: 9, style: an ? { ...zs, animation: 'yr-z 2.6s 1.3s linear infinite', transformBox: 'fill-box' } : zs }, 'z')];
  };
  const soundArcs = (k, col, n) => G(k, null, ...[0, 1, 2, 3].map(q => G('d' + q, { transform: `rotate(${q * 90} 32 32)` },
    ...[70, 81, 92].slice(0, n || 3).map((x, j) => L('a' + j, `M${x} 23 Q${x + 6} 32 ${x} 41`, 2.2, col, { opacity: [0.9, 0.6, 0.32][j] })))));
  const ripples = (k, col) => G(k, null, ...[24, 44, 64].map((r, j) => Ci('r' + j, 32, 32, r, 'none', { stroke: col, strokeWidth: [3, 2.4, 1.8][j], opacity: [0.9, 0.6, 0.35][j] })));

  // ── 짐수레 ── 주인이 앞 칸에 손수레(상자 2단)를 세워 둔다. 주인 어깨의 동그란 표 = 수레 손잡이의 짐표(같은 색)로 짝을 읽는다.
  // 잠들면 수레가 넘어져 상자가 바닥에 흩어진다(짐표도 상자에 붙은 채 함께 쓰러짐).
  const TAG_COLORS = ['#ffcf5a', '#7fd1c0', '#f2a7c3', '#9fc0ff'];
  const tagCol = (t) => typeof t === 'number' ? TAG_COLORS[t % 4] : (t || TAG_COLORS[0]);
  function cartTag(o, small) {
    const s = small ? 1.15 : 1;
    return [L('tgs', 'M45 42 L48 46', 1.2), Ci('tg', 48.5, 50, 4.4 * s, tagCol(o.tag), SK(1.6))];
  }
  // 짐수레 조각 자세: [transform-origin, 흐트러진(st down) 자세]. 서 있음 = none.
  const CART_POSE = { frame: ['0px 0px', 'translateY(43.5px) scaleY(.25)'], b1: ['32px 57px', 'translate(-10px,3px) rotate(-7deg)'], b2: ['32px 33.5px', 'translate(14px,24px) rotate(16deg)'], tag: ['40px 4px', 'translate(2px,39px) rotate(66deg)'] };
  const luggageTag = (col, up, small) => G('ltag', { transform: up ? `translate(40 4) rotate(14)${small ? ' scale(1.2)' : ''}` : `translate(22 38) rotate(-70)${small ? ' scale(1.2)' : ''}` },
    L('lts', 'M0 0 L0 3', 1.2), h('rect', { key: 'ltr', x: -4, y: 3, width: 8, height: 11, rx: 1.5, fill: col, ...SK(1.6) }), Ci('lth', 0, 6, 1.1, INK));
  const scoped = (fn) => (o) => { const prev = LW; LW = o && o.lod === 's' ? 1.3 : 1; try { return fn(o); } finally { LW = prev; } };
  const P = scoped(P0), CAT = scoped(CAT0), tile = (type, o) => scoped((oo) => tile0(type, oo))(o || {});
  const BADGE_S = { transform: 'translate(55 7) scale(1.3) translate(-55 -7)' };

  function P0(o) {
    const kind = o.kind || 'B', small = o.lod === 's';
    if (kind === 'G') return CAT(o);
    const a = o.a || 0, A = kind === 'J' ? KID : kind === 'Z' ? BALD : kind === 'U' ? KING[a % 2] : ARCH[a % 6], st = o.st || 'awake';
    const uid = (o.uid || 'p') + '-' + a, sf = o.sf || 1, side = o.side || 1, exp = o.exp || 0;
    const stat = o.f != null, f = o.f || 0, an = !stat;
    const yf = st === 'yawn' ? (stat ? f : 1) : -1;
    const sleepy = st === 'asleep' || st === 'nod' || st === 'lean';
    const frontal = (st !== 'awake' && st !== 'drowsy') || kind === 'P';
    const fd = frontal ? 'd' : (o.dir || 'd');
    const skin = A.skin, hair = A.hair, S = SK(2);
    const under = [], back = [], body = [], hd = [], F = [], front = [], top = [];
    const lifted = yf === 1 || yf === 2, lift = lifted ? 'translate(0px,-4px)' : 'none';
    // v4: stand = 선 몸(서서 가는 승객·순찰). propsOn = 민폐 소품이 켜진 상태(잠듦·기댐 빼고), handsOn = 손에 든 소품(하품 중엔 내려놓음)
    const stand = kind === 'W' || kind === 'R', propsOn = st !== 'asleep' && st !== 'lean', handsOn = propsOn && yf < 0, villain = 'VQFLZRU'.includes(kind);

    if (yf === 0) back.push(...arm('a', 17, 47, 12, 28, A.outfit, skin), ...arm('b', 47, 47, 52, 28, A.outfit, skin));
    if (lifted) back.push(...arm('a', 17, 47, 9, 14, A.outfit, skin), ...arm('b', 47, 47, 55, 14, A.outfit, skin));
    if (A.acc === 'hood' && fd !== 'u') back.push(El('hd', 32, 37, 17, 8, A.outfit2, S));

    if (kind === 'J') {
      body.push(h('path', { key: 'b', d: 'M14 58.5 C14 48.5 21 42 32 42 C43 42 50 48.5 50 58.5 Q50 63.5 43.5 63.5 L20.5 63.5 Q14 63.5 14 58.5 Z', fill: A.outfit, ...S }));
      if (st === 'awake' || st === 'glare') body.push(h('rect', { key: 'nk', x: 28.5, y: 30, width: 7, height: 13, fill: skin, ...SK(1.8) }));
    } else if (stand) {
      // 서 있는 몸: 앉은 몸보다 좁고 곧은 상체(허리 63에서 끝) + 늘어뜨린 왼팔
      if (kind === 'R' && yf < 0 && !handsOn) body.push(L('dsh', 'M15 55 L12.5 77', 6.2), L('dsh2', 'M15 55 L12.5 77', 3.6, '#c9a46a'));
      if (yf < 0 && !(kind === 'R' && handsOn)) body.push(L('fa', 'M19.5 47 L16.5 60', 8.4), L('fa2', 'M19.5 47 L16.5 60', 5.2, A.outfit), Ci('fah', 16.3, 61, 3.4, skin, SK(1.6)));
      body.push(h('path', { key: 'b', d: 'M18.5 59 C18 50 21.5 40.5 32 40.5 C42.5 40.5 46 50 45.5 59 Q45.3 63.5 40 63.5 L24 63.5 Q18.7 63.5 18.5 59 Z', fill: A.outfit, ...S }));
    } else if (kind === 'Q') body.push(h('path', { key: 'b', d: 'M11 59 C10 47 18 40.5 32 40.5 C46 40.5 54 47 53 59 Q52.5 66.5 44 66.5 Q32 68 20 66.5 Q11.5 66.5 11 59 Z', fill: A.outfit, ...S }));
    else body.push(h('path', { key: 'b', d: 'M10 58 C10 46.5 18 40.5 32 40.5 C46 40.5 54 46.5 54 58 Q54 63.5 46.5 63.5 L17.5 63.5 Q10 63.5 10 58 Z', fill: A.outfit, ...S }));
    if (fd === 'u') {
      // 뒷모습: 앞쪽 옷 장식(넥타이·지퍼·브로치·후드끈)은 숨기고, 등에서 보이는 것만
      const neck = 'M24.5 42.2 Q32 46.2 39.5 42.2';
      if (A.acc === 'tie') body.push(L('bc', neck, 1.5), L('bs', 'M32 46 L32 63', 1.1, INK, { opacity: 0.45 }), L('bv', 'M28 63 L28 57 M36 63 L36 57', 1, INK, { opacity: 0.3 }));
      else if (A.acc === 'collar') body.push(h('path', { key: 'bc', d: 'M24.5 41.6 Q32 46.6 39.5 41.6 L38.6 44.6 Q32 49 25.4 44.6 Z', fill: '#efeae0', ...SK(1.4) }));
      else if (A.acc === 'brooch') body.push(L('bc', neck, 1.5), L('bk', 'M20 55 Q32 58 44 55', 1.1, INK, { opacity: 0.35 }));
      else if (A.acc === 'zip') body.push(L('bc', neck, 1.5), L('bpS', 'M24 45 L23.5 50 M40 45 L40.5 50', 2.6, '#3e4a36'), h('rect', { key: 'bp', x: 21.5, y: 47.5, width: 21, height: 16, rx: 4.5, fill: '#5e6e4c', ...SK(1.8) }), L('bpf', 'M22 53 Q32 56 42 53', 1.4), h('rect', { key: 'bpp', x: 28, y: 56.5, width: 8, height: 5, rx: 1.5, fill: '#4e5d3e', ...SK(1.2) }));
      else if (A.acc === 'hood') body.push(h('path', { key: 'bh', d: 'M20.5 42.5 Q32 39.5 43.5 42.5 Q44 54 32 56 Q20 54 20.5 42.5 Z', fill: A.outfit2, ...SK(1.8) }), L('bhi', 'M24.5 44.5 Q32 52.5 39.5 44.5', 1.3, INK, { opacity: 0.5 }));
      else if (A.acc === 'strap') body.push(L('st', 'M19 41.5 L51 52', 4.5, '#5a4632'));
      else body.push(L('bc', neck, 1.5));
    } else {
      if (A.acc === 'tie') {
        body.push(h('path', { key: 'sh', d: 'M25.5 41.5 L32 50 L38.5 41.5 Z', fill: '#efeae0', ...SK(1.4) }));
        body.push(h('path', { key: 'ti', d: 'M30.6 42.5 L33.4 42.5 L32.8 45 L34.2 54 L32 57 L29.8 54 L31.2 45 Z', fill: '#9a4040', ...SK(1.2) }));
      } else if (A.acc === 'collar') body.push(h('path', { key: 'co', d: 'M25 41.5 L32 48.5 L39 41.5 L36 40.8 L32 44.5 L28 40.8 Z', fill: '#efeae0', ...SK(1.4) }));
      else if (A.acc === 'brooch') body.push(small ? null : L('cd', 'M32 42 L32 63', 1.3), Ci('br', 39, 49, small ? 2.8 : 2.2, '#e2bd55', SK(1.2)));
      else if (A.acc === 'zip') body.push(L('z', 'M32 41 L32 63 M26 41.5 Q32 45 38 41.5', 1.4));
      else if (A.acc === 'hood') body.push(small ? null : L('hs', 'M29 44 L28.5 52 M35 44 L35.5 52', 1.6, '#efeae0'));
      else if (A.acc === 'strap') body.push(L('st', 'M13 52 L45 41.5', 4.5, '#5a4632'));
    }
    if (villain) vProps(kind, o, A, { fd, st, f, stat, side, small, propsOn, handsOn, yf, body, front, under, back, hd, top, S });
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
      if (st === 'awake' && !small) front.push(L('stm', 'M44 39 q-2 -3 0 -6 M47.5 39 q-2 -3 0 -6', 1.3, '#cfd6e4', { opacity: 0.7 }));
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
    if (kind === 'H') front.push(...cartTag(o, small));
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
    const base = A.hs === 'bald' ? [] : { d: [['e', 32, 13, 17, 8.5]], l: [['e', 42, 19, 12, 13], ['e', 30, 12, 16, 6]], r: [['e', 22, 19, 12, 13], ['e', 34, 12, 16, 6]], u: [['r']] }[fd];
    base.forEach((b, j) => hairShapes.push(b[0] === 'e' ? El('hb' + j, b[1], b[2], b[3], b[4], hair) : h('rect', { key: 'hb' + j, x: 0, y: 0, width: 64, height: 64, fill: hair })));
    if (A.hs === 'bob') ({ d: [[16, 12, 5.5, 22], [42.5, 12, 5.5, 22]], l: [[36, 12, 12, 24]], r: [[16, 12, 12, 24]], u: [] })[fd].forEach((q, j) => hairShapes.push(h('rect', { key: 'bb' + j, x: q[0], y: q[1], width: q[2], height: q[3], fill: hair })));
    if (A.hs === 'bald') ({ d: [[19.5, 29, 3.6, 6], [44.5, 29, 3.6, 6]], l: [[42.5, 29, 6.5, 7]], r: [[21.5, 29, 6.5, 7]], u: [[32, 36.5, 16, 5.5]] })[fd].forEach((q, j) => hairShapes.push(El('bf' + j, q[0], q[1], q[2], q[3], hair)));
    if (A.hs === 'cap') hairShapes.push(El('cap', 32, fd === 'u' ? 22 : 13, 18, fd === 'u' ? 16 : 9.5, A.cap));
    if (fd === 'u') hd.push(Ci('e1', 17.8, 27, 3.2, skin, SK(1.6)), Ci('e2', 46.2, 27, 3.2, skin, SK(1.6)));
    if (A.hs === 'pony') { const pp = { d: [45, 13], l: [46.5, 27], r: [17.5, 27], u: [32, 41] }[fd]; hd.push(El('po', pp[0], pp[1], 4.2, 7, hair, S)); }
    hd.push(Ci('hf', 32, 25, 14, skin), G('hr', { clipPath: `url(#${hc})` }, ...hairShapes), Ci('ho', 32, 25, 14, 'none', SK(2.2)));
    if (kind === 'Z' || kind === 'U') vHead(kind, { fd, st, f, stat, side, propsOn, hd });
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
      } else if (kind === 'U' && st === 'shout') {
        F.push(L('br', 'M19.5 15.5 L29 20 M44.5 15.5 L35 20', 2.6), Ci('e1', 25.5, 25.5, 3.4, '#fff', SK(1.6)), Ci('e2', 38.5, 25.5, 3.4, '#fff', SK(1.6)), Ci('p1', 25.5, 25.5, 1.3, INK), Ci('p2', 38.5, 25.5, 1.3, INK));
        F.push(h('path', { key: 'mo', d: 'M25 32 Q32 29.5 39 32 Q38.5 40 32 40.5 Q25.5 40 25 32 Z', fill: '#6a1f2c', ...SK(1.8) }), L('tt', 'M26.5 32.6 Q32 31 37.5 32.6', 1.6, '#fff'));
      } else if (kind === 'V' || kind === 'U' || kind === 'L') {
        if (kind === 'V') {
          [el, er].forEach((e, j) => F.push(L('he' + j, `M${e[0] - 2.8} ${e[1] + 0.8} Q${e[0]} ${e[1] - 2} ${e[0] + 2.8} ${e[1] + 0.8}`, 2)));
          F.push(L('mo', `M${m[0] - 3} ${m[1] - 0.5} Q${m[0]} ${m[1] + 2.6} ${m[0] + 3} ${m[1] - 0.5}`, 1.8));
        } else if (kind === 'U') {
          F.push(L('br', `M${el[0] - 3.5} ${el[1] - 5.2} L${el[0] + 3} ${el[1] - 3.2} M${er[0] - 3} ${er[1] - 3.2} L${er[0] + 3.5} ${er[1] - 5.2}`, 2.2));
          F.push(El('e1', el[0], el[1] + 0.5, 2.2, 1.7, INK), El('e2', er[0], er[1] + 0.5, 2.2, 1.7, INK));
          F.push(L('mo', `M${m[0] - 3} ${m[1] + 1.2} Q${m[0]} ${m[1] - 1.4} ${m[0] + 3} ${m[1] + 1.2}`, 1.9));
        } else {
          F.push(L('br', `M${el[0] - 3} ${el[1] - 5.6} Q${el[0]} ${el[1] - 7.4} ${el[0] + 3} ${el[1] - 5.6} M${er[0] - 3} ${er[1] - 5.6} Q${er[0]} ${er[1] - 7.4} ${er[0] + 3} ${er[1] - 5.6}`, 1.7));
          F.push(El('a', el[0], el[1], 2.2, 2.7, INK), El('b', er[0], er[1], 2.2, 2.7, INK), El('mo', m[0], m[1] + 0.5, 3, 3.4, '#6a1f2c', SK(1.6)));
        }
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
          F.push(small ? G('ey', blink, El('a', el[0], el[1], 2.6, 3.2, INK), El('b', er[0], er[1], 2.6, 3.2, INK)) : G('ey', blink, El('a', el[0], el[1], 2.2, 2.7, INK), El('b', er[0], er[1], 2.2, 2.7, INK)));
        }
        if (kind === 'C') F.push(L('br', `M${el[0] - 3} ${el[1] - 4.8} L${el[0] + 3} ${el[1] - 3.6} M${er[0] - 3} ${er[1] - 3.6} L${er[0] + 3} ${er[1] - 4.8}`, 1.8), L('mo', `M${m[0] - 3} ${m[1]} Q${m[0] + 1} ${m[1] + 1.6} ${m[0] + 3.5} ${m[1] - 1}`, 1.8));
        else if (kind === 'F') F.push(L('mo', `M${m[0] - 3.4} ${m[1] - 0.4} q1.7 1.8 3.4 0 q1.7 1.8 3.4 0`, 1.7), Ci('ck', m[0] + (fd === 'l' ? -4.5 : 5), m[1] - 1.5, 2.2, '#e9a08a', { opacity: 0.7 }));
        else if (kind === 'Q' || kind === 'Z') F.push(L('mo', `M${m[0] - 2.8} ${m[1] + 0.3} Q${m[0] + 0.5} ${m[1] + 2} ${m[0] + 3} ${m[1] - 1}`, 1.8));
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
      top.push(G('bdg', small ? BADGE_S : null, h('rect', { x: 47, y: 1, width: 15, height: 11, rx: 5.5, fill: '#f4f1ea', stroke: INK, strokeWidth: 1.3 }),
        Ci('a', 51.5, 6.5, 2, left >= 1 ? INK : 'none', { stroke: INK, strokeWidth: 1.1 }), Ci('b', 57.5, 6.5, 2, left >= 2 ? INK : 'none', { stroke: INK, strokeWidth: 1.1 })));
    }
    if (st !== 'asleep' && kind === 'S') {
      top.push(G('bdg', small ? BADGE_S : null, Ci('a', 55, 7, 6.5, '#f4f1ea', { stroke: INK, strokeWidth: 1.3 }),
        L('b', 'M51.6 7.5 A3.5 3.5 0 1 1 55 10.5', 1.4), L('c', 'M49.8 6.2 L51.6 8.6 L53.6 6.6', 1.3)));
    }
    // v4.6 호통: 다음 박자에 볼 방향(시계 방향) 배지. o.next로 덮어쓸 수 있고, o.turn === false면 숨김.
    if (kind === 'U' && o.turn !== false && st !== 'asleep' && st !== 'lean' && st !== 'shout' && st !== 'yawn') {
      const nx = o.next || CW[o.dir || 'd'];
      top.push(G('bdg', small ? BADGE_S : null, Ci('a', 55, 7, 6.5, '#f4f1ea', { stroke: INK, strokeWidth: 1.3 }),
        G('ar', { transform: `rotate(${ROT[nx]} 55 7)` }, L('b', 'M51.2 7 L58.2 7', 1.6), L('c', 'M55.4 4 L58.4 7 L55.4 10', 1.5))));
    }
    if (kind === 'E' && st === 'awake' && !o.bounce && !small) top.push(G('note', null, El('a', 52, 11.5, 2.4, 1.8, LIGHT, SK(1)), L('b', 'M54.2 11 L54.2 3 Q58 3.8 58.5 7', 1.4, LIGHT)));
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
    if ((st === 'asleep' || st === 'lean') && kind !== 'N' && kind !== 'T') top.push(...zz(side, stat ? f : 0, an, small));
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
    if (stand) {
      const k = o.walk;
      const legs = k === 0 ? ['M28 42 L24 61', 'M36 42 L40 61'] : k === 1 ? ['M28 42 L31 61', 'M36 42 L33 61'] : ['M28.5 42 L28 61', 'M35.5 42 L36 61'];
      legs.forEach((d, j) => under.push(L('lo' + j, d, 8.5), L('li' + j, d, 5.5, '#2f3542')));
      legs.forEach((d, j) => { const e = d.split(' ').slice(-2).map(v => parseFloat(v.replace(/[A-Z]/g, ''))); under.push(El('sh' + j, e[0] + 1, e[1] + 0.5, 4, 2.3, '#2a2420', SK(1.4))); });
      const sway = st === 'asleep' ? `rotate(${side * 7} 47 -4)` : '';
      under.push(L('strap', 'M47 -16 L47 -8', 2.4, '#8b93a0'), Ci('ring', 47, -4, 4.2, 'none', { stroke: INK, strokeWidth: 4 }), Ci('ring2', 47, -4, 4.2, 'none', { stroke: '#c9ccd4', strokeWidth: 2 }));
      if (kind === 'R') person = G('wp', null, ...under.slice(0, 6), G('sc', { transform: 'translate(5 -10) scale(.84)' }, person));
      else person = G('wp', { transform: sway }, L('arm', 'M42 32 L47 1', 8), L('arm2', 'M42 32 L47 1', 5, A.outfit), Ci('hand', 47, 0, 3.4, skin, SK(1.6)), ...under.slice(0), G('sc', { transform: 'translate(5 -10) scale(.84)' }, person));
      under.length = 0;
    }
    if (kind === 'Q') person = G('qs', { transform: 'translate(37.12 -7) scale(.84)' }, person);
    const outer = G('t' + (o.tapK || 0), o.tapK ? { style: { animation: `yr-tap ${120 * sf}ms`, transformOrigin: '32px 63px' } } : null, ...under, person, ...top);
    if (kind === 'Q') return h('svg', { width: (o.size || 64) * 2, height: o.size || 64, viewBox: '0 0 128 64', x: o.x, y: o.y, style: { overflow: 'visible', display: 'block' } }, h('defs', null, h('clipPath', { id: hc }, Ci('c', 32, 25, 14))), outer);
    return wrap(o, outer, h('clipPath', { id: hc }, Ci('c', 32, 25, 14)));
  }

  // ── v4 빌런 소품 ── 깨어 있는 동안만 켜지는 소품. 민폐 효과(음표·김·파동)는 FX()로 따로 그린다.
  function vProps(kind, o, A, c) {
    const { fd, st, f, stat, side, small, propsOn, handsOn, yf, body, front, under, hd, top, S } = c, skin = A.skin, back = fd === 'u';
    const hand = (k, x, y) => Ci(k, x, y, 3.4, skin, SK(1.6));
    const limb = (k, d) => [L(k + 'o', d, 8.4), L(k + 'i', d, 5.2, A.outfit)];
    if (kind === 'V' && !back) {
      front.push(h('rect', { key: 'spk', x: 22, y: 49.5, width: 20, height: 12, rx: 4, fill: '#3a3f4a', ...SK(1.8) }), Ci('sg1', 28, 55.5, 3.6, '#252a35', SK(1.2)), Ci('sg2', 36.5, 55.5, 2.4, '#252a35', SK(1.2)));
      front.push(Ci('led', 38.5, 52.3, small ? 1.6 : 1.1, propsOn ? '#7fd1a0' : '#6b7080'));
      if (handsOn) front.push(hand('h1', 21, 55), hand('h2', 43, 55));
    }
    if (kind === 'F' && !back) {
      if (propsOn) front.push(h('path', { key: 'lid', d: 'M20 50 L22.5 41.5 L44.5 41.5 L44 50 Z', fill: '#f3eee3', ...SK(1.6) }), Ci('c1', 27, 49.5, 3.6, '#c98a3e', SK(1.3)), Ci('c2', 33.5, 48.5, 3.8, '#d39a4c', SK(1.3)), Ci('c3', 39, 49.5, 3.2, '#c98a3e', SK(1.3)));
      front.push(h('rect', { key: 'box', x: 19, y: 50, width: 26, height: 12, rx: 2, fill: '#c94a3a', ...SK(1.8) }), h('rect', { key: 'bx2', x: 19, y: 54, width: 26, height: 3.2, fill: '#f3eee3' }), h('rect', { key: 'bxo', x: 19, y: 50, width: 26, height: 12, rx: 2, fill: 'none', ...SK(1.8) }));
      if (!propsOn) front.push(h('rect', { key: 'lidc', x: 18, y: 47.5, width: 28, height: 4, rx: 1.5, fill: '#f3eee3', ...SK(1.5) }));
      if (handsOn) front.push(h('path', { key: 'leg', d: 'M45 46 q4 -9 8 -6 q3 3 -4 8 Z', fill: '#c98a3e', ...SK(1.4) }), L('bone', 'M45 46 L42.5 49.5', 2.6, '#f3eee3'), hand('lh', 43, 50));
    }
    if (kind === 'L' && !back) {
      if (handsOn && st !== 'startle') {
        const x = fd === 'l' ? 14 : fd === 'r' ? 36 : 25;
        front.push(h('rect', { key: 'ph', x, y: 36.5, width: 14, height: 6.5, rx: 1.8, fill: '#d3ecff', ...SK(1.6) }), L('phs', `M${x + 3} 39.8 L${x + 11} 39.8`, 1, '#7c8496'), hand('ph', x + (fd === 'l' ? 1 : 13), 42.5));
      } else front.push(h('rect', { key: 'ph', x: 27, y: 52, width: 10, height: 7, rx: 1.5, fill: '#4a5060', ...SK(1.5) }));
    }
    if (kind === 'L' && st !== 'asleep' && o.left != null) top.push(G('bdg', small ? BADGE_S : null, Ci('a', 55, 7, 6.5, YEL, { stroke: INK, strokeWidth: 1.3 }), h('text', { x: 55, y: 10.4, textAnchor: 'middle', style: { fontFamily: 'IBM Plex Mono, monospace', fontWeight: 600, fontSize: 9.5, fill: INK } }, String(o.left))));
    if (kind === 'R' && handsOn && !back) {
      const x = fd === 'l' ? 21 : fd === 'r' ? 43 : 32;
      front.push(h('rect', { key: 'ds', x: x - 2.2, y: 31, width: 4.4, height: 27, rx: 2, fill: '#c9a46a', ...SK(1.5) }), L('dsn', `M${x - 2} 40 L${x + 2} 40`, 1, '#8a6a3c'));
      [44.5, 49].forEach((y, j) => front.push(Ci('dh' + j, x, y, 0.9, INK)));
      front.push(...limb('da1', `M19 47 L${x - 1} 46`), hand('dh1', x, 46), ...limb('da2', `M45 49 L${x + 1} 54`), hand('dh2', x, 54));
    }
    if (kind === 'R' && handsOn && back) front.push(L('dsb', 'M32 30 L32 33', 4.4, '#c9a46a'));
    if (kind === 'U') {
      body.push(El('pd1', 13.5, 46.5, 7, 5, '#e2bd55', SK(1.7)), El('pd2', 50.5, 46.5, 7, 5, '#e2bd55', SK(1.7)));
      body.push(h('path', { key: 'cp', d: 'M21 45 Q32 41.5 43 45 L41 63 L23 63 Z', fill: '#b9c1cc', ...SK(1.6) }));
      if (!back) body.push(L('cph', 'M27 48 L26 60', 1.4, '#ffffff', { opacity: 0.55 }));
      if (handsOn && !back) front.push(...limb('xa', 'M15 50 Q30 61 46 53'), ...limb('xb', 'M49 50 Q34 61 18 53'), hand('xh1', 46, 53), hand('xh2', 18, 53));
    }
    if (kind === 'Q') {
      const P2 = '#2f3542';
      const leg = (k, d) => [L(k + 'o', d, 10.4), L(k + 'i', d, 7.2, P2)];
      // 정면에서 본 쩍벌: 윗몸은 서서 가는 승객처럼 0.84배로 올려(두 칸 가운데), 아래에 V자로 벌린 다리 — 짧은 허벅지가 무릎을 양옆으로, 정강이는 아래로.
      // 다리는 128 그림 좌표(under), 등받이에 걸친 두 팔은 몸 좌표(back, 몸과 같이 줄어듦).
      under.push(...leg('lr', 'M71 45 L89.5 52 L87.5 60.5'), El('sr', 88.5, 62, 5.2, 2.7, '#2a2420', SK(1.4)));
      under.push(...leg('ll', 'M57 45 L38.5 52 L40.5 60.5'), El('sl', 39.5, 62, 5.2, 2.7, '#2a2420', SK(1.4)));
      if (yf < 0) c.back.push(...limb('dr', 'M47 46 L58 39.5 L71 39'), Ci('drh', 73, 39.5, 3.6, skin, SK(1.6)), ...limb('dl', 'M17 46 L6 39.5 L-7 39'), Ci('dlh', -9, 39.5, 3.6, skin, SK(1.6)));
    }
  }
  function vHead(kind, c) {
    const { fd, st, f, stat, side, propsOn, hd } = c;
    if (kind === 'Z' && propsOn) {
      const x = fd === 'l' ? 36 : fd === 'r' ? 28 : fd === 'u' ? 32 : 26;
      hd.push(El('shn', x, 16, 5.2, 2.6, '#ffffff', { opacity: 0.7, transform: `rotate(-20 ${x} 16)` }));
      hd.push(h('path', { key: 'str', d: 'M41 4 L42.4 8.6 L47 10 L42.4 11.4 L41 16 L39.6 11.4 L35 10 L39.6 8.6 Z', fill: YEL, ...SK(1.2) }));
    }
    if (kind === 'U') {
      const k = st === 'asleep' || st === 'lean' ? 3 : st === 'nod' ? (stat ? f : 2) : -1;
      const rt = k < 0 ? '' : `translate(${side * [1.5, 3, 5, 7][k]} ${[0.5, 1.5, 2.5, 4][k]}) rotate(${side * [6, 12, 18, 26][k]} 32 12)`;
      hd.push(G('crn', rt ? { transform: rt } : null, h('path', { d: 'M20.5 14 L19.5 3.5 L26 8.5 L32 1.5 L38 8.5 L44.5 3.5 L43.5 14 Z', fill: '#e2bd55', ...SK(1.8) }),
        L('band', 'M20.8 11 L43.3 11', 1.2, '#b8922e'), Ci('j1', 26, 12.6, 1.2, '#c94a4a'), Ci('j2', 32, 12.6, 1.3, '#4a7ac9'), Ci('j3', 38, 12.6, 1.2, '#c94a4a'),
        Ci('t1', 19.5, 3.5, 1.5, '#e2bd55', SK(1)), Ci('t2', 32, 1.5, 1.6, '#e2bd55', SK(1)), Ci('t3', 44.5, 3.5, 1.5, '#e2bd55', SK(1))));
    }
  }

  // ── v4 민폐 효과 레이어 ── 원점 = 빌런 칸(64×64). 이웃 칸은 ±64. 앱이 박자에 맞춰 켜고 끈다. o.lod 's' 지원.
  const MUSIC = '#9fc0ff', SMELL = '#f2d08a', WHISTLE = '#ff9f6b';
  const N4 = [['r', 1, 0], ['l', -1, 0], ['d', 0, 1], ['u', 0, -1]];
  const zig = (x1, y1, x2, y2, amp, n, round) => {
    const dx = (x2 - x1) / n, dy = (y2 - y1) / n, L0 = Math.hypot(dx, dy) || 1, px = -dy / L0 * amp, py = dx / L0 * amp;
    let d = `M${x1} ${y1}`;
    for (let i = 0; i < n; i++) { const s = i % 2 ? -1 : 1, mx = x1 + dx * (i + 0.5) + px * s, my = y1 + dy * (i + 0.5) + py * s, ex = x1 + dx * (i + 1), ey = y1 + dy * (i + 1); d += round ? ` Q${mx} ${my} ${ex} ${ey}` : ` L${mx} ${my} L${ex} ${ey}`; }
    return d;
  };
  const note = (k, x, y, col, s) => G(k, { transform: `translate(${x} ${y}) scale(${s || 1})` }, L('st', 'M2.2 0 L2.2 -8 Q5.6 -7 6 -4', 1.4, col), El('hd', 0, 0, 2.6, 1.9, col, SK(1)));
  function FX0(type, o) {
    const k = [], dirs = o.dirs ? N4.filter(n => o.dirs.includes(n[0])) : N4;
    if (type === 'music') dirs.forEach(([d, dx, dy]) => {
      const a = [32 + dx * 24, 32 + dy * 24], b = [32 + dx * 44, 32 + dy * 44];
      k.push(L('w' + d, zig(a[0], a[1], b[0], b[1], 3.2, 4, true), 2, MUSIC, { opacity: 0.9 }));
      if (o.marks !== false) k.push(note('n' + d, 32 + dx * 64 + 18, 32 + dy * 64 - 27, MUSIC, o.lod === 's' ? 1.4 : 1.1));
    });
    if (type === 'noteMark') k.push(note('n', 50, 5, MUSIC, o.lod === 's' ? 1.4 : 1.1));
    if (type === 'smell') dirs.forEach(([d, dx, dy]) => [-5, 5].forEach((off, j) => {
      const px = dy ? off : 0, py = dx ? off : 0, a = [32 + dx * 20 + px, 40 + dy * 20 + py], b = [32 + dx * 42 + px, 40 + dy * 38 + py];
      k.push(L('s' + d + j, zig(a[0], a[1], b[0], b[1], 2.4, 3, true), 1.8, SMELL, { opacity: j ? 0.55 : 0.9 }));
    }));
    if (type === 'sniff') { const r = ROT[o.dir || 'r']; k.push(G('sf', { transform: `rotate(${r} 32 28)` }, L('a', 'M50 25 l4 -1.5 M50.5 28.5 l4.5 0 M50 32 l4 1.5', 1.5, SMELL))); }
    if (type === 'call') {
      const reach = o.reach || 2, r = ROT[o.dir || 'r'], arcs = [];
      for (let x = 66, j = 0; x < 64 * reach + 20; x += 18, j++) arcs.push(L('c' + j, `M${x} ${25 - j} Q${x + 7} 32 ${x} ${39 + j}`, 2.6, YEL, { opacity: Math.max(0.3, 0.95 - j * 0.12) }));
      k.push(G('cl', { transform: `rotate(${r} 32 32)` }, h('path', { key: 'tail', d: 'M52 28 L62 32 L52 36 Z', fill: YEL, ...SK(1.2) }), ...arcs));
    }
    if (type === 'shine') {
      const from = o.from || 'l', hz = from === 'l' || from === 'r';
      k.push(L('rays', 'M41 -2 L41 -7 M48 3 L52.5 0.5 M48 15 L52.5 17.5 M34 3 L29.5 0.5', 1.6, YEL));
      k.push(hz ? L('sp', 'M32 4 Q32 -8 32 -14 M32 46 Q32 58 32 70', 2, '#ffffff', { opacity: 0.8, strokeDasharray: '2 3' }) : L('sp', 'M14 25 L-6 25 M50 25 L70 25', 2, '#ffffff', { opacity: 0.8, strokeDasharray: '2 3' }));
    }
    if (type === 'whistle') dirs.forEach(([d, dx, dy]) => {
      const a = [32 + dx * 22, 32 + dy * 22], b = [32 + dx * 46, 32 + dy * 46];
      k.push(L('z' + d, zig(a[0], a[1], b[0], b[1], 4.2, 5, false), 2.2, WHISTLE), L('zt' + d, `M${b[0] + dx * 4 - dy * 3} ${b[1] + dy * 4 - dx * 3} L${b[0] + dx * 8} ${b[1] + dy * 8} L${b[0] + dx * 4 + dy * 3} ${b[1] + dy * 4 + dx * 3}`, 2, WHISTLE));
    });
    if (type === 'shout') {
      const lft = o.dir === 'l', bx = lft ? -18 : 46;
      const pts = []; for (let i = 0; i < 16; i++) { const t = i / 16 * Math.PI * 2, rr = i % 2 ? 11 : 15; pts.push(`${(bx + Math.cos(t) * rr * 1.45).toFixed(1)} ${(-10 + Math.sin(t) * rr).toFixed(1)}`); }
      k.push(h('path', { key: 'bb', d: 'M' + pts.join(' L') + ' Z', fill: '#fffaf0', ...SK(1.8) }), h('text', { key: 'tx', x: bx, y: -5, textAnchor: 'middle', fontSize: 15, style: { fontFamily: 'Gaegu, cursive', fontWeight: 700, fill: '#c94a3a' } }, '버럭!'));
      k.push(L('ln', lft ? 'M6 14 l-5 -2 M5 20 l-6 1' : 'M58 14 l5 -2 M59 20 l6 1', 1.8, LIGHT));
    }
    // v4.6 툭이 안 통함: 가슴판 반짝 + 튕겨 나가는 손가락(아래 오른쪽에서 들어와 튕김)
    if (type === 'ting') {
      k.push(h('path', { key: 'sp', d: 'M30 46 L31.6 50.4 L36 52 L31.6 53.6 L30 58 L28.4 53.6 L24 52 L28.4 50.4 Z', fill: '#ffffff', ...SK(1.1) }));
      k.push(L('rg', 'M21 49 Q19 52 21 55 M39 49 Q41 52 39 55', 1.4, '#ffffff', { opacity: 0.85 }));
      k.push(G('fg', { transform: 'rotate(-38 52 60)' }, h('rect', { x: 46, y: 56.5, width: 13, height: 7, rx: 3.5, fill: '#f2c8a0', ...SK(1.5) }), L('nl', 'M48.5 58.3 L48.5 61.7', 1, INK, { opacity: 0.5 })));
      k.push(L('bo', 'M44 49 l3.5 -3.5 M47.5 53.5 l5 -1 M42 45 l1 -4.5', 1.6, YEL));
    }
    // v4.6 졸음이 옮음: o.from(하품하는 옆 사람 쪽)에서 이 칸으로 스며드는 하품 김 — 시선선(곧은 점선)과 달리 둥글게 부푼 김 덩어리
    if (type === 'drowse') {
      const [, dx, dy] = N4.find(n => n[0] === (o.from || 'l')), DROW = '#c9bff0';
      // 칸 경계(t 0.5) 둘레에 김 덩어리가 모이도록. 위·아래에서 올 때는 왼쪽으로 비켜 얼굴·왕관을 피함.
      const at = (t) => [32 + dx * 64 * t + (dy ? -20 : 0), (dy ? 32 : 22) + dy * 64 * t];
      const p0 = at(0.8), p1 = at(0.22);
      k.push(L('tro', zig(p0[0], p0[1], p1[0], p1[1], 3.4, 3, true), 5.2, INK, { opacity: 0.35 }), L('tr', zig(p0[0], p0[1], p1[0], p1[1], 3.4, 3, true), 3, DROW));
      [[0.66, 8, 0.75], [0.48, 7, 0.9], [0.3, 5.6, 1]].forEach(([t, rr, op], j) => { const p = at(t); k.push(Ci('pf' + j, p[0], p[1], rr, DROW, { opacity: op, stroke: INK, strokeWidth: 1.4 }), Ci('ph' + j, p[0] - rr * 0.35, p[1] - rr * 0.35, rr * 0.3, '#ffffff', { opacity: 0.6 })); });
    }
    if (type === 'watch' && o.dir) {
      const [, dx, dy] = N4.find(n => n[0] === o.dir), cx = 32 + dx * 64, cy = 32 + dy * 64;
      k.push(h('rect', { key: 'wc', x: cx - 27, y: cy - 27, width: 54, height: 54, rx: 10, fill: 'none', stroke: YEL, strokeWidth: 2, strokeDasharray: '4 4', opacity: 0.9 }));
      k.push(Ci('w', cx + 20, cy - 22, 8, YEL, SK(1.6)), h('text', { key: 't', x: cx + 20, y: cy - 16.5, textAnchor: 'middle', fontSize: 15, style: { fontFamily: 'Gaegu, cursive', fontWeight: 700, fill: INK } }, '!'));
    } else if (type === 'watch') k.push(Ci('w', 32, 32, 8, YEL, SK(1.6)), h('text', { key: 't', x: 32, y: 37.5, textAnchor: 'middle', fontSize: 15, style: { fontFamily: 'Gaegu, cursive', fontWeight: 700, fill: INK } }, '!'));
    return wrap(o, G('fx-' + type, null, ...k));
  }
  const FX = (type, o) => scoped((oo) => FX0(type, oo))(o || {});
  // 빌런 칸 표시(노선 머리, 글자 없음): 소란 별 + 번개 선
  function villainMark(z) {
    const pts = []; for (let i = 0; i < 16; i++) { const t = i / 16 * Math.PI * 2 - Math.PI / 2, rr = i % 2 ? 9.5 : 14; pts.push(`${(16 + Math.cos(t) * rr).toFixed(1)} ${(16 + Math.sin(t) * rr).toFixed(1)}`); }
    return h('svg', { width: z || 24, height: z || 24, viewBox: '0 0 32 32', style: { display: 'block', overflow: 'visible' } }, h('path', { d: 'M' + pts.join(' L') + ' Z', fill: YEL, stroke: INK, strokeWidth: 1.8, strokeLinejoin: 'round' }), h('path', { d: 'M18 8 L12.5 17 L17.5 17 L14 24', fill: 'none', stroke: INK, strokeWidth: 2.2, strokeLinecap: 'round', strokeLinejoin: 'round' }));
  }

  function CAT0(o) {
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
    if (st === 'asleep' && an) top.push(...zz(-1, 0, true));
    else if (st === 'asleep') top.push(...zz(-1, f, false));
    return wrap(o, G('cat', null, ...k, ...top));
  }

  function tile0(type, o) {
    o = o || {};
    const small = o.lod === 's';
    const S = SK(1.6), st = o.st || 'idle', n = o.n == null ? 2 : o.n, uid = o.uid || type;
    const bg = (c) => h('rect', { key: 'bg', x: 3, y: 3, width: 58, height: 58, rx: 10, fill: c || '#252a35' });
    const badge = (v, dim) => G('bd', small ? { transform: 'translate(54 9) scale(1.3) translate(-54 -9)' } : null, Ci('a', 54, 9, 9, dim ? '#6b7080' : YEL, S), h('text', { x: 54, y: 13.2, textAnchor: 'middle', style: { fontFamily: 'IBM Plex Mono, monospace', fontWeight: 600, fontSize: 12, fill: INK } }, String(v)));
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
      if (st === 'idle' && !small) kids.push(L('sp', 'M46 10 l0 8 M42 14 l8 0', 1.6, '#fff'));
    } else if (type === 'cart') {
      // 앞 칸의 짐수레. st 'up'(막음) | 'down'(넘어짐·통과), o.tag = 짐표 색(번호 0–3 또는 hex). 방향과 상관없이 같은 그림.
      // v4.3: 상자 2개를 빨간 고무끈(X자)으로 묶어 세워 둔다. 잠들면 끈이 툭 풀리며 **그 자리에서** 흐트러진다 —
      // 위 상자는 오른쪽 바닥으로 미끄러지고, 아래 상자는 왼쪽으로 기울어 주저앉고, 수레 틀은 뒤로 눕는다(정면에서 보면 바닥에 납작).
      // 조각(frame·b1·b2·tag·strap·loose)마다 두 자세 POSE[조각] = [기준점, 흐트러진 자세]. o.anim = { 조각: CSS animation } 으로 두 자세 사이를 움직인다.
      const RAIL = '#9aa0ab', T1 = '#c99a66', T2 = '#d9ae78', TAPE = '#ead6ad', CORD = '#c94a3a', dn = st === 'down', an = o.anim || {};
      const POSE = CART_POSE;
      const part = (k, ...c) => G(k, { style: { transform: dn ? POSE[k][1] : 'none', transformOrigin: POSE[k][0], animation: an[k] } }, ...c);
      const vis = (k, on, ...c) => G(k, { style: { opacity: on ? 1 : 0, animation: an[k] } }, ...c);
      kids = [El('sh', 32, dn ? 59 : 60, dn ? 28 : 19, 3, 'rgba(0,0,0,.32)'),
        part('frame', L('fo', 'M21 4 L21 58 M43 4 L43 58', 4.2), L('fi', 'M21 4 L21 58 M43 4 L43 58', 2.2, RAIL), L('fb', 'M17 58 L47 58', 3.6), L('fbi', 'M17 58 L47 58', 1.8, RAIL),
          h('rect', { key: 'g', x: 17, y: 1, width: 30, height: 4.8, rx: 2.2, fill: '#3a3f4a', ...SK(1.6) })),
        Ci('w1', 17, 60, 3.8, INK), Ci('w2', 47, 60, 3.8, INK)];
      if (!small) kids.push(Ci('h1', 17, 60, 1.4, RAIL), Ci('h2', 47, 60, 1.4, RAIL));
      kids.push(part('b1', h('rect', { key: 'r', x: 14, y: 33, width: 36, height: 24, rx: 2, fill: T1, ...SK(2) }), L('t', 'M32 33 L32 57', 3.4, TAPE), small ? null : h('rect', { key: 'lb', x: 18, y: 45, width: 9, height: 6, fill: '#f6f1e4', ...SK(1) })));
      kids.push(part('b2', h('rect', { key: 'r', x: 18, y: 14, width: 28, height: 19.5, rx: 2, fill: T2, ...SK(2) }), L('t', 'M32 14 L32 33.5', 3, TAPE)));
      if (!dn || an.strap) kids.push(vis('strap', !dn, L('co', 'M20 15 L44 55 M44 15 L20 55', 4.6), L('ci', 'M20 15 L44 55 M44 15 L20 55', 2.4, CORD), Ci('k1', 20, 15, 1.8, '#3a3f4a', SK(1.1)), Ci('k2', 44, 15, 1.8, '#3a3f4a', SK(1.1)), Ci('k3', 20, 55, 1.8, '#3a3f4a', SK(1.1)), Ci('k4', 44, 55, 1.8, '#3a3f4a', SK(1.1))));
      if (dn || an.loose) kids.push(vis('loose', dn, L('lo', 'M8 61.5 Q18 55.5 27 61 T49 60.5 Q55 57 59 61', 4.4), L('li', 'M8 61.5 Q18 55.5 27 61 T49 60.5 Q55 57 59 61', 2.2, CORD), Ci('k1', 8, 61.5, 1.8, '#3a3f4a', SK(1.1)), Ci('k2', 59, 61, 1.8, '#3a3f4a', SK(1.1))));
      if (dn && !small) kids.push(L('pf', 'M3 34 q2 -3 5 -1 M58 30 q2 -3 4 0', 1.4, LIGHT));
      kids.push(part('tag', luggageTag(tagCol(o.tag), true, small)));
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
  HUES.push([250, 'C']);
  HUES.push([260, 'D'], [20, 'D'], [55, 'D'], [135, 'D'], [105, 'D'], [345, 'D'], [300, 'D']); // v4 빌런 노선 22–28: 더 진하고 선명한 단계
  const TIER = { A: [0.5, 0.1, 0.76, 0.11], B: [0.4, 0.085, 0.68, 0.1], C: [0.42, 0.035, 0.74, 0.04], D: [0.45, 0.14, 0.82, 0.12] };
  const LINE_COLORS = HUES.map(([hh, t], i) => ({ n: i + 1, hue: hh, light: oklch(TIER[t][0], TIER[t][1], hh), dark: oklch(TIER[t][2], TIER[t][3], hh) }));

  // 노선 순서 v3. 색은 번호에, 아이콘은 기믹에 붙는다. icon(size, lod)
  const GI = {
    basic: s => ['기본', (z, l) => P({ a: 0, dir: 'd', size: z, uid: 'i1', f: 0, lod: l })],
    phone: s => ['휴대폰', (z, l) => P({ a: 4, kind: 'P', size: z, uid: 'i2', f: 0, lod: l })],
    coffee: s => ['커피', (z, l) => P({ a: 0, kind: 'C', dir: 'd', size: z, uid: 'i3', f: 0, lod: l })],
    pole: s => ['기둥', (z, l) => tile('pole', { size: z, uid: 'i11', st: 'split', lod: l })],
    cart: s => ['짐수레', (z, l) => h('svg', { width: z, height: z, viewBox: '0 0 64 64', style: { overflow: 'visible', display: 'block' } }, G('t', { transform: 'translate(14 26) scale(.6)' }, tile('cart', { size: 64, uid: 'i21t', lod: l })), G('p', { transform: 'translate(14 -12) scale(.6)' }, P({ a: 3, kind: 'H', dir: 'd', size: 64, uid: 'i21', f: 0, lod: l })))],
    window: s => ['창문 반사', (z, l) => tile('window', { size: z, uid: 'i4', lod: l })],
    wide: s => ['말똥말똥', (z, l) => P({ a: 1, kind: 'M', dir: 'd', size: z, uid: 'i5', f: 0, lod: l })],
    looker: s => ['두리번', (z, l) => P({ a: 3, kind: 'S', dir: 'd', size: z, uid: 'i6', f: 0, lod: l })],
    snorer: s => ['코골이', (z, l) => P({ a: 3, kind: 'N', st: 'asleep', size: z, uid: 'i7', f: 1, lod: l })],
    baby: s => ['우는 아기', (z, l) => P({ a: 5, kind: 'Y', dir: 'd', size: z, uid: 'i8', f: 0, lod: l })],
    talker: s => ['잠꼬대', (z, l) => P({ a: 4, kind: 'T', st: 'asleep', size: z, uid: 'i9', f: 0, lod: l })],
    mask: s => ['마스크', (z, l) => P({ a: 1, kind: 'K', dir: 'd', size: z, uid: 'i10', f: 0, lod: l })],
    door: s => ['출입문', (z, l) => tile('door', { size: z, uid: 'i12', n: 3, lod: l })],
    cat: s => ['고양이', (z, l) => CAT({ size: z, f: 0, lod: l })],
    standing: s => ['서서 가는 승객', (z, l) => P({ a: 0, kind: 'W', dir: 'd', size: z, uid: 'i14', f: 0, lod: l })],
    couple: s => ['커플', (z, l) => h('svg', { width: z, height: z, viewBox: '0 0 64 64', style: { overflow: 'visible', display: 'block' } },
      G('a', { transform: 'translate(-6 4) scale(.8)' }, P({ a: 4, dir: 'd', size: 64, uid: 'i15a', f: 0, hand: 'r', lod: l })), G('b', { transform: 'translate(19 4) scale(.8)' }, P({ a: 1, dir: 'd', size: 64, uid: 'i15b', f: 0, hand: 'l', lod: l })))],
    myopic: s => ['근시', (z, l) => P({ a: 4, kind: 'O', dir: 'd', size: z, uid: 'i16', f: 0, lod: l })],
    tiptoe: s => ['까치발 아이', (z, l) => P({ kind: 'J', dir: 'd', size: z, uid: 'i17', f: 0, lod: l })],
    earphone: s => ['이어폰', (z, l) => P({ a: 1, kind: 'E', dir: 'd', size: z, uid: 'i18', f: 0, lod: l })],
    tunnel: s => ['터널', (z, l) => tile('tunnel', { size: z, uid: 'i19', lod: l })],
    alarm: s => ['알람 시계', (z, l) => tile('alarm', { size: z, uid: 'i20', n: 3, lod: l })],
    speaker: s => ['스피커', (z, l) => P({ a: 4, kind: 'V', dir: 'd', size: z, uid: 'i22', f: 0, lod: l })],
    spread: s => ['쩍벌', (z, l) => h('svg', { width: z, height: z, viewBox: '0 0 64 64', style: { overflow: 'visible', display: 'block' } }, G('q', { transform: 'translate(0 14) scale(.5)' }, P({ a: 0, kind: 'Q', dir: 'd', size: 64, uid: 'i23', f: 0, lod: l })))],
    chicken: s => ['치킨', (z, l) => P({ a: 1, kind: 'F', dir: 'd', size: z, uid: 'i24', f: 0, lod: l })],
    call: s => ['스피커폰 통화', (z, l) => P({ a: 5, kind: 'L', dir: 'd', size: z, uid: 'i25', f: 0, lod: l })],
    bald: s => ['대머리', (z, l) => P({ kind: 'Z', dir: 'd', size: z, uid: 'i26', f: 0, lod: l })],
    patrol: s => ['순찰', (z, l) => P({ a: 3, kind: 'R', dir: 'd', size: z, uid: 'i27', f: 0, walk: 2, lod: l })],
    shout: s => ['호통', (z, l) => P({ a: 0, kind: 'U', dir: 'd', size: z, uid: 'i28', f: 0, lod: l })],
  };
  const ORDER = ['basic', 'phone', 'coffee', 'pole', 'cart', 'window', 'wide', 'looker', 'snorer', 'baby', 'talker', 'mask', 'door', 'cat', 'standing', 'couple', 'myopic', 'tiptoe', 'earphone', 'tunnel', 'alarm', 'speaker', 'spread', 'chicken', 'call', 'bald', 'patrol', 'shout'];
  const GIMMICKS = ORDER.map((key, i) => { const [name, icon] = GI[key](); return { n: i + 1, key, name, icon }; });
  // v5 섞기 장(마지막·끝없는 장). 노선 번호 대신 고리 기호, 색은 28색과 다른 단계 E(아주 깊은 밤색 남색).
  const MIX_COLOR = { key: 'mix', hue: 235, light: oklch(0.3, 0.14, 235), dark: oklch(0.86, 0.1, 235) };
  // 칩 안 고리 기호: 닫힌 고리 + 도는 방향 화살촉 1 + 역 점 3. 64 그리드, fg = 칩 위 글자 색(라이트 흰 / 다크 #14161C).
  function mixMark(o) {
    o = o || {}; const fg = o.fg || '#ffffff', z = o.size || 64, sw = o.lod === 's' ? 7.5 : 6.5;
    return h('svg', { width: z, height: z, viewBox: '0 0 64 64', style: { overflow: 'visible', display: 'block' } },
      h('rect', { key: 'ring', x: 10, y: 17, width: 44, height: 30, rx: 15, fill: 'none', stroke: fg, strokeWidth: sw }),
      h('path', { key: 'ah', d: 'M39 8.5 L49.5 17 L39 25.5 Z', fill: fg, stroke: fg, strokeWidth: 2, strokeLinejoin: 'round' }),
      o.lod === 's' ? null : h('circle', { key: 'd1', cx: 22, cy: 47, r: 4.2, fill: fg }),
      o.lod === 's' ? null : h('circle', { key: 'd2', cx: 42, cy: 47, r: 4.2, fill: fg }),
      o.lod === 's' ? null : h('circle', { key: 'd3', cx: 10, cy: 32, r: 4.2, fill: fg }));
  }
  // 섞기 장 아이콘: 여러 노선 승객 셋이 겹친 얼굴 묶음(뒤 둘 = 휴대폰·호통, 앞 = 기본). 다른 노선 아이콘과 같은 64 칸.
  const mixIcon = (z, l) => h('svg', { width: z, height: z, viewBox: '0 0 64 64', style: { overflow: 'visible', display: 'block' } },
    G('b1', { transform: 'translate(-8 -4) scale(.66)' }, P({ a: 4, kind: 'P', size: 64, uid: 'imx1', f: 0, lod: l })),
    G('b2', { transform: 'translate(29 -4) scale(.66)' }, P({ a: 0, kind: 'U', dir: 'd', size: 64, uid: 'imx2', f: 0, turn: false, lod: l })),
    G('f', { transform: 'translate(12 14) scale(.72)' }, P({ a: 2, dir: 'd', size: 64, uid: 'imx3', f: 0, lod: l })));
  const MIX = { n: null, key: 'mix', name: '섞기', icon: mixIcon, mark: mixMark, color: MIX_COLOR, loop: true };
  GIMMICKS.push(MIX); // 항상 맨 끝. 새 노선은 이 앞에 끼운다(GIMMICKS.splice(GIMMICKS.length - 1, 0, …)).
  // v5 어려운 역 표시: 역 동그라미(중심 cx, cy, 반지름 r) 둘레의 옅은 겹 테두리 + 오른쪽 위 작은 반짝 별(노랑 + 먹 외곽).
  // 경고가 아니라 도전 신호 — 빨강·해골·느낌표 쓰지 않음. 노선 색 28개 + 섞기 색 위에서 같은 별(먹 외곽이 대비를 맡음).
  function hardMark(o) {
    const cx = o.cx, cy = o.cy, rr = o.r || 12, c = o.color || INK, s = o.star || 7, bx = cx + rr * 0.95, by = cy - rr * 0.95, k = s * 0.2;
    return h('g', { key: o.key || 'hard' },
      o.ring === false ? null : h('circle', { key: 'hr', cx, cy, r: rr + 5.5, fill: 'none', stroke: c, strokeWidth: 2, strokeOpacity: 0.55 }),
      h('path', { key: 'hs', d: `M${bx} ${by - s} Q${bx + k} ${by - k} ${bx + s} ${by} Q${bx + k} ${by + k} ${bx} ${by + s} Q${bx - k} ${by + k} ${bx - s} ${by} Q${bx - k} ${by - k} ${bx} ${by - s} Z`, fill: '#ffcf5a', stroke: INK, strokeWidth: 1.5, strokeLinejoin: 'round' }));
  }
  return { INK, ARCH, KID, BALD, KING, FX, CART_POSE, villainMark, VILLAINS: 'VQFLZRU', P, CAT, tile, LINE_COLORS, GIMMICKS, TAG_COLORS, oklch, ripples, soundArcs, MIX, MIX_COLOR, mixMark, hardMark };
};
