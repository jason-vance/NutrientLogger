//
//  StaticNutrientExplanations.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 6/17/25.
//

import Foundation

class StaticNutrientExplanations {

    public static func explanation(for fdcNumber: String) -> NutrientExplanation? {
        return map[fdcNumber]
    }

    private static let map: [String: NutrientExplanation] = {
        var result = [String: NutrientExplanation]()

        func add(_ fdcNumber: String, _ sections: [NutrientExplanation.Section]) {
            let exp = NutrientExplanation("")
            exp.sections = sections
            result[fdcNumber] = exp
        }

        // MARK: - Ash
        add(FdcNutrientGroupMapper.NutrientNumber_Ash, [
            .init(
                header: "What is Ash?",
                text: "Ash isn't a nutrient you consume — it's a lab measurement. When food is burned completely in an analytical oven, the non-combustible minerals that remain are collectively called 'ash.' The value is a rough indicator of the food's total mineral content (calcium, potassium, sodium, and other minerals combined). It doesn't represent a single substance and has no recommended daily intake."
            )
        ])

        // MARK: - Sodium
        add(FdcNutrientGroupMapper.NutrientNumber_Sodium_Na, [
            .init(
                header: "What it is",
                text: "Sodium is a mineral your body needs to balance fluids, transmit nerve signals, and contract muscles. Most dietary sodium comes from salt (sodium chloride) and processed foods."
            ),
            .init(
                header: "Too little",
                text: "Low sodium (hyponatremia) is rare from diet alone and usually results from excessive water intake or certain medical conditions. Symptoms include nausea, headache, and confusion."
            ),
            .init(
                header: "Too much",
                text: "Most people consume far more sodium than they need. Chronically high intake raises blood pressure, increasing the risk of heart disease, stroke, and kidney disease. The recommended daily limit for most adults is 2,300 mg (about 1 teaspoon of salt)."
            )
        ])

        // MARK: - Alpha Carotene
        add(FdcNutrientGroupMapper.NutrientNumber_Carotene_Alpha, [
            .init(
                header: "What it is",
                text: "Alpha carotene is a carotenoid — a pigment that gives orange and yellow fruits and vegetables their color. Like beta carotene, your body can partially convert alpha carotene into vitamin A. It also acts as an antioxidant, protecting cells from damage. Good sources include carrots, pumpkin, and winter squash."
            ),
            .init(
                header: "Too little",
                text: "No official daily requirement has been established. Low intake is associated with diets low in colorful vegetables and fruits. Higher alpha carotene intake has been linked to lower risk of certain chronic diseases in observational studies."
            ),
            .init(
                header: "Too much",
                text: "Very high intake from food is not known to be harmful. Extremely high doses may cause carotenodermia — a harmless orange-yellow skin discoloration that reverses when intake is reduced. Alpha carotene converts to vitamin A less efficiently than beta carotene, so vitamin A toxicity from this source is very unlikely."
            )
        ])

        // MARK: - Lycopene
        add(FdcNutrientGroupMapper.NutrientNumber_Lycopene, [
            .init(
                header: "What it is",
                text: "Lycopene is a bright-red carotenoid found in tomatoes, watermelon, and pink grapefruit. It is a potent antioxidant that may help protect cells from oxidative stress. Unlike most carotenoids, your body cannot convert lycopene into vitamin A. Cooking tomatoes in oil significantly increases lycopene absorption."
            ),
            .init(
                header: "Too little",
                text: "No official recommended intake exists. Low lycopene levels have been associated with increased cardiovascular risk, and some studies link higher intake to lower prostate cancer risk — though the evidence is not definitive."
            ),
            .init(
                header: "Too much",
                text: "High intake from food is considered safe. Extremely high consumption can cause lycopenodermia, an orange skin discoloration, which reverses when intake is reduced. No upper limit has been established by health authorities."
            )
        ])

        // MARK: - Lutein & Zeaxanthin
        add(FdcNutrientGroupMapper.NutrientNumber_Lutein_Zeaxanthin, [
            .init(
                header: "What it is",
                text: "Lutein and zeaxanthin are yellow carotenoids concentrated in the macula of the eye. They filter blue light and act as antioxidants, helping to protect the retina from damage. They are found in dark leafy greens (kale, spinach), egg yolks, and orange vegetables."
            ),
            .init(
                header: "Too little",
                text: "Low levels are associated with increased risk of age-related macular degeneration (AMD) and cataracts — two leading causes of vision loss. No official RDI exists, but research suggests 6–10 mg/day may benefit eye health."
            ),
            .init(
                header: "Too much",
                text: "High intake from food is generally safe. Very large amounts may cause skin to take on a yellowish tint (carotenodermia), which is harmless and reversible. No official upper limit has been established."
            )
        ])

        // MARK: - Betaine
        add(FdcNutrientGroupMapper.NutrientNumber_Betaine, [
            .init(
                header: "What it is",
                text: "Betaine (also called trimethylglycine, or TMG) is a compound found in beets, spinach, quinoa, and wheat germ. It plays a role in the metabolism of homocysteine — an amino acid associated with heart disease when elevated — and supports liver function. Betaine and choline are closely related; both help regulate homocysteine levels."
            ),
            .init(
                header: "Too little",
                text: "No established RDI exists. Low betaine intake is associated with elevated homocysteine levels. Since choline can be converted to betaine in the body, choline intake also influences betaine status."
            ),
            .init(
                header: "Too much",
                text: "Betaine from food is not considered harmful. High-dose supplements (above 4–6 g/day) may raise LDL cholesterol in some people. Dietary intake from normal food sources is not a concern."
            )
        ])

        // MARK: - Caffeine
        add(FdcNutrientGroupMapper.NutrientNumber_Caffeine, [
            .init(
                header: "What it is",
                text: "Caffeine is a natural stimulant found in coffee, tea, chocolate, and energy drinks. It works by blocking adenosine receptors in the brain, which reduces feelings of tiredness. It also stimulates the central nervous system, increasing alertness, focus, and heart rate."
            ),
            .init(
                header: "Too little",
                text: "Caffeine is not an essential nutrient, so there is no deficiency. However, habitual consumers who reduce or stop caffeine intake may experience withdrawal: headache, fatigue, irritability, and difficulty concentrating, typically lasting 2–9 days."
            ),
            .init(
                header: "Too much",
                text: "Up to 400 mg/day (roughly 4 cups of coffee) is generally considered safe for healthy adults. Exceeding this can cause anxiety, jitteriness, insomnia, rapid heart rate, and digestive issues. Pregnant women are advised to stay under 200 mg/day."
            )
        ])

        // MARK: - Theobromine
        add(FdcNutrientGroupMapper.NutrientNumber_Theobromine, [
            .init(
                header: "What it is",
                text: "Theobromine is a mild stimulant found primarily in cacao (chocolate), tea, and coffee. It is structurally similar to caffeine but acts more slowly and with less potency. Theobromine relaxes smooth muscle, has a mild bronchodilator effect, and acts as a mild diuretic."
            ),
            .init(
                header: "Too little",
                text: "Theobromine is not an essential nutrient, so there is no deficiency."
            ),
            .init(
                header: "Too much",
                text: "At very high doses, theobromine can cause nausea, headache, and heart palpitations, but normal food consumption does not pose this risk for humans. Note: theobromine is highly toxic to dogs and cats, which metabolize it far more slowly than humans do. No established upper limit exists for human dietary intake."
            )
        ])

        return result
    }()
}
