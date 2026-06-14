# Nutrient Logger — Strategy & Product Notes
*Generated June 13, 2026 via App Store report analysis + codebase review*

---

## What the codebase shows

**Tech stack:** SwiftUI + SwiftData, Swinject DI, Firebase Analytics, Google Mobile Ads (AdMob), StoreKit 2 subscriptions. Clean architecture with proper separation of concerns. Good test coverage in Domain and Utils layers.

**Current feature set:**
- Dashboard with macros, vitamins, minerals, amino acids, lipids, carbs breakdown
- Food search against bundled USDA FDC SQLite database (3 databases: legacy, supporting data, survey)
- Recently logged foods + reusable custom meals
- Per-nutrient detail view with RDI explanations
- Water tracking
- User profile with age/gender-specific RDIs for 30+ nutrients
- Home screen widget
- Subscription manager (monthly + yearly, StoreKit 2)
- Native ads via AdMob (shown on Dashboard and Search)

**The offline angle is real and already implemented.** The entire FDC food database ships bundled in the app. This is a genuine differentiator — not a marketing claim that needs to be built.

---

## Market appeal: offline + micronutrient focus

**Short answer: yes, this is a real niche with underserved demand.**

The calorie tracker market hit $4.14B in 2026 growing at 9%/year. But the micronutrient-specific corner is much less crowded:

- **Cronometer** is the main competitor. 10M+ users, 84 nutrients tracked, 4.8 stars with 81K reviews. But users are increasingly angry about intrusive full-screen video ads that "hijack the app for up to half a minute" — even mid-logging. This is a meaningful opening.
- **MyFitnessPal** dominates on food database size (20M+ items) and calories/macros but is weak on micronutrients.
- **MacroFactor** targets strength athletes specifically.
- Newer entrants (PlateLens, Nutrola, Fitia) are betting on AI photo logging.

Your positioning — offline, micronutrient-focused, no intrusive ads, privacy-respecting — is coherent and addresses real Cronometer user frustrations. The risk is that Cronometer still has massive brand recognition and a much larger food database. The USP needs to be sharper in your App Store listing and paywall.

---

## The paywall — what needs to change

**Current state** (from `MarketingView.swift`):
```
• Full access to all premium features
• Helping me feed my family
• Completely ad free experience
```

**What's wrong:**
1. "Full access to all premium features" is meaningless. Users don't know what those features are.
2. "Helping me feed my family" is endearing but not a value proposition. It doesn't help the user decide to pay.
3. There's no feature comparison — what does free get you vs. premium?
4. The strongest hook (offline + privacy) doesn't appear anywhere on the paywall.
5. Products are sorted cheapest first (monthly), which anchors users to the cheaper/higher-churn option. Show yearly first as the default/recommended.

**Suggested rewrite direction:**
```
Unlock Nutrient Logger Premium

Track every vitamin, mineral, and amino acid — completely offline. 
Your data never leaves your device.

✓ Unlimited food logging history
✓ Micronutrient trend charts (7-day, 30-day)
✓ Custom nutrient goals beyond RDIs
✓ Ad-free experience
✓ Priority support

First 7 days free. Cancel anytime.
```

The key changes: lead with the privacy/offline angle, name specific features users can evaluate, and anchor on the yearly plan.

---

## Ads vs. subscriptions only

**Keep ads, but only for free users — and make the ad removal benefit explicit.**

The hybrid model is right for this app. Here's why:

- Ads give free users a reason to upgrade (not just "more features" but immediate relief)
- Native ads (what you have) are far less damaging to retention than interstitial/video ads — Cronometer's mistake is a cautionary tale
- Removing ads entirely means giving up the only monetization on the ~99% of users who won't subscribe

**What to avoid:** never show ads during active logging (the moment a user is adding a food). That's where Cronometer destroys trust. Keep ads to the top of Dashboard and Search only, which is what the code currently does. That's fine.

**Revenue math:** At your current ~300 monthly active users (rough estimate from download/sub data), even $1 CPM from native ads is a few dollars a month. It's not meaningful until DAUs grow substantially. The subscription path has much better unit economics.

---

## Missing features (prioritized)

### High priority — directly impact DAU and conversion

**1. Push notifications / daily logging reminder**
There is no notification code anywhere in the codebase. This is the single biggest missing retention mechanic. A daily reminder at the user's first meal time, or a "you haven't logged anything today" push at 8pm, is standard in every competing app and dramatically improves daily return rates.

**2. Logging streak**
No streak tracking exists. Streaks are the most effective low-cost retention mechanic in habit-forming apps. Even a simple "Day 3 streak 🔥" on the dashboard would meaningfully improve DAU. Pair it with a streak-breaking protection (grace period) to reduce churn anxiety.

**3. Barcode scanner**
Not in the codebase. This is table stakes for a food logger in 2026. Cronometer, MFP, and every major competitor have it. Without it, logging packaged foods requires manual search, which is a major friction point. The USDA FDC database has limited branded food coverage, so barcode scanning + Open Food Facts or a commercial barcode database would also expand coverage.

**4. Calorie / macro targets**
From the code, RDIs are calculated from the USDA tables by age/gender. But there's no visible goal-setting for calories or custom macros (e.g., a keto user wanting 70% fat). Users expect to set personal targets. This likely already exists somewhere but wasn't surfaced in the scenes I reviewed — if it doesn't, it's critical.

### Medium priority — increase conversion

**5. Historical nutrient charts**
`ConsumedNutrientDetailsView` exists and shows a chart for a single nutrient, but there's no multi-day trend view. A "7-day average for Vitamin D" chart would be a natural premium feature — it requires historical data that free users generate but can't visualize.

**6. Apple Health integration**
Not present. Syncing consumed nutrients / calories to Apple Health is expected by health-conscious users and increases perceived value. It also makes the app "sticky" — users don't want to lose their Health data if they delete the app.

**7. Weight tracking**
`WeightUnit.swift` exists in Domain but there's no WeightTrackingView. If weight is tracked, correlating it with nutrient intake would be a compelling premium feature.

### Lower priority

**8. iPad layout** — the app works on iPad but likely uses iPhone layout. Given your Advanced 1st Aid HD history, you know iPad users exist.

**9. Export (CSV / PDF)** — power users want this, and it's a natural premium feature.

**10. AI photo logging** — expensive to build but the market is moving here fast. Worth watching but not urgent for an indie.

---

## ASO / Discovery notes

Your App Store title is "Nutrient Logger Food Tracker." Consider whether "micronutrient" in the subtitle or keyword field would capture searchers who are specifically dissatisfied with macro-only apps. Searches like "vitamin tracker app," "mineral tracking," and "micronutrient log" likely have far less competition than "food tracker" or "calorie counter."

---

## Summary priorities

1. **Push notifications** — implement a daily logging reminder. Highest DAU impact for least code.
2. **Fix the paywall copy** — name specific features, lead with offline/privacy, anchor on yearly plan.
3. **Add a streak** — simple, high retention impact.
4. **Raise prices** — $1.99/year is not a viable subscription price. Test $9.99–$14.99/year.
5. **Barcode scanner** — removes a major logging friction point.
6. **Historical charts as premium feature** — gives a concrete reason to upgrade beyond "ad free."
