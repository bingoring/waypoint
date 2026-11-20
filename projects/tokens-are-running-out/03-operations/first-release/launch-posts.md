# 3-1 소개 글 초안

> AI가 쓴 초안이다. 게시는 사용자가 하고, 문안은 3-1 게이트 11에서 정한다.
> - 대괄호 `[...]`는 본인 기록의 집계 수치를 쓸 때만 넣는 문장이다. 값은 설계 입력 1장의 집계다.
> - Homebrew 설치를 확인한 뒤에 올리고, 두 곳 모두 한 번만 올린다. 추천이나 댓글은 부탁하지 않는다.
> - 미확인 환경 안내(게이트 4)를 넣지 않기로 하면 해당 문장을 뺀다.

## Show HN (Hacker News)

- **Title** (76자, 80자 제한): `Show HN: Tokens Are Running Out – why your Claude Code usage drained (macOS)`
- **URL:** `https://github.com/bingoring/tokens-are-running-out`
- **첫 댓글(작성자):**

```text
I kept running out of Claude Code usage without knowing why. Claude Code already writes every API call to ~/.claude/projects as JSONL, including cache read and write tokens, so the answer is on disk.

What I found is that a lot of the spend was the prompt cache being rebuilt after a break: the cache had expired, so the next message wrote the whole context again. [On my own history over a test period, rebuilds after an expired cache were 17% of the API-price-equivalent cost, and a third of that came after short breaks of 1–3 hours.]

Tokens Are Running Out is a small menu bar app that reads those files and:

- splits the last 5 hours, today and the last 7 days by cause: normal work, cache rebuilds after a short or a long break, subagents, advisor consults and other causes
- warns before an idle session's cache expires, with how many tokens a resume would have to write again (optionally as a notification)
- lists each rebuild with its session, the break before it and the rule that classified it

It sends nothing over the network, never writes to ~/.claude, and doesn't read login tokens, the keychain or cookies. Costs are API list-price equivalents, not your plan's quota, because the quota percentage isn't stored locally.

Install: brew install --cask bingoring/tap/tokens-are-running-out (macOS 14+). Signed and notarized, MIT licensed. So far I've only run it on Apple silicon with macOS 27, so reports from Intel Macs or macOS 14–26 are welcome.

I'd especially like to hear whether the cause breakdown matches what you thought was eating your usage.
```

## GeekNews (Show GN)

- **유형:** Show(선택하면 제목 앞에 "Show GN:"이 붙는다)
- **제목:** `Tokens Are Running Out - Claude Code 사용량이 왜 줄었는지 원인별로 보여 주는 macOS 메뉴 막대 앱`
- **URL:** `https://github.com/bingoring/tokens-are-running-out`
- **본문:**

```text
Claude Code 사용량이 생각보다 빨리 줄어드는데, 무엇 때문인지 알 수 없어서 만들었습니다. Claude Code는 모든 API 호출을 ~/.claude/projects 아래 JSONL로 기록하고, 여기에는 캐시를 읽고 쓴 토큰 수도 들어 있습니다. 그래서 원인을 로컬 파일에서 찾을 수 있습니다.

직접 살펴보니, 쉬다가 돌아온 뒤 프롬프트 캐시가 만료되어 다음 메시지가 컨텍스트 전체를 다시 쓰는 경우가 비용의 상당 부분을 차지했습니다. [제 기록의 시험 기간에는 만료로 생긴 캐시 재구축이 API 정가 환산 비용의 17%였고, 그중 3분의 1은 1~3시간의 짧은 휴식 뒤에 생겼습니다.]

Tokens Are Running Out은 이 기록을 읽는 작은 메뉴 막대 앱입니다.
- 최근 5시간, 오늘, 최근 7일의 비용을 원인별로 나눕니다: 일반 작업, 짧은 휴식이나 긴 휴식 뒤의 캐시 재구축, 서브에이전트, advisor 호출 등
- 쉬고 있는 세션의 캐시가 만료되기 전에 남은 시간과, 이어 갈 때 다시 써야 할 토큰 수를 알려 줍니다(알림은 선택).
- 캐시 재구축마다 세션, 그 전에 쉰 시간, 분류 규칙을 보여 줍니다.

네트워크로 아무것도 보내지 않고, ~/.claude에 쓰지 않으며, 로그인 토큰이나 키체인, 쿠키를 읽지 않습니다. 금액은 요금제의 한도가 아니라 API 정가 환산 값입니다. 한도 비율은 로컬에 저장되지 않기 때문입니다.

설치: brew install --cask bingoring/tap/tokens-are-running-out (macOS 14 이상). Developer ID로 서명하고 공증했으며, MIT 라이선스입니다. 지금까지 Apple silicon의 macOS 27에서만 확인했습니다. Intel Mac이나 macOS 14~26에서 써 보신 결과를 이슈로 알려 주시면 큰 도움이 됩니다.

원인 분해가 평소에 생각하던 사용량 소모 원인과 맞는지 의견을 듣고 싶습니다.
```
