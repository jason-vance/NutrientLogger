# Nutrient Logger — Website Strategy & Roadmap
*Generated June 23, 2026*

---

## Purpose

The website is a **discovery channel**, not a brand destination. At ~300 MAU, there isn't enough brand awareness for people to seek the app out. The site exists to catch people mid-search — via SEO content and community links — and funnel them to the App Store.

---

## Phase 1 — Landing Page ✅ *Complete*

A single-page static site. Deployable for free on GitHub Pages or Netlify.

### What it includes
- **Hero section** — lead with the positioning from STRATEGY.md: "Track every vitamin, mineral, and amino acid — completely offline. Your data never leaves your device."
- **Feature highlights** — barcode scanning, custom foods, 30+ nutrients, goal setting, streak tracking. Screenshots from the app.
- **Competitor differentiation** — brief callout (not aggressive) of what makes this different: micronutrient depth, no intrusive ads, fully offline.
- **App Store link** — prominent, above the fold and repeated at the bottom.
- **Email signup** — "Get notified about new features." Captures warm leads you can announce v3.11/v4.0 to directly. Use a free tier provider (Buttondown, Mailchimp, or similar).
- **Social proof** — pull in notable App Store reviews once available.

### What it does for you
- Gives you a shareable URL for Reddit/forums/social that isn't a raw App Store link (which gets flagged as spam in many communities).
- Starts building an email list — an audience you own, independent of the App Store.
- Establishes a home base before you start publishing content.

---

## Phase 2 — Blog / Content Marketing *(ongoing, 1 post/month minimum)*

### Editorial angle

Don't compete with SEO farms on commodity health content. Write what only you can write: you built a micronutrient tracking tool and have real perspective on nutrition gaps, tracking behavior, and the app landscape. That's the angle.

**Good:** "I tracked every micronutrient for 30 days — here's where my diet actually fell short"
**Bad:** "Top 10 foods high in magnesium" (commodity content, will never outrank WebMD)

### Content types

#### 1. Search content (blog posts) — long-term compounding asset

Target mid-tail queries where competition is lower and intent maps to your app:

| Query cluster | Example topics |
|---|---|
| Micronutrient tracking | "How to track micronutrients not just macros," "What nutrients am I missing?" |
| Competitor frustration | "Cronometer alternatives without ads," "Best offline nutrition tracker" |
| Diet-specific gaps | "Carnivore diet nutrient deficiencies," "Keto micronutrient gaps," "Vegan B12 and iron tracking" |
| Privacy / health data | "Do nutrition apps sell your data?", "Why offline health tracking matters" |
| Nutrient education | "RDI vs actual nutrient needs," "How to know if you're getting enough zinc" |

The person searching "cronometer alternatives without ads" is literally the ideal customer — they've tried the competitor and are frustrated by the exact problem this app solves.

#### 2. Community content (Reddit, forums) — reputation + traffic spikes

Target subreddits: r/nutrition, r/carnivore, r/keto, r/vegan, r/Supplements, r/indiehackers, r/SwiftUI

Strategy:
- Be genuinely helpful first. Answer questions about micronutrient tracking. Share things learned while building the app.
- Don't post "check out my app." Profile links to the site; people find it organically.
- After building some post history, share articles from the blog when relevant to a discussion.
- The indie dev narrative ("I built this because I couldn't find what I wanted") resonates in r/indiehackers and health communities alike.

Community content pays off faster than SEO (a single well-received post can drive 50-200 site visits in a day) but doesn't compound the way search does. Do both.

### Editorial voice & brand positioning

The blog should have a clear, opinionated point of view. Neutral content is invisible — opinion creates loyalty. The people who nod along are the customers; the people who disagree just leave.

**The perspective:** Natural, whole foods — quality meats, dairy, fruit, honey — are the foundation of good health. Processed food is ubiquitous and normalized but not optimal. Influenced by Paul Saladino's animal-based framework, skeptical of conventional nutrition orthodoxy where the data supports skepticism, and willing to say so directly.

**Why this works for the blog:**
- Opinionated content attracts passionate users who are most likely to pay for a premium app.
- The animal-based / ancestral health community (r/carnivore, r/AnimalBased) is underserved by mainstream nutrition apps and highly engaged.
- The indie dev with a point of view is a compelling narrative — "I built this because I couldn't find what I wanted and I think most tracking apps get nutrition wrong."
- Opinion pieces get shared in communities. Neutral listicles don't.

**Voice guidelines:**
- Confident, not combative. "I think BMI is nearly useless compared to body fat percentage" lands differently than "anyone who uses BMI is an idiot."
- Back opinions with reasoning. "Here's why I focus on animal-based nutrition" is persuasive. "Processed food is garbage" without context is dismissive.
- Be honest about personal bias. "I'm an animal-based guy, so take this with that context" builds trust. Readers respect transparency about where you're coming from.
- It's fine to be funny and irreverent. The "laboratory junk" framing is entertaining and relatable when it reads as a real person talking, not a lecture.

**Important distinction — blog vs. app voice:** The blog is where you persuade. The app is where you serve. See STRATEGY.md "Brand voice & opinion in the app" section for how to express a point of view in the app without alienating users who don't share it yet.

### Pillar topics

Pick 3-4 pillars that map to the app's strengths. Write one solid pillar article each, then branch out with shorter related posts over time.

1. **Micronutrient tracking** — the core differentiator. Why macros aren't enough, what most people miss. Strong opinion angle: "Calorie counting is the least interesting thing about nutrition."
2. **Diet-specific nutrition gaps** — carnivore, keto, vegan. Each is a community with search volume and specific nutrient concerns. Natural home for animal-based perspective, but covering other diets fairly broadens reach.
3. **Privacy in health apps** — the offline angle. Timely given increasing health data concerns.
4. **Challenging nutrition orthodoxy** — BMI vs body fat %, RDIs that haven't been updated in decades, the food pyramid's legacy. Opinionated takes backed by reasoning.
5. **Indie app development** *(secondary)* — building a nutrition app as a solo dev. Different audience but builds personal brand and cross-pollinates.

### Comparison content

People searching "cronometer vs myfitnesspal" or "best micronutrient tracker app" are at the bottom of the funnel — actively choosing an app right now.

A fair, honest comparison page that includes Nutrient Logger alongside competitors can capture these searches. Being transparent about where competitors are stronger (database size, community) builds credibility and makes the app's strengths (offline, privacy, no intrusive ads, micronutrient depth) land harder.

---

## Phase 3 — EU / Localization *(when content engine is running)*

Germany, Netherlands, Sweden, and Ireland are the top markets by installs. This is unusual for an English-language app and represents an untapped opportunity.

- Translate the landing page into German and Swedish.
- Publish a few blog posts in German targeting nutrient-related search terms. The competition for German-language micronutrient content is far lower than English.
- This aligns with the v4.0 App Store localization plan in ROADMAP.md — the website can lead that effort and validate whether localized content drives installs before investing in full app localization.

---

## Distribution Strategy

### Channels (ranked by expected ROI)

1. **Organic search (SEO)** — slow to build, compounds over time. The primary long-term growth channel.
2. **Reddit / community** — faster payoff, builds reputation, drives spikes. Requires ongoing participation, not just link-dropping.
3. **Email list** — lets you announce v3.11, v4.0, blog posts to warm leads. Small at first but high-intent audience.
4. **Backlinks** — articles that get linked to from other sites improve both SEO ranking and App Store discoverability (Apple indexes web presence).

### What to skip for now

- **Paid ads** — don't pay for traffic until organic traction validates the messaging and you know your cost-per-install math.
- **Social media accounts** — managing Twitter/Instagram/TikTok as a solo dev is a time sink with uncertain ROI. Reddit participation is higher leverage for this niche.
- **Web version of the app** — different product entirely, too much effort, dilutes focus.

---

## Realistic Timeline

| Period | What to expect |
|---|---|
| Month 1 | Landing page live. First 1-2 blog posts published. Almost no organic search traffic — this is normal. |
| Months 2-3 | A few Reddit posts drive traffic spikes. Google begins indexing content. Email list has a handful of subscribers. |
| Months 3-6 | Low-competition articles start appearing in search results. ~100-300 monthly organic visitors. |
| Months 6-12 | Search traffic compounds if posting consistently. Some articles drive steady daily visits. Email list grows enough to meaningfully amplify app update launches. |
| Year 2+ | The blog becomes a durable acquisition channel. Older posts continue driving traffic without additional effort. |

Content marketing is a slow game, especially solo. But it's free, it compounds, and it builds an asset you own. Paid ads stop the moment you stop paying. A good blog post keeps working for years.

---

## Technical Decisions

| Decision | Recommendation | Why |
|---|---|---|
| Hosting | GitHub Pages or Netlify (free tier) | Zero cost, easy deployment, sufficient for a static site + blog |
| Framework | Static site generator (Hugo, Astro, or plain HTML/CSS) | Fast, no server to maintain, free hosting compatible |
| Email provider | Buttondown or Mailchimp (free tier) | Simple signup form embed, sufficient until list exceeds free limits |
| Analytics | Plausible or Umami (privacy-respecting) | Aligns with the app's privacy positioning; avoid Google Analytics irony |
| Domain | Custom domain (~$12/year) | Credibility; nutrientlogger.com or similar |

---

## Success Metrics

- **Monthly organic visitors** — are search-driven visits growing month over month?
- **App Store click-through rate** — what percentage of site visitors tap the App Store link?
- **Email signups** — is the list growing? Do subscribers convert to installs when you announce updates?
- **Content ROI** — which articles drive the most traffic and App Store clicks? Double down on those topics.
- **Reddit engagement** — are posts in target subreddits gaining traction and driving site visits?

---

## Relationship to App Roadmap

| App version | Website opportunity |
|---|---|
| v3.11 (Premium Depth) | Blog post: "Why we built 30-day nutrient trend charts." Email blast to list. New screenshots on landing page. |
| v4.0 (New Chapter) | Full site refresh. Launch blog post / Reddit post (already in ROADMAP.md). German/Swedish landing page if Phase 3 is underway. App Preview video embedded on site. |
| v4.x (AI photo logging) | Content angle: "The future of food logging" — positions the app as forward-thinking before the feature even ships. |
