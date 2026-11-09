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
| **P2** | **계열 틀**(2026-11-05 계획) | 계열 17 표 · 아이템마다 계열 · 개수 세기 · 단계 2/4/6 갈고리 · 계열 고르게 뽑기 · 보상 끌림 1.5/2.5배 · 열쇠 없는 보상 막기 · 갈림길 「계열 문」 · 계열 봇(`PICK=family`) · 화면에 계열 단계 · 이전 태그/변신은 v1에만 | §2 · §3-1 · §7 |
| **P3** | **판을 바꾸는 계열**(2026-11-06 계획) | 기계 · 화상 · 얼음 · 페그 밭 단계 효과 12 + 새 아이템 8(태엽 구슬 · 부싯돌 · 기름통 · 고드름 · 눈사람 · 동상 · 서리 거울 · 씨뿌리개) · 적 체력 1차(§31) | §3 |
| **P4** | **상태이상 · 공격 모양**(2026-11-09 계획) | 독 · 출혈 · 레이저(착지 가로 레이저) · 폭탄 · 거대·무게 단계 효과 15 + 새 아이템 16(구슬 5 · 유물 11) | §3 |
| **P5** | **구슬 수 · 표적**(2026-11-09 계획) | 물량 · 메아리(다시 발동) · 크리 · 처형·사냥 · 보물 단계 효과 15 + 새 아이템 13(구슬 4 · 유물 9) + 황금왕 | §3 |
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

## P2. 계열 틀 (2026-11-05)

**Goal:** 진형에서 아이템마다 계열이 붙고, 개수·단계(2/4/6)를 세며, 보상이 계열 고르게 뽑기 · 보상 끌림 · 열쇠 규칙을 따른다. 갈림길에 계열 문이, 봇에 계열 몰기가 생긴다. 계열 효과(단계마다 하는 일)는 P3~P6이 `famStage()`에 걸어 넣는다.

**Spec:** [`build-families-2026-11-03.md`](build-families-2026-11-03.md) §2(세는 방식 · 보상 끌림 · 계열 고르게 뽑기) · §3(계열마다 「열쇠」 줄) · §3-1(아이템 배치 — 오너 확정 2026-11-05 「46개 그대로」) · §5-1(갈림길 문) · §6(계열 봇) · §7 3·4·8·9. 브랜치 `ball-roguelite/families`(`ball-roguelite/choose` 위, PR 기준도 그 브랜치).

**범위:** 지금 있는 구슬 40 · 유물 76만 계열에 넣는다. 새 아이템 46은 P3~P6에서 각 계열 효과와 함께 넣는다. 그래서 P2가 끝나도 계열 크기는 §3-1 「있는 구슬 · 있는 유물」 열 그대로다(보물 1 · 출혈 2 …). 6단계에 닿는 계열은 아직 일부뿐이다.

**계획에서 정한 것(설계서가 비워 둔 자리 — 구현자 판단, §32에 적는다):**
1. **계열 키**(코드 안 이름, 화면은 한국어): `mech` 기계 · `fire` 화상 · `ice` 얼음 · `field` 페그 밭 · `poison` 독 · `bleed` 출혈 · `laser` 레이저 · `bomb` 폭탄 · `mass` 거대·무게 · `swarm` 물량 · `resound` 메아리 · `crit` 크리 · `hunt` 처형·사냥 · `loot` 보물 · `summon` 소환 · `guard` 수호 · `blood` 피의 대가. 공용은 `common`(아이템에 `fam`이 없음). `ORBS`·`RELICS` 키와 겹치지 않게 골랐다(`echo`·`heavy`·`weight`는 이미 구슬·유물 키).
2. **열쇠·보상:** 구슬은 모두 열쇠(§7 8). 유물은 §3 계열마다 「열쇠」 줄에 이름이 있는 것만 열쇠, 나머지는 보상. 두 계열에 걸친 유물은 한 계열에서라도 열쇠면 열쇠다(벌집: 소환 열쇠 → 독에서도 열쇠).
3. **선택의 두루마리는 임시 열쇠.** 보물에는 P5 전까지 다른 아이템이 없다. 보상으로 두면 진형에서 영영 나오지 않으므로, P5에서 행운의 금박이 들어올 때 보상으로 바꾼다.
4. **세기는 늘 지금 가진 것으로.** 쉼터 버리기 · 합성으로 열쇠가 빠지면 개수·단계가 내려가고, 그 계열의 보상 유물이 다시 막힌다. 이미 가진 보상 유물은 계속 듣는다. 융합 구슬(레시피 없는 합성)은 두 재료의 계열을 모두 받는다(같은 계열이면 1).
5. **고르게 뽑기는 새 구슬 카드와 유물 카드에만.** 가진 구슬의 강화 · 복제 카드는 지금 그대로 섞는다(계열을 고르는 카드가 아니라서).
6. **계열 문:** 갈림길 문 후보가 「구슬 · 유물 · 강화」에서 「구슬 · 유물 · 강화 · 계열」로 넷이 된다(그중 둘 + 30% 엘리트, 지금과 같음). 계열 문의 계열 = 가진 개수가 가장 많은 계열(같으면 `FAM` 순서) 중 보상에 나올 카드가 3장 이상인 것. 그런 계열이 없으면 「보상 카드 3장 이상」인 계열 가운데 무작위. 그것도 없으면 계열 문을 후보에서 뺀다. 빈 문은 생기지 않는다.
7. **계열 봇:** 몰 계열 = `fam` 인자(`FAM` 환경 변수) → 없으면 첫 보상에서 공용이 아닌 첫 카드의 첫 계열. 고르는 순서는 그 계열 구슬의 복제·강화 → 그 계열 새 구슬 → 그 계열 유물 → 아무 강화 → 공용 유물 → 첫 카드. 갈림길은 그 계열 문 → (주력 구슬이 있으면) 강화 문 → 구슬 문 → 첫 문.

**Review Focus(P2):**
- **이전 규칙(v1)이 쓰는 함수** — `relicCands` · `rewardCards` · `checkTrans` · `cardHtml`은 v1도 쓴다. 계열 거르기 · 고르게 뽑기를 여기 넣으면 v1 지문 `fdf868b7…`이 깨진다. 진형 경로(`rewardCardsR`)에만 넣고, v1 결과가 같은지 시험으로 고정한다. (Task 2 · 3 시험, Task 5 지문)
- **후보가 모자랄 때** — 유물을 거의 다 가졌거나 열쇠 없는 보상이 다 빠져서, 뽑을 수 있는 카드가 3장보다 적거나 0장이어도 뽑기가 멈추지 않고 있는 만큼만 낸다. (Task 2 시험)
- **열쇠를 잃을 때** — 쉼터에서 계열의 하나뿐인 구슬을 버리면 단계가 내려가고, 그 계열 보상 유물이 더미에서 빠지되 이미 가진 것은 남는다. (Task 1 · 2 시험)
- **갈림길 문을 부르는 두 곳**(`UI.fork` · 봇 `UI.fork`) — 같은 시드 · 같은 가방이면 같은 문(계열까지 같음). 계열 문 보상은 늘 3장. (Task 4 시험)
- **375px 화면** — 카드의 계열 표시(계열 둘 + 열쇠/보상)와 HUD 계열 줄이 판과 버튼을 가리지 않는다. (Task 3 브라우저 확인)

### Task 1: 계열 자료 · 세기 · 단계
**Files:** `index.html`(`ORBS` 143~187줄 · `RELICS` 235~328줄 · `TAGS` 옆 330줄 · `applyCard` · `doSynth` · `restPick`) · 새 시험 `lab/family.js`(`lab/choose.js`와 같은 `check()` 형식)
**Interfaces (Produces):**
- `FAM`: `{ mech: '기계', fire: '화상', …, blood: '피의 대가' }`(위 「정한 것 1」 순서 그대로 17개)
- 아이템 자료: 계열이 있는 `ORBS[k].fam: string[]` · `RELICS[k].fam: string[]` · 열쇠 유물 `RELICS[k].key: true`. `tags`는 그대로 둔다(v1과 구슬 능력 `orbRole`이 씀).
- `famsOf(o): string[]` — 구슬 객체(융합은 재료 합집합) · 유물 키 문자열 모두 받음. 공용이면 `[]`
- `famCount(f): number` — 가진 구슬 **종류**(`kindKey` 기준, 조약돌 제외) 중 f가 붙은 것 + 가진 유물 중 f가 붙은 것
- `famStage(f): 0 | 2 | 4 | 6` · `famKeyed(f): boolean`(f가 붙은 구슬이 가방에 있거나 f가 붙은 열쇠 유물이 있음) · `isPayoff(k): boolean`(유물이고 `key`가 없고 `fam`이 있음)
- `famCheck()`: 진형에서만, 단계가 오른 계열마다 `FX.texts`에 「{계열} {단계}단계」(봇이면 생략). `RUN.famSeen = { [f]: 최고 단계 }`로 오름만 알림. `applyCard` · `doSynth` 끝의 `checkTrans()` 옆에서 부른다.

**자료(§3-1 「있는」 열 + §3 「열쇠」 줄 — 이대로 넣는다):**
| 계열 | 구슬 | 열쇠 유물 | 보상 유물 |
|---|---|---|---|
| mech | bolt, storm | rubber, drill, drumstick, cement | wandergate, gatekey, wideframe, doubledoor, secretmap, gatebell, goggles |
| fire | ember, cauldron, volcano | — | tinder, brazier, firewick |
| ice | frost, storm | icebell | bindchain |
| field | seed, ghost, moss, bell, garden, redring | — | rain, rebirth, hourglass, dance, clover, crystalseed |
| poison | sting, brew, cauldron | sporepouch, hive | — |
| bleed | briar, rose | — | — |
| laser | prism, redring | — | hunter |
| bomb | sticky, hammer, volcano | arsenal, powder, fuse | — |
| mass | heavy, giant, twins | weight | lead, bedrock, pierce, glove |
| swarm | twin, egg, cricket, frogking, echo, twins | dandelion, starsplit | dew, arrow, swarmflag, voidmaw, revolving |
| resound | boomer, swirl, echo | — | memory |
| crit | dagger, rose | whet, gardener | gambler, marksman, midas, goldhinge |
| hunt | scythe, chainweight, rift | horn, crookhook | axe, vinewrap |
| loot | — | scroll(임시) | — |
| summon | hornet | flies, hive | — |
| guard | holywater, catclaw, yarn | halo, mantle, holyflask | shell, spring, catbell, herb |
| blood | — | laststand, crown | leash, ninecat, fist |

공용(`fam` 없음): 구슬 stone · bouncy · firefly, 유물 spyglass · starmap · favorite · pioneer · soy · mushroom · antidote · lantern · cateye · fullpod · podfield.

- [x] 시험 `lab/family.js`:
  - 계열마다 붙은 아이템 수 = 위 표: `{ mech: 13, fire: 6, ice: 4, field: 12, poison: 5, bleed: 2, laser: 3, bomb: 6, mass: 8, swarm: 13, resound: 4, crit: 8, hunt: 7, loot: 1, summon: 3, guard: 10, blood: 5 }`
  - 공용이 위 목록과 정확히 같다(`fam` 없는 구슬 3 · 유물 11, 이름으로 비교) · `FAM` 키가 `ORBS`·`RELICS` 키와 겹치지 않는다 · `fam`의 값은 모두 `FAM`에 있다
  - 가방 `[bolt, bolt, stone, stone]` + 유물 rubber → `famCount('mech') === 2`(복제는 세지 않음), `famStage('mech') === 2`
  - 가방에 storm 하나 → mech · ice 둘 다 1 · 융합 구슬 `{ kind: 'fusion', parts: ['ember', 'sting'] }` → fire · poison 각 1, `{ parts: ['ember', 'volcano'] }` → fire 1
  - 4 · 6 경계: mech 아이템 3개 → 2단계, 4개 → 4단계, 5개 → 4단계, 6개 → 6단계
  - 계열의 하나뿐인 구슬을 `restPick('drop', i)`로 버리면 `famCount`가 1 줄고 `famKeyed`가 거짓이 된다(ember 하나 + brazier: 버리기 전 fire 2 · 열쇠 있음 → 뒤 1 · 열쇠 없음, brazier는 `RUN.relics`에 남음)
  - `famCheck`: 진형에서 mech를 1 → 2로 올리는 `applyCard` 뒤 `FX.texts`에 「기계 2단계」, 같은 단계로 다시 오르면(버렸다 다시 얻음) 알리지 않음, v1에서는 아무것도 안 함
- [x] 실패 확인: `node lab/family.js` / Expected: `FAM is not defined`류로 실패
- [x] 구현 → `node lab/family.js && node lab/choose.js && node lab/route.js && node lab/formation.js` 모두 통과
- [x] 커밋 `prototype(ball-roguelite): 계열 틀 1 — 계열 17 자료 · 세기 · 단계(2/4/6)`

### Task 2: 보상 — 계열 고르게 뽑기 · 보상 끌림 · 열쇠 없는 보상 막기
**Files:** `index.html`(`relicCands` 옆 · `rewardCardsR` 2788줄) · `lab/family.js`
**Interfaces:**
- Consumes: `famsOf` · `famCount` · `famKeyed` · `isPayoff`
- Produces:
  - `FAM_PULL = [[4, 2.5], [2, 1.5]]` · `famPull(f): number`(`common`은 1)
  - `famWeights(cands: { fams: string[] }[]): number[]` — 아래 식
  - `famPick(cands, r, n): cand[]` — 무게대로 하나 뽑고 빼고 무게를 다시 계산하기를 n번(후보가 바닥나면 거기까지)
  - `relicCandsR(): string[]` = `relicCands()`에서 `isPayoff(k) && !famsOf(k).some(famKeyed)`인 것을 뺀 것(진형 전용, `relicCands`는 손대지 않음)
  - `rewardCardsR(r, kind, fam?)` — 새 구슬 카드는 `famPick(fresh, r, 3)`, 유물 카드는 `famPick(relicCandsR(), r, 4)`로 순서를 정한다. 그 밖(구슬 40% · 유물 60% 칸 고르기, 강화·복제 카드, `relic`·`orb`·`up` 종류)은 지금 그대로

무게 식(§2): 후보 i의 계열 목록 `F_i`(빈 배열이면 `['common']`), 계열 f에 걸친 지금 후보 수 `n_f`라 하면
`w_i = Σ_{f ∈ F_i} famPull(f) / (|F_i| × n_f)`

- [x] 시험(`lab/family.js`에 덧붙임):
  - `famWeights` 고정값: 가진 것 없이 `[mech, mech, fire]` → `[0.5, 0.5, 1]` · `[fire, fire+poison]` → `[0.5, 0.75]` · 공용 하나 → `[1]` · mech 개수 2일 때 `[mech, mech, fire]` → `[0.75, 0.75, 1]` · 4일 때 `[1.25, 1.25, 1]`
  - 결정성: 같은 시드 `rng`로 `rewardCardsR` 두 번 → 같은 카드
  - 끌림 빈도: 가방 `[bolt, ember, stone, stone]` + 유물 rubber(mech 2 · fire 1, 둘 다 열쇠 있음)로 `rewardCardsR(rng(s), 'relic')`을 시드 1~5000 → **첫 카드만** 세어 (mech 유물 횟수) ÷ (fire 유물 횟수) = 1.5 ± 0.25(계열 무게 1.5 대 1, 표준오차 약 0.1)
  - 열쇠 없는 보상 막기: 가방이 조약돌뿐이면 `relicCandsR()`에 tinder·brazier·firewick(fire 보상)이 없다 · ember를 넣으면 셋 다 있다 · scroll은 아무것도 없어도 있다 · 진형에서 ember를 버리면 다시 빠진다
  - v1은 그대로: `S.foe = 'v1'`에서 `relicCands()`에 tinder가 있다(이 함수는 계열을 보지 않음)
  - 모자랄 때: 유물을 다 가진 런(`RUN.relics`에 `relicCandsR()` 전부)에서 `rewardCardsR(r, 'relic')`이 `[]`, `'mixed'`가 구슬 쪽만으로 3장 이하 · `famPick([], r, 3)`이 `[]`
- [x] 실패 확인 → 구현 → `node lab/family.js && node lab/route.js && node lab/choose.js && node lab/formation.js` 통과(`route.js`가 특정 카드를 고정해 두었다면 기대값을 새 뽑기에 맞춰 고치고 커밋 메시지에 적는다)
- [x] 커밋 `prototype(ball-roguelite): 계열 틀 2 — 보상을 계열 고르게 뽑기 · 끌림 1.5/2.5배 · 열쇠 없는 보상 막기`

### Task 3: 이전 태그 · 변신은 v1에만 + 화면에 계열
**Files:** `index.html`(`trans` · `checkTrans` 344~357줄 · `cardHtml` 2827줄 · 승리 화면 `tagLine` 2886줄 · 런 끝 2921줄 · HUD `#area`) · `lab/family.js`
**Interfaces:**
- Consumes: `FAM` · `famsOf` · `famCount` · `famStage` · `isPayoff`
- Produces: `famLine(max = 3): string` — 개수 1 이상인 계열을 많은 순(같으면 `FAM` 순)으로 `max`개, `기계 4·4단계 · 화상 1` 꼴(단계 0이면 개수만)
- 진형이면 `checkTrans()`가 아무것도 하지 않고 `trans(t)`가 늘 거짓. v1은 한 글자도 바꾸지 않는다. 변신이 진형에서 하던 일(`TRANS_R`)은 P3~P6에서 계열 단계로 옮긴다(§7 4). 구슬의 `tags`로 정하는 능력(칼날 처형 · 벌집의 벌레 구슬 등)은 그대로 둔다.

- [x] 시험:
  - 진형: `tags`에 `'blade'`가 있는 구슬·유물 3개를 가진 뒤 `checkTrans()` → `RUN.trans`가 비어 있고 `trans('blade') === false` · v1에서 같은 일 → `trans('blade') === true`
  - `cardHtml`: 진형 유물 카드 tinder에 「화상 보상」, rubber에 「기계 열쇠」, storm 구슬 카드에 「기계·얼음」, 공용 카드에는 계열 글이 없고, 진형 카드에 `[칼날` 같은 태그 글이 없다. v1 카드는 지금과 같은 문자열(태그 글 있음)
  - `famLine()`: mech 4 · fire 1 · crit 2 → `'기계 4·4단계 · 크리 2·2단계 · 화상 1'`
- [x] 구현: 진형이면 카드의 태그 글 자리에 계열(+ 유물이면 「열쇠」·「보상」), 승리 화면 「변신:」 줄 자리에 「계열: {famLine(17)}」, 런 끝 요약에 「계열:」 줄, HUD `#area`에 `famLine(3)`(진형 · 조준 중, P1b 구슬 버튼 위 한 줄)
- [x] 통과: `node lab/family.js && node lab/choose.js && node lab/route.js && node lab/formation.js`
- [x] 브라우저: `preview_start ball-prototype` → 진형 새 런 → 보상 카드 · 승리 화면 · HUD 계열 줄이 보이고, 375px에서 카드 글이 넘치지 않으며 HUD가 판을 가리지 않음, 콘솔 오류 없음
- [x] 커밋 `prototype(ball-roguelite): 계열 틀 3 — 태그·변신은 이전 규칙에만 · 카드 · 승리 화면 · HUD에 계열 단계`

### Task 4: 갈림길 「계열 문」
**Files:** `index.html`(`forkDoors` 473줄 · `DOOR_NAME` 474줄 · `UI.fork` 2890줄 · `winFight` 2853~2856줄) · `lab/family.js`
**Interfaces:**
- Consumes: `famCount` · `famPick` · `relicCandsR` · `rewardCardsR`
- Produces:
  - `famDoorFam(r): string | null` — 「정한 것 6」 규칙. 「보상에 나올 카드」 = 그 계열이 붙은 새 구슬(가방에 없는 기본 구슬) + `relicCandsR()` 중 그 계열
  - `forkDoors(r)` → 문 객체 배열, 계열 문은 `{ reward: 'family', fam }`
  - `doorName(d): [string, string]` — 계열 문이면 `[FAM[d.fam], `${FAM[d.fam]} 카드 3장 중 하나`]`, 아니면 `DOOR_NAME[d.reward]`
  - `rewardCardsR(r, 'family', fam)` → 그 계열 후보에서 `famPick` 3장(새 구슬 + 유물을 한 후보 목록으로)
  - `winFight`가 `d?.fam`을 `rewardCardsR`에 넘긴다
- [x] 시험:
  - 같은 시드 · 같은 가방이면 `forkDoors` 두 번이 같은 문(계열까지)
  - 가방에 bolt · rubber · drill(mech 3), ember(fire 1) → 계열 문이 나오면 그 계열은 `mech`
  - mech 아이템을 다 가져 mech 후보가 3장 미만이면 계열 문은 다른 계열(후보 3장 이상)
  - 모든 계열의 후보가 3장 미만인 런(가진 것을 크게 늘린 시험 상태)에서는 계열 문이 없고 문은 늘 2개 이상
  - `rewardCardsR(r, 'family', 'mech')` → 3장, 모두 `famsOf`에 `mech`가 있음
  - 시드 1~200에서 계열 문이 한 번 이상 나온다(문 후보 넷 중 둘)
- [x] 구현 → `node lab/family.js && node lab/route.js` 통과(`route.js`가 문 종류를 `orb · relic · up · elite`로 고정해 두었다면 `family`를 더하고 커밋 메시지에 적는다)
- [x] 브라우저: 시험용 「숲 갈림길부터」 → 계열 문 카드 글 · 고른 뒤 그 계열 보상 3장, 375px
- [x] 커밋 `prototype(ball-roguelite): 계열 틀 4 — 갈림길 계열 문(가장 많이 가진 계열의 카드 3장)`

### Task 5: 계열 봇 · 측정 · 기록
**Files:** `index.html`(`botRun` 3348줄) · `lab/foebot.js` · `lab/family.js` · waypoint `15-ball-roguelite.md` · `STATUS.md`
**Interfaces:**
- Consumes: Task 1~4 전부
- Produces: `botRun(seed, { …, pick: 'family', fam: string | null })` — 「정한 것 7」 규칙, 결과에 `fam`(몬 계열) · `fams`(끝났을 때 `famCount` 1 이상인 계열, `mech:5,fire:1` 꼴) 추가. `lab/foebot.js`는 `PICK=family`와 `FAM=<계열 키>`를 받는다.
- [x] 시험: `botRun(s, { opts: { foe: 'rank' }, pick: 'family', fam: 'mech' })` 시드 1~3 → 예외 없이 끝남 · `pf`가 21마디 · 결과 `fams`에서 mech가 가장 크다 · `fam` 없이 → `fam`이 `FAM` 키 하나로 정해짐
- [x] 회귀:
  - `node lab/family.js && node lab/choose.js && node lab/route.js && node lab/formation.js` → `모두 통과`
  - v1 지문: 스냅샷을 `_curN.html`로 링크하고 `FILE=_curN.html FOE=v1 PICK=mixed` 40런(scratchpad `batch.sh`) → `fp` = `fdf868b7bc18e2e04d7e176a25b21310e2286ac3`, 21승
  - `selfTest()` 이전 스냅샷 대 지금 → BAD 없음(`same` · `angleDiffers`)
- [x] 측정(기록만 — 균형은 P8): 진형 40런 × `PICK=mixed` · `focus` · `family`(계열 자동). 승수 · 진 곳 · 끝났을 때 가장 큰 계열의 단계 분포(0/2/4/6). 그리고 `PICK=family FAM=<17개 각각>` 4런씩 → 계열마다 닿은 최고 단계. 지금 아이템이 6개 미만인 계열(ice 4 · bleed 2 · laser 3 · resound 4 · loot 1 · summon 3 · poison 5 · blood 5)은 6단계에 못 닿는 것이 맞다(P3~P6에서 채움)
- [x] 기록: `15-ball-roguelite.md` §32(계열 틀: 「정한 것」 1~7 · 자료 표 요약 · 고르게 뽑기 식 · 계열 문 · 봇 숫자 · 변신이 진형에서 빠져 생긴 차이), 체크리스트, STATUS → waypoint 커밋·푸시 → 앱 저장소 서브모듈 포인터
- [x] 커밋 · PR: `git commit -am "prototype(ball-roguelite): 계열 틀 5 — 계열 봇(PICK=family · FAM) · 측정"` → `ball-roguelite/families` 푸시 → PR(기준 `ball-roguelite/choose`, 본문에 트레일러·AI 서명 없음). 병합 순서는 #16 → #17 → #18 → 이 PR

## P3. 판을 바꾸는 계열 — 기계 · 화상 · 얼음 · 페그 밭 (2026-11-06)

**Goal:** 네 계열의 단계 효과(2 · 4 · 6) 12개와 새 아이템 8개를 진형에 넣고, 계열 덱으로 한 발 수를 잰 뒤 진형 적 체력을 1차로 맞춘다.

**Spec:** [`build-families-2026-11-03.md`](build-families-2026-11-03.md) §3 「판을 바꾸는 계열」(단계 효과 원문) · §3-1 기계·화상·얼음·페그 밭 표(새 아이템 8) · §1 원칙 6·7(다시 채우기 · 한 발 상한) · §7 2·4·5·10. 체력 기준은 `15-ball-roguelite.md` §31(「무작위 덱 4~6발 · 계열 덱 2~3발」). 브랜치 `ball-roguelite/board-families`(`ball-roguelite/families` 위, PR 기준도 그 브랜치).

**Global Constraints(P3 추가):**
- 새 구슬 4 · 유물 4는 모두 `rank: true`. 하나라도 빠지면 이전 규칙 보상 더미가 바뀌어 지문 `fdf868b7…`이 깨진다.
- **마른 발 규칙:** 발 도중에 판 · 런 상태를 바꾸는 새 코드는 `jot(shot, obj, [바꾸는 키])`로 기록하거나 `if (!shot.dry)` 안에 둔다. 새 페그 필드(`age` · `ice` · `fruit` · `keep`)는 `JOT_KEYS`(1934줄)에 더한다. 봇이 봐야 하는 피해(전류 · 서리 거울 · 얼음 감옥 크리)는 `land`의 마른 발 조기 반환(약 2307줄) **앞에서** `shot.dmg`에 더한다.
- 단계 수치는 계열마다 표 하나에 모은다: `MECH_R` · `FIRE_R` · `ICE_R` · `FIELD_R`. P8 균형은 이 표만 고친다.
- 효과는 모두 `S.foe === 'rank'` 그리고 `famStage(f) >= 단계`일 때만. 새 아이템 효과는 그 아이템을 가졌을 때(구슬은 `ab`, 유물은 `has`) 단계와 상관없이 듣는다.

**계획에서 정한 것(설계서가 비워 둔 자리 — §33에 적는다):**
1. **불 페그는 이미 있는 `'fire'` 페그를 쓴다**(맞히면 화상 +2 그대로). 설계서의 「+1」 대신 지금 값을 둔다 — 같은 모양 페그가 둘이면 대화재 수를 세기 헷갈린다.
2. **불씨(화상 2):** 화상을 실은 구슬(`b.burn > 0`)이 깬 일반 페그는 발 끝에 불 페그로 되살아난다(`B.flameQ`, 한 발 `FIRE_R.seedMax = 6`개까지). 깬 자리가 그대로 불 페그가 되는 셈이다.
3. **들불(화상 4):** 적 턴 뒤(`regen`) 불 페그마다 가장 가까운 살아 있는 일반 페그 하나(16px 안)에 불이 옮는다. 한 턴 `FIRE_R.spread = 8`개까지. 화상 입은 적: 화상 중첩마다 받는 착지 피해 +3%, 그 발 동안 갑옷이 중첩만큼 줄고 막기 배율이 ×0.5에서 중첩마다 +0.05(최대 ×1).
4. **대화재(화상 6):** `regen`에서 들불 뒤 살아 있고 숨지 않은 불 페그가 **30개를 넘으면**(> 30) 모두 사라지고, 줄의 적마다 화상 +그 수(3턴). `RUN.ember += 1`. 전투를 시작할 때 일반 페그 `RUN.ember`개가 불 페그로 시작한다.
5. **서리(얼음 2):** 빙결을 실은 구슬(`b.st.freeze > 0`)이 일반 페그를 맞히면 깨지 않고 얼음 페그로 바꾼다(`p.ice = 1`, 충전은 한다). 얼음 페그를 맞히면 빙결 +1 · 구슬 속도 ×1.15 · 그 페그는 이번엔 깨진다.
6. **얼음 감옥(얼음 4):** 기절한 적(`f.daze > 0`)에게 착지한 구슬은 크리. 기절 동안 받은 착지 피해를 `f.jail`에 모아, 기절이 풀리는 순간(약 2757줄 `if (!--e.daze)`) 그 30%를 한 번 더 준다.
7. **영구 동토(얼음 6):** 기절을 거는 세 곳(약 1954 · 2251 · 2323줄)을 `setDaze(e, n)` 하나로 모으고, 거기서 `RUN.chill += 1`. 전투를 시작할 때 모든 적의 빙결 = `min(RUN.chill, ICE_R.chillCap = 5)`. 기절이 풀린 뒤 면역 턴이 2 → 1.
8. **씨뿌리기(페그 밭 2):** 씨앗 대기열(`B.seedQ`)로 돋는 페그가 `'norm'` 대신 `'seed'` 페그가 된다(맞히면 충전 ×2). 진형의 「첫 페그는 약초」는 그대로 둔다.
9. **자라남(페그 밭 4):** 씨앗 페그는 `regen`마다 `p.age += 1`, 3이 되면 열매(`p.fruit = 1`, `p.keep = true`, 종류는 크리 · 약초 · 폭탄을 `B.rnd`로 고름). 열매를 깨면 충전 ×3이고 런 기록 `RUN.fruits += 1`. 설계서의 「리프레시가 30%를 되살린다」는 리프레시가 이미 판 전체를 되살리므로, **「살아 있는 일반 페그가 `B.normal0`의 절반 아래면 `regen`에서 사라진 일반 페그의 30%를 되살린다」**로 읽는다(원칙 6 「굶지 않게」).
10. **과수원(페그 밭 6):** 전투를 시작할 때 일반 페그 `floor(RUN.fruits / 20)`개가 열매로 시작. 살아 있는 페그가 전투 시작 때(`B.peg0`)보다 많으면 많은 만큼 착지 +1%.
11. **설치(기계 2):** 진형 전투의 첫 발 전에 「범퍼 · 버섯 · 단지」 셋 중 하나를 고르는 창 → `MODE = 'place'` → 판을 누른 자리에 놓는다(`PEG_TOP + 10` ~ `PEG_BOTTOM - 10`, 가로 12 ~ `W - 12`로 자르고 반경 8 안 페그는 치움). 범퍼 `{ x, y, spin: 0 }`, 버섯 `{ k: 'shroom', r: 4.5 }`, 단지 `{ k: 'jar', n: 2, r: 6 }`. 놓은 장치는 `B.placed`에 두고, 전투 중 판이 새로 깔리면(약 2540줄 `newBoard`) 다시 놓는다. 봇은 범퍼를 `(W / 2, (PEG_TOP + PEG_BOTTOM) / 2)`에 놓는다. 창에는 「건너뛰기」도 있다.
12. **전류 · 장치 성장 · 회로(기계 4 · 6):** 장치 충돌 여섯 곳(단지 약 1996 · 버섯 1997 · 바람개비 2005 · 범퍼 2029 · 스피너 2045 · 드롭 2051줄)이 모두 `devHit(shot, b, u, kind)`를 부른다. 전류 = 그 순간의 `front()`에게 `MECH_R.zap × 장치 레벨`(첫 값 1 — 설계서 「장치 레벨만큼」), 한 발 `MECH_R.zapCap = 60`번까지. 장치 성장 = 한 장치를 한 발에 10번 맞히면 `RUN.devLv[kind] += 1`(발마다 장치당 한 번). 레벨 효과: 전류 × 레벨, 단지 배수 +(레벨 − 1), 버섯 튕김 ×(1 + 0.15 × (레벨 − 1)). 회로 = 장치가 맞으면 가장 가까운 다른 장치도 전류 한 번 + 그 구슬 충전 1, 한 발 `MECH_R.circuitCap = 20`번까지(원칙 7).
13. **변신이 하던 일:** 기계 · 씨앗 변신의 진형 역할(장치 충전 2배 · 드롭 하나 덜 · 관문 폭 +20% / 첫 착지 끌기)은 되살리지 않는다. 기계는 설치 · 전류 · 성장이, 페그 밭은 씨앗 · 열매가 그 자리를 맡는다.
14. **단계 설명을 화면에:** P2는 단계 글을 보여 주지 않았다. P3부터 승리 화면에 2단계 이상인 계열의 단계 한 줄(「기계 4 · 전류 — 장치에 맞을 때마다 1번 칸 적에게 전기」)을 보여 준다(`FAM_STAGE[f][s]`, 효과가 들어간 계열만).

**새 구슬 레벨 식:** 태엽 구슬 `clock: 1 + lv`(장치에 맞을 때마다 이 구슬 힘 +, 구슬마다 10번까지) · 부싯돌 `flint: 2 + floor(lv / 2)`(벽 · 장치에 튕길 때마다 가장 가까운 일반 페그 그 수만큼 불 페그로, 구슬마다 8개까지) · 고드름 `icicle: 2 + floor((lv - 1) / 2)`(이 발 첫 착지 적에 빙결) · `iceBreak: 1.5`(기절한 적에 착지 ×1.5) · 씨뿌리개 `sowDist: 30 - 3 × (lv - 1)`(지나간 길 그 거리마다 씨앗 하나) · `sowCap: 8 + 2 × lv`(한 발). 모두 `crit: 2`, `look`은 계열 색(기계 노랑 · 화상 주황 · 얼음 하늘 · 페그 밭 초록).

**Review Focus(P3):**
- **마른 발 새는 것** — 봇이 각도마다 미리 쏴 보는 발이 얼음 페그 · 불 · 씨앗 대기열 · 장치 레벨 · 냉기 · 열매 수를 바꾸면, 실제로 쏘기 전에 판이 달라진다. `dryShot` 뒤 `B.pegs`의 종류 · `ice` · `age`, `RUN.devLv` · `RUN.chill` · `RUN.fruits` · `RUN.ember`, `B.seedQ` · `B.flameQ` 길이가 같아야 한다. (Task 0 시험, 계열마다 Task 1~4에서 덧붙임)
- **성 행진** — 불 · 얼음 · 씨앗 · 열매 페그와 놓은 장치가 행진으로 내려가거나 숨어도 멈추지 않고, 대화재 · 들불은 숨은 페그를 세지 않는다. (Task 2 · 4 시험)
- **전투 중 판이 새로 깔릴 때**(판을 다 비움) — 놓은 장치가 다시 놓이고, 불씨 · 과수원 시작 페그도 새 판에 다시 깔린다. (Task 1 · 2 · 4 시험)
- **한 발 시간** — 들불 · 회로 · 씨뿌리개가 겹쳐도 한 발이 장치 쉼(10초) 안에서 끝나고, 상한(`zapCap` · `circuitCap` · `spread` · `sowCap`)이 지켜진다. (Task 5 측정)
- **375px 설치** — 「설치할 장치」 창과 판 누르기가 P1b 구슬 버튼과 겹치지 않고, 놓는 동안 발사되지 않는다. (Task 1 브라우저 확인)

### Task 0: 공통 바탕 — 새 아이템 자료 · 장치 맞힘 · 기절 걸기 · 새 페그 · 단계 글
**Files:** `index.html`(`ORBS` · `RELICS` · `FAM_ITEMS` 약 336줄 · 장치 충돌 여섯 곳 · 기절 세 곳 · `JOT_KEYS` 1934줄 · 페그 그리기 약 3160줄 · 승리 화면) · `lab/family.js`(개수 고침) · 새 시험 `lab/stages.js`(`lab/formation.js`의 `lane()` · `shoot()` · `turn()` 방식)
**Interfaces (Produces):**
- 새 키: 구슬 `clock`(태엽 구슬) · `flint`(부싯돌) · `icicle`(고드름) · `sower`(씨뿌리개), 유물 `oilcan`(기름통) · `snowman`(눈사람, 열쇠) · `frostbite`(동상) · `frostmirror`(서리 거울). `FAM_ITEMS`: mech += clock, fire += flint · oilcan, ice += icicle · snowman(열쇠) · frostbite · frostmirror, field += sower
- `devHit(shot, b, u, kind: 'bumper' | 'shroom' | 'jar' | 'mill' | 'spinner' | 'drop'): void` — Task 0에서는 빈 함수(장치 여섯 곳에서 부름). Task 1이 채운다
- `setDaze(e, n): void` — `e.daze = n`(지금 세 곳과 같은 값), Task 3이 냉기를 더한다
- `MECH_R` · `FIRE_R` · `ICE_R` · `FIELD_R`(「정한 것」의 값) · `FAM_STAGE = { mech: { 2: '설치 — …', 4: '전류 — …', 6: '장치 성장 — …' }, fire: …, ice: …, field: … }` · `famStageLines(): string[]`(2단계 이상, `FAM_STAGE`에 있는 계열만)
- 새 페그 그리기: 얼음(`p.ice`, 하늘색 테) · 씨앗(`'seed'`, 작은 초록 점) · 열매(`p.fruit`, 금색 테)
- [x] 시험: `family.js` 개수 → `mech: 14, fire: 8, ice: 8, field: 13`(나머지 그대로) · 새 8개 모두 `rank: true` · 이전 규칙 `relicCands()`와 `rewardCards` 구슬 후보에 새 키가 없다 · `stages.js`: 각 장치를 맞히는 발에서 `devHit`가 그 `kind`로 불린다(시험용으로 감싸 셈) · 기절 세 곳이 `setDaze`를 거친다(값은 지금과 같음) · `famStageLines()`가 mech 4단계에서 「설치」 · 「전류」 두 줄 · 마른 발 하나 뒤 `B.pegs` 상태와 `RUN` 기록이 같다
- [x] 실패 확인 → 구현 → `node lab/stages.js && node lab/family.js && node lab/choose.js && node lab/formation.js` 통과
- [x] 커밋 `prototype(ball-roguelite): 판 계열 0 — 새 아이템 8 자료 · 장치 맞힘 · 기절 걸기 · 새 페그 · 단계 글`

### Task 1: 기계 — 설치 · 전류 · 장치 성장 · 회로 · 태엽 구슬
**Files:** `index.html`(`devHit` · `startFight` 599~621줄 · 포인터 3366~3368줄 · `newBoard` 다시 깔기 약 2540줄 · `multiply` 단지 배수 · 버섯 튕김 1997줄 · `botRun`) · `lab/stages.js`
**Interfaces:**
- Consumes: `devHit` 자리 · `MECH_R` · `famStage`
- Produces: `RUN.devLv: { [kind]: number }`(없으면 1) · `devLv(kind): number` · `placeDevice(kind, x, y): boolean`(놓았으면 참) · `UI.place(next)`(설치 창) · `MODE === 'place'` · `B.placed: { kind, x, y } | null`
- [x] 시험:
  - 설치: mech 2단계 진형 전투 시작 → `UI.place`가 열림 · `placeDevice('bumper', 90, 120)` → `B.bumpers`에 하나 늘고 반경 8 안 페그가 없음 · 판 밖 좌표는 범위 안으로 자름 · mech 1단계에서는 열리지 않음 · 판을 새로 깔면 `B.placed`가 다시 놓임 · 봇은 `(90, 119)`에 범퍼
  - 전류: mech 4단계에서 범퍼를 맞힌 발 → 1번 칸 적 체력이 맞힌 수 × 1만큼 더 줄고 `shot.dmg`에 들어감 · 마른 발도 `shot.dmg`는 같고 적 체력은 그대로 · 한 발 60번에서 멈춤 · 3단계에서는 없음
  - 장치 성장: mech 6단계에서 한 범퍼를 한 발에 10번 → `RUN.devLv.bumper === 2`, 같은 발에 20번이어도 2 · 마른 발에서는 오르지 않음 · 단지 레벨 2면 배수가 하나 더 · 회로: 장치 둘이 있을 때 하나를 맞히면 다른 하나의 전류도, 한 발 20번에서 멈춤
  - 태엽 구슬: 장치에 맞을 때마다 힘 +2(Lv1), 구슬마다 10번까지 · 단계와 상관없이 들음
- [x] 실패 확인 → 구현 → `node lab/stages.js && node lab/choose.js && node lab/route.js` 통과
- [x] 브라우저: mech 2단계 런 → 「설치할 장치」 창 · 판을 눌러 범퍼가 놓이고 그 누름으로 발사되지 않음 · 375px에서 창과 구슬 버튼이 겹치지 않음 · 콘솔 오류 없음
- [x] 커밋 `prototype(ball-roguelite): 판 계열 1 — 기계(설치 · 전류 · 장치 성장 · 회로) · 태엽 구슬`

### Task 2: 화상 — 불씨 · 들불 · 대화재 · 부싯돌 · 기름통
**Files:** `index.html`(`breakPeg` 2147줄 · `endShot` 2499줄 · `regen` 약 2805줄 · `landMods` 2332줄 · 벽 튕김 1971줄 · `devHit` · `onDeath` 2721줄 · `startFight`) · `lab/stages.js`
**Interfaces:**
- Consumes: `devHit` · `FIRE_R` · 불 페그 `'fire'`
- Produces: `B.flameQ: peg[]` · `RUN.ember: number` · `ignite(p): void`(일반 페그를 불 페그로, 마른 발이면 `jot`) · `fireSpread(): number`(옮긴 수) · `inferno(): boolean`
- [x] 시험:
  - 불씨: fire 2단계, 화상을 실은 구슬이 일반 페그 10개를 깬 발 → 발 끝에 그중 6개가 불 페그로 살아남 · 화상 없는 구슬은 0 · 1단계는 0 · 마른 발 뒤 `B.flameQ` 비어 있음
  - 들불: fire 4단계, 불 페그 3개 · 옆에 일반 페그 → `regen` 뒤 불 페그 6개(각 하나씩) · 한 턴 8개까지 · 숨은 페그로는 안 옮음 · 화상 4중첩 적에게 착지 100 → 112, 갑옷 5인 적은 갑옷 1로 계산
  - 대화재: fire 6단계, 불 페그 31개 → `regen` 뒤 0개 · 줄의 적마다 화상 +31 · `RUN.ember === 1` · 30개면 일어나지 않음 · 다음 전투 시작 때 불 페그 1개
  - 부싯돌: 벽에 한 번 튕기면 가장 가까운 일반 페그 2개가 불 페그(Lv1) · 구슬마다 8개까지 · 단계와 상관없이
  - 기름통: 화상 5인 적이 쓰러지면 줄의 다른 적마다 화상 +5
- [x] 실패 확인 → 구현 → `node lab/stages.js && node lab/formation.js` 통과
- [x] 커밋 `prototype(ball-roguelite): 판 계열 2 — 화상(불씨 · 들불 · 대화재) · 부싯돌 · 기름통`

### Task 3: 얼음 — 서리 · 얼음 감옥 · 영구 동토 · 고드름 · 눈사람 · 동상 · 서리 거울
**Files:** `index.html`(`hitPeg` 2086줄 · `land` 2271줄 · `landMods` · `enemyTurn` 기절 풀림 2757줄 · `setDaze` · `startFight`) · `lab/stages.js`
**Interfaces:**
- Consumes: `setDaze` · `ICE_R`
- Produces: `p.ice` · `f.jail` · `RUN.chill`
- [x] 시험:
  - 서리: ice 2단계, 빙결을 실은 구슬이 일반 페그를 맞힘 → 페그가 살아 있고 `p.ice === 1`, 충전은 됨 · 그 얼음 페그를 다시 맞힘 → 깨지고 구슬 빙결 +1 · 속도 ×1.15 · 마른 발 뒤 `p.ice` 그대로
  - 얼음 감옥: ice 4단계, 기절한 적에게 착지 → 크리로 계산 · 기절 동안 받은 착지 피해 200 → 기절이 풀리는 적 턴에 60 더
  - 영구 동토: ice 6단계, `setDaze` 두 번 → `RUN.chill === 2` · 다음 전투 시작 때 적마다 빙결 2 · `RUN.chill = 9`여도 빙결 5 · 기절이 풀린 뒤 면역 1턴
  - 고드름: 이 발 첫 착지 적에 빙결 2(Lv1) · 기절한 적에 착지 ×1.5 · 눈사람: 전투 시작 때 얼음 페그 5 · 동상: 빙결 3 이상 적은 착지 ×1.3 · 서리 거울: 기절한 적에게 크리 착지 100 → 줄의 다른 적마다 30
- [x] 실패 확인 → 구현 → `node lab/stages.js && node lab/formation.js` 통과
- [x] 커밋 `prototype(ball-roguelite): 판 계열 3 — 얼음(서리 · 얼음 감옥 · 영구 동토) · 고드름 · 눈사람 · 동상 · 서리 거울`

### Task 4: 페그 밭 — 씨뿌리기 · 자라남 · 과수원 · 씨뿌리개
**Files:** `index.html`(`regen` 2805~2812줄 · `breakPeg` · `charge` · `rollSpecials` 1879줄 · `landMods` · `startFight` · `march` 2792줄) · `lab/stages.js`
**Interfaces:**
- Consumes: `B.seedQ` · `FIELD_R` · `B.normal0`
- Produces: `'seed'` 페그 · `p.age` · `p.fruit` · `RUN.fruits` · `B.peg0`
- [x] 시험:
  - 씨뿌리기: field 2단계, 씨앗 대기열 3개 → `regen` 뒤 `'seed'` 페그 3(첫 하나는 약초 그대로면 2) · 씨앗 페그를 깨면 충전 2배 · 1단계는 `'norm'`
  - 자라남: field 4단계, 씨앗 페그가 `regen` 3번 뒤 열매(크리 · 약초 · 폭탄 중 하나, `keep`) · `rollSpecials`가 열매를 되돌리지 않음 · 열매를 깨면 충전 3배 · `RUN.fruits` +1(마른 발은 그대로) · 일반 페그가 `B.normal0`의 절반 아래면 `regen`에서 사라진 일반 페그의 30%가 돋음, 절반 이상이면 안 돋음
  - 과수원: field 6단계, `RUN.fruits = 41` → 다음 전투 시작 때 열매 2 · 살아 있는 페그가 시작보다 10개 많으면 착지 100 → 110
  - 씨뿌리개: 30px마다 씨앗 대기열 하나(Lv1), 한 발 10개까지 · 단계와 상관없이 · 성 행진 판에서 씨앗 · 열매가 행진과 함께 내려감
- [x] 실패 확인 → 구현 → `node lab/stages.js && node lab/formation.js && node lab/choose.js` 통과
- [x] 커밋 `prototype(ball-roguelite): 판 계열 4 — 페그 밭(씨뿌리기 · 자라남 · 과수원) · 씨뿌리개`

### Task 5: 봇 · 측정 · 기록
**Files:** `index.html`(`botRun`) · `lab/foebot.js` · 새 측정 `lab/stagebot.js` · waypoint `15-ball-roguelite.md` · `STATUS.md`
**Interfaces:**
- Consumes: Task 0~4 전부
- Produces: `botRun(seed, { …, bag: orb[] | null })`(시작 가방을 덮어씀) · `lab/stagebot.js`: 계열 × 단계(2 · 4 · 6)마다 그 단계가 켜지는 가방 · 유물로 시작하는 진형 봇을 돌려 지역마다 한 전투 평균 발 수 · 한 발 최장 시간을 낸다
- [x] 시험: `botRun(1, { opts: { foe: 'rank' }, bag: [{ kind: 'flint', lv: 1 }, …] })`의 첫 가방이 그 가방 · `stagebot.js`가 4계열 × 3단계 표를 낸다
- [x] 회귀: `node lab/stages.js && node lab/family.js && node lab/choose.js && node lab/route.js && node lab/formation.js` · 이전 규칙 지문 `fdf868b7…`(21승) · `selfTest()` 이전 스냅샷과 같음
- [x] 측정(기록): 진형 40런 × mixed · focus · family(자동) · family `FAM=` mech · fire · ice · field 각 10런 → 승수 · 6단계 런 수. `stagebot.js` 표(계열 × 단계 × 지역 → 평균 발 수 · 한 발 최장 시간). 한 발이 10초를 넘는 조합이 있으면 그 계열 상한을 낮추고 다시 잰다
- [x] 기록 `15-ball-roguelite.md` §33(「정한 것」 1~14 · 측정 표), 체크리스트, STATUS → waypoint 커밋·푸시 → 서브모듈 포인터
- [x] 커밋 `prototype(ball-roguelite): 판 계열 5 — 시작 가방 봇 · 단계별 발 수 측정`

### Task 6: 적 체력 1차 (진형)
**Files:** `index.html`(적 체력 세 곳 609 · 2659 · 2729줄) · `lab/stagebot.js`
**Interfaces:** Produces `REGION_HP_R: { forest, cave, castle }`(진형에서만 `REGION_HP`에 더 곱함) · `regionHp(): number`(세 곳이 함께 씀)
- [x] 정하기: Task 5의 무작위 봇 「동굴 · 성 한 전투 중앙 발 수」가 4~6이 되는 배율을 0.25 간격으로 찾는다(숲은 §7 5 「아무 구슬로도 넘김」 — 1 그대로, 숲 엘리트부터 벽). 같은 배율에서 `stagebot.js`의 6단계 계열 덱 발 수를 적는다. 둘 다 맞출 수 없으면(계열 덱이 3발을 넘음) 무작위 기준만 넣고 차이를 기록한다(P4~P6 계열이 들어온 뒤 다시)
- [x] 시험: 진형에서 `regionHp()`가 표 값, 이전 규칙은 1(지문 그대로) · `route.js` 통과
- [x] 측정: 진형 40런 × mixed · family 다시 → 승수 기록
- [x] 기록 §33에 배율 · 앞뒤 숫자 → waypoint → 포인터
- [x] 커밋 · PR: `prototype(ball-roguelite): 판 계열 6 — 진형 적 체력 1차(지역 배율)` → `ball-roguelite/board-families` 푸시 → PR(기준 `ball-roguelite/families`, 본문에 트레일러·AI 서명 없음). 병합 순서 #16 → #17 → #18 → #19 → 이 PR

## P4. 상태이상 · 공격 모양 — 독 · 출혈 · 레이저 · 폭탄 · 거대·무게 (2026-11-09)

**Goal:** 다섯 계열의 단계 효과(2 · 4 · 6) 15개와 새 아이템 16개(구슬 5 · 유물 11)를 진형에 넣고, 계열 덱 발 수를 잰다.

**Spec:** [`build-families-2026-11-03.md`](build-families-2026-11-03.md) §3 「상태이상 계열」 · 「공격 모양 계열」(단계 원문) · §3-1 독 · 출혈 · 레이저 · 폭탄 표(새 아이템 16) · §1 원칙 4(도트만으로는 미끼) · 7(한 발 상한). P3와 같은 틀(`devHit` · `setDaze` · `boardStart` · `famRegen` · 단계 수치 표 · `FAM_STAGE` · `lab/stages.js` · `lab/stagebot.js`)을 이어 쓴다. 브랜치 `ball-roguelite/status-families`(`main`에서, PR 기준 `main`).

**Global Constraints(P3에 더해):**
- 새 구슬 5 · 유물 11은 모두 `rank: true`(이전 규칙 지문 `fdf868b7…` 유지).
- 마른 발 규칙 그대로: 발 도중의 판 · 런 · 적 상태 변경은 `jot` 또는 `if (!shot.dry)`. 봇이 봐야 할 피해(레이저 · 피 터뜨림 · 폭죽)는 `land`의 마른 발 반환 앞에서 `shot.dmg`에 더한다.
- 수치 표: `POISON_R` · `BLEED_R` · `LASER_R` · `BOMB_R` · `MASS_R`(아래 값 그대로).
- 쓰러짐 연쇄(기름통 · 터지는 상처 · 도깨비 뇌관 · 포자)는 한 번의 쓰러짐에서 이어지는 깊이를 `DEATH_CHAIN = 12`로 막는다(무한 재귀 방지).

**계획에서 정한 것(설계서가 비워 둔 자리 — §34에 적는다):**
1. **새 키:** 구슬 `poisonfog`(독안개 주머니) · `saw`(톱날 원반) · `bat`(흡혈 박쥐) · `sunset`(노을 구슬) · `firework`(폭죽 구슬), 유물 `catalyst`(촉매) · `fumes`(독 연기, 열쇠) · `tridagger`(혈흔 단검, 열쇠) · `spleen`(터지는 상처) · `bloodpool`(피 웅덩이) · `unclot`(굳지 않는 피) · `lens`(집광 렌즈) · `mirrorshield`(거울 방패) · `scope`(표적 조준기) · `spectro`(분광기) · `imp`(도깨비 뇌관). 계열 수: 독 8 · 출혈 8 · 레이저 8 · 폭탄 8 · 거대·무게 8. **흡혈 박쥐**는 §3-1에 「보상」으로 적혀 있지만 구슬은 모두 열쇠(§7 8)라 열쇠로 둔다.
2. **수치 표:**
   - `POISON_R = { start: 3, pegMax: 8, fogEvery: 12, mutateAt: 100, virulent: 1.5, cap: 99, corrode: 5, neuro: 30, sporePegs: 3 }`
   - `BLEED_R = { burstAt: 12, burstPct: 0.15, chalicePer: 100, chaliceHp: 5, poolCap: 10, sawEvery: 5, batCap: 5, tri: 2 }`
   - `LASER_R = { prism: 0.2, sunset: 0.3, lens: 0.1, radPer: 0.03, radCap: 10, grind: 0.02, rateCap: 1, boardAt: 0.5, rowCap: 8, spectro: 0.2 }`
   - `BOMB_R = { extra: 2, chainR: 24, chainCap: 20, chainPer: 0.2, landPlus: 3, depotPer: 10, bigMul: 5, mul6: 2, firework: 0.5, imp: 0.1 }`
   - `MASS_R = { growEvery: 10, sizeUp: 1.08, sizeCap: 1.6, weightMul: 0.1, crush: 20 }`
3. **독 페그(배양 · 독안개):** 새 페그 `'toxic'`. 깨지지 않고, 구슬은 튕기지 않고 지나가며, 구슬마다 독 페그 하나에서 한 번 중독 +1을 싣는다. 독 2단계는 판이 깔릴 때 일반 페그 3개를 독 페그로 바꾼다. 독안개 주머니는 충전 12마다 그 자리를 `B.toxQ`에 넣고, 적 턴 뒤(`regen`)에 독 페그로 돋운다. 판의 독 페그는 8개까지다. 리프레시 · `rollSpecials`가 독 페그를 되돌리지 않는다.
4. **번식(독 4):** 중독된 적에게 착지할 때마다 그 적 중독 +1. 적 턴의 중독 피해는 두 번 든다.
5. **변이(독 6):**
   - 한 전투에서 중독이 준 피해의 합(`B.poisonDealt`)이 100 이상이면, 승리 보상 **앞에** 「변이」 창을 띄운다. 아직 안 고른 것 중 하나를 고른다(런 내내 `RUN.mutations`, 넷 다 고르면 안 뜸). 봇은 맹독 → 부식 → 신경독 → 포자 순으로 고른다.
   - 맹독은 적 턴마다 중독 ×1.5(올림, 최대 99)다. 부식은 중독 5마다 그 적 갑옷 −1이다. 신경독은 적 턴에 중독 30 이상이면 `setDaze`다(면역이면 안 함). 포자는 중독된 적이 쓰러지면 독 페그 3을 돋운다.
6. **출혈:**
   - **상처 벌리기(2):** 출혈 적에게 크리 착지하면 그 적 출혈 ×2, 출혈을 실은 착지는 +1 더.
   - **피 터뜨림(4):** 착지 직전 그 적 출혈이 12를 넘으면 그 착지가 출혈을 모두 쓰고, 현재 체력의 15%를 더 깎는다.
   - **피의 잔(6):** 터뜨린 출혈을 `RUN.chalice`에 더하고, 터뜨린 뒤 출혈 절반이 남는다. 잔이 100을 넘을 때마다 최대 체력 +5(지금 체력도 +5)이고, 착지마다 더하는 출혈은 `floor(잔 / 100)`이다.
   - **굳지 않는 피(유물):** 이 프로토타입의 출혈은 원래 줄지 않아서 설계서 문구는 하는 일이 없다. 그래서 「피를 터뜨린 뒤에도 출혈이 그대로 남는다」로 바꾼다.
7. **레이저:**
   - 레이저를 쏘는 구슬은 햇살 프리즘 · 붉은 원륜(`laser: 0.2`)과 노을 구슬(`laser: 0.3`)이다. 그 구슬이 적에게 착지할 때마다 줄의 보이는 적(칸 1~4) 모두에게 `round(구슬 힘 × 레이저 비율)`을 준다. 비율 = 구슬 값 + 집광 렌즈 0.1 + `RUN.lensBonus`(최대 1).
   - 지킴이가 막는 적은 지킴이가 대신 맞는다(거울 방패가 있으면 그대로 맞음). 단계와 상관없이 쏜다(§3 「열쇠: 햇살 프리즘(새로)」). 노을 구슬의 「깔때기로 빠질 때」는 이 게임에서 빠지는 구슬이 곧 착지하는 구슬이라 착지 때 쏜다.
   - **굴절(2):** 그 구슬이 실은 중독 · 출혈 · 빙결 · 화상을 맞은 적마다 옮긴다.
   - **방사선(4):** 레이저에 맞을 때마다 `e.rad` +1(최대 10). 그 적이 받는 모든 피해 +3%/중첩(`hurt`).
   - **렌즈 연마(6):** 레이저로 쓰러뜨리면 `RUN.lensBonus += 0.02`. 비율이 0.5를 넘으면 그 구슬이 마지막으로 맞힌 페그 높이의 가로줄 페그(±5px, 8개까지)도 깨고, 깬 수만큼 그 레이저 피해 +1이다(착지한 구슬은 더 충전할 수 없으므로 피해로 바꾼다).
8. **폭탄:**
   - **도화선(2):** 판이 깔릴 때 폭탄 페그 +2, 폭탄이 한 번에 터진다.
   - **연쇄(4):** 터진 폭탄 반경 24 안의 폭탄도 터지고(한 발 20개), 연쇄 하나마다 그 폭발 줄 피해 +20%. 폭탄이 터질 때마다 이 발 모든 착지 +3(`shot.bombLand`).
   - **화약 창고(6):** 터뜨린 폭탄 수 `RUN.bombsLit`가 10개마다 판이 깔릴 때 대형 폭탄(`p.big`) 하나. 대형 폭탄은 줄의 적에게 구슬 힘 ×5, 폭탄 피해 ×2다.
   - **폭죽 구슬:** 착지하면 줄의 적 모두에게 그 힘의 50%(폭탄 피해로 셈 — 화약고 · 화약 주머니 · 폭탄 6단계 배율을 받음). 설계서의 「반경 안 폭탄 페그도 터뜨린다」는 착지한 구슬이 판 아래에 있어 닿는 폭탄이 없으므로 뺀다.
9. **거대·무게:**
   - **무거운 구슬** = 거대·무게 계열 구슬(닻추 · 거인 이슬 · 거인 쌍둥이).
   - **눈덩이(2):** 무거운 구슬은 맞힌 페그 10개마다 반지름 ×1.08(처음의 1.6배까지) · 무게 +1, 착지 ×(1 + 0.1 × 무게).
   - **짓누르기(4):** 착지 20 이상은 갑옷 · 막기 · 비늘 문턱을 무시하고, 넘친 피해가 다음 적에게 간다.
   - **기록 경신(6):** 착지 한 방이 `RUN.bestLand`를 넘을 때마다 기록을 바꾸고 `RUN.startPow += 1`(모든 구슬 시작 힘), 그 착지의 넘친 피해는 줄 끝까지 이어진다.
10. **단계 글:** `FAM_STAGE`에 다섯 계열을 더한다(승리 화면).

**Review Focus(P4):**
- **마른 발 새는 것** — 독 페그 · 피 페그 · 대형 폭탄 · `RUN.chalice` · `RUN.lensBonus` · `RUN.bombsLit` · `RUN.bestLand` · `RUN.startPow` · `B.poisonDealt`, 적의 중독 · 출혈 · `rad`가 봇의 미리 쏘기로 바뀌면 안 된다. (계열마다 마른 발 불변 시험)
- **쓰러짐 연쇄** — 기름통 · 터지는 상처 · 도깨비 뇌관 · 포자가 서로를 부르며 줄 전체가 연달아 쓰러져도 멈추고, 승리 판정이 한 번만 난다. (Task 0 · 4 시험)
- **변이 창과 다른 창** — 엘리트 · 보스 · 갈림길 문 보상, 합성 창, 아끼는 구슬 창과 겹쳐도 보상을 잃지 않는다. (Task 1 시험)
- **한 발 피해 · 시간** — 레이저(줄 전체 × 착지 수십) · 폭탄 연쇄 · 방사선이 겹친 발이 30초 안에 끝나고 피해 숫자가 화면을 덮지 않는다(`FX.nums` 50개 상한). (Task 6 측정)
- **이전 규칙** — 레이저 · 방사선(`hurt`) · 무게 시작 힘(`makeBall`)이 진형에서만 듣는다. (Task 6 지문)

### Task 0: 공통 바탕 — 새 아이템 자료 · 수치 표 · 새 페그 · 단계 글 · 쓰러짐 연쇄 상한
**Files:** `index.html`(`ORBS` · `RELICS` · `FAM_ITEMS` · `FAM_STAGE` · `JOT_KEYS` · `drawPeg` · `onDeath`) · `lab/stages.js`(P4 절) · `lab/family.js`(개수)
**Interfaces (Produces):** 「정한 것」 1 · 2의 키와 표 · 페그 `'toxic'`(보라 테 · 깨지지 않음) · `'blood'`(붉은 점) · `p.big`(큰 폭탄) · `DEATH_CHAIN` · `B.deathDepth`(onDeath가 늘리고 줄임) · `JOT_KEYS`에 `big` · `laserHit`
- [x] 시험: `family.js` 개수 → `poison: 8, bleed: 8, laser: 8, bomb: 8, mass: 8` · 새 16개 `rank: true`, 이전 규칙 보상 후보에 없음 · 키가 기존 키와 겹치지 않음 · 열쇠: `fumes` · `tridagger`, 나머지 유물 보상 · `famStageLines()`가 독 4단계에서 「배양」 · 「번식」 두 줄 · `onDeath`가 `DEATH_CHAIN` 깊이를 넘으면 더 부르지 않음(일부러 서로 부르는 가짜 연쇄로)
- [x] 실패 확인 → 구현 → `NOBOT=1 node lab/stages.js && NOBOT=1 node lab/family.js && node lab/choose.js && node lab/formation.js`
- [x] 커밋 `prototype(ball-roguelite): 상태 계열 0 — 새 아이템 16 자료 · 수치 표 · 독·피 페그 · 단계 글 · 쓰러짐 연쇄 상한`

### Task 1: 독 — 배양 · 번식 · 변이 · 독안개 주머니 · 촉매 · 독 연기
**Files:** `index.html`(`hitPeg` 앞 · `boardStart` · `regen`/`famRegen` · `land` · `enemyTurn` 중독 2905줄 · `landMods` · `onDeath` · `winFight` · `UI`) · `lab/stages.js`
**Interfaces:** Produces `B.toxQ` · `B.poisonDealt` · `RUN.mutations: string[]` · `UI.mutate(next)` · `mutateOn(): boolean`(이 전투가 변이 창 조건인가)
- [x] 시험:
  - 배양: 독 2단계 전투 시작 → 독 페그 3 · 독 페그를 지난 구슬은 튕기지 않고 중독 +1(같은 페그 두 번은 +1만) · 페그는 그대로 · 1단계는 0
  - 독안개 주머니: 충전 12마다 `B.toxQ` 하나 → `regen` 뒤 독 페그 · 판에 8개 넘게 돋지 않음 · 마른 발은 `B.toxQ` 그대로
  - 번식: 독 4, 중독 3인 적에게 착지 → 4 · 적 턴 중독 피해 3 → 6(두 번) · 3단계는 한 번
  - 변이: 독 6, `B.poisonDealt = 100`으로 이기면 보상 전에 `UI.mutate`가 열리고, 고른 뒤 보상이 그대로 뜸(엘리트 · 보스 · 갈림길 문 각각) · 99면 안 열림 · 넷을 다 고르면 안 열림 · 봇은 맹독부터
  - 변이 효과: 맹독(중독 10 → 적 턴 뒤 15 · 70 → 99) · 부식(중독 10 · 갑옷 3 → 착지 갑옷 1) · 신경독(중독 30 → 적 턴에 기절, 면역이면 안 함) · 포자(중독된 적이 쓰러지면 독 페그 3)
  - 촉매: 이 발 첫 착지가 그 적 중독 2배(두 번째 착지는 그대로) · 독 연기: 적 턴마다 모든 적 중독 +1
  - 마른 발(독 6 · 독안개 주머니): 판 · 런 · 적 그대로
- [x] 실패 확인 → 구현 → `NOBOT=1 node lab/stages.js && node lab/route.js && node lab/formation.js`
- [x] 브라우저 375px: 변이 창(네 줄 설명) · 고른 뒤 보상 창
- [x] 커밋 `prototype(ball-roguelite): 상태 계열 1 — 독(배양 · 번식 · 변이) · 독안개 주머니 · 촉매 · 독 연기`

### Task 2: 출혈 — 상처 벌리기 · 피 터뜨림 · 피의 잔 · 톱날 원반 · 흡혈 박쥐 · 혈흔 단검 · 터지는 상처 · 피 웅덩이 · 굳지 않는 피
**Files:** `index.html`(`land` · `breakPeg`/`charge` · `onDeath` · `regen`) · `lab/stages.js`
**Interfaces:** Produces `RUN.chalice` · `chaliceLv(): number` · `B.bloodQ`
- [x] 시험:
  - 상처 벌리기: 출혈 2, 출혈 4인 적에게 크리 착지 → 8 이상(옮김 전) · 출혈 1을 실은 착지 → 1 + 1 · 1단계는 그대로
  - 피 터뜨림: 출혈 4, 출혈 13 · 체력 1000인 적에 착지 → 출혈 0 · 그 착지 피해 + 150 · 출혈 12면 안 터짐 · 마른 발도 `shot.dmg`에 150
  - 피의 잔: 출혈 6, 13 터뜨림 → `RUN.chalice` 13 · 출혈 6 남음 · 잔 95 → 13 더하면 최대 체력 +5 · `chaliceLv()` 1 → 착지마다 출혈 +1 · 굳지 않는 피: 터뜨린 뒤 출혈 13 그대로
  - 톱날 원반: 페그 10개 맞힌 구슬이 착지 → 출혈 +2 · 흡혈 박쥐: 출혈 적에 착지 → 출혈 −1 · 체력 +1 · 같은 발 다른 구슬 힘 +1, 한 발 5번까지 · 혈흔 단검: 크리 착지 출혈 +2 · 터지는 상처: 출혈 7인 적이 쓰러지면 다른 적마다 7 · 피 웅덩이: 출혈 적에 착지할 때마다 `B.bloodQ` 하나(한 발 10) → `regen` 뒤 피 페그, 맞히면 구슬 힘 +1
  - 마른 발(출혈 6): 그대로
- [x] 실패 확인 → 구현 → `NOBOT=1 node lab/stages.js && node lab/formation.js`
- [x] 커밋 `prototype(ball-roguelite): 상태 계열 2 — 출혈(상처 벌리기 · 피 터뜨림 · 피의 잔) · 톱날 원반 · 흡혈 박쥐 · 혈흔 단검 · 터지는 상처 · 피 웅덩이 · 굳지 않는 피`

### Task 3: 레이저 — 착지 레이저 · 굴절 · 방사선 · 렌즈 연마 · 노을 구슬 · 집광 렌즈 · 거울 방패 · 표적 조준기 · 분광기
**Files:** `index.html`(`ORBS.prism` · `redring` ab · `land` · `hurt` 2477줄 · `breakPeg`(마지막 페그 높이 `b.lastPegY`)) · `lab/stages.js`
**Interfaces:** Produces `laserRate(shot, b): number` · `fireLaser(shot, b, f): number`(준 피해 합) · `RUN.lensBonus` · `e.rad`
- [x] 시험:
  - 착지 레이저: 프리즘(힘 50) 착지 → 줄의 다른 적마다 10(1번 칸 적은 착지 + 10) · 마른 발은 `shot.dmg`에만 · 노을 구슬 0.3 · 지킴이 뒤 적의 몫은 지킴이가 맞음 · 거울 방패면 그대로 · 단계와 상관없이 · 이전 규칙은 레이저 없음
  - 굴절(2): 중독 2 · 출혈 1을 실은 프리즘 → 맞은 적마다 중독 +2 · 출혈 +1 · 방사선(4): 레이저 세 번 → `rad` 3 · 그 적 `hurt(100)` → 109 · 10에서 멈춤
  - 렌즈 연마(6): 레이저로 쓰러뜨림 → `RUN.lensBonus` 0.02 · 비율 1에서 멈춤 · 0.5를 넘으면 마지막 페그 높이 가로줄 8개까지 깨고 그만큼 피해 +
  - 집광 렌즈 +0.1 · 크리 구슬이면 레이저도 크리 배율 · 표적 조준기: 레이저 맞은 적에게 이 발 다음 착지 크리 · 분광기: 중독 · 출혈 걸린 적에게 레이저 +40%
  - 마른 발(레이저 6): 그대로
- [x] 실패 확인 → 구현 → `NOBOT=1 node lab/stages.js && node lab/formation.js && node lab/choose.js`
- [x] 커밋 `prototype(ball-roguelite): 상태 계열 3 — 레이저(착지 레이저 · 굴절 · 방사선 · 렌즈 연마) · 노을 구슬 · 집광 렌즈 · 거울 방패 · 표적 조준기 · 분광기`

### Task 4: 폭탄 — 도화선 · 연쇄 · 화약 창고 · 폭죽 구슬 · 도깨비 뇌관
**Files:** `index.html`(`hitPeg` 폭탄 · `bombLane` · `boardStart` · `land` · `onDeath`) · `lab/stages.js`
**Interfaces:** Produces `bombChain(shot, b, p, ev): number` · `RUN.bombsLit` · `shot.bombLand`
- [x] 시험:
  - 도화선(2): 판 깔 때 폭탄 페그 +2 · 한 번에 터짐 · 1단계는 두 번
  - 연쇄(4): 폭탄 셋이 반경 24 안에 줄지어 → 하나 맞히면 셋 다 터지고 줄 피해가 1 · 1.2 · 1.4배 · 한 발 20개에서 멈춤 · 터질 때마다 그 발 착지 +3
  - 화약 창고(6): `RUN.bombsLit` 23 → 판 깔 때 대형 폭탄 2 · 대형 폭탄은 구슬 힘 ×5 · 폭탄 피해 ×2 · 마른 발은 `RUN.bombsLit` 그대로
  - 폭죽 구슬: 힘 40 착지 → 줄의 적마다 20(화약고면 40) · 도깨비 뇌관: 최대 체력 200인 적이 쓰러지면 다른 적마다 20 · 기름통 · 터지는 상처와 함께 줄 전체가 쓰러져도 멈춤(`DEATH_CHAIN`)
  - 마른 발(폭탄 6): 그대로
- [x] 실패 확인 → 구현 → `NOBOT=1 node lab/stages.js && node lab/formation.js`
- [x] 커밋 `prototype(ball-roguelite): 상태 계열 4 — 폭탄(도화선 · 연쇄 · 화약 창고) · 폭죽 구슬 · 도깨비 뇌관`

### Task 5: 거대·무게 — 눈덩이 · 짓누르기 · 기록 경신
**Files:** `index.html`(`charge` · `land` · `landMods` · `makeBall`(시작 힘)) · `lab/stages.js`
**Interfaces:** Produces `isHeavy(shot): boolean` · `b.weight` · `RUN.bestLand` · `RUN.startPow`
- [x] 시험:
  - 눈덩이(2): 닻추가 페그 20개 → 무게 2 · 반지름 ×1.08² · 착지 ×1.2 · 반지름은 1.6배에서 멈춤 · 조약돌은 그대로
  - 짓누르기(4): 착지 25 · 갑옷 5 · 막기인 적 → 25 그대로(19는 깎임) · 체력 10인 적에 착지 25 → 다음 적에게 15
  - 기록 경신(6): `RUN.bestLand` 100, 착지 120 → 기록 120 · `RUN.startPow` 1 → 다음 발 구슬 시작 힘 +1 · 그 착지의 넘친 피해가 셋째 적까지 · 마른 발은 기록 그대로
- [x] 실패 확인 → 구현 → `NOBOT=1 node lab/stages.js && node lab/formation.js`
- [x] 커밋 `prototype(ball-roguelite): 상태 계열 5 — 거대·무게(눈덩이 · 짓누르기 · 기록 경신)`

### Task 6: 봇 · 측정 · 검토 · 기록 · PR
**Files:** `index.html`(`botRun` 변이 고르기) · `lab/stagebot.js`(KIT에 다섯 계열) · waypoint `15-ball-roguelite.md` · `STATUS.md`
- [x] `lab/stagebot.js` KIT: 독 `['sting', 'poisonfog'] / ['sporepouch', 'hive', 'fumes', 'catalyst']` · 출혈 `['briar', 'saw'] / ['tridagger', 'spleen', 'bloodpool', 'unclot']` · 레이저 `['prism', 'sunset'] / ['lens', 'mirrorshield', 'scope', 'spectro']` · 폭탄 `['sticky', 'firework'] / ['arsenal', 'powder', 'fuse', 'imp']` · 거대·무게 `['heavy', 'giant'] / ['weight', 'lead', 'bedrock', 'pierce']`
- [x] 회귀: `lab/stages.js` · `family` · `choose` · `route` · `formation` 모두 · 이전 규칙 지문 `fdf868b7…`(21승) · `selfTest()` 결정성
- [x] 측정(기록, 균형은 P8): `stagebot.js` 다섯 계열 × 2 · 4 · 6 × 6런 → 지역별 한 전투 발 수 · 30초 발 · 진형 40런 × mixed · focus · family · `FAM=` 다섯 계열 각 12런. P3 계열과 나란히 표로
- [x] 브랜치 전체 검토(새 검토자, 가장 강한 모델) → Critical · Important 고침(시험 RED → GREEN) · Minor 기록
- [x] 기록 `15-ball-roguelite.md` §34 · 체크리스트 · STATUS → waypoint → 포인터 → PR(기준 `main`, 트레일러 · AI 서명 없음)

## P5. 구슬 수 · 표적 — 물량 · 메아리 · 크리 · 처형·사냥 · 보물 (2026-11-09)

**Goal:** 다섯 계열의 단계 효과(2 · 4 · 6) 15개와 새 아이템 13개(구슬 4 · 유물 9), 보물 6단계의 「황금왕」을 진형에 넣고, 계열 덱 발 수를 잰다.

**Spec:** [`build-families-2026-11-03.md`](build-families-2026-11-03.md) §3 「구슬 수 계열」 · 「표적 계열」(단계 원문) · §3-1 메아리 · 크리 · 처형·사냥 · 보물 표(새 아이템 13) · §1 원칙 3(덧셈은 흔하게) · 7(한 발 상한) · §5-1 갈림길. P3 · P4와 같은 틀(`boardStart` · `famRegen` · 단계 수치 표 · `FAM_STAGE` · `lab/stages.js` · `lab/stagebot.js`)을 이어 쓴다. 브랜치 `ball-roguelite/target-families`(`ball-roguelite/status-families` 위 — PR #21이 머지되면 `main`을 합치고 PR 기준 `main`).

**Global Constraints(P4에 더해):**
- 새 구슬 4 · 유물 9 · 황금왕은 모두 `rank: true`(이전 규칙 지문 `fdf868b7…` 21승 유지).
- 마른 발 규칙 그대로: 발 도중의 판 · 런 · 적 상태 변경은 `jot` 또는 `if (!shot.dry)`. 봇이 봐야 할 피해(두 번 친 착지 · 유령 구슬 · 처형)는 `land`의 마른 발 반환 앞에서 `shot.dmg`(처형은 `shot.exec`)에 넣는다.
- 수치 표: `SWARM_R` · `ECHO_R` · `CRIT_R` · `HUNT_R` · `LOOT_R`(아래 값 그대로).
- 두 번 발동은 서로 곱하지 않고 더한다(§3 메아리 「원칙」): 한 착지가 계산되는 횟수 = 1 + 그 착지에 걸린 발동 수.
- 측정 비교 기준은 P4 끝(§34): 진형 40런 무작위 14 · 몰기 21 · 계열 18승. 구현 전에 브랜치 끝을 `base-p5.html`로 떠 두고 `selfTest` 기준으로 쓴다.

**계획에서 정한 것(설계서가 비워 둔 자리 — §35에 적는다):**
1. **새 키:** 구슬 `reverb`(메아리 구슬 — `echo`는 산울림 버섯이 씀) · `magpie`(도둑 까치) · `shovel`(도굴꾼 삽) · `greedhand`(욕심쟁이 손), 유물 `echobox`(잔향 상자, 열쇠) · `duskdrum`(황혼 북) · `tuning`(소리굽쇠) · `journal`(사냥꾼의 일지) · `luckfoil`(행운의 금박, 열쇠) · `goldidol`(황금 우상) · `sack`(장물 자루) · `pirateflag`(해적 깃발) · `bronzescale`(청동 저울) · `goldking`(황금왕, 계열 밖). `선택의 두루마리`(`scroll`)는 보물 임시 열쇠에서 보상으로 옮긴다. 계열 수: 메아리 8 · 크리 9 · 처형·사냥 8 · 보물 8 · 물량 13(여왕벌은 P6).
   - 구슬 레벨 식: 메아리 구슬 `reverb: 0.5 + 0.1 × (lv − 1)`(유령 힘 비율) · 도둑 까치 `magpie: 2 + lv` · 도굴꾼 삽 `shovel: lv >= 3 ? 2 : 1`(보물 적으로 만드는 적 수) · 욕심쟁이 손 `greed: 1, landMul: 1 + 0.1 × (lv − 1)`.
2. **수치 표:**
   - `SWARM_R = { jar: 1, legionPer: 0.01, legionCap: 0.6, nestAt: 30, eggCap: 5 }`
   - `ECHO_R = { ghost: 0.5, every: 2, ghostCap: 2, per: 100, cap: 5, tuning: 3 }`
   - `CRIT_R = { chain: 0.2, hone: 50, honePer: 0.25, honeCap: 3 }`
   - `HUNT_R = { markPer: 0.01, markCap: 0.25, cap: 0.6, bossMul: 0.5, permPer: 0.01, permCap: 0.2, journal: 0.1, spoil: { guard: 1, heal: 2, atk: 2, summon: 3, ctrl: 1 } }`
   - `LOOT_R = { landPer: 0.05, chest: 3, scale: 4 }`
3. **물량:**
   - **분봉(2):** 진형 단지(`src[0] === 'j'`)의 `multiply` 개수 +1. 단지 열쇠 +1과 더해진다(보라 열매 · 관문은 그대로).
   - **군단(4):** 착지 피해 ×(1 + min(0.6, 0.01 × 판 위에 아직 안 빠진 구슬 수)).
   - **둥지(6):** 진짜 발이 끝날 때(`endShot`) 그 발 구슬이 30개 이상이면 `RUN.eggs` +1(한 발에 한 번, 최대 5). `newShot`이 알 수만큼 구슬을 더 쏜다(각도 ±0.05씩). 착지하는 구슬이 그 발의 마지막 구슬(다른 구슬이 모두 빠졌고 `shot.born`이 비었고 유령이 아님)이면 힘 + `shot.landed`로 계산한다.
4. **메아리 — 두 번 계산:**
   - 착지의 반복 수 `reps = 1 + 되울림(이 발 첫 착지, 메아리 2) + 황혼 북(마지막 한 방과 같은 「이번 바퀴 마지막 칸」 조건) + 메아리 모음(이 발 시작에 고른 착지 번호)`.
   - 반복은 `landMods`까지 거친 피해를 `hurt`로 `reps`번 준다(목숨 토큰 · 방패가 한 번씩 받음). 상태이상 옮김은 메아리 6에서만 `reps`번이다. 처형 · 출혈 · 박쥐 같은 착지 효과는 한 번이다.
   - 소리굽쇠: `reps > 1`인 착지는 힘 +3으로 계산한다. 메아리 모음(6): 두 번 이상 계산된 착지마다 `RUN.echoN` +1, 100마다 `RUN.echo` +1(최대 5). 발이 시작될 때 `RUN.echo`개의 착지 번호를 `shot.rnd`로 `[0, max(4, B.lastLanded))`에서 고른다(`B.lastLanded` = 직전 진짜 발의 착지 수).
5. **메아리 — 유령 구슬(잔상 · 메아리 구슬 · 잔향 상자 공통):**
   - 진짜 발에서만 길을 적는다. 구슬마다 `b.path`에 2스텝마다 `[x, y]`를 넣는다(필요할 때만: 메아리 4 이상 · 이번 구슬이 메아리 구슬 · 잔향 상자의 전투 첫 발). `spawnBall`은 새 구슬의 `path`를 빈 배열로 둔다(공유 금지).
   - `endShot`이 다음 발 유령의 길을 `B.echoQ`(최대 2개)에 넣는다: 메아리 구슬이면 첫 구슬의 길 → 메아리 4면 그 발에서 페그를 가장 많이 맞힌 구슬의 길 → 잔향 상자면 전투 첫 발의 첫 구슬 길(설계서의 「같은 각도로 한 번 더」를 다음 발 유령으로 둔다 — 발 사이에 따로 쏘는 발을 만들지 않는다).
   - `newShot`이 `B.echoQ`를 꺼내 유령 구슬(`b.phantom = path`, `b.pi = 0`)을 `shot.balls`에 넣는다. `step`은 유령을 물리로 움직이지 않고 2스텝마다 다음 점으로 옮기며, 그 점에 겹친 살아 있는 페그를 `hitPeg`로 맞힌다(속도는 점 사이 차이로 둠). 단지 · 관문 · 장치에는 들어가지 않는다. 길이 끝나면 `land`하고, 피해는 ×0.5(메아리 구슬이 남긴 길은 그 구슬의 `reverb` 비율). 유령은 이번 발 구슬의 능력으로 친다. 마른 발도 같은 유령을 돌려 봇이 피해를 본다(길은 마른 발에서 안 바뀜).
6. **크리:**
   - **조준점(2):** 조준 중 화면에 「조준점」 버튼(발마다 한 번, 강제 창 없음). 누르고 판의 일반 페그를 누르면, 그 페그에 가장 가까운 크리 페그가 일반이 되고 누른 페그가 크리가 된다(`MODE = 'critpick'`, 취소 가능). 크리 페그는 발마다 `rollSpecials`로 다시 깔리므로 `keep`을 두지 않는다. 봇은 고른 각도로 마른 발을 첫 페그 맞힘까지 돌려 그 페그를 크리로 만든다(`aimCrit(p)`).
   - **연속 크리(4):** 크리 페그를 맞힐 때마다 `shot.critAdd += 0.2` → 착지 크리 배율에 더한다.
   - **칼날 갈기(6):** 진짜 발이 끝날 때 그 발 크리 착지 수가 50을 넘을 때마다(`floor(n / 50)`) `RUN.critPlus += 0.25`(최대 3) → `info.critBonus`에 더한다. 크리 착지는 그 적에 없는 상태이상 하나를 1 건다(중독 → 출혈 → 화상 → 빙결 순서로 처음 0인 것).
   - **도둑 까치:** 크리 페그를 맞히면 `b.magpie = ab.magpie`. 그 뒤 일반 페그를 맞히면 깨지 않고 크리 페그로 바꾸고(`keep: true`, 맞힐 때까지 남음) 튕긴다, `b.magpie`만큼.
7. **처형·사냥:**
   - **처형 하나로 모음:** `execTh(f, ab): number`(문턱) · `canExec(f, b, shot): boolean` · `execute(f)`(목숨 · 방패를 0으로 하고 `hurt(f, f.hp)` → `onDeath`)로 `land`의 두 자리(마른 발 어림 · 진짜 처형)를 바꾼다. 문턱 = 기본(`ab.exec || FORM.exec`, 도끼 +0.1, 칼날 어미 +0.1) + 사냥 표식 + 영구 + 일지, 전체 0.6까지. 이전 규칙과 0단계는 지금과 같다(칼날 구슬의 크리 착지만).
   - **사냥 표식(2):** 진형 사냥 2단계면 어느 구슬이든 크리 착지로 처형한다. 크리 착지마다 그 적 `f.hunts` +1(`huntMark` 불리언과 따로), 문턱 +0.01 × 표식(최대 +0.25 — 15% → 40%).
   - **전리품(4):** 처형한 적의 `plan` 동사 중 첫 「공격 아닌」 동사로 묶음을 정한다. 방어(shield · armor · harden · thorn) → 적 턴마다 가호 +1(최대 3) · 치유(heal · mend · revive) → 적 턴마다 체력 +2 · 소환(summon · hatch) → 발마다 날벌레 +3 · 표식·제어(mark · trap · steal · shuffle · plague · pick · hang · grab · fog · dirt · curse · snipe) → 크리 페그 +1 · 공격(그 밖) → 착지마다 +2. 전투 동안 `B.spoils[묶음]` +1, 엘리트면 `RUN.trophies[묶음]` +1(런 내내). 둘을 더해 쓴다.
   - **보스 사냥(6):** 보스도 처형한다(문턱 ×0.5). 살덩이 부위처럼 체력을 나눠 쓰는 적도 `hurt`를 거쳐 함께 쓰러진다. 처형할 때마다 `RUN.execPerm` +0.01(최대 0.2).
   - **사냥꾼의 일지:** 처형한 적 종류를 `RUN.journal`에 적고, 그 종류의 문턱 +0.1.
8. **보물:**
   - **보물 적(2):** 전투 시작(`startFight`)에 살아 있는 적 하나(보스 제외, 없으면 보스)를 `e.loot = true`로(황금 우상이면 둘). 도굴꾼 삽은 그 구슬이 전투에서 처음 착지한 적(레벨 3이면 둘째까지)을 더한다. 적 머리 위에 금화 표식. 보물 적이 어떤 이유로든 쓰러지면(`onDeath0`) `B.lootKills` +1 → 이번 보상 카드 +1(`rewardCardsR(r, kind, fam, extra)`). `B.treasure`(용의 보물 폭발)와 다른 필드다.
   - **큰 보물(4):** 보물 적을 쓰러뜨릴 때마다 `B.rnd`로 셋 중 하나: 가진 구슬 하나(가장 낮은 레벨) Lv +1 · 이번 보상 다시 뽑기 +1 · 늘어나는 카드 하나가 「보물상자」(가진 계열 — `famCount(f) > 0` — 의 후보에서만).
   - **황금(6):** 보물 계열 유물 하나마다 착지 +5%. `goldking`이 진형 보상 유물 후보에 나온다(보물 6단계일 때만). 황금왕: 가진 모든 계열(기본 개수 1 이상)의 개수 +1(`famCount`).
   - **욕심쟁이 손:** 그 구슬 착지로 적을 쓰러뜨린 전투는 이번 보상의 새 구슬 카드가 Lv2, 유물 보상이면 한 장 더.
   - **행운의 금박:** 보상 창에 「다시 뽑기」(보상마다 1번 + 큰 보물 몫). `winFight`가 다시 만들 함수(새 `rng`)를 `UI.reward(cards, f, next, again)`로 넘긴다.
   - **장물 자루:** 고르지 않은 카드 중 가진 계열 카드(없으면 첫 카드) 하나를 `RUN.stash`에 두고, 다음 보상에 한 장 더로 붙인다(「장물」 표시, 하나만).
   - **해적 깃발:** 갈림길 엘리트 문(`d?.reward === 'elite'`) 보상 뒤에 보물상자 창(가진 계열 카드 3장)을 하나 더 띄운다.
   - **청동 저울:** `famPull`의 4개 이상 끌림 2.5 → 4.
9. **봇:** 조준점은 6의 규칙 · 다시 뽑기는 `pick === 'family'`에서 몬 계열 카드가 없을 때 한 번(그 밖은 안 함) · 장물 자루 · 큰 보물은 자동이라 고를 것이 없다 · 보물상자 창은 보상과 같은 `choose`.
10. **단계 글:** `FAM_STAGE`에 다섯 계열을 더한다(승리 화면).

**Review Focus(P5):**
- **마른 발 새는 것** — `B.echoQ` · `RUN.eggs` · `RUN.echo` · `RUN.echoN` · `RUN.critPlus` · `RUN.execPerm` · `RUN.journal` · `B.spoils` · `RUN.trophies` · `e.loot` · `e.hunts` · 도둑 까치 크리 페그 · 조준점이 봇의 미리 쏘기로 바뀌면 안 된다. (계열마다 마른 발 불변 시험)
- **유령 구슬의 길** — 갈라진 구슬이 부모의 `path`를 같이 쓰지 않고, 행진 · 다시 돋음으로 판이 바뀌어도 유령이 끝까지 가서 착지하며, 길이 없는 전투 첫 발과 판 비움 뒤에도 멈추지 않는다. (Task 2 시험)
- **창이 겹침** — 조준점 → 변이 → 보물상자 → 보상 → 합성 · 아끼는 구슬, 다시 뽑기와 장물 자루가 한 보상에서 같이 와도 보상을 잃거나 두 번 받지 않는다. (Task 5 시험)
- **처형 대상** — 목숨 토큰 · 방패 · 되살림 적, 살덩이 부위, 보물 폭발 중인 용 · 수액 고목 같은 단계 보스를 처형해도 승리 판정이 한 번만 나고 다음 마디로 간다. (Task 4 시험)
- **이전 규칙 · 계열 문** — 보물 계열이 8개가 되어 갈림길에 보물 문이 생긴다(`famCands('loot').length >= 3`) — `route.js` · `choose.js` 기대가 진형에서만 바뀌고 이전 규칙 지문은 그대로. (Task 0 · 6)

### Task 0: 공통 바탕 — 새 아이템 자료 · 수치 표 · 단계 글 · 처형 하나로 모음
**Files:** `index.html`(`ORBS` · `RELICS` · `FAM_ITEMS` · `FAM_STAGE` · `JOT_KEYS` · `land` 처형 두 자리) · `lab/stages.js`(P5 절, 67부터) · `lab/family.js`(개수)
**Interfaces (Produces):** 「정한 것」 1 · 2의 키와 표 · `execTh(f, ab)` · `canExec(f, b, shot)` · `execute(f)` · `JOT_KEYS`에 `keep`(이미 있으면 그대로) · `magpie`
- [x] 시험: `family.js` 개수 → `resound: 8, crit: 9, hunt: 8, loot: 8, swarm: 13` · 새 13개 + 황금왕 `rank: true`, 이전 규칙 보상 후보에 없음 · 키가 기존 키와 겹치지 않음 · 열쇠: `echobox` · `luckfoil`, `scroll`은 보상 · 황금왕은 계열 밖 · `famStageLines()`가 크리 4단계에서 「조준점」 · 「연속 크리」 두 줄 · `execTh`가 지금 문턱과 같음(낫 Lv1 0.25 · 도끼 +0.1 · 기본 0.15) · 이전 규칙에서 칼날 아닌 구슬의 크리 착지는 처형 안 함
- [x] 실패 확인 → 구현 → `NOBOT=1 node lab/stages.js && NOBOT=1 node lab/family.js && node lab/choose.js && node lab/route.js && node lab/formation.js`(보물 문이 생겨 바뀐 기대는 진형에서만인지 보고 고침)
- [x] 커밋 `prototype(ball-roguelite): 표적 계열 0 — 새 아이템 13 · 황금왕 자료 · 수치 표 · 단계 글 · 처형 하나로 모음`

### Task 1: 물량 — 분봉 · 군단 · 둥지
**Files:** `index.html`(`multiply` · `land` · `endShot` · `newShot`) · `lab/stages.js`
**Interfaces:** Produces `RUN.eggs`
- [x] 시험:
  - 분봉: 물량 2, 단지 ×2 → 3 · 단지 열쇠까지 → 4 · 보라 열매는 그대로 · 1단계는 그대로
  - 군단: 물량 4, 안 빠진 구슬 10개일 때 착지 ×1.1 · 100개면 ×1.6
  - 둥지: 물량 6, 진짜 발 구슬 30개 → `RUN.eggs` 1 · 29개면 0 · 5에서 멈춤 · 알 2면 다음 발 구슬 +2 · 마지막 착지 구슬은 힘 + 그 발 착지 수, 마지막이 아니면 그대로
  - 마른 발(물량 6): 판 · 런 그대로
- [x] 실패 확인 → 구현 → `NOBOT=1 node lab/stages.js && node lab/formation.js`
- [x] 커밋 `prototype(ball-roguelite): 표적 계열 1 — 물량(분봉 · 군단 · 둥지)`

### Task 2: 메아리 — 되울림 · 잔상 · 메아리 모음 · 메아리 구슬 · 잔향 상자 · 황혼 북 · 소리굽쇠
**Files:** `index.html`(`land` · `step` 앞 · `spawnBall` · `newShot` · `endShot`) · `lab/stages.js`
**Interfaces:** Produces `landReps(shot, b): number` · `B.echoQ: number[][][]` · `RUN.echo` · `RUN.echoN` · `b.phantom` · `B.lastLanded`
- [x] 시험:
  - 되울림: 메아리 2, 이 발 첫 착지 피해 10 → 적 체력 −20(목숨 토큰 적은 첫 번에 버티고 둘째에 −) · 둘째 착지는 한 번 · 1단계는 한 번
  - 황혼 북: 이번 바퀴 마지막 칸 구슬의 착지가 모두 두 번 · 되울림과 겹친 첫 착지는 세 번(곱 아님) · 소리굽쇠: 두 번 친 착지는 힘 +3, 한 번은 그대로
  - 메아리 모음: 메아리 6, 두 번 친 착지 100 → `RUN.echo` 1 · 5에서 멈춤 · 상태이상(중독 2)을 실은 두 번 착지 → 중독 +4 · 메아리 4면 +2
  - 유령: 메아리 4 진짜 발 뒤 `B.echoQ` 길 1(페그를 가장 많이 맞힌 구슬) → 다음 발 `shot.balls`에 유령 · 유령은 길 위 페그를 깨고 끝에서 착지, 피해 ×0.5 · 단지에 안 들어감 · 갈라진 구슬의 `path`가 부모와 따로 · 메아리 구슬 Lv3 길이면 ×0.7 · 잔향 상자는 전투 첫 발 뒤에만 · 한 발 유령 2개까지 · 판이 바뀌어도(행진 · 다시 돋음) 끝까지 감
  - 마른 발(메아리 6 · 메아리 구슬): `B.echoQ` · 런 그대로, 마른 발 `shot.dmg`에 유령 피해가 들어감
- [x] 실패 확인 → 구현 → `NOBOT=1 node lab/stages.js && node lab/formation.js`
- [x] 브라우저 375px: 유령 구슬이 반투명으로 길을 따라감
- [x] 커밋 `prototype(ball-roguelite): 표적 계열 2 — 메아리(되울림 · 잔상 · 메아리 모음) · 메아리 구슬 · 잔향 상자 · 황혼 북 · 소리굽쇠`

### Task 3: 크리 — 조준점 · 연속 크리 · 칼날 갈기 · 도둑 까치
**Files:** `index.html`(`hitPeg` · `land` · `newShot` critBonus · `endShot` · 조준 HUD · 판 누름 · `botRun` 쏘기) · `lab/stages.js`
**Interfaces:** Produces `aimCrit(p): void` · `MODE 'critpick'` · `RUN.critPlus` · `shot.critAdd`
- [x] 시험:
  - 조준점: 크리 2, `aimCrit(일반 페그)` → 그 페그 크리 · 가장 가까운 크리 페그 일반 · 크리 페그 수 그대로 · 한 발에 두 번 안 됨 · 1단계는 버튼 없음 · 봇 런(크리 2 가방)에서 발마다 첫 맞힌 페그가 크리
  - 연속 크리: 크리 4, 크리 페그 3개 맞힌 구슬 착지 → 크리 배율 + 0.6
  - 칼날 갈기: 크리 6, 진짜 발 크리 착지 120 → `RUN.critPlus` 0.5 · 3에서 멈춤 · 중독 있는 적에게 크리 착지 → 출혈 1(중독은 그대로)
  - 도둑 까치: 크리 페그를 맞힌 뒤 일반 페그 3개가 깨지지 않고 크리(`keep`) · 넷째는 깨짐 · `rollSpecials` 뒤에도 남음 · 맞히면 사라짐
  - 마른 발(크리 6 · 도둑 까치): 판 · 런 그대로
- [x] 실패 확인 → 구현 → `NOBOT=1 node lab/stages.js && node lab/formation.js`
- [x] 브라우저 375px: 「조준점」 버튼 → 페그 누름 → 크리 페그 옮김 · 취소 · 쏘기
- [x] 커밋 `prototype(ball-roguelite): 표적 계열 3 — 크리(조준점 · 연속 크리 · 칼날 갈기) · 도둑 까치`

### Task 4: 처형·사냥 — 사냥 표식 · 전리품 · 보스 사냥 · 사냥꾼의 일지
**Files:** `index.html`(`execTh` · `canExec` · `land` · `enemyTurn` 가호 · 체력 · `newShot` 날벌레 · `rollSpecials` 크리 수 · `startFight`) · `lab/stages.js`
**Interfaces:** Produces `e.hunts` · `spoilOf(kind): string` · `B.spoils` · `RUN.trophies` · `RUN.execPerm` · `RUN.journal: string[]`
- [x] 시험:
  - 사냥 표식: 사냥 2, 칼날 아닌 구슬(사슬 추)의 크리 착지가 체력 14% 적을 처형 · 1단계는 안 함 · 표식 10이면 25% 적 처형 · 표식 40이어도 문턱 0.40
  - 전리품: 사냥 4, 방패 적 처형 → 적 턴에 가호 +1 · 치유 적 → 체력 +2 · 소환 적 → 다음 발 날벌레 +3 · 표식 적 → 크리 페그 +1 · 공격만 있는 적 → 착지 +2 · 다음 전투엔 없음 · 엘리트 처형은 다음 전투에도
  - 보스 사냥: 사냥 6, 체력 7%인 보스 처형(문턱 0.15 × 0.5 = 0.075) · 8%면 안 함 · 처형마다 `RUN.execPerm` +0.01 · 살덩이 부위 처형 → 네 부위 모두 쓰러지고 승리 한 번 · 목숨 토큰 적도 벗김
  - 사냥꾼의 일지: 슬라임 처형 → 다음 슬라임 문턱 +0.1 · 다른 종류는 그대로
  - 마른 발(사냥 6): 적 · 런 그대로, `shot.exec`로 봇이 처형을 봄(사냥 2면 칼날 아닌 구슬도)
- [x] 실패 확인 → 구현 → `NOBOT=1 node lab/stages.js && node lab/formation.js && node lab/route.js`
- [x] 커밋 `prototype(ball-roguelite): 표적 계열 4 — 처형·사냥(사냥 표식 · 전리품 · 보스 사냥) · 사냥꾼의 일지`

### Task 5: 보물 — 보물 적 · 큰 보물 · 황금 · 황금왕 · 도굴꾼 삽 · 욕심쟁이 손 · 행운의 금박 · 황금 우상 · 장물 자루 · 해적 깃발 · 청동 저울
**Files:** `index.html`(`startFight` · `onDeath0` · `land` · `rewardCardsR` · `winFight` · `UI.reward` · `famCount` · `famPull` · `relicCandsR` · 적 그림 · `botRun` 보상) · `lab/stages.js`
**Interfaces:** Produces `e.loot` · `B.lootKills` · `chestCands(): famPick 후보` · `rewardCardsR(r, kind, fam, extra = 0)` · `UI.reward(cards, f, next, again)` · `RUN.stash` · `famCount0(f)`(황금왕 전 개수)
- [x] 시험:
  - 보물 적: 보물 2 전투 시작 → `e.loot` 하나(보스 아닌 적) · 황금 우상이면 둘 · 1단계는 없음 · 보물 적이 독 · 폭발로 쓰러져도 보상 3 → 4장(섞인 · 엘리트 · 보스 · 계열 문 각각) · 도굴꾼 삽 첫 착지 적이 보물 적
  - 큰 보물: 보물 4, 보물 적 셋을 쓰러뜨림 → 강화 · 다시 뽑기 · 보물상자가 시드대로 · 보물상자 카드는 가진 계열 카드만
  - 황금: 보물 6, 보물 유물 4개 → 착지 ×1.2 · 황금왕이 보상 후보에 나옴(6단계 아래면 안 나옴) · 황금왕을 가지면 기계 3 → 4(단계 4) · 없는 계열은 0 그대로
  - 욕심쟁이 손: 그 구슬로 적을 쓰러뜨린 전투 → 새 구슬 카드 Lv2 · 유물 보상 한 장 더
  - 행운의 금박: 다시 뽑기가 다른 카드를 내고 한 번 뒤 버튼이 없음 · 봇(계열)은 몬 계열 카드가 없을 때만
  - 장물 자루: 고르지 않은 가진 계열 카드가 다음 보상에 한 장 더 · 그다음엔 없음
  - 해적 깃발: 엘리트 문 보상 뒤 보물상자 창 3장 · 그냥 엘리트(문 아님)는 없음
  - 청동 저울: 4개 가진 계열 끌림 4 · 3개면 1.5 그대로
  - 창 겹침: 변이 → 보물상자 → 보상 → 합성 순서로 모두 뜨고 끝나면 다음 마디
  - 마른 발(보물 6 · 도굴꾼 삽): `e.loot` · 런 그대로
- [x] 실패 확인 → 구현 → `NOBOT=1 node lab/stages.js && node lab/route.js && node lab/choose.js && node lab/formation.js`
- [x] 브라우저 375px: 금화 표식 · 보상 창 「다시 뽑기」 · 「장물」 카드 · 보물상자 창
- [x] 커밋 `prototype(ball-roguelite): 표적 계열 5 — 보물(보물 적 · 큰 보물 · 황금 · 황금왕) · 도굴꾼 삽 · 욕심쟁이 손 · 행운의 금박 · 황금 우상 · 장물 자루 · 해적 깃발 · 청동 저울`

### Task 6: 봇 · 측정 · 검토 · 기록 · PR
**Files:** `lab/stagebot.js`(KIT에 다섯 계열) · waypoint `15-ball-roguelite.md` · `STATUS.md`
- [x] `lab/stagebot.js` KIT: 물량 `['twin', 'egg'] / ['dandelion', 'starsplit', 'dew', 'arrow']` · 메아리 `['boomer', 'reverb'] / ['echobox', 'memory', 'duskdrum', 'tuning']` · 크리 `['dagger', 'magpie'] / ['whet', 'gardener', 'gambler', 'marksman']` · 처형·사냥 `['scythe', 'chainweight'] / ['horn', 'crookhook', 'axe', 'journal']` · 보물 `['shovel', 'greedhand'] / ['luckfoil', 'goldidol', 'sack', 'bronzescale']`
- [x] 회귀: `lab/stages.js` · `family` · `choose` · `route` · `formation` 모두 · 이전 규칙 지문 `fdf868b7…`(21승) · `selfTest()` 결정성(`base-p5.html` 기준)
- [x] 측정(기록, 균형은 P8): `stagebot.js` 다섯 계열 × 2 · 4 · 6 × 6런 → 지역별 한 전투 발 수 · 30초 발 · 진형 40런 × mixed · focus · family · `FAM=` 다섯 계열 각 12런. P4 표와 나란히
- [x] 브랜치 전체 검토(새 검토자, 가장 강한 모델) → Critical · Important 고침(시험 RED → GREEN) · Minor 기록
- [x] 기록 `15-ball-roguelite.md` §35 · 체크리스트 · STATUS → waypoint → 포인터 → PR(PR #21 머지 뒤 `main` 기준, 트레일러 · AI 서명 없음)

## P8에서 볼 것 (P3~P5에서 미룬 측정, 2026-11-09)

P3~P5는 측정을 기록만 하고 균형을 P8로 미뤘다. P8 계획을 쓸 때 아래 항목을 빠짐없이 넣는다. 각 줄은 「무엇이 · 얼마나 · 어느 표를 볼지 · 근거 절」 순서다. 수치는 측정한 때의 값이라, P6 · P7을 거친 뒤 다시 잰다.

- **무작위 봇이 이긴다:** 진형 160런 P4 60승(38%) · P5 63승(39%). P8 목표는 「무작위 거의 0」이다. 적 체력(`REGION_HP_R`, 지금 동굴 ×3 · 성 ×3은 1차 값)과 함께 본다. (§33 · §34 · §35)
  - P5의 40런 14 → 20승은 흔들림이었다. 같은 시드 160런으로 다시 재니 P4 · P5 차이가 3승(2%p)이라, P5 아이템이 무작위 봇을 세게 만든 것은 아니다. 40런 하나로는 6승 차이도 가르지 못하므로, P8은 비교마다 160런으로 잰다. (§35)
- **물량이 가장 세다:** 단계별 덱 4단계부터 숲 · 동굴 · 성 모두 한 전투 1발, 6런 모두 승리. `SWARM_R`의 `legionCap`(0.6) · `legionPer` · `nestAt`(30) · `eggCap`(5) · `jar`를 먼저 본다. (§35)
- **폭탄 · 레이저도 4단계부터 1~2발:** `BOMB_R` · `LASER_R`. 물량과 함께 「계열 2~3발」로 내린다. (§34)
- **처형·사냥이 느리다:** 4단계 성 5발, 6단계 3발. 문턱이 차기 전까지 때려야 하는 구조라 `HUNT_R`의 `markPer` · `markCap` · `cap`을 본다. (§35)
- **메아리가 단계를 올려도 빨라지지 않는다:** 단계별 덱 12런에서 2단계 6승 · 4단계 5승 · 6단계 7승, 한 전투 발 수는 모두 3~4발이다. 6런 측정의 「4단계 1승」은 표본이 작아서 나온 값이었다. 유령 구슬을 끈 덱(`ECHO_R.ghostCap` 0)도 9 · 6 · 7승으로 나빠지지 않아, 잔상 · 메아리 구슬 · 잔향 상자가 지금은 이득이 없다. 유령이 진짜 구슬과 같은 발에 페그를 깨서 진짜 구슬 몫을 빼앗는 것으로 보이지만 확인하지 않았다. 유령이 페그를 깨지 않고 힘만 모으게 할지 · `ECHO_R.ghost`(0.5)를 올릴지 본다. (§35)
- **독이 성에서 4발로 가장 느리다:** §1 원칙 4(도트만으로는 미끼)와 같은 방향이라 그대로 둘지를 정한다. `POISON_R`. (§34)
- **거대·무게의 30초 발 2%:** 커진 구슬이 페그 사이에 오래 머문다. `MASS_R`. 발 시간 기준은 「30초까지 안 끝나는 발」로 잰다(10초 기준은 P2 끝에서도 61%라 쓸 수 없음). (§33 · §34)
- **한 계열을 끝까지 모으기 어렵다:** 계열마다 12런(`FAM=`)에서 6단계 런이 드물다(레이저 12런 중 7런이 2단계도 못 감, 메아리 · 처형·사냥 · 보물은 6단계 런 0). 보상 끌림 `FAM_PULL`(4개 이상 2.5배 · 2개 이상 1.5배) · 계열 문을 본다. (§34 · §35)
- **보물은 측정 방법부터 정한다:** 단계별 덱(`lab/stagebot.js`)은 덱을 고정해서 보물의 보상 몫(카드 +1 · 다시 뽑기 · 보물상자)이 쌓이지 않는다(2단계 0승). 보물은 40런 · `FAM=loot` 쪽으로 재거나, stagebot에 보상 몫을 흉내 내는 방법을 더한다. `LOOT_R`. (§35)
- **판단을 미룬 것:** 연속 크리는 한 발 상한이 없음(`CRIT_R.chain`) · 판 밖으로 빠진 길의 유령도 착지함 · 착지마다 계열 단계를 더 자주 셈(성능). (§35)
- **단지 힘 나누기 실험을 켤지:** 순서표의 P8 줄 그대로. (§30)
- 균형과 별개로 미룬 Minor는 §33(8개) · §34(5개) · §35(9개)에 있다. P8에서 함께 고칠지 따로 고칠지 정한다.

## 다음 계획
P5가 끝나면 P6(생존·대가 · 계열 잇기: 소환 · 수호 · 피의 대가 · 디버프 종류 보너스 · 듀오 유물 · 변환 · 복사 · 확률 두 배 · 비움 보상 + 새 아이템 9) 계획을 같은 형식으로 쓴다. P5 · P6이 끝날 때마다 `lab/stagebot.js`로 계열 덱 발 수를 다시 재고, 적 체력 배율(`REGION_HP_R`)은 P8에서 최종으로 맞춘다.
