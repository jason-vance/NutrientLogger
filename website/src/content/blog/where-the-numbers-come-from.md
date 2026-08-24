---
title: "A Zero in Your Food Log Usually Means Nobody Measured"
description: "Nutrition apps print numbers to two decimal places. Underneath, those numbers are lab assays from 2018, modeled recipes, and label transcriptions - and the gaps between them look exactly like zeros."
date: 2026-08-24
author: Jason Vance
tags: [nutrition-science, tracking, data, app]
---

The last three posts have been a slow walk down the same hallway. First that a nutrient has a ceiling and not just a target. Then that the number on the screen is intake rather than uptake. Then that which numbers you see first should depend on how you eat.

All three quietly assumed the number itself is real. This week I want to pull that assumption out and look at it, because it's the shakiest one of the four.

Every nutrition app is a front end for a food database. Mine included. The interface is the part you argue about in reviews, but the database is the part that decides whether anything on the screen is true, and almost nobody talks about where those numbers actually come from.

## Three kinds of number, wearing the same font

Open a tracker, log three foods, and you'll get three numbers rendered identically - same typeface, same decimal places, same confident little row. They were produced in ways that have nothing in common.

**A lab assay.** Somebody bought raw spinach, homogenized it, and ran it through a mass spectrometer. In USDA's world this is mostly SR Legacy, the standard reference dataset, and it's the deepest micronutrient data that exists in public domain form - dozens of nutrients per food. It's also, as the name suggests, legacy. The last release was 2018, and it is no longer being updated. Its successor, Foundation Foods, is better in every way that matters - real provenance, sample counts, actual analytical methods disclosed - and it covers a small fraction of the foods. So the deep data is old, and the new data is thin. That's the tradeoff sitting under the entire field, not just under my app.

**A modeled recipe.** Log "beef stew" and there is no lab anywhere that assayed beef stew. What exists is FNDDS, the survey database built to code what people report eating in national health surveys. Its values are computed: take a recipe, take the ingredient values from the reference data, apply yield and retention factors for cooking losses, sum. That's a defensible way to produce a number, and it is not a measurement. It's a model, and models inherit every gap in the data they're built from.

**A label transcription.** Scan a barcode and you get whatever the manufacturer printed on the panel, which is governed by labeling rules rather than by curiosity. Two consequences fall straight out of those rules. First, rounding: under US labeling regulations, fat below half a gram per serving is declared as zero, and calories under five are declared as zero - which is exactly how a product can be "0 g trans fat" and still contain trans fat, and how a cooking spray becomes a zero-calorie food at a quarter-second spray. Second, and much bigger for a micronutrient tracker: the mandatory panel carries only vitamin D, calcium, iron, and potassium. Four micronutrients. Everything else is optional, and optional means absent.

So a scanned granola bar isn't low in magnesium. It's silent on magnesium. Those are completely different facts, and the screen has no way to tell them apart.

## Missing looks exactly like zero

This is the part I want to be blunt about, because it's a flaw in my own app and not only in other people's.

Nutrient Logger builds a food's profile from the nutrient rows that exist for it in the database. A row that isn't there contributes nothing to your daily total. It doesn't render as "unknown" or "not measured." It just doesn't add anything, and the day's total for that nutrient comes out lower - which on a dashboard reads as a gap in your diet rather than a gap in the data.

There's a second, smaller version of the same problem that I made deliberately. When a food's entry lists a nutrient at exactly zero, the app skips it rather than storing a zero row. For most foods that's correct and keeps the database small. But "measured, and there genuinely isn't any" and "nobody looked" end up in the same bucket, and that bucket is invisible.

The practical shape of this: the more of your day comes from scanned packaged products, the more your micronutrient totals under-report, and they under-report in a lopsided way. Your calcium and iron look fine, because those are on the mandatory panel. Your magnesium, vitamin K, selenium, and the entire B complex minus whatever got fortified drift toward zero, because nobody was ever required to measure them. A day of whole foods logged from the USDA data will show a fuller nutrient profile than a day of packaged food with identical actual nutrition. Not because it was more nourishing. Because it was better documented.

If you've ever seen your dashboard collapse on a travel week and wondered whether airport food is really *that* bad - some of that is real, and some of it is that airport food comes with barcodes.

## The same food isn't the same food

Set aside missing data and there's still the question of what a single number can mean for an entire food.

Take one hundred grams of raw spinach. The database gives you a value. That value is a central estimate drawn from some number of samples, and the real thing varies with cultivar, soil, season, how far it traveled, how long it sat in your fridge, and what you did to it. Selenium is the extreme case - it tracks the selenium content of the soil the plant grew in, which varies by orders of magnitude across regions, and no food database can know which field your lunch came from. Vitamin C is the fragile case: it degrades with time, heat, and light, so the gap between the database value and your actual serving grows every day the bag sits in the crisper. Grass-fed versus grain-fed beef differ measurably in fatty acid profile and some vitamins. None of this is exotic. It's just averaged away, because a single number is what a database row can hold.

Which means the two decimal places are theater. The app shows 1.34 mg because that's what floating-point arithmetic produces when you scale a portion, not because anyone can distinguish 1.34 from 1.28 in the food you actually ate.

## What I do about it, and what I can't

The honest inventory:

**What's fixed.** The data sources are named in the app, under Settings, with links - USDA FoodData Central for whole and survey foods, Open Food Facts for barcode products. You can go look at exactly what I'm drawing from. It ships bundled and offline, so the numbers don't silently change under you between releases.

**What isn't fixed yet.** The app doesn't distinguish "not measured" from "zero" in the interface, and it should. The right fix is visible provenance: mark a nutrient as unmeasured for a given food rather than folding it into the total, and show which of the three kinds of number you're looking at. It's on the list. It's a real amount of work, because it touches the database schema, the totals math, and every place a nutrient renders.

**What can't be fixed by any app.** Nobody assayed your specific spinach. There is no version of this software, or anyone else's, that knows the selenium content of the soil your lunch grew in. That's not a limitation of tracker design. It's a limitation of what a food database is.

## How to read a nutrition number without being fooled by it

Three things I'd actually tell someone.

Prefer whole-food entries when the choice exists. If you ate chicken and rice and broccoli, logging three whole foods gets you a far more complete micronutrient picture than logging one packaged frozen dinner, even when the dinner is the same food. That's a statement about data coverage, not about health.

Read low numbers as questions. A bar sitting near zero on a day dominated by scanned products is a prompt to check whether that nutrient was ever measured, not evidence of a deficiency. A bar sitting near zero across a week of varied whole foods is worth taking seriously.

Trust the trend over the day. This keeps being the answer, and it keeps being the answer for a different reason each time. Two posts ago it was absorption variability. Last post it was that a single day is a small sample of how you eat. This time it's measurement error, and measurement error is exactly the kind of noise that averages out over a week and dominates on any single day.

## The part that actually matters

I'm not arguing the numbers are useless. They're the best public nutrition data that exists, they're free, and directionally they're right about the things that matter most - which foods carry which nutrients, and where your diet is thin.

I'm arguing against the specific false confidence that a clean interface manufactures. A well-designed app makes a modeled recipe estimate built on a 2018 lab assay look exactly as authoritative as a scale reading. That polish is doing something dishonest, and the honest version isn't to hide the numbers - it's to show where they came from.

An app that tells you it doesn't know something is more useful than one that quietly reports zero.

---

*[Nutrient Logger](https://apps.apple.com/app/nutrient-logger-food-tracker/id1536557332) tracks 80+ nutrients completely offline - no account, no cloud, no ads.*
