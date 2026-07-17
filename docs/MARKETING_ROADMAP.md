# Nutrient Logger — Marketing Strategy & Roadmap
*Created July 14, 2026. Companion to APP_STRATEGY.md (product) and WEBSITE_STRATEGY.md (website/content/SEO detail).*

**Situation:** Solid app in a saturated category with a real niche (offline, privacy-respecting, micronutrient-focused). ~300 MAU. No marketing budget, but meaningful time available.

**Strategy in one line:** Fire the spike channels now (launches, featuring, influencer mentions) while the compounding assets (SEO, review count, email list) grow underneath them.

---

## Channel map

| Channel | Type | Cost | Payoff speed | Status |
|---|---|---|---|---|
| App Store listing localization (ASO) | Compounding | Time only | Weeks | Not started |
| Apple editorial featuring nomination | Spike | ~1 hour | Lottery ticket | Not started |
| In-App Events + Custom Product Pages | Compounding | Time only | Weeks | Not started |
| v4.0 launch posts (HN, Product Hunt, Reddit) | Spike | Time only | Days | Not started |
| Micro-influencer outreach (promo codes) | Spike | Free codes | Weeks | Not started |
| Blog / SEO (see WEBSITE_STRATEGY.md) | Compounding | Time only | Months | Landing page done, blog not started |
| Reddit community presence | Hybrid | Ongoing time | Weeks | Not started |
| Email list | Compounding | Free tier | Months | Signup form on landing page |
| Short-form video (experiment) | Hybrid | Time only | Unpredictable | Not started |
| Review flywheel (in-app) | Compounding | Code change | Ongoing | ReviewPrompter exists — verify triggers |
| Paid ads | — | Money | — | **Skip** until organic validates messaging |

---

## Phase 1 — Quick wins (this month)

### 1. Localize the App Store listing for top markets
Germany, Netherlands, Sweden, and Ireland are the top install markets. Localizing the **listing** (not the app) is a weekend of work and targets the highest-intent traffic that exists — people already searching the store. Each locale gets its own title, subtitle, screenshots, and 100-char keyword field. German "Vitamin Tracker" / "Mikronährstoffe" searches have far less competition than English equivalents.

- [x] German (de-DE): title, subtitle, keywords, description, screenshots
- [x] Swedish (sv-SE): title, subtitle, keywords, description, screenshots
- [x] Dutch (nl-NL): title, subtitle, keywords, description, screenshots
- [x] Spanish (es-ES): title, subtitle, keywords, description, screenshots
- [x] French (fr-FR): title, subtitle, keywords, description, screenshots
- [x] Italian (it): title, subtitle, keywords, description, screenshots
- [x] Japanese (ja): title, subtitle, keywords, description, screenshots
- [x] Korean (ko): title, subtitle, keywords, description, screenshots
- [x] Portuguese (pt-BR): title, subtitle, keywords, description, screenshots
- [x] Chinese (zh-Hans): title, subtitle, keywords, description, screenshots
- [x] LLM-draft translations, then native-speaker sanity check (Reddit language subs or Fiverr-level spend if needed)
- [ ] After 30 days: check App Store Connect → Sources for impression/conversion lift per storefront

### 2. Nominate the app for Apple editorial featuring
App Store Connect → "Promote Your App" nomination form. The pitch: **fully offline nutrition tracker — your health data never leaves your device**. This is exactly the privacy narrative Apple features. Free lottery ticket; re-enter for each seasonal moment.

- [x] Write the nomination pitch (privacy/offline angle, indie story, v4.0 feature set) — see APPLE_FEATURING_NOMINATION.md
- [ ] Submit nomination for New Year's resolutions window (submit by ~November 2026)
- [ ] Submit nomination for National Nutrition Month (March 2027; submit by ~January)
- [ ] Re-nominate with each major version

### 3. Set up free App Store visibility surfaces
- [ ] Custom Product Page A: leads with offline/privacy (use for Reddit, HN, blog links)
- [ ] Custom Product Page B: leads with micronutrient depth (use for diet-community links)
- [ ] First In-App Event (e.g., "7-Day Micronutrient Challenge") — events surface in App Store search
- [ ] Compare CPP conversion rates after 30 days; adopt the winning message more broadly

### 4. Launch v4.0 publicly
One good launch shot per major version — v4.0 just shipped, so use it. The bundled-USDA-database architecture is a genuinely good technical story.

- [ ] Show HN post — drafted in HN_LAUNCH_POST.md (title options, body, Q&A prep, timing); complete its pre-flight checklist, then submit
- [ ] Product Hunt launch (screenshots, maker comment, respond all day)
- [ ] r/SideProject, r/iosapps posts (indie narrative: "built this because I couldn't find what I wanted")
- [ ] Link all of the above to the offline/privacy Custom Product Page or landing page, not the raw store link
- [ ] Email blast to existing list announcing v4.0

### 5. Fix the review flywheel
Rating count and recency affect both search rank and conversion — this multiplies every other channel.

- [ ] Verify `ReviewPrompter` triggers at earned-happiness moments (streak milestone, first weekly insight, goal reached) — not on a timer or app-open count
- [ ] Never prompt during or right after logging friction (failed search, unrecognized barcode)
- [ ] Reply to every App Store review, ongoing (replies visible on the listing; shows an alive developer)

---

## Phase 2 — Ongoing engine (weekly rhythm, starting now)

Target: **~10 hrs/week** total marketing time.

### Reddit / community (~4 hrs/week)
Full strategy in WEBSITE_STRATEGY.md. Summary: be helpful first, profile links to the site, never "check out my app." Target subs: r/nutrition, r/carnivore, r/keto, r/vegan, r/Supplements, r/AnimalBased, r/indiehackers.

- [ ] Establish account presence: 2–3 genuinely helpful comments/answers per week
- [ ] After ~4 weeks of history, begin sharing relevant blog posts in discussions
- [ ] Watch for "app recommendation" threads — these are free bottom-funnel placements

### Blog / SEO (~4 hrs/week — one post or video per week)
Full editorial plan in WEBSITE_STRATEGY.md. **Sequencing change from that doc: write bottom-funnel pages first** — those searchers are choosing an app this week.

- [ ] Comparison page: "Cronometer vs MyFitnessPal vs Nutrient Logger" (fair; admit competitor strengths)
- [ ] "Cronometer alternatives without ads" post
- [ ] "Best offline nutrition tracker" post
- [ ] Then pillar content per WEBSITE_STRATEGY.md (micronutrient tracking, diet-specific gaps, privacy, orthodoxy takes)

### Micro-influencer outreach (~2 hrs/week)
The channel the other docs skip. Free promo codes per version + subscription offer codes = free product to give away. The animal-based/carnivore/keto world is full of 2k–50k-follower YouTubers, podcasters, and newsletter writers who answer their own email. The blog's editorial stance makes you legible as "one of us who builds apps."

- [ ] Build a list of 30 niche micro-influencers (YouTube, podcasts, newsletters; prioritize 2k–50k subscribers/followers — big enough to move installs, small enough to answer their own email; for podcasts judge by downloads per episode)
- [ ] Write the pitch template: short personal note, why you built it, code for them + batch for their audience
- [ ] Generate subscription offer codes in App Store Connect
- [ ] Send 10 pitches/month; log responses and mentions
- [ ] After a mention lands: thank them, watch Sources data, offer their audience a dedicated offer code

---

## Phase 3 — Experiments & expansion (month 2+)

### Short-form video experiment (8 weeks, then evaluate)
WEBSITE_STRATEGY.md says skip social media — right call for the follow-me treadmill, but short-form video is interest-based distribution: a zero-follower account can reach 100k people. Time-boxed experiment, one repeatable format.

- [ ] Format: screen-record the app logging a real day of eating → reveal the deficiency insight ("I eat whole foods and was still low on magnesium")
- [ ] Post identical video to TikTok + Reels + Shorts, 1×/week for 8 weeks
- [ ] Evaluate: any video >10k views or measurable install bump → continue; otherwise drop it, having lost only a few hours

### Localized content (per WEBSITE_STRATEGY.md Phase 3)
- [ ] German landing page + 2–3 German blog posts, once English content engine is running
- [ ] Use listing-localization results (Phase 1 #1) to decide whether full app localization is worth it for v4.x

### Press / app roundups (opportunistic)
- [ ] Pitch MacStories, 9to5Mac, iMore, and "best nutrition app" roundup authors when there's a hook (major version, Apple featuring, HN front page). Low hit rate, near-zero cost — batch with influencer outreach.

---

## Measurement (monthly review — first Monday of each month)

Check App Store Connect + Plausible and record in the log below:

- **Installs by source** (App Store Connect → Sources): which channel is actually moving downloads?
- **Storefront breakdown**: did DE/NL/SE listing localization lift impressions → installs?
- **Custom Product Page conversion**: which message wins?
- **Organic search visitors** (site) and App Store CTR from site
- **Email list size** and open rate on announcements
- **Rating count + average** (per storefront)
- **Influencer outreach**: pitches sent / responses / mentions / install spikes

Rule: after 90 days of data, double down on the top channel and cut the bottom one.

---

## Monthly log

| Month | Installs | MAU | Ratings | Top source | Notes |
|---|---|---|---|---|---|
| Jul 2026 (baseline) | | ~300 MAU | | | Phase 1 begins |

---

## What NOT to do (agreed constraints)

- **No paid ads** until organic traction validates messaging and CPI math is known.
- **No always-on social accounts** (Twitter/Instagram feeds as a brand-presence chore) — short-form video experiment is the only exception, and it's time-boxed.
- **No web version of the app.**
- **No link-dropping on Reddit** — reputation first, links later.
