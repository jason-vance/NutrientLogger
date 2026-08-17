---
title: "There Is No Average Diet. Every Tracker Is Built for One Anyway."
description: "Nutrient gaps aren't random - they're diet-shaped, and they're predictable enough to name in advance. So why does every app show everyone the same dashboard in the same order?"
date: 2026-08-17
author: Jason Vance
tags: [micronutrients, diet, nutrition-science, app]
---

Last week's post ended on a loose thread I've been pulling at ever since. RDAs already have an absorption assumption baked into them, drawn from population studies of people eating ordinary mixed diets. The number isn't naive. It's just an *average* assumption, and the further your eating pattern sits from that average, the less it fits you.

Here's the thing about that average diet: essentially nobody eats it. And the ways people depart from it aren't random noise. They're structured, they repeat, and after enough time looking at nutrient data you can name a person's likely gaps from their diet label alone with uncomfortable accuracy.

Which raises a question I couldn't get past: if the gaps are that predictable, why does every tracker on the App Store show everyone the same nutrients in the same order?

## The gaps run in packs

Cut a food group out of your diet and you don't lose one nutrient. You lose the cluster that food group was carrying, all at once, and you keep everything else the diet is good at. The result is that each way of eating has a characteristic shape - a short list of things that get hard, sitting right next to a long list of things that get easier.

**Plant-based.** B12 isn't low, it's absent - there is no meaningful plant source, and fortification or a supplement is the entire answer. Iron and zinc are there in quantity but arrive in the forms that absorb worst, which is exactly why the Institute of Medicine puts the vegetarian iron requirement at about 1.8 times the standard RDA. Calcium looks fine on paper and often isn't, if the sources are high-oxalate greens. And the omega-3 story is a conversion problem: ALA from flax and walnuts is plentiful, but the body converts it to EPA and especially DHA at rates low enough that the intake number badly overstates what you end up with.

**Keto and low-carb.** The famous one is electrolytes, and the mechanism is real rather than folklore. Lower insulin means the kidneys excrete more sodium, potassium follows, and magnesium was marginal in most diets to begin with. That's most of what people call keto flu. The less-discussed half is what leaves with the carbohydrates: fruit, legumes, and starchy vegetables were carrying a lot of the vitamin C and folate, and cutting them doesn't announce itself the way a headache does.

**Carnivore.** I wrote a whole post on this in July, so briefly: extraordinary on B12, zinc, iron, and B vitamins, genuinely thin on vitamin C, folate, and manganese, with calcium depending entirely on whether dairy or bone is in the picture. Whole-animal carnivore closes most of it. Ribeye-and-ground-beef carnivore does not.

**Pescatarian.** Probably the best omega-3 position of any of these, and then the same iron and zinc problem as plant-based, for the same reason - the heme sources went out with the red meat. Vitamin D depends heavily on whether the fish is fatty or lean.

None of these are indictments. Every one of these diets is doing something well, and in several cases doing it better than the mixed-diet average the RDA was built on. The point is narrower: the shortlist exists, it's different per diet, and it's knowable before you log a single meal.

## What the default order is actually doing

Open a nutrition app and the micronutrients come at you in an order somebody chose once. Usually it's the canonical order from the reference tables - vitamins A, C, D, E, K, then the B complex, then minerals roughly by how famous they are. It's a perfectly reasonable default. It's also completely indifferent to you.

That indifference has a cost, and it's not aesthetic. Screens are short. Most apps, mine included, show the first handful of nutrients per group and tuck the rest behind a "More" button, because a wall of forty rows helps nobody. So the ordering decides what you see, and everything downstream of that button is functionally invisible.

Play it out. A plant-based eater opens the app, and the vitamins section leads with A and C - two nutrients their diet is swimming in, both reading a comfortable 140%. B12, the one nutrient that can genuinely go to zero on their diet and cause irreversible nerve damage before it causes anything noticeable, is below the fold. Manganese, for the carnivore eater, is nowhere near the top of any list on any app I've used.

The app was showing them the right data the whole time. It just put it in the wrong order, and the wrong order is close enough to not showing it.

## So the app asks now

In the current version, onboarding asks two questions before it asks anything else: how you eat, and what you're mainly focused on. Two menus, two taps, both defaulting to a neutral option if you'd rather not say.

What happens next is the part I want to be precise about, because it would be easy to oversell. It changes the *order*, and nothing else. Your promoted nutrients get pulled to the top of their sections, and the number of visible rows in each affected group goes up so that none of them land under "More." Every other nutrient is still tracked, still charted, still one tap away. No goals move. No RDA changes. The math underneath is identical for everyone.

The focus question layers on the same way. Pick Energy and iron, B12, and magnesium come up. Immunity brings vitamin C, D, and zinc. Bone and joint brings calcium, D, and K. It unions with your diet answer rather than overriding it - a plant-based eater focused on energy gets both lists, deduplicated.

There's one design rule I wrote down early and have had to defend to myself a few times since: **promote the gaps, not the strengths.** It is tempting to show a new user their diet's best nutrients, because a screen of full green bars feels like a good first impression. It's the wrong instinct. If you're carnivore, your vitamin C bar is probably going to sit near zero, and that near-zero bar is the single most useful thing the app can show you on day one. A dashboard that flatters you is a dashboard you have no reason to keep opening.

The same logic drove the other new onboarding screen: a sample day, seeded with food that actually matches your answer - steak and eggs for carnivore, tofu and lentils and oats for plant-based, salmon and avocado for keto - so you can see what your dashboard is going to look like before you've logged anything. Including the parts of it that look bad.

## Where a diet label falls short

A five-option menu is a crude instrument, and I want to be honest about the ways it's crude.

It describes a category, not you. Two people who both tap "plant-based" can be eating diets with almost nothing in common - one on fortified foods and a B12 supplement with a well-managed profile, one on rice and peanut butter. The shortlist is a hypothesis about where to look first. Your actual logged data is the evidence, and when the two disagree, the data wins.

It also can't see supplements, which is where most real-world correction actually happens, and it can't see absorption, which was last week's entire subject. A promoted nutrient reading 100% on a diet full of inhibitors is worth more suspicion than the same bar on a mixed diet. Ordering doesn't fix that. Nothing an app can do fixes that.

And the label is a starting point that should stop mattering. If you've already arranged your Nutrition tab by hand, personalization won't touch those groups - it fills in around what you chose and leaves your arrangement alone, because a preset guessing at your priorities should never outrank you stating them. If you've been using the app for two years and never saw an onboarding question, it's in Nutrition Settings under Personalize, alongside a per-group control for how many rows you want visible.

## The smaller point underneath

Every tracker makes a claim about what matters just by deciding what to draw first, and most of them make that claim without noticing they've made it. The canonical ordering isn't neutral - it's a default that fits the average eater, and the average eater is a statistical artifact rather than a person.

Two taps is not a lot of personalization. It's not a nutrition plan, and it isn't advice. It's just the app admitting it doesn't know who you are yet, and asking, instead of assuming.

---

*[Nutrient Logger](https://apps.apple.com/app/nutrient-logger-food-tracker/id1536557332) tracks 80+ nutrients completely offline - no account, no cloud, no ads.*
