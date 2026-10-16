# 출처와 보관 범위

- **출처:** Claude Design 프로젝트 `36f7d853-3fc2-486e-8575-f953f04e746c` (오너 공유 링크, 2026-10-16), 폴더 `design_handoff_yawn_relay/`. DesignSync(읽기 전용)로 가져왔다.
- **원문 그대로 보관:** `README.md`, `01`~`06` 문서, `reference/prototype/Yawn Relay.dc.html`(부품 조합 렌더러 `P(o)` 포함 — 캐릭터의 코드 원본), `reference/prototype/support.js`.
- **보관하지 않은 것과 이유:**
  - `reference/characters/*.svg` 59개: 내보낸 파일의 SVG 본문이 여러 겹 이스케이프된 글자로 저장되어(예: `&lt;defs&gt;&amp;lt;clipPath…`) 그림으로 열리지 않고, 파일마다 C2PA 서명 메타데이터(약 10KB)가 붙어 있다. 캐릭터는 시안 HTML의 `P(o)` 렌더러로 다시 뽑는다(2-9 Build Spec §4 「스프라이트 파이프라인」).
  - `reference/prototype/android-frame.jsx`: Claude Design의 범용 안드로이드 기기 틀(시안 실행용). 구현과 무관하다. 시안을 로컬에서 실행하려면 프로젝트에서 다시 받는다.
  - `reference/design-brief.md`: 우리가 보낸 요청서와 같다(`02-construction/yawn-relay/design-brief-2026-10-16.md`).
