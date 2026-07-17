# Show HN Post — Nutrient Logger v4.0
*Drafted July 14, 2026. Submit at news.ycombinator.com/submit. See "Mechanics" at the bottom for timing and URL choice.*

HN rewards technical specifics, honest trade-offs, and a real person answering questions — and punishes marketing language and overclaiming. Everything below is written for that audience.

---

## Title (80 char max — pick one)

1. `Show HN: I bundled the USDA food database into an iOS app so it works offline` *(recommended — 78 chars, leads with the technical hook)*
2. `Show HN: An offline-first nutrition tracker with the USDA database on-device`
3. `Show HN: Nutrient Logger – track 80+ nutrients fully offline`

No clickbait, no superlatives — HN moderators rewrite titles that oversell, and the community downvotes them.

---

## Post text

> I got frustrated that every nutrition tracker I tried was a thin client for someone's server — my food log lived in their cloud, search broke without a signal, and the biggest micronutrient tracker started interrupting logging with full-screen video ads. So I built the opposite.
>
> Nutrient Logger ships the USDA FoodData Central database inside the app: three SQLite files (~54 MB total, ~15k whole and survey foods) with FTS5 for search. Searching, logging, and all nutrient analysis happen on-device. There's no account and no backend — your food log is in SwiftData on your phone and syncs nowhere. It works on a plane or off the grid.
>
> The angle that made me build it: most trackers stop at calories and macros. Every food in the USDA data carries 80+ nutrients — vitamins, minerals, amino acids, lipids — so the app computes your daily intake against age/sex-based targets and, in the new 4.0 release, flags the nutrients you've been consistently low on and suggests foods that would close the gap.
>
> Tech, for the curious: SwiftUI + SwiftData, StoreKit 2, HealthKit sync, a home-screen widget, all solo-developed. The fun problems were search (FTS5 query generation that handles "OJ" → orange juice) and squeezing the FDC data down to something bundle-able.
>
> Honest limitations: it's iOS-only. Branded/packaged food coverage is thinner than MyFitnessPal's 20M-item database — barcode scans fall back to Open Food Facts, which is the one feature that does need a network. Business model is boring on purpose: free with small native ads (never during logging), and a subscription that removes them and unlocks trend charts, body-goal tracking, and Health sync. The free tier is fully functional for logging and daily nutrient breakdowns.
>
> I'd love feedback — especially from anyone who's tried tracking micronutrients and given up, and from anyone who's shipped large read-only datasets in a mobile bundle and found a better trade-off than I did.
>
> App Store: https://apps.apple.com/us/app/nutrient-logger-food-tracker/id1536557332 · Site: https://nutrientlogger.com/

---

## Anticipated questions — prep your answers before posting

Have these ready; response speed in the first hour matters more than the post itself.

**"You say private, but the privacy label shows ads and analytics."** ⚠️ *This is the thread-killer if handled badly.* The app uses Firebase Analytics and AdMob. Do NOT claim "no data collection." The defensible claim — which the post above is careful to make — is that **the food log never leaves the device**. Suggested answer: "Fair point, and I want to be precise: your food log, body metrics, and search history never leave the device — there's no server for them to go to. The free tier shows AdMob native ads and I use Firebase for crash/usage analytics, which collect standard device-level data; that's disclosed in the privacy label. Subscribing removes the ads. I'd genuinely like to move to privacy-respecting analytics eventually." If that last clause isn't true, cut it — don't promise on HN what you won't ship.

**"Why not open source?"** Honest answer only. E.g.: "It's my income as a solo dev and I'm not ready to give the app away, but I'm happy to write up the FDC-to-SQLite pipeline / FTS5 approach if there's interest." (That write-up is also a future blog post — see WEBSITE_STRATEGY.md.)

**"Android/web version?"** "No plans — solo dev, staying focused on making the iOS app excellent." Don't waffle.

**"How is this different from Cronometer?"** Facts, no trash talk: offline/on-device vs. cloud account; no interstitial video ads; smaller food database (concede this); cheaper.

**"USDA data licensing?"** USDA FoodData Central is U.S. government work — public domain. Open Food Facts is ODbL; confirm the app's attribution for OFF data before posting.

**"How do you handle database updates?"** Know your actual answer: shipped with app updates? Describe the pipeline briefly — HN loves pipeline details.

**"SwiftData in production?"** War stories welcome — this alone can carry a comment subthread with iOS devs.

---

## Mechanics

- **URL:** Link the Show HN to the **landing page** (most HN readers are on desktop and can't open the App Store), with the App Store link prominent there. Use the offline/privacy Custom Product Page as the store link if it's live (Roadmap Phase 1 #3).
- **Text + URL:** Show HN allows both a URL and text. If the form drops the text, post the body as your immediate first comment instead.
- **Timing:** Post Tuesday–Thursday, 8–10 AM Eastern. Block off the next 4–6 hours to answer every comment — a responsive author is what keeps a Show HN on the front page.
- **Don't ask for upvotes.** Voting-ring detection penalizes it. Don't share the direct HN link asking people to vote; sharing "I'm on HN today" after it has traction is fine.
- **One shot per story:** If it gets no traction, HN allows a repost after a few days (mods sometimes even invite one via the second-chance pool). Don't repost more than once.
- **Afterwards:** Add the traffic spike numbers to MARKETING_ROADMAP.md's monthly log, and mine the comment thread — HN objections are free copy testing for the paywall and landing page.

---

## Pre-flight checklist

- [ ] Verify Open Food Facts attribution exists in the app (ODbL requirement) — check before HN finds it
- [ ] Confirm database-update story (how do bundled DBs get refreshed?) so the answer is ready
- [ ] Landing page live, loads fast, App Store link above the fold
- [ ] Decide the analytics answer (keep Firebase vs. commit to privacy-respecting analytics) — don't improvise this one
- [x] Fill in the two [link] placeholders in the post text
