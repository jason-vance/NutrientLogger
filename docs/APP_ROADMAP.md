# Nutrient Logger — Release Roadmap
*Starting point: v3.6 (current) | Generated June 2026 | Revised June 2026 after App Store review analysis*

The goal of this roadmap is to convert a high-download, low-revenue app into a sustainable subscription business. Each release is scoped to be shippable in roughly 1–3 weeks of part-time work. Non-code tasks are included because they're often where releases fail commercially even when the code is solid.

**Testing convention:** Test coverage is currently thin (~9 test files, mostly Domain/FoodModels). Starting with v3.6, each new feature that includes non-trivial logic (streaks, goals, chart aggregation, etc.) should ship with unit tests covering that logic — especially date-boundary, precedence/fallback, and aggregation edge cases. Don't retrofit later.

---

## v3.6 — "Foundation" *(~1 week)* ✅ Done
**Theme:** Zero-risk revenue improvements. No new code features, just fixing what's already broken about the business model.

### Code
- [x] Reorder subscription products on the paywall — **show yearly plan first** (highest LTV, should be the default)
- [x] Rewrite `MarketingView` copy (see `STRATEGY.md` for suggested text — lead with offline/privacy, name specific features, remove "Helping me feed my family")
- [x] Add yearly plan savings callout (e.g. "Save 60% vs monthly")
- [x] Add simple **logging streak counter** to the Dashboard header (day count + flame icon). No notifications yet — just the visual. Store streak in UserDefaults; reset if no foods logged by midnight.

### App Store Connect
- [x] **Raise subscription prices:**
  - Monthly: $0.99 → $1.99
  - Yearly: $1.99 → $9.99
  - *(Existing subscribers are grandfathered automatically)*
- [x] Update subscription display names and descriptions in ASC to match new paywall copy
- [x] Verify free trial is active and set to 7 days on both products

### Store Listing
- [x] Update **app subtitle** — current is likely generic; test "Offline Micronutrient & Vitamin Tracker"
- [x] Update **keyword field** — add: `micronutrient`, `vitamin tracker`, `mineral log`, `offline food log`, `nutrient deficiency`; drop low-volume generic terms like `food` or `health`
- [x] Update **description** to open with the offline/privacy angle and name the micronutrient depth as the key differentiator vs. MyFitnessPal/Cronometer
- [x] Update **What's New** text to mention price includes 7-day free trial

---

## v3.7 — "Habit Loop" *(~2 weeks)* ✅ Done
**Theme:** Push notifications and streak protection. The single highest-ROI retention investment.

### Code
- [x] Request notification permission during onboarding (post-setup, not on first launch)
- [x] **Daily logging reminder** — user sets a preferred time (e.g. "Remind me at 7pm if I haven't logged dinner"). Default: 8pm. Fire only if no food logged since noon.
- [x] **Streak-at-risk notification** — fire at 9pm if streak > 3 days and nothing logged today ("Don't break your 5-day streak! Log something before midnight.")
- [x] Persist streak to iCloud (via `NSUbiquitousKeyValueStore`) so it survives app reinstalls
- [x] **Smarter paywall trigger** — show `MarketingView` after the user completes their first full logging day (all 3 meal times have at least 1 food), not just from settings. Only show once per 30 days if dismissed.

### App Store Connect
- [x] No product changes needed

### Store Listing
- [x] Add new screenshot showing streak counter on dashboard
- [x] Add notification permission prompt to onboarding screenshots if applicable
- [x] Update **What's New**: "Daily reminders and streak tracking to build a lasting nutrition habit"

---

## v3.8 — "Log Anything" *(~2–3 weeks)* ✅ Done
**Theme:** Custom food entry. App Store review analysis (20 reviews, Nov 2020–Aug 2024) showed the app's negative reviews aren't about value — they're almost all "the data is great but I can't log what I'm actually eating." Manual food entry is the single most-requested feature and the biggest driver of 1-star reviews, so it leads the roadmap now.

### Code
- [x] **Manual/custom food entry** — when search comes up empty, let the user create a food from scratch: name, serving unit/size, and nutrient values (calories, macros, and as many tracked micronutrients as they want to fill in; unfilled nutrients default to 0/unknown rather than blocking save)
  - New `CustomFood`-style model + local persistence
  - Surface custom foods as a result type in `FoodSearchView` alongside Recently Logged / FDC / User Meals
  - Allow editing and deleting custom foods later
- [x] **Saveable custom foods** — once created, a custom food is reusable (covers the "save my daily smoothie and reuse it" request), which falls naturally out of the model above
- [x] **Delete whole meal** — add a delete action on the meal header in `ConsumedMealsView` to remove every food logged under one meal time in a single action
- [x] Audit `NutrientInfoView` content coverage — make sure every tracked nutrient (including edge cases like Ash) has a plain-language explanation of what it is and what too-high/too-low means; fill any gaps
- [x] Add unit tests for custom food persistence and nutrient calculation with partially-filled nutrient data

### App Store Connect
- [x] No product changes needed

### Store Listing
- [x] New screenshot: custom food entry screen
- [x] Update **What's New**: "Can't find a food? Add it yourself — and save it for next time."
- [x] Update description: "log anything — search our database or add your own"

---

## v3.9 — "Set Your Targets" *(~2 weeks)* ✅ Done
**Theme:** Calorie/macro goal setting, plus a food-search quality pass. Goal-setting is prerequisite groundwork for v3.11's trend charts; search-matching fixes were called out repeatedly in review feedback and are a quick, contained win while `FoodSearchView` is already in scope.

### Code
- [x] **Improve food search matching** — reduce false-positive matches surfaced in reviews (e.g. searching "peas" returning peaches/pears) and improve discoverability for items that currently require unintuitive search terms (e.g. cinnamon only found via "spice, cinnamon")
- [x] **Calorie/macro goal setting** — confirmed missing (see `UserProfileView.swift` TODO at line 42; `User` model has no goal fields). Scope as its own feature, not a quick audit:
  - Add persisted goal fields to the `User` model (daily calorie target, optional macro targets)
  - Add UI in `UserProfileView` to set/edit goals, with sensible RDI-derived defaults
  - Update dashboard comparisons to use custom goals when set, falling back to RDI/USDA values otherwise
  - This is prerequisite groundwork for v3.11 trend charts (need a target line to plot against)
  - Add unit tests for goal precedence logic (custom goal vs. RDI fallback) and any date-boundary handling
- [x] **Extend goal setting to all micronutrients** — collapsible sections with full nutrient coverage, RDI override per nutrient
- [x] Fix `ConsumedNutrientChart` crash, ln 114 when `nutrientFoodPairs` is empty

### App Store Connect
- [x] No product changes needed

### Store Listing
- [x] Update **What's New**: "Set your own calorie and macro goals — see how today compares"
- [x] Update description to mention custom goal setting

---

## v3.10 — "Scan" *(~2 weeks)* ✅ Done
**Theme:** Barcode scanner, on its own. Removes the biggest remaining logging friction for packaged foods, and pairs naturally with v3.8's custom-food entry as the fallback for anything a scan doesn't find. This is a marquee feature that will show up in reviews and word-of-mouth.

### Code
- [x] Implement **barcode scanner** using `AVFoundation` (no third-party SDK needed)
- [x] Look up scanned UPC/EAN against a barcode-to-FDC mapping. Options:
  - Open Food Facts API (free, large, open source) — best starting point
  - USDA FDC branded foods database (already partially in `fdc_legacy.db` — check coverage)
- [x] Add camera permission usage description to `Info.plist`
- [x] Add barcode scan button to `FoodSearchView` toolbar (next to the search field)
- [x] Handle "not found" gracefully — fall back to manual search, and from there to the v3.8 custom-food-entry flow as the ultimate fallback
- [x] **Analytics:** Track barcode scan success/failure rate, scan-to-log conversion, and "not found" fallback path taken (manual search vs. custom food entry)

### App Store Connect
- [x] Add camera permission justification (required for App Review)

### Store Listing
- [x] New **feature screenshot**: barcode scanner in action
- [x] Add "Scan barcodes" to feature list in description
- [x] Update **What's New**: "New: Scan any barcode to instantly log packaged foods"
- [x] Consider **A/B test** on first screenshot (current vs. barcode scan as hero image) — this is now a visual hook that competing apps lead with

---

## v3.11 — "Premium Depth" *(~3 weeks)*
**Theme:** Give subscribers concrete reasons they can't get elsewhere. Creates tangible value separation between free and premium tiers.

### Code
- [x] **7-day and 30-day nutrient trend charts** (premium only)
  - Aggregate `ConsumedFood` history by day for any selected nutrient
  - Reuse/extend `ConsumedNutrientChart.swift` which already exists
  - Show vs. RDI target line
  - Gate behind `subscriptionManager.isSubscribed`
- [x] **Apple Health integration**
  - Write consumed calories, protein, fat, carbs, water to `HKHealthStore`
  - Request read permission for weight (to populate user profile automatically)
  - Add toggle in `UserProfileView` to enable/disable sync
- [x] **Weight tracking**
  - `WeightUnit.swift` already exists in Domain — build the UI on top of it
  - Simple log view: date + weight entry, chart over time
  - Sync weight entries to Apple Health if integration is enabled
- [x] Update paywall copy to list the three new premium features specifically
- [x] **Analytics:** Track premium feature tap when not subscribed (trend charts, Health sync, weight tracking), chart nutrient selection frequency, and Health sync enable/disable rate
- [x] Random improvements
  1. Auto-select meal time when logging food based on time of day
  2. Body measurement streak (weekly streak on Body tab, kept alive by logging at least once per week)

### App Store Connect
- [x] No subscription product changes needed
- [x] Ensure HealthKit capability is added in the App ID (entitlements)

### Store Listing
- [x] New screenshots showing trend charts and weight tracking
- [x] Update description premium features section
- [x] **What's New**: "Premium: nutrient trend charts, weight tracking, and Apple Health sync"
- [ ] Submit for **App Store feature consideration** (apple.com/search) — HealthKit integration makes this more likely to be featured in Health & Fitness

---

## v4.0 — "New Chapter" *(~4–6 weeks)*
**Theme:** Major milestone release. Justifies a full store listing refresh, potential press mention, and a reason for lapsed users to return. Version 4.0 signals maturity and intentional investment.

### Code
- [x] Update website features, etc for v3.11.
- [x] **Visual Identity**
  1. [x] App-wide accent color? (currently .systemBlue, not really integrated anywhere except as tint/accent. Should it be a more primary part of the UI?) No
  2. [x] Remove favorite color setting from profile
- [ ] **Navigation & Tab Restructure** (still needs some planning)
  1. [x] Dashboard should probably be renamed "Nutrition"
  2. [x] Food search moved to nutrition tab
- [x] **Engagement & Gamification**
  1. [x] Daily Streak is moved into a Nutition tab card
  2. [x] Weekly Streak is moved into a Body tab card 
  3. [x] Streak cards - animations on increment and milestone
  4. [x] Tap streak card for streak stats
  5. [x] Make water logging a more exciting part of nutrition logging (trend charts like other nutrients, animations would be nice, quick log)
- [x] **Body Metrics & Goals**
  1. [x] Choose a more active looking icon for the tab bar
  2. [x] Basic tracking is not premium gated but goals and everything based on goals is premium
  3. [x] More body metrics (optional, BMI, waist circumference, healthkit read/write)
  4. [x] Ability to select and order which metrics are on the body tab (per metric on/off toggle)
  5. [x] Body goals deadline (calculate required weekly rate of change, pace tracker, linear(or maybe fancier based on their past performance) projected trajectory on body metric chart(s))
  6. [x] calculate BMR from current stats (weight, height, age, sex), then show a TDEE-based calorie target that would move you toward your goal weight by your deadline
  7. [x] Change chart time frames (1,3,6,12 months)
  8. [x] Move body settings from profile to body tab settings
  9. [x] Body metrics change stat should be based on selected time frame 
  10. [x] Move goals and calorie target to the body tab settings 
- [x] **Profile Tab**
  1. [x] Add achievements card
  2. [x] Add subscription card
  3. [x] Put personal data into a card
  4. [x] Group other settings appropriately into cards
  5. [x] Add an app version label at the bottom
- [x] **Onboarding flow redesign** — current `AppSetupView` gets users into the app but likely doesn't sell the value. New flow:
  1. Hero screen: "Track every vitamin, mineral, and amino acid. Offline."
  2. Goal setting: what are you tracking for? (general health / specific deficiency / diet protocol)
  3. Profile setup (age, gender, weight → RDI, BMI calculation. Height -> useful for anything?)
  4. Notification permission
  5. Paywall (contextual, after they understand the value)
  6. Discount for quick subscribers (current subscription is advertised as a discount, available for the first 24 hours, countdown on dashboard, afterwards only the "full-priced" subscription is avaialable)
- [x] **Nutrition Tab Customization & Charts**
  1. [x] Ability to select and order which nutrients are on the nutrition tab (per nutrient on/off toggle, order within nutrient group)
  2. [x] Use Swift Charts for nutrient intake charts instead of my own
  3. [x] Add trend charts, and nutrient trend charts, to calories, macros, water (like other nutrients have, navigated to by clicking their tile)
  4. [x] Move nutrition goals from profile to nutrition tab settings (same button icon as body tab settings)
- [x] **Analytics:** Track onboarding funnel (step completion rate, drop-off point), time-to-first-log, and day-1/day-7/day-30 retention cohorts
- [x] **Export (CSV)** as a premium feature — export all logged foods with nutrient data for a date range. Useful for users tracking for medical or clinical reasons (a natural Nutrient Logger audience).
- [x] **Nutrient deficiency insights** — a simple weekly digest view: "You've been consistently low in Vitamin D and Magnesium this week. Here are foods that would help." This is premium-only and differentiates from every macro-focused competitor.
- [x] Address the `//TODO: Days with foods hang for a second while loading` in `DashboardView.swift`
- [x] **Misc**
  1. [x] Calorie goal ring on nutrition tab
  2. [x] Food search bar not immediately in view
  3. [x] Crash when searching "Five guys"
  4. [x] Match styling across app (text fields are sometimes black or blue, other inconsistencies?. Generally, interactive elements should be .accentColor, non-interactive text should be .black.) — colored the black-text editable TextFields to `.accentColor` (EditProfileView height, BodyMetricCustomizeSheet goals, NutritionSettingsSheet, WeightEntrySheet, ConsumedWaterView custom amount, EditMealView name); dropped EditMealView's stray `.roundedBorder` style; replaced BodyMetricCustomizeSheet's hardcoded `Color.black` (broke dark mode) with default `.primary`; replaced hardcoded `.blue` with semantic `.accentColor` in FoodSearchView and MarketingView
  5. [x] Fix food log field tapping area (way to small especially portion amount "1")
  6. [x] Search as you type
  7. [x] Check places where we show the marketing view. Do they properly block the premium feature (audited all `MarketingView` presentation sites — all gate correctly; removed dead `showMarketingView`/`fullScreenCover` code in `NutrientTrendView` that never fired since its only caller already blocks free users)
  8. [x] Dismiss keyboard on scroll in BodyMetricCustomizeSheet, NutritionSettingsSheet
  9. [x] Micronutrient goals button doesn't navigate
  10. [x] Profile image should be primary color so that it is black in light mode and white in dark mode
  11. [x] Have onboarding match light or dark mode instead of being dark all the time
  12. [x] Onboarding weight entry - dismiss keyboard on scroll
  13. [x] Onboarding paywall - add discount percentage off
  14. [x] ConsumedNutrientDetailView chart - Only show upper limit if the intake is close to or above the upper limit.
  15. [x] NutrientTrendView - Add upper limit to trend chart. Only show upper limit if the intake is close to or above the upper limit.
  16. [x] Log Food Screen - Put date, meal time, portion, portion amount in a card together like other screens with grouped fields

### App Store Connect
- [x] Consider adding a **third subscription tier**: an annual "Family" or one-time lifetime purchase if StoreKit 2 supports it — v4.0 is a natural moment to introduce this
- [x] Prepare **promotional pricing** for launch week (introductory offer on yearly plan)

### Store Listing
- [x] **Full screenshot refresh** — all new screens focusing on user outcomes (What's the best background color for this kind of app to catch the customer's eye while they are searching on the app store)
- [x] Update **app description** completely — the v4.0 feature set is now materially different from what shipped in v3.x
- [x] Write a **launch blog post or Reddit post** in r/nutrition, r/carnivore, r/keto explaining the v4.0 story — what changed and why. Indie dev narrative resonates in those communities.

---

## Backlog (v4.x and beyond)

These are worth tracking but don't have a clear version slot yet:

- **Analytics:** Build the onboarding funnel tracking on Google Analytics
- **Food database coverage** — evaluate supplementing or replacing the underlying food database to close common-food gaps surfaced in reviews (beyond the search-ranking fix in v3.9). Separate problem from matching/ranking: this is about what's *in* the database, not how it's found.
- **AI photo logging** — the market is moving here fast (PlateLens, Nutrola). Expensive to build well; consider a third-party API (LogMeal, Calorie Mama) rather than training your own model.
- **Carnivore/keto mode** — preset nutrient goals for specific diet protocols. Natural cross-sell with Carnivore Diet Guide & Recipes.
- **Meal planning** — suggest meals based on nutrient gaps. High development cost but high premium value.
- **Android** — only relevant if subscriber base grows to justify the port.
- **Nutrition AI Analysis** - Use AI to analyze average nutrition and give feedback on how it might affect their health
- **Small Nutrient Group Analysis** - For example, analyze electrolyte intake and warn if out-of-balance/too low/etc.
- **iPad app — new platform target, not an optimization.** The main app is currently `TARGETED_DEVICE_FAMILY = 1` (iPhone-only); it doesn't run on iPad at all today. v4.0 is the right time to introduce it properly:
  - Enable iPad in the device family / App ID capabilities
  - Build a proper iPad layout (e.g. `NavigationSplitView` / sidebar) rather than scaling the iPhone UI
  - Test all major flows (dashboard, search, logging, charts, settings) at iPad sizes
  - You have iPad users from the Advanced 1st Aid HD days; this is a genuine new-platform launch that can recapture them
- **Custom search bar** - Could it provide better UI/UX? Should it be put directly on the root view of the nutrition tab?
- **App Preview video** (30-second screen recording) — barcode scan → dashboard with nutrient breakdown is a compelling 30 seconds
- **Localization** — your EU install data (Germany #1, Netherlands, Sweden, Ireland) suggests German and Swedish localizations could meaningfully increase conversion in those markets. v4.0 is the right moment to invest.

---

## ROI Summary

| Version | Est. Effort | Primary Revenue Impact |
|---------|-------------|------------------------|
| v3.6 | ~1 week | Immediate — price increase 5x on yearly plan |
| v3.7 | ~2 weeks | DAU increase → more trial starts |
| v3.8 | ~2–3 weeks | Defuses majority of 1-star reviews (custom food entry) → rating recovery + conversion |
| v3.9 | ~2 weeks | Logging retention (goal-setting) + search quality; groundwork for v3.11 |
| v3.10 | ~2 weeks | Install increase (new keyword surface) + logging retention |
| v3.11 | ~3 weeks | Subscription conversion (concrete premium features) |
| v4.0 | ~4–6 weeks | Lapsed user reactivation + press/feature opportunity |
