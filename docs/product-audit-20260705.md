# gridbill-ph product audit, 2026-07-05

8-dimension product audit (not a code review), run as a grounded propose-verify
loop: deterministic gates first, four subagents over eight dimensions, then every
cited file:line re-checked by hand against the source. Scored in bands, worst
unmitigated finding caps the band.

Live evidence this session:
- `ruff check .` clean; `python3 tests/test_data.py` all green; `python3
  tests/qa_gate.py` clean; `zsh tests/e2e.sh` 17/17 at audit start.
- Not deployed (deploy gated on Xavier). Git repo, clean tree, 7 commits.

Two findings changed the numbers and were fixed in the same session (see the
roadmap); this audit records the state that prompted them.

## Bands

| Dimension | Band | One line |
|---|---|---|
| UX | Adequate | Desktop polished and honest; mobile buried the mode bar under the rail, hover-only features unreachable on touch, no deep links, no share image |
| Intelligence | Adequate | Honest spine is real and test-enforced, but the league counted hourly day-ahead re-runs as "5-min rows" and the price series mixed 24 suspension-window days into a market-outcome claim |
| Reliability | Adequate | Bake fails loudly on schema drift and the frontend degrades without crashing, but the archiver could not fail visibly and a partial download poisoned the archive silently |
| Performance | Adequate | Page is light (about 0.5 MB cold); the DIPCEF branch fetched about 24 zips a day against a "sample only" intent, roughly 1.3 GB/yr repo growth |
| Observability | Needs work | Strong dev-time `__diag`; every production failure path failed dark (no banner, no beacon, hardcoded layer count, unused meta) |
| Security | Excellent | SRI-pinned CDN, least-privilege token, no shell injection, path-confined writes, dev server bound to localhost |
| Operational | Adequate | Reproducible make targets and offline bake, but no LICENSE file behind the badge, no remote, cron did not re-bake |
| Feature Gaps | Adequate | Findings drawer, deep links, per-corridor joins, og.png all absent vs the house bar |
| **Ship-readiness** | **Adequate** | Honest and well-built; the launch-mechanic gaps (share image, mobile, deep links) and two data-integrity findings were the blockers, now addressed |

## Ship blockers (for the stated goal: a public launch and a LinkedIn post)

- **[High] The congestion league counted day-ahead re-runs as time-at-limit.**
  RTDCV rows are 5-minute real-time intervals; DAPCV rows are hourly and the
  day-ahead market re-prices through the day, so the same equipment-hour appeared
  up to 23 times. 82% of the league's row count (32,943 of 40,351) was day-ahead
  re-run persistence, and the column was labeled "5-min rows." Verified against
  the raw archive. Fixed: the league now ranks by days (a re-run cannot inflate a
  day) and keeps RT intervals and DAP rows in separate, correctly-labeled columns.
- **[High] The price series folded 24 suspension-window days into a market claim.**
  WESM ran administered prices through 2026-05-01; 24 of the 80 price days
  (Apr 7-30) are not market outcomes, yet the Q3 verdict read "the market already
  prices the geography daily" with no flag. Verified: those 24 days show a
  P0.015/kWh max regional spread vs P5.88 mean after resumption. Fixed: the bake
  now splits administered vs market regimes and every mean says which it covers.
- **[High] No live URL, no share image.** A share-first artifact needs both. The
  og:image tag and a hero image were absent. og.png tag wired (image generated in
  the figures phase); deploy stays gated on Xavier.

## High impact (fixed this session)

- **[High] The daily archive cron could not fail.** A total IEMOP outage or a page
  restructure was caught, printed, and returned 0; nothing notified; the manifest
  timestamp forced a daily commit even on total failure. Against IEMOP's rolling
  ~90-day window, a silent multi-week outage is permanent loss of the exact asset
  the project exists to keep. Fixed: `main()` returns nonzero on any dataset
  failure, a `--check` staleness gate fails the workflow when the archive stops
  growing, and the workflow has explicit red steps.
- **[High] A partial download poisoned the archive.** On a curl exit code the
  truncated file stayed on disk, passed the not-HTML check next run, and was
  committed and skipped forever. Fixed: the partial file is deleted on any curl
  failure.
- **[High] Every production failure path failed dark.** A failed data fetch mapped
  to null with no banner, log, or diag flag; a missing chokepoints file blanked
  all layers including the DC pins that had loaded; `__diag.layers` was hardcoded
  to 3. Fixed: a visible banner on fetch failure, per-source layer guards, an
  honest layer count, and the fetch-failure list in `__diag`.
- **[High] Mobile buried the mode bar and hid every evidence panel.** At 390px the
  mode bar sat under the story rail and the side panel plus legend were
  `display:none`, so a touch user could not read a pin or switch questions. Fixed:
  mode bar repositioned above a height-capped rail, a Details toggle surfaces the
  panel, and map features answer to tap as well as hover.

## Improvements (addressed or logged)

- **[Medium] DIPCEF fetched ~24 zips/day against a "sample only" intent.** Fixed:
  DIPCEF defaults to 0 days on `--daily`, so the sample stays static and the repo
  stays light.
- **[Medium] `hvdc.json` was a schema-only stub.** The archive has zero RTD HVDC
  limit rows in-window (a real receipt: the links' binding evidence is in the
  monthly reports, not the RTD limit file). Fixed: the bake records the in-window
  limit-row count and a plain note instead of a stub.
- **[Medium] Methodology called LOAD_BID "peak demand."** The code comment
  forbids that reading (bid-in load, hundreds of MW, not grid peak). Logged for
  the methodology pass.
- **[Low] No LICENSE file behind the MIT/CC-BY badge.** Fixed: LICENSE and
  CITATION.cff added, with the IEMOP republication and takedown posture stated.
- **[Low] CLAUDE.md said port 8788; everything else says 8789.** Logged.

## Cross-cutting themes

1. **Built and honest, and now measured and shippable.** The honesty spine (labeled
   forecasts, contested ranges, banned-framing gate) was real from the start. The
   two data-integrity findings were subtle counting choices, not framing failures,
   and both are now split and labeled.
2. **The archive is the product, so the archiver is the reliability surface.** The
   sharpest findings were all about the unattended cron silently losing the one
   asset nobody else keeps. That is now the loudest failure path, not the quietest.
3. **Launch mechanics were under-built for a share-first map.** Deep links, a
   findings drawer, per-corridor receipts on hover, and a share image are what make
   the map spread and what let a reader check a claim in one click. All added.

## Top 5 actions (impact/effort, all done this session unless noted)

1. Split the congestion league by market and rank by days; split the price series
   by regime. Fixes the two integrity findings. Effort: M. Done.
2. Findings drawer with fly-to cards, deep-linkable `?q=&finding=`, per-corridor
   receipts on the choke-point hover. Fixes the biggest feature gaps. Effort: M. Done.
3. Make the archiver fail loud: nonzero exit, `--check` staleness gate, partial-file
   cleanup, cron re-bake and test. Fixes the reliability blockers. Effort: M. Done.
4. Mobile layout, failure banner, og.png tag, meta freshness surfaced. Fixes UX and
   observability. Effort: S-M. Done (mobile pixel-verify deferred to the deploy gate).
5. LICENSE + CITATION.cff; CI workflow running the gates on push. Effort: S. Done.
