---
title: "Some Nutrients Only Make Sense in Pairs. Trackers Draw Them Alone."
description: "A dashboard of independent bars quietly claims that every nutrient acts on its own. For several of them that's false - the useful number is the proportion between two nutrients, not either one by itself."
date: 2026-08-31
author: Jason Vance
tags: [micronutrients, nutrition-science, tracking, app]
---

The last four posts have all been arguments about a bar. That a bar implies a target when most nutrients have a range. That the bar measures intake and your body settles on a different number. That the order of the bars is a claim about you. That the number filling the bar is sometimes an estimate wearing a lab coat.

Every one of those was about a single bar being wrong in some way. This one is about something the dashboard never draws at all: the space between two of them.

## The claim nobody makes out loud

Open any tracker, including mine, and the nutrient section is a stack of independent rows. Sodium has a bar. Potassium has a bar. Zinc has a bar, copper has a bar. Each one is computed on its own, colored on its own, and judged against its own number.

That layout is making a claim, and it's the same kind of silent claim as the ordering was: **these nutrients act independently.** Fill each one and you're done, in any combination.

For most of the list that's a perfectly good approximation. Your vitamin K intake genuinely does not care what your thiamine intake was. But for a handful of pairs it's flatly wrong, and it's wrong in the direction that matters - the two nutrients compete for the same transporter, or push the same physiological lever in opposite directions, and the number that predicts anything is the proportion between them.

You can have both bars land in the green and still be sitting in the bad part of that relationship. The dashboard has no way to tell you, because the dashboard has no concept of "between."

## The pair that makes the case

Sodium is the cleanest example, and it's clean partly because sodium is the nutrient where mainstream advice has been loudest and least effective.

Sodium and potassium both act on blood pressure regulation, in opposing directions, through overlapping mechanisms in the kidney. Which is why sodium intake on its own turns out to be a mediocre predictor of blood pressure across populations, and why the sodium-to-potassium ratio consistently does better. Two people eating identical sodium can sit in very different places depending on whether the rest of the day contained potassium.

And the modern failure mode isn't symmetrical. Processed food is engineered to be sodium-dense, and the potassium-rich end of the diet - fruit, tubers, dairy, leafy things, actual meat rather than meat products - is the part that gets displaced. So the typical Western ratio doesn't drift high because people are salting their eggs. It drifts high because the denominator collapsed.

That distinction is invisible on a stack of bars. "Sodium 140%" reads as an instruction to use less salt. "Sodium : Potassium at 2.3 : 1" reads as a different instruction entirely, and usually a more accurate one: eat something that grew.

Zinc and copper is the other pair I'd call solidly evidenced, and it's the one that catches supplement users. They compete for absorption directly - zinc induces a protein in the intestinal wall that binds copper and carries it back out - so sustained high-dose zinc can produce a genuine copper deficiency in someone whose copper intake never changed. Food-based intakes tend to land somewhere around 8 to 12 : 1 and cause nobody any trouble. A 50 mg zinc lozenge habit is what moves you somewhere else. Copper's own bar can look completely fine the entire time.

## The pairs I'm less sure about

I'd rather name the confidence gradient than pretend the whole idea is equally solid, because it isn't.

Omega-6 to omega-3 is genuinely interesting and genuinely contested. The mechanism is real - the two families compete for the same desaturase enzymes, so a flood of linoleic acid does reduce conversion of ALA into EPA and DHA. What's disputed is how much the *ratio* matters compared with simply getting enough EPA and DHA outright, and there's a reasonable argument that the ratio framing is a distraction from that simpler answer. I ship it anyway, flagged above 4 : 1, because for anyone eating a lot of seed oil it's a fair summary of a real pattern. I don't think it's as load-bearing as sodium and potassium.

Calcium to phosphorus is mostly a marker for how processed the diet is - phosphate additives and soda push phosphorus up - and the bone-health evidence is more suggestive than conclusive. Calcium to magnesium is softer still. The app says so in the explanation text rather than presenting all five as equally settled, which felt like the minimum honest thing to do given the last four posts were largely about false confidence.

## Why a ratio survives problems that a single number doesn't

Here's the part I didn't expect when I started building this, and it's the reason the feature is worth more than the sum of its five pairs.

Every objection from the previous four posts hits a lone nutrient bar harder than it hits a ratio.

Measurement error partly cancels. If the database undercounts a food's mineral content because the assay is old or the sample was small, it tends to be wrong about that food's sodium and potassium in a correlated way. Divide one by the other and some of that error divides out. Not all of it. But a ratio built from two numbers drawn from the same source, the same day, and the same person is a more stable quantity than either number alone.

Absorption competition stops being a confounder and becomes the actual subject. Two posts ago the whole problem was that intake isn't uptake, and one of the largest reasons for that is nutrients interfering with each other's absorption. When you measure zinc against copper, that interference is no longer noise contaminating your reading. It *is* the reading.

And the reference values sidestep the average-diet problem. An RDA is a population-level number with an absorption assumption baked in that may not describe you. "Keep sodium at or below potassium" doesn't depend on that assumption in the same way, because both sides shift together with whatever your body actually does.

None of that makes ratios magic. It makes them a different, and in several cases sturdier, way to read the same food log.

## What it looks like in the app

Nutrient Balances ships as part of the "This Week" card - the same card that already shows what's running low and what crossed an upper limit, because all three answer the same question about the same window of days.

A balance only appears when it's actually out of range. In range, it stays quiet. Tap one and you get the measured ratio, the target range, a plain-language explanation of why the pair matters, and the foods driving each side over the window, ranked by how much they contributed. That last part came from using it myself and finding that "Sodium : Potassium 2.3 : 1" is a diagnosis without a treatment. Seeing that one lunch accounts for 60% of the sodium side is a treatment.

Two design choices worth naming:

**It refuses to print a ratio it can't form.** If either side has no logged intake, no balance appears - no "0 : 1", no infinity, nothing. Last week's post ended on the line that an app telling you it doesn't know something is more useful than one quietly reporting zero, and the same rule applies here with more force, because a ratio with a broken denominator isn't just uninformative, it's actively alarming.

**The five built-ins are defaults, not doctrine.** You can turn any of them off, and you can define your own between any two nutrients with your own bounds. If you think the omega ratio is overrated, remove it. The window is adjustable too, from a single day out to thirty; seven is the default for the reason that keeps coming up.

## Where this can mislead you

The failure mode is important enough to state plainly: **a ratio can look excellent while both numbers are terrible.**

500 mg of sodium against 600 mg of potassium is a beautiful 0.83 : 1, and it's also a day where you barely ate. The proportion is right and the amounts are inadequate. This is exactly why balances are an addition to the nutrient bars and never a replacement for them - the bars answer "enough?", the balances answer "in proportion?", and you need both questions answered before either answer means much.

Two more limits. Supplements are invisible unless you log them, and supplements are the single most common cause of a genuinely dangerous zinc-to-copper ratio. And a missing-data day can distort a ratio the same way it distorts a total, which is another argument for the week over the day.

I'd also gently warn against optimizing the number for its own sake. These are indicators of dietary pattern, not scores. Chasing a 4 : 1 omega ratio by eating flaxseed while the underlying diet stays the same is the kind of technically-successful move that misses the entire point.

## The smaller point underneath

Five posts in, the pattern I keep landing on is that a nutrition dashboard is a stack of design decisions that look like neutral reporting. A bar shape decides that more is better. An ordering decides what matters. Two decimal places decide how much you should trust the source. And a grid of separate rows decides that nutrients act alone.

That last one is the easiest to miss because it isn't drawn - it's the assumption in the whitespace. For most of the list it's harmless. For a few pairs it's the whole story, and the app that only draws bars will never be able to tell you which few.

---

*[Nutrient Logger](https://apps.apple.com/app/nutrient-logger-food-tracker/id1536557332) tracks 80+ nutrients completely offline - no account, no cloud, no ads.*
