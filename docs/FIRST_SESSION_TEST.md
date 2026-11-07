# First-Session Test

Part of weeks 1–3 of the 90-day plan: find out how long it takes a brand-new user to log a full day of food, and where they get stuck.

## Setup

- Delete the app, then install a fresh build (TestFlight or Xcode). Onboarding only runs on a clean install.
- Have a stopwatch ready, or screen-record with the mic on and time it afterward.
- Testing someone else? Hand them the phone and say only: *"Log everything you ate yesterday."* Don't help. Write down every time they hesitate, back out of a screen, or ask a question.

## The day to log

Use a real day if you can. If not, use this one. It mixes easy foods, a typo, a quantity, a branded item and a homemade dish:

| Meal | Type exactly this |
| --- | --- |
| Breakfast | `2 eggs`, `toast`, `cofee` (typo on purpose) |
| Lunch | `chiken breast`, `brown rice`, `brocoli` |
| Snack | `greek yogurt`, `blueberies` |
| Dinner | `ribeye`, `sweet potato`, then something homemade that won't be in the database (e.g. `grandma's chili`) |
| Drinks | `diet coke`, `latte` |

## What to record

| Step | Time (mm:ss) | Notes |
| --- | --- | --- |
| App open → onboarding finished | 0:50| |
| Onboarding finished → first food logged | 0:40| I knew exactly where to go. Not sure if a brand new user would find it as fast as I can.|
| First food → whole day logged | 3:00| I made a few mistakes and had to go back to the dashboard to correct it, like logging a food in the wrong meal. I also had the thought that maybe I was making more mistakes and couldn't check it easily. I'm wondering if a record of your food logging session would be useful. Like a shopping cart, but for foods logged this time during the search screen being open. And it could be used to make sure you logged all the foods you meant to and/or quickly fix mistakes in a just-logged-food|
| **Total: open → full day logged** | 4:30| |

For every food, also note:

- Was the right food in the **top 3 results**?
	The one that stuck out was "toast" which brought up a bunch french toast options.
- How many taps from tapping search to the food being saved?
	I count 11, excluding typing. Tap search, Tap search bar, Type food name, Tap food. Tap meal menu, Tap meal in menu, Tap portion menu, Tap portion in menu, Tap amount, Double tap amount to select all, Type number, tap checkmark.
- Anything that made you or them stop and think.
	Not really.

## What good looks like

- Whole day logged in **under 5 minutes**, without help.
	Yea
- The right food in the top 3 for every everyday item above.
	Yes
- The homemade dish entered and logged in **under 60 seconds** using *Not here? Add "…" manually*.
	Yes, although One might not necessarily know the nutrition facts off the top of their head.

## After the test

Write the three biggest sticking points at the bottom of this file. Those are next week's fixes.

The new analytics events show how real users behave once this ships:

- `search_corrected`: a typo or synonym was fixed for the user (includes the original and corrected query).
- `custom_food_entry_opened`: where manual entry was started from (`search_row`, `no_results` or `toolbar`).
- `search_no_results`: searches that still found nothing. These are the gaps in the food database.
- `first_day_recap_shown`: the user finished their first full day and saw their nutrient gaps.
- `first_day_recap_action`: what they did next (`trial_started`, `all_plans`, `not_now`, …). Shown vs. `trial_started` is the trial conversion at the payoff moment.
- `search_log_opened`: the user opened the list of foods logged during this search (`food_count`).
- `search_log_food_changed`: a food was fixed from that list (`edited` or `deleted`). Often = mistakes being caught before they reach the dashboard.
- `search_result_picked`: a USDA food was logged from search (`search_term`, `position` in the Foods list, `result_count`). Searches where people keep picking something far down show where ranking still needs work.

## Findings

1. The uncertainty of logging many foods without going back to the dashboard to check. "I just logged 10 foods. Did I include the banana I had for breakfast?"
2. Can we surface the most likely options as easily selectable pills (or stepper/slider for amount) when logging a food (date, meal, portion, amount)
3. 
