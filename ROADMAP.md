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

## v3.9 — "Set Your Targets" *(~2 weeks)*
**Theme:** Calorie/macro goal setting, plus a food-search quality pass. Goal-setting is prerequisite groundwork for v3.11's trend charts; search-matching fixes were called out repeatedly in review feedback and are a quick, contained win while `FoodSearchView` is already in scope.

### Code
- [ ] **Improve food search matching** — reduce false-positive matches surfaced in reviews (e.g. searching "peas" returning peaches/pears) and improve discoverability for items that currently require unintuitive search terms (e.g. cinnamon only found via "spice, cinnamon")
- [ ] **Calorie/macro goal setting** — confirmed missing (see `UserProfileView.swift` TODO at line 42; `User` model has no goal fields). Scope as its own feature, not a quick audit:
  - Add persisted goal fields to the `User` model (daily calorie target, optional macro targets)
  - Add UI in `UserProfileView` to set/edit goals, with sensible RDI-derived defaults
  - Update dashboard comparisons to use custom goals when set, falling back to RDI/USDA values otherwise
  - This is prerequisite groundwork for v3.11 trend charts (need a target line to plot against)
  - Add unit tests for goal precedence logic (custom goal vs. RDI fallback) and any date-boundary handling

### App Store Connect
- [ ] No product changes needed

### Store Listing
- [ ] Update **What's New**: "Set your own calorie and macro goals — see how today compares"
- [ ] Update description to mention custom goal setting

---

## v3.10 — "Scan" *(~2 weeks)*
**Theme:** Barcode scanner, on its own. Removes the biggest remaining logging friction for packaged foods, and pairs naturally with v3.8's custom-food entry as the fallback for anything a scan doesn't find. This is a marquee feature that will show up in reviews and word-of-mouth.

### Code
- [ ] Implement **barcode scanner** using `AVFoundation` (no third-party SDK needed)
- [ ] Look up scanned UPC/EAN against a barcode-to-FDC mapping. Options:
  - Open Food Facts API (free, large, open source) — best starting point
  - USDA FDC branded foods database (already partially in `fdc_legacy.db` — check coverage)
- [ ] Add camera permission usage description to `Info.plist`
- [ ] Add barcode scan button to `FoodSearchView` toolbar (next to the search field)
- [ ] Handle "not found" gracefully — fall back to manual search, and from there to the v3.8 custom-food-entry flow as the ultimate fallback

### App Store Connect
- [ ] Add camera permission justification (required for App Review)

### Store Listing
- [ ] New **feature screenshot**: barcode scanner in action
- [ ] Add "Scan barcodes" to feature list in description
- [ ] Update **What's New**: "New: Scan any barcode to instantly log packaged foods"
- [ ] Consider **A/B test** on first screenshot (current vs. barcode scan as hero image) — this is now a visual hook that competing apps lead with

---

## v3.11 — "Premium Depth" *(~3 weeks)*
**Theme:** Give subscribers concrete reasons they can't get elsewhere. Creates tangible value separation between free and premium tiers.

### Code
- [ ] **7-day and 30-day nutrient trend charts** (premium only)
  - Aggregate `ConsumedFood` history by day for any selected nutrient
  - Reuse/extend `ConsumedNutrientChart.swift` which already exists
  - Show vs. RDI target line
  - Gate behind `subscriptionManager.isSubscribed`
- [ ] **Apple Health integration**
  - Write consumed calories, protein, fat, carbs, water to `HKHealthStore`
  - Request read permission for weight (to populate user profile automatically)
  - Add toggle in `UserProfileView` to enable/disable sync
- [ ] **Weight tracking**
  - `WeightUnit.swift` already exists in Domain — build the UI on top of it
  - Simple log view: date + weight entry, chart over time
  - Sync weight entries to Apple Health if integration is enabled
- [ ] Update paywall copy to list the three new premium features specifically

### App Store Connect
- [ ] No subscription product changes needed
- [ ] Ensure HealthKit capability is added in the App ID (entitlements)

### Store Listing
- [ ] New screenshots showing trend charts and weight tracking
- [ ] Update description premium features section
- [ ] **What's New**: "Premium: nutrient trend charts, weight tracking, and Apple Health sync"
- [ ] Submit for **App Store feature consideration** (apple.com/search) — HealthKit integration makes this more likely to be featured in Health & Fitness

---

## v4.0 — "New Chapter" *(~4–6 weeks)*
**Theme:** Major milestone release. Justifies a full store listing refresh, potential press mention, and a reason for lapsed users to return. Version 4.0 signals maturity and intentional investment.

### Code
- [ ] **Onboarding flow redesign** — current `AppSetupView` gets users into the app but likely doesn't sell the value. New flow:
  1. Hero screen: "Track every vitamin, mineral, and amino acid. Offline."
  2. Goal setting: what are you tracking for? (general health / specific deficiency / diet protocol)
  3. Profile setup (age, gender → RDI calculation)
  4. Notification permission
  5. Paywall (contextual, after they understand the value)
- [ ] **iPad app — new platform target, not an optimization.** The main app is currently `TARGETED_DEVICE_FAMILY = 1` (iPhone-only); it doesn't run on iPad at all today. v4.0 is the right time to introduce it properly:
  - Enable iPad in the device family / App ID capabilities
  - Build a proper iPad layout (e.g. `NavigationSplitView` / sidebar) rather than scaling the iPhone UI
  - Test all major flows (dashboard, search, logging, charts, settings) at iPad sizes
  - You have iPad users from the Advanced 1st Aid HD days; this is a genuine new-platform launch that can recapture them
- [ ] **Export (CSV)** as a premium feature — export all logged foods with nutrient data for a date range. Useful for users tracking for medical or clinical reasons (a natural Nutrient Logger audience).
- [ ] **Nutrient deficiency insights** — a simple weekly digest view: "You've been consistently low in Vitamin D and Magnesium this week. Here are foods that would help." This is premium-only and differentiates from every macro-focused competitor.
- [ ] Address the `//TODO: Days with foods hang for a second while loading` in `DashboardView.swift`

### App Store Connect
- [ ] Consider adding a **third subscription tier**: an annual "Family" or one-time lifetime purchase if StoreKit 2 supports it — v4.0 is a natural moment to introduce this
- [ ] Prepare **promotional pricing** for launch week (introductory offer on yearly plan)

### Store Listing
- [ ] **Full screenshot refresh** — all new screens reflecting the redesigned onboarding and v4.0 UI
- [ ] **App Preview video** (30-second screen recording) — barcode scan → dashboard with nutrient breakdown is a compelling 30 seconds
- [ ] Update **app description** completely — the v4.0 feature set is now materially different from what shipped in v3.x
- [ ] **Localization** — your EU install data (Germany #1, Netherlands, Sweden, Ireland) suggests German and Swedish localizations could meaningfully increase conversion in those markets. v4.0 is the right moment to invest.
- [ ] Write a **launch blog post or Reddit post** in r/nutrition, r/carnivore, r/keto explaining the v4.0 story — what changed and why. Indie dev narrative resonates in those communities.

---

## Backlog (v4.x and beyond)

These are worth tracking but don't have a clear version slot yet:

- **Food database coverage** — evaluate supplementing or replacing the underlying food database to close common-food gaps surfaced in reviews (beyond the search-ranking fix in v3.9). Separate problem from matching/ranking: this is about what's *in* the database, not how it's found.
- **AI photo logging** — the market is moving here fast (PlateLens, Nutrola). Expensive to build well; consider a third-party API (LogMeal, Calorie Mama) rather than training your own model.
- **Carnivore/keto mode** — preset nutrient goals for specific diet protocols. Natural cross-sell with Carnivore Diet Guide & Recipes.
- **Meal planning** — suggest meals based on nutrient gaps. High development cost but high premium value.
- **Android** — only relevant if subscriber base grows to justify the port.

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
