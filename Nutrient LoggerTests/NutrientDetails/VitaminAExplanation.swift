//
//  VitaminAExplanation.swift
//  Nutrient LoggerTests
//
//  Created by Jason Vance on 4/6/25.
//

import Foundation

public class VitaminAExplanation {
    public static var preMade: NutrientExplanation {
        let explanation = NutrientExplanation("https://ods.od.nih.gov/factsheets/VitaminA-Consumer/")

        explanation.sections.append(NutrientExplanation.Section(
            header: "What is vitamin A and what does it do?",
            text: "Vitamin A is a fat-soluble vitamin that is naturally present in many foods. Vitamin A is important for normal vision, the immune system, and reproduction. Vitamin A also helps the heart, lungs, kidneys, and other organs work properly.\n\nThere are two different types of vitamin A. The first type, preformed vitamin A, is found in meat, poultry, fish, and dairy products. The second type, provitamin A, is found in fruits, vegetables, and other plant-based products. The most common type of provitamin A in foods and dietary supplements is beta-carotene."
        ))
        explanation.sections.append(NutrientExplanation.Section(
            header: "How much vitamin A do I need?",
            text: "The amount of vitamin A you need depends on your age and sex. Average daily recommended amounts are listed below in micrograms (mcg) of retinol activity equivalents (RAE).",
            table: NutrientExplanation.Section.SectionTable(2, [
                "Life Stage", "Recommended Amount",
                "Birth to 6 months", "400 mcg RAE",
                "Infants 7-12 months", "500 mcg RAE",
                "Children 1-3 years", "300 mcg RAE",
                "Children 4-8 years", "400 mcg RAE",
                "Children 9-13 years", "600 mcg RAE",
                "Teen boys 14-18 years", "900 mcg RAE",
                "Teen girls 14-18 years", "700 mcg RAE",
                "Adult men", "900 mcg RAE",
                "Adult women", "700 mcg RAE",
                "Pregnant teens", "750 mcg RAE",
                "Pregnant women", "770 mcg RAE",
                "Breastfeeding teens", "1,200 mcg RAE",
                "Breastfeeding women", "1,300 mcg RAE"
            ])
        ))
        explanation.sections.append(NutrientExplanation.Section(
            header: "What foods provide vitamin A?",
            text: "Vitamin A is found naturally in many foods and is added to some foods, such as milk and cereal. You can get recommended amounts of vitamin A by eating a variety of foods, including the following:",
            list: NutrientExplanation.Section.BulletedList([
                "Beef liver and other organ meats (but these foods are also high in cholesterol, so limit the amount you eat).",
                "Some types of fish, such as salmon.",
                "Green leafy vegetables and other green, orange, and yellow vegetables, such as broccoli, carrots, and squash.",
                "Fruits, including cantaloupe, apricots, and mangos.",
                "Dairy products, which are among the major sources of vitamin A for Americans.",
                "Fortified breakfast cereals.",
            ])
        ))
        explanation.sections.append(NutrientExplanation.Section(
            header: "What kinds of vitamin A dietary supplements are available?",
            text: "Vitamin A is available in dietary supplements, usually in the form of retinyl acetate or retinyl palmitate (preformed vitamin A), beta-carotene (provitamin A), or a combination of preformed and provitamin A. Most multivitamin-mineral supplements contain vitamin A. Dietary supplements that contain only vitamin A are also available."
        ))
        explanation.sections.append(NutrientExplanation.Section(
            header: "Am I getting enough vitamin A?",
            text: "Most people in the United States get enough vitamin A from the foods they eat, and vitamin A deficiency is rare. However, certain groups of people are more likely than others to have trouble getting enough vitamin A:",
            list: NutrientExplanation.Section.BulletedList([
                "Premature infants, who often have low levels of vitamin A in their first year.",
                "Infants, young children, pregnant women, and breastfeeding women in developing countries.",
                "People with cystic fibrosis."
            ])
        ))
        explanation.sections.append(NutrientExplanation.Section(
            header: "What happens if I don't get enough vitamin A?",
            text: "Vitamin A deficiency is rare in the United States, although it is common in many developing countries. The most common symptom of vitamin A deficiency in young children and pregnant women is an eye condition called xerophthalmia. Xerophthalmia is the inability to see in low light, and it can lead to blindness if it isn't treated."
        ))
        explanation.sections.append(NutrientExplanation.Section(
            header: "What are some effects of vitamin A on health?",
            text: "Scientists are studying vitamin A to understand how it affects health. Here are some examples of what this research has shown.",
            subsections: [
                NutrientExplanation.Section(
                    header: "Cancer",
                    text: "People who eat a lot of foods containing beta-carotene might have a lower risk of certain kinds of cancer, such as lung cancer or prostate cancer. But studies to date have not shown that vitamin A or beta-carotene supplements can help prevent cancer or lower the chances of dying from this disease. In fact, studies show that smokers who take high doses of beta-carotene supplements have an increased risk of lung cancer."
                ),
                NutrientExplanation.Section(
                    header: "Age-Related Macular Degeneration",
                    text: "Age-related macular degeneration (AMD), or the loss of central vision as people age, is one of the most common causes of vision loss in older people. Among people with AMD who are at high risk of developing advanced AMD, a supplement containing antioxidants, zinc, and copper with or without beta-carotene has shown promise for slowing down the rate of vision loss."
                ),
                NutrientExplanation.Section(
                    header: "Measles",
                    text: "When children with vitamin A deficiency (which is rare in North America) get measles, the disease tends to be more severe. In these children, taking supplements with high doses of vitamin A can shorten the fever and diarrhea caused by measles. These supplements can also lower the risk of death in children with measles who live in developing countries where vitamin A deficiency is common."
                )
            ]
        ))
        explanation.sections.append(NutrientExplanation.Section(
            header: "Can vitamin A be harmful?",
            text: "Yes, high intakes of some forms of vitamin A can be harmful.\n\nGetting too much preformed vitamin A (usually from supplements or certain medicines) can cause dizziness, nausea, headaches, coma, and even death. High intakes of preformed vitamin A in pregnant women can also cause birth defects in their babies. Women who might be pregnant should not take high doses of vitamin A supplements.\n\nConsuming high amounts of beta-carotene or other forms of provitamin A can turn the skin yellow-orange, but this condition is harmless. High intakes of beta-carotene do not cause birth defects or the other more serious effects caused by getting too much preformed vitamin A.\n\nThe daily upper limits for preformed vitamin A include intakes from all sources-food, beverages, and supplements-and are listed below. These levels do not apply to people who are taking vitamin A for medical reasons under the care of a doctor. Upper limits for beta-carotene and other forms of provitamin A have not been established.",
            table: NutrientExplanation.Section.SectionTable(2, [
                "Ages", "Upper Limit",
                "Birth to 12 months", "600 mcg",
                "Children 1-3 years", "600 mcg",
                "Children 4-8 years", "900 mcg",
                "Children 9-13 years", "1,700 mcg",
                "Teens 14-18 years", "2,800 mcg",
                "Adults 19 years and older", "3,000 mcg"
            ])
        ))
        explanation.sections.append(NutrientExplanation.Section(
            header: "Does vitamin A interact with medications or other dietary supplements?",
            text: "Yes, vitamin A supplements can interact or interfere with medicines you take. Here are several examples:",
            list: NutrientExplanation.Section.BulletedList([
                "Orlistat (Alli®, Xenical®), a weight-loss drug, can decrease the absorption of vitamin A, causing low blood levels in some people.",
                "Several synthetic forms of vitamin A are used in prescription medicines. Examples are the psoriasis treatment acitretin (Soriatane®) and bexarotene (Targretin®), used to treat the skin effects of T-cell lymphoma. Taking these medicines in combination with a vitamin A supplement can cause dangerously high levels of vitamin A in the blood."
            ])
        ))
        explanation.sections.append(NutrientExplanation.Section(
            text: "Tell your doctor, pharmacist, and other healthcare providers about any dietary supplements and medicines you take. They can tell you if those dietary supplements might interact or interfere with your prescription or over-the-counter medicines or if the medicines might interfere with how your body absorbs, uses, or breaks down nutrients."
        ))
        explanation.sections.append(NutrientExplanation.Section(
            header: "Vitamin A and healthful eating",
            text: "People should get most of their nutrients from food and beverages, according to the federal government's Dietary Guidelines for Americans. Foods contain vitamins, minerals, dietary fiber and other components that benefit health. In some cases, fortified foods and dietary supplements are useful when it is not possible to meet needs for one or more nutrients (e.g., during specific life stages such as pregnancy). For more information about building a healthy dietary pattern, see the Dietary Guidelines for Americans and the U.S. Department of Agriculture's MyPlate."
//            links: [
//                NutrientExplanation.Link(
//                    url: "https://www.dietaryguidelines.gov",
//                    text: "Dietary Guidelines for Americans",
//                    start: 485
//                ),
//                NutrientExplanation.Link(
//                    url: "http://www.choosemyplate.gov/",
//                    text: "MyPlate",
//                    start: 559
//                )
//            ]
        ))
        explanation.sections.append(NutrientExplanation.Section(
            header: "Where can I find out more about vitamin A?",
            list: NutrientExplanation.Section.BulletedList([
                NutrientExplanation.Section.BulletedList.Item(
                    text: "For more information on vitamin A:",
                    sublist: NutrientExplanation.Section.BulletedList([
                        NutrientExplanation.Section.BulletedList.Item(
                            text: "Office of Dietary Supplements Health Professional Fact Sheet on Vitamin A"
//                            links: [
//                                NutrientExplanation.Link(
//                                    url: "https://ods.od.nih.gov/factsheets/VitaminA-HealthProfessional/",
//                                    text: "Health Professional Fact Sheet on Vitamin A",
//                                    start: 30
//                                )
//                            ]
                        ),
                        NutrientExplanation.Section.BulletedList.Item(
                            text: "Vitamin A, MedlinePlus®"
//                            links: [
//                                NutrientExplanation.Link(
//                                    url: "https://medlineplus.gov/vitamina.html",
//                                    text: "Vitamin A",
//                                    start: 0
//                                )
//                            ]
                        )
                    ])
                ),
                NutrientExplanation.Section.BulletedList.Item(
                    text: "For more information on food sources of vitamin A:",
                    sublist: NutrientExplanation.Section.BulletedList([
                        NutrientExplanation.Section.BulletedList.Item(
                            text: "U.S. Department of Agriculture's (USDA's) FoodData Central"
//                            links: [
//                                NutrientExplanation.Link(
//                                    url: "https://fdc.nal.usda.gov/",
//                                    text: "FoodData Central",
//                                    start: 42
//                                )
//                            ]
                        ),
                        NutrientExplanation.Section.BulletedList.Item(
                            text: "Nutrient List for vitamin A (listed by food or by vitamin A content), USDA"
//                            links: [
//                                NutrientExplanation.Link(
//                                    url: "https://ods.od.nih.gov/pubs/usdandb/VitaminA-Food.pdf",
//                                    text: "food",
//                                    start: 39
//                                ),
//                                NutrientExplanation.Link(
//                                    url: "https://ods.od.nih.gov/pubs/usdandb/VitaminA-Content.pdf",
//                                    text: "vitamin A content",
//                                    start: 50
//                                )
//                            ]
                        ),
                        NutrientExplanation.Section.BulletedList.Item(
                            text: "Nutrient List for beta-carotene (listed by food or by beta-carotene content), USDA"
//                            links: [
//                                NutrientExplanation.Link(
//                                    url: "https://ods.od.nih.gov/pubs/usdandb/VitA-betaCarotene-Food.pdf",
//                                    text: "food",
//                                    start: 43
//                                ),
//                                NutrientExplanation.Link(
//                                    url: "https://ods.od.nih.gov/pubs/usdandb/VitA-betaCarotene-Content.pdf",
//                                    text: "beta-carotene content",
//                                    start: 54
//                                )
//                            ]
                        )
                    ])
                ),
                NutrientExplanation.Section.BulletedList.Item(
                    text: "For more advice on choosing dietary supplements:",
                    sublist: NutrientExplanation.Section.BulletedList([
                        NutrientExplanation.Section.BulletedList.Item(
                            text: "Office of Dietary Supplements Frequently Asked Questions: Which brand(s) of dietary supplements should I purchase?"
//                            links: [
//                                NutrientExplanation.Link(
//                                    url: "https://ods.od.nih.gov/Health_Information/ODS_Frequently_Asked_Questions.aspx#Brands",
//                                    text: "Frequently Asked Questions: Which brand(s) of dietary supplements should I purchase?",
//                                    start: 30
//                                )
//                            ]
                        )
                    ])
                ),
                NutrientExplanation.Section.BulletedList.Item(
                    text: "For information about building a healthy dietary pattern:",
                    sublist: NutrientExplanation.Section.BulletedList([
                        NutrientExplanation.Section.BulletedList.Item(
                            text: "MyPlate"
//                            links: [
//                                NutrientExplanation.Link(
//                                    url: "http://www.choosemyplate.gov/",
//                                    text: "MyPlate",
//                                    start: 0
//                                )
//                            ]
                        ),
                        NutrientExplanation.Section.BulletedList.Item(
                            text: "Dietary Guidelines for Americans"
//                            links: [
//                                NutrientExplanation.Link(
//                                    url: "https://www.dietaryguidelines.gov",
//                                    text: "Dietary Guidelines for Americans",
//                                    start: 0
//                                )
//                            ]
                        )
                    ])
                )
            ])
        ))

        return explanation
    }
}
