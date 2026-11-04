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
| App open → onboarding finished | | |
| Onboarding finished → first food logged | | |
| First food → whole day logged | | |
| **Total: open → full day logged** | | |

For every food, also note:

- Was the right food in the **top 3 results**?
- How many taps from tapping search to the food being saved?
- Anything that made you or them stop and think.

## What good looks like

- Whole day logged in **under 5 minutes**, without help.
- The right food in the top 3 for every everyday item above.
- The homemade dish entered and logged in **under 60 seconds** using *Not here? Add "…" manually*.

## After the test

Write the three biggest sticking points at the bottom of this file. Those are next week's fixes.

The new analytics events show how real users behave once this ships:

- `search_corrected`: a typo or synonym was fixed for the user (includes the original and corrected query).
- `custom_food_entry_opened`: where manual entry was started from (`search_row`, `no_results` or `toolbar`).
- `search_no_results`: searches that still found nothing. These are the gaps in the food database.

## Findings

1.
2.
3.
