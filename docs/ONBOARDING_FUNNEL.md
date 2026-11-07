# Onboarding Funnel

How to see where new users drop off between the first screen and the paywall, in Google Analytics (GA4, fed by Firebase).

## Steps

| Index | `step_name` | Screen |
| --- | --- | --- |
| 0 | `hero` | Welcome |
| 1 | `personalization` | Diet and focus questions |
| 2 | `food_breakdown` | Tap a food (added Nov 7 2026) |
| 3 | `demo` | Sample day |
| 4 | `notification` | Reminder permission |
| 5 | `paywall` | Trial offer |

Before Nov 7 2026 there was no `food_breakdown` step, so `demo` was index 2 and every later step was one lower. Compare versions by `step_name`, not `step_index`.

## Events

- `onboarding_step_viewed` (`step_name`, `step_index`): a step came on screen.
- `onboarding_step_completed` (`step_name`, `step_index`, `seconds_on_step`): the user moved on from a step.
- `onboarding_step_back` (`step_name`, `step_index`): the user went back from this step.
- `onboarding_personalization_selected` (`diet`, `concern`)
- `onboarding_food_breakdown_viewed` (`diet`): each food tapped on the breakdown step. Which food isn't logged, since the privacy policy keeps food names out of analytics.
- `paywall_shown` and `paywall_dismissed` with `trigger` = `onboarding`. Before Nov 7 2026 the onboarding paywall logged `smart_paywall`, mixed in with the in-app one, and skipping it logged nothing.
- `onboarding_completed` (`total_seconds`, `diet`, `concern`, `subscribed` = 1 or 0)

User properties `diet` and `nutrition_focus` are set when the diet question is answered (and again from Nutrition Settings), so every later event, including trial starts and purchases, can be split by diet.

## One-time setup in Firebase / GA4

1. **Custom definitions** (GA4 Admin → Custom definitions):
    - Event-scoped dimensions: `step_name`, `trigger`, `diet`, `concern`
    - Event-scoped metrics: `seconds_on_step`, `total_seconds`
    - User-scoped dimensions: `diet`, `nutrition_focus`
    - Data only fills in from when a definition is created, so add these first.
2. **Funnel** (Explore → Funnel exploration), open funnel off:
    1. `onboarding_step_viewed` where `step_name` = `hero`
    2. ... `personalization`
    3. ... `food_breakdown`
    4. ... `demo`
    5. ... `notification`
    6. ... `paywall`
    7. `onboarding_completed`
    - Breakdown: app version, to compare 4.5 with earlier builds.
    - Add a segment on `onboarding_completed` with `subscribed` = 1 to see paywall conversion.
3. **Time per step**: a free-form exploration with rows `step_name` and the value average `seconds_on_step`, filtered to `onboarding_step_completed`.

## What to look for

- The biggest drop between two steps is the next thing to fix.
- `food_breakdown` → `demo` should be close to 100%. If not, the new step costs completions and should merge into the demo instead.
- A step with many `onboarding_step_back` events is confusing people.
