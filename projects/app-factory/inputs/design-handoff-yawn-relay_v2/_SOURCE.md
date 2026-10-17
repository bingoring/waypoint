# 출처와 보관 범위

- **출처:** Claude Design 프로젝트 `36f7d853-3fc2-486e-8575-f953f04e746c`, 폴더 `design_handoff_yawn_relay_v2/` (핸드오프 **v2.1**, 2026-10-17). DesignSync(읽기 전용)로 가져왔다(2-11 구현 착수 때, Build Spec yawn-mechanics FC 머리말).
- **원문 그대로 보관:** `README.md`, `02`~`06` 문서, `reference/yawn-render.js`(부품 조합 렌더러 v2 — 캐릭터·타일 코드 원본, Dart 이식 `apps/yawn/lib/ui/character/`의 기준).
- **보관하지 않은 것과 이유:**
  - `reference/svg/*.svg` 238개: 파일마다 C2PA 서명 메타데이터가 붙어 있고 CSS 변형을 쓴다. 앱은 SVG를 읽지 않고, 기준 그림은 `yawn-render.js`를 헤드리스 Chrome으로 다시 그려 뽑는다(`apps/yawn/tool/sprites/export_v2.py` → `test/reference_sprites_v2/`). 파일 이름 목록은 프로젝트에서 `list_files`로 볼 수 있다.
  - `reference/Yawn Handoff v2.dc.html`, `reference/support.js`: 시안 실행용(카드·화면 예시). 규칙·그림의 원본은 렌더러와 문서다. 시안을 보려면 프로젝트에서 연다.
  - `reference/line-colors.json`: 값이 `05_LINE_MAP.md` 표·렌더러 `LINE_COLORS`와 같고, 앱(`lib/ui/lines.dart`)에 이미 반영했다(`570e7c5`).
  - `shots/`: 디자이너 확인용 화면 캡처.
- **확인 기록:** [`../../02-construction/yawn-relay/handoff-v2-review-2026-10-17.md`](../../02-construction/yawn-relay/handoff-v2-review-2026-10-17.md).
