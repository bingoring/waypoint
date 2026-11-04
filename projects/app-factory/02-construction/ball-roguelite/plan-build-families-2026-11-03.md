# 빌드 계열 · 런 구조 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 확정된 빌드 계열 설계(계열 17 · 단계 2/4/6 · 계열 잇기 · 지역 상성 · 4지역 런 구조)를 프로토타입에 단계별로 넣는다. 이 문서는 전체 순서(10덩어리 — 2026-11-04 P1b · P7b 추가)와 첫 덩어리 **P1 런 구조**의 상세 작업을 담는다.

**Architecture:** 한 파일 프로토타입 `prototypes/ball-roguelite/index.html`(약 3,300줄, 순수 JS + 캔버스)에 진형 규칙(`S.foe === 'rank'`)에서만 켜지는 경로로 넣는다. 이전 규칙(v1)은 그대로 두고 같은 시드 봇 지문으로 확인한다(§24~§27 방식). 시험은 `lab/*.js`(Node, `lab/load.js`가 스크립트를 화면 없이 띄움).

**Tech Stack:** 순수 JavaScript(브라우저 · Node 24), 캔버스 2D, 외부 의존 없음.

**Spec:** [`build-families-2026-11-03.md`](build-families-2026-11-03.md) — 특히 §2(세는 방식·단계·보상 끌림), §3(계열 17), §5-1(런 구조), §5-2(고르는 머리), §7(정한 것).

## Global Constraints
- 새 규칙은 모두 `S.foe === 'rank'`에서만. 이전 규칙 봇 지문 `FOE=v1 PICK=mixed` 40런 = `fdf868b7bc18e2e04d7e176a25b21310e2286ac3`(21승)이 바뀌면 안 된다.
- `selfTest()` 17조합은 결정성(`same`·`angleDiffers`)이 유지되어야 한다.
- 커밋 메시지에 `Co-Authored-By`·`Generated with Claude Code` 트레일러 금지(훅이 거부). 문서는 waypoint(`docs/dlc`) 먼저 커밋·푸시 → 앱 저장소에서 서브모듈 포인터. 작업 시작·푸시 전 `git pull --rebase`.
- 커밋 메시지 형식: `prototype(ball-roguelite): …` / `docs: waypoint 서브모듈 갱신(…)`.
- 화면 글은 한국어, 구슬·유물 이름은 지금 것 그대로.
- 런 구조(§5-1): 지역 하나 = 일반 → 일반 → 갈림길 → 엘리트 → 일반 → 쉼터 → 보스. 보상: 일반 = 구슬·강화·복제·유물을 섞은 무작위 3장 중 하나, 엘리트 = 유물 3장 중 하나, 보스 = 구슬 하나 + 유물 하나(마지막 보스 제외).

## Review Focus
- **시험용 「○부터」 버튼과 진형 후보 버튼(`restart(i)`·`restartPickR(i, j)`)** — 진형에서는 마디(node) 번호가 바뀐다. 갈림길·쉼터 마디부터 시작해도 멈추지 않고 그 마디 화면이 떠야 한다. (P1 Task 1·3 시험)
- **유물 더미가 3장보다 적을 때**(유물을 거의 다 가진 런) — 보상이 2장·1장이어도, 0장이면 「건너뛰기」만 떠도 멈추지 않아야 한다. (P1 Task 2 시험)
- **쉼터 「버리기」로 가방을 비우는 경우** — 4칸 가방은 늘 4칸이 차 있어야 하므로 버린 칸은 조약돌이 된다. 조약돌만 남은 가방에서 버리기는 고를 수 없다. (P1 Task 3 시험)
- **봇이 새 마디(갈림길·쉼터·보스 두 번 고르기)를 만나도 런을 끝까지 돈다** — `UI.fork`·`UI.rest`·두 번째 보상을 봇이 덮어쓰지 않으면 런이 그 자리에서 멈춘다. (P1 Task 4 시험)
- **조합별 패배 집계(`lab/foebot.js`의 `combos`)** — `FIGHTS` 이름으로 세던 것을 마디 이름으로 바꾸지 않으면 새 전투가 집계에서 빠진다. (P1 Task 4)

---

## 전체 순서 (10덩어리 — 덩어리마다 따로 계획을 쓰고, 끝날 때마다 플레이 가능)
| # | 덩어리 | 끝나면 되는 것 | 설계 절 |
|---|---|---|---|
| **P1** | **런 구조**(이 문서) | 3지역 × 7마디(21마디 · 18전투), 갈림길·쉼터, 섞인 보상, 엘리트 유물, 보스 구슬 + 유물, 봇이 끝까지 돎 | §5-1 |
| **P1b** | **고르는 머리 바탕** | 구슬 순서 고르기(한 바퀴 안에서 남은 칸 중 고름 · 화면 버튼 · 봇은 지금의 섞인 순서를 기본으로) · 「아끼는 구슬」 유물 · 페그 늘리기(장치 판 페그 약 60 → 100~120, 작은 크기를 진형 기본으로) + 적 체력·한 발 시간 다시 맞춤 · 단지 복사본 힘 나누기 실험 설정(기본 꺼짐) | §5-2 가 · 다 · 라 |
| P2 | 계열 틀 | 계열 17 표 · 아이템마다 계열 · 개수 세기 · 단계 2/4/6 갈고리 · 보상 끌림 1.5/2.5배 · 열쇠 없는 보상 막기 · 갈림길 「계열 문」 · 계열 봇(`PICK=family`) · 화면에 계열 단계 · 이전 태그/변신은 v1에만 | §2 · §7 |
| P3 | 판을 바꾸는 계열 | 기계 · 화상 · 얼음 · 페그 밭(씨뿌리개 구슬) | §3 |
| P4 | 상태이상 · 공격 모양 | 독 · 출혈 · 레이저(착지 가로 레이저) · 폭탄 · 거대·무게 | §3 |
| P5 | 구슬 수 · 표적 | 물량 · 다시 발동 · 크리 · 처형·사냥 · 보물 | §3 |
| P6 | 생존·대가 · 계열 잇기 | 소환 · 수호 · 피의 대가 · 디버프 종류 보너스 · 듀오 유물 · 변환 · 복사 · 확률 두 배 · 비움 보상 | §3 · §4 |
| P7 | 심연 지역 | 네 번째 지역(적·판·보스, 사서·살덩이 옮김) → 4지역 × 7마디 | §5 · §5-1 |
| **P7b** | **방해 적** | §5-2 나의 후보에서 지역마다 2~3종(예고 아이콘 · 잡으면 보상 카드 +1 · 처형 전리품) · 이미 있는 판 방해를 네 원칙으로 점검 · 숲 엘리트 뒤부터 | §5-2 나 |
| P8 | 균형 | 숲 엘리트부터 적 체력(벽) · 무작위 봇 거의 0 · 계열 봇 · 한 구슬 봇 대부분 클리어 · 최상의 덱 보스 1~3발 · 단지 힘 나누기 실험을 켤지 | §6 |

P1b는 P2보다 먼저 한다 — 페그 수가 바뀌면 계열 수치(페그 밭 · 화상 · 얼음 등)를 다시 재야 하므로, 판을 먼저 굳힌다(2026-11-04 오너 「고르는 머리 쪽으로 · 세 가지 다 반영」). P7b는 계열 효과(P3~P6)가 있어야 「괴롭히는 계열 · 푸는 계열」을 잴 수 있어 그 뒤에, P8 앞에 둔다. P2가 P3~P6의 바탕이다(계열 개수·단계 갈고리). P3~P6은 서로 독립이라 순서를 바꿔도 된다. P7은 P1 뒤 언제든, P8은 맨 끝.

---

## P1. 런 구조

**Files:**
- Modify: `prototypes/ball-roguelite/index.html` — `FIGHTS`(약 420줄) 아래에 진형 마디 표, `startFight`(약 480줄)·`winFight`(약 2730줄)·`UI`(약 2737줄)·`rewardCards`(약 2666줄) 옆에 진형 보상, `botRun`(약 3195줄), 설정 → 시험용 버튼(약 3095줄 `restart`·`restartPickR`).
- Create: `prototypes/ball-roguelite/lab/route.js` — 런 구조 시험(Node, `lab/formation.js`와 같은 `check()` 형식).
- Modify: `prototypes/ball-roguelite/lab/foebot.js` — 조합 집계를 마디 기준으로.

### Task 1: 진형 마디 표와 마디 진행

**Interfaces:**
- Produces:
  - `ROUTE_R`: 배열, 마디 `{ region, name, kind: 'fight' | 'fork' | 'rest', ...fightFields }`. `kind === 'fight'`인 마디는 `FIGHTS` 항목을 펼친 것(`pick`·`pickR`·`elite`·`boss`·`region`)에 `name`·`hpMul`(없으면 1)을 덧씌운다.
  - `route()` → `S.foe === 'rank' ? ROUTE_R : FIGHTS`
  - `curNode()` → `route()[RUN.fight]`
  - `enterNode()` — 지금 마디에 따라 `startFight()` · `UI.fork(node)` · `UI.rest(node)`를 부른다.
- 기존 코드에서 `FIGHTS[RUN.fight]`·`FIGHTS.length`를 쓰는 곳(482 · 1468 · 2730~2732 · 2759 · 2769 · 3222 · 3234줄 근처)은 `curNode()`·`route().length`로 바꾼다. v1에서는 `route() === FIGHTS`라 결과가 같다.

- [ ] **Step 1: 실패하는 시험 쓰기** — `lab/route.js`

```js
// 런 구조 시험 (node lab/route.js)
const { load } = require('./load');
const c = load('index.html', ['ROUTE_R', 'route', 'curNode']), a = c.api;
let fail = 0; const check = (name, ok, got) => { console.log(`${ok ? 'ok  ' : 'FAIL'} ${name}${ok ? '' : ' — ' + got}`); if (!ok) fail++; };
a.S = { ...a.S_DEFAULT, foe: 'rank' };
const R = a.ROUTE_R, kinds = R.map(n => n.kind === 'fight' ? (n.boss ? 'boss' : n.elite ? 'elite' : 'fight') : n.kind);
check('진형 마디 21개', R.length === 21, R.length);
check('지역마다 일반 · 일반 · 갈림길 · 엘리트 · 일반 · 쉼터 · 보스', kinds.join(',') === Array(3).fill('fight,fight,fork,elite,fight,rest,boss').join(','), kinds.join(','));
check('지역 순서 숲 → 동굴 → 성', R.filter(n => n.boss).map(n => n.region).join() === 'forest,cave,castle', R.filter(n => n.boss).map(n => n.region).join());
check('다섯 번째 일반 전투는 체력 ×1.2', R.filter((n, i) => i % 7 === 4).every(n => n.hpMul === 1.2), R.map(n => n.hpMul));
a.S = { ...a.S_DEFAULT, foe: 'v1' };
check('이전 규칙은 FIGHTS 12개 그대로', a.route() === a.FIGHTS && a.FIGHTS.length === 12, a.route().length);
console.log(fail ? `실패 ${fail}` : '모두 통과'); process.exitCode = fail ? 1 : 0;
```

- [ ] **Step 2: 시험이 실패하는지 확인** — Run: `node lab/route.js` / Expected: `ROUTE_R`가 없어 `TypeError`(또는 FAIL).
- [ ] **Step 3: `ROUTE_R`·`route()`·`curNode()`·`enterNode()`를 `FIGHTS` 바로 아래에 만들고, 위 줄들을 바꾼다.** 지역 하나의 마디는 그 지역 `FIGHTS` 넷(1 · 2 · 3(엘리트) · 보스)에서: 일반1 = 1, 일반2 = 2, 갈림길 = 갈림길 마디(문을 고른 뒤 싸울 전투는 2를 펼친 것), 엘리트 = 3, 일반5 = 2를 펼치고 `hpMul: 1.2`, 쉼터, 보스. 이름은 `숲 1`~`숲 5`·`숲 갈림길`·`숲 쉼터`·`숲 엘리트`·`숲 보스`. `hpMul`은 `startFight`에서 적 체력 계산(483줄의 곱)에 곱한다. `winFight`에서 다음 전투를 `startFight()` 대신 `enterNode()`로.
- [ ] **Step 4: 시험 통과 확인** — Run: `node lab/route.js && node lab/formation.js` / Expected: 둘 다 `모두 통과`.
- [ ] **Step 5: 커밋** — `git add prototypes/ball-roguelite/index.html prototypes/ball-roguelite/lab/route.js && git commit -m "prototype(ball-roguelite): 런 구조 1 — 진형 마디 21(지역마다 일반 · 일반 · 갈림길 · 엘리트 · 일반 · 쉼터 · 보스)"`

### Task 2: 섞인 보상 · 엘리트 유물 · 보스 구슬 + 유물

**Interfaces:**
- Consumes: `curNode()`(Task 1)
- Produces:
  - `rewardCardsR(r, kind)` → 카드 배열(최대 3장). `kind`: `'mixed'`(구슬·강화·복제·유물 한 더미에서 무작위 3장, 겹치지 않게) · `'orb'`(구슬 쪽만 3장: 새 구슬 · 가진 구슬 강화 · 복제) · `'relic'`(유물만 3장, 선택의 두루마리면 4장) · `'up'`(가진 구슬 강화만, 레벨 끝이면 복제). 카드 모양은 지금 `rewardCards`와 같다(`{ t: 'orb' | 'up' | 'copy' | 'relic', … }`).
  - `UI.reward(cards, f, next)` — 세 번째 인자 `next`(없으면 `enterNode`)를 받는다. 카드가 0장이면 「건너뛰기」만.
  - 진형 `winFight`: 일반 → `rewardCardsR(r, RUN.door?.reward || 'mixed')`, 엘리트 → `'relic'`, 보스 → 합성(지금처럼) → `'orb'` 고르기 → `'relic'` 고르기. 마지막 보스는 보상 없이 `UI.end(true)`.
- [ ] **Step 1: 실패하는 시험 쓰기** — `lab/route.js`에 덧붙인다.

```js
a.S = { ...a.S_DEFAULT, foe: 'rank' }; a.newRun(1, 0);
const firsts = new Set(); for (let s = 1; s <= 200; s++) { const cs = c.rewardCardsR(a.rng(s), 'mixed'); firsts.add(cs[0].t === 'relic' ? 'relic' : 'orb'); if (cs.length !== 3) { check('섞인 보상 3장', false, cs.length); break; } }
check('섞인 보상: 첫 카드가 구슬 쪽으로 고정되지 않음', firsts.has('relic') && firsts.has('orb'), [...firsts]);
check('엘리트 보상: 유물만 3장', c.rewardCardsR(a.rng(7), 'relic').every(x => x.t === 'relic'), c.rewardCardsR(a.rng(7), 'relic').map(x => x.t));
check('같은 시드 = 같은 카드', JSON.stringify(c.rewardCardsR(a.rng(9), 'mixed')) === JSON.stringify(c.rewardCardsR(a.rng(9), 'mixed')), '');
for (const k of Object.keys(a.RELICS)) a.RUN.relics.add(k);
check('유물을 다 가지면 유물 카드 0장(멈추지 않음)', c.rewardCardsR(a.rng(3), 'relic').length === 0, c.rewardCardsR(a.rng(3), 'relic').length);
// 보스: 구슬 고르기 → 유물 고르기 두 번 (UI를 가로채 순서를 적는다)
a.S = { ...a.S_DEFAULT, foe: 'rank' }; a.newRun(1, 0); a.RUN.fight = 6; const seen = [];
const UIo = { ...c.UI }; c.UI.synth = n => n(); c.UI.reward = (cs, f, next) => { seen.push(cs.every(x => x.t === 'relic') ? 'relic' : 'orb'); (next || (() => {}))(); };
c.enterNode = () => seen.push('next'); c.winFight(); Object.assign(c.UI, UIo);
check('보스: 구슬 하나 → 유물 하나 → 다음 마디', seen.join() === 'orb,relic,next', seen.join());
```

- [ ] **Step 2: 실패 확인** — Run: `node lab/route.js` / Expected: `rewardCardsR is not a function`.
- [ ] **Step 3: `rewardCardsR`를 `rewardCards` 바로 아래에, 진형 `winFight` 분기와 `UI.reward`의 `next` 인자를 넣는다.** 이전 규칙의 `rewardCards`·`winFight` 경로는 건드리지 않는다(`S.foe !== 'rank'`면 예전 그대로). `'mixed'` 더미: 구슬 쪽 후보(새 구슬 하나 · 가진 구슬 강화 · 복제 — 지금 `rewardCards`의 4칸 가방 규칙으로 만든 것) + 유물 후보 전부를 한 배열에 넣고 `shuffle(…, r)` 뒤 앞 3장. 보상 화면 문구의 「쉼터에서 체력을 모두 회복했다」는 진형에서 빼고(쉼터 마디가 따로 있음), 보스를 이긴 뒤 체력 전부 회복도 진형에서는 +8로 바꾼다.
- [ ] **Step 4: 통과 확인** — Run: `node lab/route.js && node lab/formation.js` / Expected: `모두 통과`.
- [ ] **Step 5: 커밋** — `git commit -am "prototype(ball-roguelite): 런 구조 2 — 섞인 보상 3장 · 엘리트 유물 · 보스 구슬 + 유물"`

### Task 3: 갈림길과 쉼터

**Interfaces:**
- Consumes: `enterNode()`·`curNode()`(Task 1), `rewardCardsR(r, kind)`(Task 2)
- Produces:
  - `forkDoors(r)` → 문 2~3개 `[{ reward: 'orb' | 'relic' | 'up' | 'elite' }]`. 늘 서로 다른 보상, `'elite'`는 30% 확률로 셋째 문.
  - `UI.fork(node)` — 문 카드(보상 종류 이름: 「구슬」·「유물」·「강화」·「엘리트 — 유물 2장 고르기」)를 보여 주고, 고르면 `RUN.door = door` 뒤 그 지역 「2」 전투(엘리트 문이면 그 지역 엘리트 전투를 펼친 것)로 `startFight()`. 전투를 이기면 `winFight`가 `RUN.door.reward`로 보상(엘리트 문은 `'relic'`을 두 번), 그 뒤 `RUN.door = null`.
  - `UI.rest(node)` — 셋 중 하나: 「회복」(최대 체력 30%) · 「구슬 강화」(가진 구슬 하나 Lv +1, `LV_MAX()`까지) · 「버리기」(구슬 칸 하나를 조약돌로, 또는 유물 하나 삭제). 고르면 `RUN.fight++` → `enterNode()`.
- [ ] **Step 1: 실패하는 시험 쓰기** — `lab/route.js`에 덧붙인다: (1) `forkDoors`가 시드 1~100에서 늘 2~3개, 보상이 겹치지 않음. (2) 갈림길 마디(인덱스 2)에서 `UI.fork`를 가로채 `'relic'` 문을 고르면 그 전투 승리 뒤 보상이 유물만. (3) 쉼터 마디(인덱스 5)에서 회복을 고르면 체력이 `+round(maxHp × 0.3)`(최대 체력까지), 마디가 6(보스)으로. (4) 버리기: 조약돌이 아닌 칸 하나가 조약돌이 되고 가방은 4칸 그대로, 조약돌만 있으면 버리기 선택지가 없음. (5) `restart(2)`·`restart(5)`(진형)가 갈림길·쉼터 화면을 띄운다(`UI.fork`·`UI.rest` 호출 여부로 확인).
- [ ] **Step 2: 실패 확인** — Run: `node lab/route.js` / Expected: `forkDoors is not a function`.
- [ ] **Step 3: `forkDoors`·`UI.fork`·`UI.rest`를 만들고, 설정 → 시험용의 `restart(i)`가 진형에서는 `route()` 마디를 쓰고 `enterNode()`로 들어가게 한다.** 버튼 줄은 진형이면 `ROUTE_R` 이름으로(「숲 갈림길부터」 등). `restartPickR(i, j)`는 `FIGHTS[i]` 기준을 유지하되, 진형에서는 그 `FIGHTS` 항목과 같은 이름의 첫 전투 마디로 들어간다.
- [ ] **Step 4: 통과 확인** — Run: `node lab/route.js && node lab/formation.js` / Expected: `모두 통과`.
- [ ] **Step 5: 브라우저 확인** — `preview_start ball-prototype` → 설정 → 시험용 「숲 갈림길부터」 · 「숲 쉼터부터」 → 문 카드·쉼터 카드가 뜨고, 고른 뒤 다음 마디로 넘어가며 콘솔 오류 없음. 휴대폰 폭(375px)에서 카드가 화면 안.
- [ ] **Step 6: 커밋** — `git commit -am "prototype(ball-roguelite): 런 구조 3 — 갈림길(보상 종류가 보이는 문 · 엘리트 문) · 쉼터(회복 · 강화 · 버리기)"`

### Task 4: 봇 · 측정 도구 · 기록

**Interfaces:**
- Consumes: Task 1~3 전부
- Produces: `botRun`이 진형 마디 21개를 끝까지 돈다. `UI.fork`(봇): `mixed` = 무작위 문, `focus` = 주력 구슬이 있으면 `'up'` 문 아니면 `'orb'` 문. `UI.rest`(봇): 체력 50% 미만이면 회복, 아니면 구슬 강화. 보스 두 번 고르기는 `UI.reward`의 `next`를 부른다. `lab/foebot.js`의 `combos`는 `route()` 마디 이름으로 센다.
- [ ] **Step 1: 실패하는 시험 쓰기** — `lab/route.js`에 덧붙인다: `c.botRun(s, { opts: { foe: 'rank' }, pick: 'mixed' })`를 시드 1~3으로 돌려 예외 없이 끝나고, `r.pf.split(' ').length === 21`, 이긴 런이면 `r.reached === '성 보스'`.
- [ ] **Step 2: 실패 확인** — Run: `node lab/route.js` / Expected: 봇이 갈림길에서 멈춰 `maxShots`까지 돌거나 `pf` 길이가 12.
- [ ] **Step 3: `botRun`의 `UI.fork`·`UI.rest`·`UI.reward(…, next)`를 위 규칙으로 덮어쓰고, `pf`를 `route().map(() => 0)`으로. `lab/foebot.js` 조합 집계를 `a.route()`로.**
- [ ] **Step 4: 통과 · 회귀 확인**
  - Run: `node lab/route.js && node lab/formation.js` / Expected: `모두 통과`
  - Run: 이전 규칙 지문 — 스냅샷을 `_curN.html`로 링크하고 `FILE=_curN.html FOE=v1 PICK=mixed` 40런(scratchpad `batch.sh`) / Expected: `fp` = `fdf868b7bc18e2e04d7e176a25b21310e2286ac3`, 21승
  - Run: `selfTest()` 비교(이전 스냅샷 대 지금) / Expected: BAD 없음
  - Run: 진형 40런 무작위 · 몰기 / Expected: 숫자를 기록만(전투가 18개로 늘어 이기는 수가 바뀜 — 균형은 P8)
- [ ] **Step 5: 기록** — waypoint `15-ball-roguelite.md`에 §28(런 구조: 마디 표 · 보상 · 봇 숫자 · 한 런 발 수와 예상 시간), 체크리스트, STATUS. waypoint 커밋·푸시 → 앱 저장소 서브모듈 포인터 커밋.
- [ ] **Step 6: 커밋 · PR** — `git commit -am "prototype(ball-roguelite): 런 구조 4 — 봇이 갈림길 · 쉼터 · 보스 두 번 고르기를 돎 · 조합 집계를 마디로"` → 브랜치를 푸시하고 PR(본문에 트레일러·AI 서명 없음).

## P1b. 고르는 머리 바탕 (2026-11-04)

**Spec:** [`build-families-2026-11-03.md`](build-families-2026-11-03.md) §5-2 가(구슬 순서 고르기) · 다(페그 늘리기) · 라(단지 힘 나누기 실험), §7 11·13·14. 브랜치 `ball-roguelite/choose`(#17 위).

**측정한 출발점(2026-11-04, `makeBoard` 직접):** 장치 판 15장의 보이는 일반 페그 — 지금 크기 22~78(평균 약 55) · 작게 24~112 · 아주 작게 28~135. 작게는 판마다 고르지 않다(점 개수를 정해 찍는 `pts`·`castleRow`·`solo` 무늬는 늘지 않음) → 「작게」만으로는 목표 100~120에 못 미치는 판이 많아, **작게 + 빈자리 채우기**로 간다.

**Review Focus(P1b):**
- 구슬 가두기(적이 가방에서 구슬을 삼킴)로 고른 칸이 사라질 때 — 고른 것이 풀리고 남은 칸의 첫 구슬이 나가야 한다. 돌려받은 칸은 이번 바퀴에 아직 안 쓴 칸으로 돌아온다. (Task 1 시험)
- 가방이 조약돌뿐이거나 칸이 하나뿐일 때 — 바퀴가 늘 한 칸 이상이고 멈추지 않아야 한다. (Task 1 시험)
- 아끼는 구슬로 정한 구슬을 쉼터에서 버리거나 합성으로 바꾼 뒤 — 유물이 죽지 않고 가방에서 가장 많은 구슬로 저절로 옮겨 간다. (Task 2 시험)
- 성 행진 판 — 채운 페그도 행진 층을 따라 숨었다 나타나고, 보이는 수가 목표 안이어야 한다. (Task 3 시험)
- 이전 규칙(v1) — 새 설정 둘(페그 · 단지 힘)은 진형에서만 듣는다. 봇 지문 `fdf868b7…` 그대로. (Task 5)

### Task 1: 구슬 순서 고르기
**Files:** `index.html`(`currentOrb` 약 554줄 · 발 끝 `B.bagIdx++` 약 2402줄 · 마지막 한 방 약 2136줄 · 구슬 가두기 약 2543·2580줄 · HUD `#area` 약 3162줄) · 새 시험 `lab/choose.js`
**Interfaces (Produces):** `cycleLeft(): number[]`(이번 바퀴에 남은 칸 번호, 가방 순서) · `B.used: number[]`(이번 바퀴에 쓴 칸) · `B.sel: number|null`(고른 칸) · `pickOrb(slot)`(화면 버튼) · `chooseOn(): boolean`(= `S.foe === 'rank'`)
- [x] 시험: 진형에서 고르지 않으면 쏘는 순서가 지금과 같다(`B.bag` 순서, 한 바퀴 뒤 다시 처음) · `pickOrb`로 고른 칸이 나가고 그 칸은 이번 바퀴에 다시 안 나옴 · 다 쓰면 모든 칸이 돌아옴 · 같은 구슬 두 칸이면 한 바퀴에 두 번 · 마지막 한 방은 `cycleLeft().length === 1`일 때 · 가둔 칸을 골라 두었으면 고른 것이 풀림 · 이전 규칙은 `bagIdx` 그대로
- [x] 구현 → `node lab/choose.js && node lab/route.js && node lab/formation.js` 통과
- [x] 화면: 조준 중(`MODE === 'aim'`) 진형이면 `#area` 「다음 구슬」 자리에 남은 칸을 작은 버튼으로(고른 것 강조, 같은 구슬 여러 칸은 「×2」처럼 묶음). 고르면 `B.ver++`(조준선 다시 계산). 375px에서 판을 가리지 않는지 확인
- [x] 커밋 `prototype(ball-roguelite): 고르는 머리 1 — 구슬 순서 고르기(한 바퀴 안에서 남은 칸 중 고름)`

### Task 2: 「아끼는 구슬」 유물
**Files:** `index.html`(`RELICS` · `applyCard` · `pickCard` 흐름 약 2811줄 · `UI`) · `lab/choose.js`
**Interfaces:** Consumes `cycleLeft`. Produces `RELICS.favorite`(`rank: true`) · `RUN.fav`(구슬 `kindKey`) · `favSlot(): number|undefined` · `UI.favorite(next)`
- [x] 시험: 유물이 있으면 바퀴가 칸 수 + 1(아끼는 구슬의 첫 칸이 끝에 한 번 더) · 얻을 때 기본값은 가방에서 칸이 가장 많은 구슬(같으면 레벨 높은 것, 그다음 앞 칸) · 그 구슬이 가방에서 사라지면 같은 규칙으로 옮겨 감 · 조약돌만 있으면 더하지 않음 · 이전 규칙 보상 더미에 나오지 않음
- [x] 구현: 보상에서 고르면 「어느 구슬을 아낄까」 창(가방의 구슬 종류마다 버튼), 봇·설정의 유물 받기는 기본값
- [x] 커밋 `prototype(ball-roguelite): 고르는 머리 2 — 아끼는 구슬 유물`

### Task 3: 페그 늘리기
**Files:** `index.html`(`S_DEFAULT` · `SCALES` 쓰는 곳 515·523·528·2517·2587·3227줄 · `makeBoard` 끝 · 설정 화면) · 새 측정 `lab/pegs.js`
**Interfaces:** Produces `S.peg: 'dense' | 'now'`(기본 `dense`) · `scaleKey(): string`(진형 + dense면 `'small'`, 아니면 `S.scale`) · `DENSE_TARGET = 110` · `DENSE_HP[판 이름]`
- [x] 측정 도구 `lab/pegs.js`: 장치 판 15장 × (now · dense)의 보이는 일반 페그 수, 첫 발 평균 피해(당김 41 × 시드 6), 한 발 최장 시간
- [x] 시험: dense에서 판마다 보이는 일반 페그 95~125(성은 행진 위치 8곳 평균) · 채운 페그가 장치·관문 자리를 비움(`devBlock` 뒤에 셈) · 같은 시드 같은 판 · v1과 `S.peg: 'now'`는 지금과 같은 판
- [x] 구현: `makeBoard`에서 무늬를 다 찍은 뒤(dense일 때만) 엇갈린 격자 간격을 16에서 0.5씩 줄이며 「보이는 일반 페그 ≥ 110」이 되는 첫 간격으로 빈자리를 채움(좌우 대칭, 기존 페그와 7px 이상, 장치 자리 제외 — 행진 판은 층 높이로 나눠 층마다 같은 비율). 난수는 쓰지 않는다(뒤의 특수 페그 시드 흐름 유지)
- [x] 적 체력: `DENSE_HP[판] = dense 첫 발 평균 ÷ now 첫 발 평균`을 `SCALE_HP` 대신 곱함(판마다 「한 발 피해 대비 체력」 유지) · 한 발 시간이 장치 쉼(10초) 안인지
- [x] 설정 「페그 수」: 촘촘하게(진형 기본, 작은 페그 약 110개) / 이전
- [x] 커밋 `prototype(ball-roguelite): 고르는 머리 3 — 페그 늘리기(작은 페그 + 빈자리 채우기, 판마다 약 110)`

### Task 4: 단지 힘 나누기 실험 설정
**Files:** `index.html`(`multiply` 약 2210줄 · 설정) · `lab/choose.js`
**Interfaces:** Produces `S.share: 'copy' | 'half'`(기본 `copy`, 진형에서만 들음)
- [x] 시험: half면 단지·보라 열매·관문이 늘린 구슬의 힘이 원래 구슬 힘의 절반(반올림, 최소 1), 원래 구슬은 그대로 · copy와 v1은 지금과 같음
- [x] 구현 · 설정 「늘어난 구슬의 힘」: 그대로 복사(지금) / 절반(실험 — 한 구슬 덱 비교용)
- [x] 커밋 `prototype(ball-roguelite): 고르는 머리 4 — 단지 힘 나누기 실험 설정`

### Task 5: 확인 · 봇 · 기록
- [x] `node lab/choose.js && node lab/route.js && node lab/formation.js` · 이전 규칙 봇 지문 `fdf868b7…`(21승) · `selfTest()` 결정성
- [x] 진형 봇 40런(무작위 · 몰기): 페그 dense · now 각각, half 한 번 — 숫자는 기록만(균형은 P8). 한 런 발 수
- [x] 브라우저 375px: 구슬 버튼 · 아끼는 구슬 창 · 촘촘한 판 모양, 콘솔 오류 없음
- [x] 기록 `15-ball-roguelite.md` §30 · 체크리스트 · STATUS → waypoint 커밋·푸시 → 서브모듈 포인터 → 브랜치 푸시 · PR(#17 위)

## 다음 계획
P1이 끝나면 P1b(고르는 머리 바탕) 계획을, 그다음 P2(계열 틀) 계획을 같은 형식으로 쓴다. P2 계획을 쓰기 전에 지금 구슬 41종·유물 75종 안팎을 계열 17에 나누는 표(계열마다 열쇠 3~4 · 보상 2~3, 모자란 계열의 새 아이템 목록)를 먼저 만들어 오너에게 보여 준다 — 콘텐츠 범위가 정해지는 자리라서.
