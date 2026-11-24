# 3-1 소개 글 초안

> AI가 쓴 초안이다. 게시는 사용자가 하고, 문안은 3-1 게이트 11에서 정한다.
> - 대괄호 `[...]`는 본인 기록의 집계 수치를 쓸 때만 넣는 문장이다. 값은 2-5 재분석(개발자 기기의 최근 7일, 2026-11-13 ~ 20)과 2-5 프롬프트 시험의 집계다.
> - Homebrew 설치를 확인한 뒤에 올리고, 두 곳 모두 한 번만 올린다. 추천이나 댓글은 부탁하지 않는다.
> - 미확인 환경 안내(게이트 4)를 넣지 않기로 하면 해당 문장을 뺀다.
> - "아낄 수 있다"는 단정은 쓰지 않는다(반목표 5번). 크기와 비용 같은 사실만 쓴다.
> - 2026-11-24: `v0.2`의 큰 세션 정리 안내를 넣고, 수치를 첫 초안의 시험 기간(캐시 재구축 17%)에서 2-5 재분석으로 바꿨다(사용자 결정).

## Show HN (Hacker News)

- **Title** (76자, 80자 제한): `Show HN: Tokens Are Running Out – why your Claude Code usage drained (macOS)`
- **URL:** `https://github.com/bingoring/tokens-are-running-out`
- **첫 댓글(작성자):**

```text
I kept running out of Claude Code usage without knowing why. Claude Code already writes every API call to ~/.claude/projects as JSONL, including cache read and write tokens, so the answer is on disk.

I expected the culprit to be the prompt cache expiring while I took a break, so that the next message had to write the whole context again. That does happen, but it wasn't the biggest part. [Over my last 7 days, cache rebuilds after a break were 13% of the API-price-equivalent cost.] More of it came from ordinary work in long sessions, because every call reads the whole context back from the cache. [68% of my "normal work" cost was those cache reads, and 93% of that normal work cost came from calls with prompts of 200K tokens or more. All 88 compactions in my history were automatic, at a median of about 940K tokens.]

Tokens Are Running Out is a small menu bar app that reads those files and:

- splits the last 5 hours, today and the last 7 days by cause: normal work, cache rebuilds after a short or a long break, subagents, advisor consults and other causes
- points out running sessions over 200K tokens, with what each call re-reads at list price, and copies a /compact prompt for you to paste into that session. The prompt asks the summary to keep the goal, the rules you gave, decisions, files, current state, open problems and the remaining work. The app never runs /compact itself.
- warns before an idle session's cache expires, with how many tokens a resume would have to write again (optionally as a notification), and suggests compacting a large one before you leave
- lists each rebuild with its session, the break before it and the rule that classified it

[I compared the prompt with the default /compact on forked copies of two of my sessions, scored blind, and it came out ahead on both. That's a small sample, and I tested the Korean version; the English one is a translation.]

It sends nothing over the network, never writes to ~/.claude, and doesn't read login tokens, the keychain or cookies. Costs are API list-price equivalents, not your plan's quota, because the quota percentage isn't stored locally.

Install: brew install --cask bingoring/tap/tokens-are-running-out (macOS 14+). Signed and notarized, MIT licensed. So far I've only run it on Apple silicon with macOS 27, so reports from Intel Macs or macOS 14–26 are welcome.

I'd especially like to hear whether the cause breakdown matches what you thought was eating your usage, and whether the compact prompt keeps what you need.
```

## GeekNews (Show GN)

- **유형:** Show(선택하면 제목 앞에 "Show GN:"이 붙는다)
- **제목:** `Tokens Are Running Out - Claude Code 사용량이 왜 줄었는지 원인별로 보여 주는 macOS 메뉴 막대 앱`
- **URL:** `https://github.com/bingoring/tokens-are-running-out`
- **본문:**

```text
Claude Code 사용량이 생각보다 빨리 줄어드는데, 무엇 때문인지 알 수 없어서 만들었습니다. Claude Code는 모든 API 호출을 ~/.claude/projects 아래 JSONL로 기록하고, 여기에는 캐시를 읽고 쓴 토큰 수도 들어 있습니다. 그래서 원인을 로컬 파일에서 찾을 수 있습니다.

처음에는 쉬다가 돌아온 뒤 프롬프트 캐시가 만료되어, 다음 메시지가 컨텍스트 전체를 다시 쓰는 것이 주된 원인이라고 생각했습니다. 실제로 그런 경우도 있었지만, 가장 큰 원인은 아니었습니다. [제 최근 7일 기록에서 쉬었다 돌아온 뒤의 캐시 재구축은 API 정가 환산 비용의 13%였습니다.] 더 큰 부분은 긴 세션에서 하는 일반 작업이었습니다. 호출할 때마다 컨텍스트 전체를 캐시에서 다시 읽기 때문입니다. [일반 작업 비용의 68%가 이렇게 캐시를 다시 읽는 비용이었습니다. 또한 일반 작업 비용의 93%는 프롬프트가 20만 토큰 이상인 호출에서 나왔습니다. 기록에 남은 compact 88회는 모두 자동이었고, 압축 직전 크기의 중앙값은 약 94만 토큰이었습니다.]

Tokens Are Running Out은 이 기록을 읽는 작은 메뉴 막대 앱입니다.
- 최근 5시간, 오늘, 최근 7일의 비용을 원인별로 나눕니다: 일반 작업, 짧은 휴식이나 긴 휴식 뒤의 캐시 재구축, 서브에이전트, advisor 호출 등
- 실행 중인 세션 가운데 컨텍스트가 20만 토큰을 넘는 세션을, 호출마다 다시 읽는 비용(정가)과 함께 보여 줍니다. 그 세션에 붙여 넣을 /compact 프롬프트도 복사해 줍니다. 이 프롬프트는 목표, 사용자가 정한 규칙, 결정, 파일, 현재 상태, 해결하지 못한 문제, 남은 작업을 요약에 남기도록 지시합니다. 앱이 /compact를 직접 실행하지는 않습니다.
- 쉬고 있는 세션의 캐시가 만료되기 전에 남은 시간과, 이어 갈 때 다시 써야 할 토큰 수를 알려 줍니다(알림은 선택). 큰 세션이면 떠나기 전에 정리하라고 안내합니다.
- 캐시 재구축마다 세션, 그 전에 쉰 시간, 분류 규칙을 보여 줍니다.

[제 세션 두 개를 복제해 이 프롬프트와 기본 /compact를 비교했고, 블라인드 평가에서 두 세션 모두 이 프롬프트가 앞섰습니다. 표본이 작다는 점은 감안해 주세요.]

네트워크로 아무것도 보내지 않고, ~/.claude에 쓰지 않으며, 로그인 토큰이나 키체인, 쿠키를 읽지 않습니다. 금액은 요금제의 한도가 아니라 API 정가 환산 값입니다. 한도 비율은 로컬에 저장되지 않기 때문입니다.

설치: brew install --cask bingoring/tap/tokens-are-running-out (macOS 14 이상). Developer ID로 서명하고 공증했으며, MIT 라이선스입니다. 지금까지 Apple silicon의 macOS 27에서만 확인했습니다. Intel Mac이나 macOS 14~26에서 써 보신 결과를 이슈로 알려 주시면 큰 도움이 됩니다.

원인 분해가 평소에 생각하던 사용량 소모 원인과 맞는지, 그리고 정리 프롬프트가 필요한 내용을 잘 남기는지 의견을 듣고 싶습니다.
```
