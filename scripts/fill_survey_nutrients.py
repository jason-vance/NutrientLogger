#!/usr/bin/env python3
"""Fill in nutrients the USDA survey foods (FNDDS 2017-2018) never report.

FNDDS leaves out pantothenic acid and manganese, so in the app every survey food reads 0 for
them. But USDA builds each survey food from SR Legacy ingredients with gram weights
(input_food.csv), and SR Legacy does report both nutrients. This adds them up per food and writes
the result into the bundled fdc_survey.db.

A plain sum of raw ingredients misses what cooking does: water loss concentrates everything, and
heat destroys some vitamins. Survey foods do report other nutrients that behave the same way, so
each food is calibrated against them:

- manganese uses the food's own survey/ingredient ratio for other minerals (Mg, Zn, Cu, P, K)
- pantothenic acid uses the ratio for other B vitamins (B6, niacin, riboflavin)

Run with --validate to measure the method on nutrients we can check (it predicts magnesium and
vitamin B6 the same way and compares with USDA's published survey values), then --write.

Usage:
    python3 scripts/fill_survey_nutrients.py FNDDS_CSV_DIR [--validate] [--write]

FNDDS_CSV_DIR is the unzipped
https://fdc.nal.usda.gov/fdc-datasets/FoodData_Central_survey_food_csv_2020-10-30.zip
"""

import csv
import os
import statistics
import sqlite3
import sys

RESOURCES = os.path.join(os.path.dirname(__file__), "..", "Nutrient Logger", "FdcDatabase", "Resources")
LEGACY_DB = os.path.join(RESOURCES, "fdc_legacy.db")
SURVEY_DB = os.path.join(RESOURCES, "fdc_survey.db")

PANTOTHENIC, MANGANESE = 1170, 1101
TARGETS = [PANTOTHENIC, MANGANESE]
MINERALS = [1090, 1095, 1098, 1091, 1092]  # Mg, Zn, Cu, P, K
B_VITAMINS = [1175, 1167, 1166]  # B6, niacin, riboflavin
ALL_IDS = TARGETS + MINERALS + B_VITAMINS

# Ingredients that report the nutrient must make up this much of the recipe's weight, or the food
# is left without a value rather than given a guess.
MIN_COVERAGE = 0.8
RATIO_RANGE = (0.2, 5.0)


def load_legacy(db):
    """SR Legacy values per 100 g, by NDB number (the sr_code used in input_food.csv)."""
    ndb_to_fdc = dict(db.execute("select NDB_number, fdc_id from LegacyFood"))
    marks = ",".join("?" * len(ALL_IDS))
    values = {}
    for fdc_id, nutrient_id, amount in db.execute(
        f"select fdc_id, nutrient_id, amount from Nutrient where nutrient_id in ({marks})", ALL_IDS
    ):
        values.setdefault(fdc_id, {})[nutrient_id] = float(amount)
    return {ndb: values.get(fdc, {}) for ndb, fdc in ndb_to_fdc.items()}


def load_survey(db):
    """Published survey values per 100 g, and food code -> fdc_id."""
    marks = ",".join("?" * len(ALL_IDS))
    values = {}
    for fdc_id, nutrient_id, amount in db.execute(
        f"select fdc_id, nutrient_id, amount from Nutrient where nutrient_id in ({marks})", ALL_IDS
    ):
        values.setdefault(fdc_id, {})[nutrient_id] = float(amount)
    code_to_fdc = dict(db.execute("select food_code, fdc_id from SurveyFnddsFood"))
    return values, code_to_fdc


def load_recipes(csv_dir):
    recipes = {}
    with open(os.path.join(csv_dir, "input_food.csv"), newline="") as f:
        for row in csv.DictReader(f):
            grams = float(row["gram_weight"] or 0)
            if grams > 0 and row["sr_code"]:
                recipes.setdefault(int(row["fdc_id"]), []).append((int(row["sr_code"]), grams))
    return recipes


class Builder:
    def __init__(self, legacy, survey, code_to_fdc, recipes):
        self.legacy, self.survey, self.code_to_fdc, self.recipes = legacy, survey, code_to_fdc, recipes
        self.memo = {}

    def ingredient_values(self, code):
        """Per-100 g values for one ingredient: an SR Legacy food, or another survey food."""
        if code in self.legacy:
            return self.legacy[code]
        fdc_id = self.code_to_fdc.get(code)
        if fdc_id is None:
            return {}
        # A survey food used as an ingredient: its published values, plus our filled-in targets.
        values = dict(self.survey.get(fdc_id, {}))
        values.update(self.filled(fdc_id))
        return values

    def raw_sum(self, fdc_id, nutrient_id):
        """Ingredient total per 100 g of recipe, and the share of recipe weight that reported it."""
        parts = self.recipes.get(fdc_id, [])
        total = sum(g for _, g in parts)
        if total <= 0:
            return None, 0.0
        amount, covered = 0.0, 0.0
        for code, grams in parts:
            value = self.ingredient_values(code).get(nutrient_id)
            if value is not None:
                amount += value * grams
                covered += grams
        return (amount / total if covered else None), covered / total

    def ratio(self, fdc_id, nutrient_ids):
        """Median of survey value / ingredient sum, over nutrients both sides report."""
        ratios = []
        for nid in nutrient_ids:
            published = self.survey.get(fdc_id, {}).get(nid)
            raw, coverage = self.raw_sum(fdc_id, nid)
            if published and raw and raw > 0 and coverage >= MIN_COVERAGE:
                ratios.append(published / raw)
        if not ratios:
            return None
        low, high = RATIO_RANGE
        return min(max(statistics.median(ratios), low), high)

    def estimate(self, fdc_id, nutrient_id, calibrators):
        raw, coverage = self.raw_sum(fdc_id, nutrient_id)
        if raw is None or coverage < MIN_COVERAGE:
            return None
        ratio = self.ratio(fdc_id, calibrators)
        if ratio is None:
            others = [n for n in MINERALS + B_VITAMINS if n != nutrient_id]
            ratio = self.ratio(fdc_id, others) or 1.0
        return raw * ratio

    def filled(self, fdc_id):
        if fdc_id in self.memo:
            return self.memo[fdc_id]
        self.memo[fdc_id] = {}  # guards against a recipe that includes itself
        result = {}
        for nutrient_id, calibrators in ((MANGANESE, MINERALS), (PANTOTHENIC, B_VITAMINS)):
            value = self.estimate(fdc_id, nutrient_id, calibrators)
            if value is not None:
                result[nutrient_id] = round(value, 3)
        self.memo[fdc_id] = result
        return result


def validate(builder, survey_ids):
    """Predict nutrients USDA does publish, the same way, and compare."""
    # (nutrient, calibrators without it, smallest published amount worth checking per 100 g)
    checks = {"magnesium": (1090, [1095, 1098, 1091, 1092], 2.0), "vitamin B6": (1175, [1167, 1166], 0.02)}
    for name, (nid, calibrators, floor) in checks.items():
        errors = []
        for fdc_id in survey_ids:
            published = builder.survey.get(fdc_id, {}).get(nid)
            predicted = builder.estimate(fdc_id, nid, calibrators)
            if published is None or predicted is None or published < floor:
                continue
            errors.append(abs(predicted - published) / published)
        errors.sort()
        within = lambda p: sum(e <= p for e in errors) / len(errors)
        print(f"{name}: {len(errors)} foods, median error {statistics.median(errors):.1%}, "
              f"within 10% {within(0.10):.0%}, within 25% {within(0.25):.0%}")


def main():
    args = sys.argv[1:]
    if not args:
        print(__doc__)
        sys.exit(1)
    csv_dir = args[0]
    legacy_db, survey_db = sqlite3.connect(LEGACY_DB), sqlite3.connect(SURVEY_DB)

    legacy = load_legacy(legacy_db)
    survey, code_to_fdc = load_survey(survey_db)
    builder = Builder(legacy, survey, code_to_fdc, load_recipes(csv_dir))
    survey_ids = [row[0] for row in survey_db.execute("select fdc_id from Food")]

    filled = {fdc_id: builder.filled(fdc_id) for fdc_id in survey_ids}
    for nid, name in ((MANGANESE, "manganese"), (PANTOTHENIC, "pantothenic acid")):
        count = sum(nid in values for values in filled.values())
        print(f"{name}: filled for {count} of {len(survey_ids)} survey foods")

    if "--validate" in args:
        validate(builder, survey_ids)

    if "--write" in args:
        existing = survey_db.execute(
            "select count(*) from Nutrient where nutrient_id in (?, ?)", TARGETS
        ).fetchone()[0]
        if existing:
            print(f"fdc_survey.db already has {existing} of these rows; delete them first to rebuild.")
            sys.exit(1)
        next_id = survey_db.execute("select max(id) from Nutrient").fetchone()[0] + 1
        rows = []
        for fdc_id, values in filled.items():
            for nid, amount in values.items():
                rows.append((next_id, fdc_id, nid, amount))
                next_id += 1
        survey_db.executemany("insert into Nutrient (id, fdc_id, nutrient_id, amount) values (?, ?, ?, ?)", rows)
        survey_db.commit()
        survey_db.execute("vacuum")
        print(f"wrote {len(rows)} rows to fdc_survey.db")


if __name__ == "__main__":
    main()
