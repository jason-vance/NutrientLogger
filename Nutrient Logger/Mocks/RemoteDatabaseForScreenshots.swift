//
//  RemoteDatabaseForScreenshots.swift
//  RemoteDatabaseForScreenshots
//
//  Created by Jason Vance on 9/15/21.
//

import Foundation

class RemoteDatabaseForScreenshots: RemoteDatabase {
    
    public func search(_ query: String) throws -> [FdcSearchableFood] {
        [
            .init(fdcId: 1, description: "Pork sausage", rank: 0),
            .init(fdcId: 2, description: "Pork and beef sausage", rank: 0),
            .init(fdcId: 3, description: "Polish sausage, pork", rank: 0),
            .init(fdcId: 4, description: "Sausage, smoked link sausage, pork", rank: 0),
            .init(fdcId: 5, description: "Turkey or chicken and pork sausage", rank: 0),
            .init(fdcId: 6, description: "Sausage, smoked link sausage, pork and beef", rank: 0),
            .init(fdcId: 7, description: "Pork sausage, reduced sodium", rank: 0),
            .init(fdcId: 8, description: "Pork sausage rice links", rank: 0),
            .init(fdcId: 9, description: "Pork sausage, reduced fat", rank: 0),
            .init(fdcId: 10, description: "Braunschweiger (a liver sausage), pork", rank: 0),
            .init(fdcId: 11, description: "Liver sausage, liverwurst, pork", rank: 0),
            .init(fdcId: 21, description: "Luncheon sausage, pork and beef", rank: 0),
            .init(fdcId: 31, description: "Sausage, Berliner, pork, beef", rank: 0),
            .init(fdcId: 41, description: "Pork sausage, link/patty, unprepared", rank: 0),
            .init(fdcId: 51, description: "Pork sausage, reduced sodium, cooked", rank: 0),
            .init(fdcId: 61, description: "Sausage, Italian, pork, mild, raw", rank: 0),
            .init(fdcId: 71, description: "Sausage, Polish, pork and beef, smoked", rank: 0),
            .init(fdcId: 81, description: "Sausage, pork and beef, fresh, cooked", rank: 0),
            .init(fdcId: 91, description: "Sausage, pork and turkey, pre-cooked", rank: 0),
            .init(fdcId: 100, description: "Sausage, chicken, beef, pork, skinless, smoked", rank: 0),
        ]
    }
    
    public func getFood(_ foodId: String) throws -> FoodItem? {
        let jsonData = Data(porkSausage.utf8)
        return try! JSONDecoder().decode(FoodItem.self, from: jsonData)
    }
    
    public func getPortions(_ food: FoodItem) throws -> [Portion] {
        var portions = [Portion]()

        portions.append(Portion(
            name: "half smoke sausage",
            amount: 1,
            gramWeight: 112
        ))
        portions.append(Portion(
            name: "bun-size or griller link",
            amount: 1,
            gramWeight: 75
        ))
        portions.append(Portion(
            name: "cocktail or miniature link",
            amount: 1,
            gramWeight: 10
        ))
        portions.append(Portion(
            name: "breakfast size link",
            amount: 1,
            gramWeight: 20
        ))
        portions.append(Portion(
            name: "slice",
            amount: 1,
            gramWeight: 15
        ))
        portions.append(Portion(
            name: "patty",
            amount: 1,
            gramWeight: 35
        ))
        portions.append(Portion(
            name: "piece",
            amount: 1,
            gramWeight: 75
        ))
        portions.append(Portion(
            name: "cubic inch",
            amount: 1,
            gramWeight: 18
        ))
        portions.append(Portion(
            name: "oz, cooked",
            amount: 1,
            gramWeight: 28.35
        ))
        portions.append(Portion(
            name: "cup, NFS",
            amount: 1,
            gramWeight: 138
        ))

        return portions
    }
    
    public func getAllNutrients() throws -> [Nutrient] {
        return []
    }
    
    public func getAllNutrientsLinkedToFoods() throws -> [Nutrient] {
        return []
    }
    
    public func getFoodsContainingNutrient(_ nutrient: Nutrient) throws -> [NutrientFoodPair] {
        return []
    }
    
    private let porkSausage = """
    {
        "fdcId": 1098705,
        "fdcType": "Survey (FNDDS)",
        "name": "Pork sausage",
        "amount": 2,
        "portionName": "breakfast size link",
        "gramWeight": 20,
        "dateLogged": 20250408,
        "mealTime":"Dinner",
        "nutrientGroups": [
            {
                "fdcNumber": "951",
                "name": "Proximates",
                "rank": 0,
                "nutrients": [
                    {
                        "fdcNumber": "203",
                        "name": "Protein",
                        "amount": 7.4,
                        "unitName": "g",
                        "dateLogged": 20250408,
                        "mealTime":"Dinner",
                        "id": 1042,
                        "fdcId": 1042,
                        "created": 20201106184426
                    },
                    {
                        "fdcNumber": "204",
                        "name": "Total Fat",
                        "amount": 10.88,
                        "unitName": "g",
                        "dateLogged": 20250408,
                        "mealTime":"Dinner",
                        "id": 1043,
                        "fdcId": 1043,
                        "created": 20201106184426
                    },
                    {
                        "fdcNumber": "208",
                        "name": "Energy",
                        "amount": 130,
                        "unitName": "cal",
                        "dateLogged": 20250408,
                        "mealTime":"Dinner",
                        "id": 1044,
                        "fdcId": 1044,
                        "created": 20201106184426
                    },
                    {
                        "fdcNumber": "255",
                        "name": "Water",
                        "amount": 19.960001,
                        "unitName": "g",
                        "dateLogged": 20250408,
                        "mealTime":"Dinner",
                        "id": 1045,
                        "fdcId": 1045,
                        "created": 20201106184426
                    }
                ]
            },
            {
                "fdcNumber": "956",
                "name": "Carbohydrates",
                "rank": 1,
                "nutrients": [
                    {
                        "fdcNumber": "205",
                        "name": "Carbohydrate, by difference",
                        "amount": 0.568,
                        "unitName": "g",
                        "dateLogged": 20250408,
                        "mealTime":"Dinner",
                        "id": 1046,
                        "fdcId": 1046,
                        "created": 20201106184426
                    },
                    {
                        "fdcNumber": "269",
                        "name": "Sugars, total including NLEA",
                        "amount": 0.436000019,
                        "unitName": "g",
                        "dateLogged": 20250408,
                        "mealTime":"Dinner",
                        "id": 1047,
                        "fdcId": 1047,
                        "created": 20201106184426
                    }
                ]
            },
            {
                "fdcNumber": "300",
                "name": "Minerals",
                "rank": 2,
                "nutrients": [
                    {
                        "fdcNumber": "301",
                        "name": "Calcium, Ca",
                        "amount": 3.60000014,
                        "unitName": "mg",
                        "dateLogged": 20250408,
                        "mealTime":"Dinner",
                        "id": 1048,
                        "fdcId": 1048,
                        "created": 20201106184426
                    },
                    {
                        "fdcNumber": "303",
                        "name": "Iron, Fe",
                        "amount": 0.480000019,
                        "unitName": "mg",
                        "dateLogged": 20250408,
                        "mealTime":"Dinner",
                        "id": 1049,
                        "fdcId": 1049,
                        "created": 20201106184426
                    },
                    {
                        "fdcNumber": "304",
                        "name": "Magnesium, Mg",
                        "amount": 6.4,
                        "unitName": "mg",
                        "dateLogged": 20250408,
                        "mealTime":"Dinner",
                        "id": 1050,
                        "fdcId": 1050,
                        "created": 20201106184426
                    },
                    {
                        "fdcNumber": "305",
                        "name": "Phosphorus, P",
                        "amount": 59.6000023,
                        "unitName": "mg",
                        "dateLogged": 20250408,
                        "mealTime":"Dinner",
                        "id": 1051,
                        "fdcId": 1051,
                        "created": 20201106184426
                    },
                    {
                        "fdcNumber": "306",
                        "name": "Potassium, K",
                        "amount": 136.8,
                        "unitName": "mg",
                        "dateLogged": 20250408,
                        "mealTime":"Dinner",
                        "id": 1052,
                        "fdcId": 1052,
                        "created": 20201106184426
                    },
                    {
                        "fdcNumber": "307",
                        "name": "Sodium, Na",
                        "amount": 325.6,
                        "unitName": "mg",
                        "dateLogged": 20250408,
                        "mealTime":"Dinner",
                        "id": 1053,
                        "fdcId": 1053,
                        "created": 20201106184426
                    },
                    {
                        "fdcNumber": "309",
                        "name": "Zinc, Zn",
                        "amount": 0.98,
                        "unitName": "mg",
                        "dateLogged": 20250408,
                        "mealTime":"Dinner",
                        "id": 1054,
                        "fdcId": 1054,
                        "created": 20201106184426
                    },
                    {
                        "fdcNumber": "312",
                        "name": "Copper, Cu",
                        "amount": 0.028400002,
                        "unitName": "mg",
                        "dateLogged": 20250408,
                        "mealTime":"Dinner",
                        "id": 1055,
                        "fdcId": 1055,
                        "created": 20201106184426
                    },
                    {
                        "fdcNumber": "317",
                        "name": "Selenium, Se",
                        "amount": 8.280001,
                        "unitName": "μg",
                        "dateLogged": 20250408,
                        "mealTime":"Dinner",
                        "id": 1056,
                        "fdcId": 1056,
                        "created": 20201106184426
                    }
                ]
            },
            {
                "fdcNumber": "952",
                "name": "Vitamins and Other Components",
                "rank": 3,
                "nutrients": [
                    {
                        "fdcNumber": "319",
                        "name": "Retinol",
                        "amount": 11.2,
                        "unitName": "μg",
                        "dateLogged": 20250408,
                        "mealTime":"Dinner",
                        "id": 1057,
                        "fdcId": 1057,
                        "created": 20201106184426
                    },
                    {
                        "fdcNumber": "320",
                        "name": "Vitamin A, RAE",
                        "amount": 11.2,
                        "unitName": "μg",
                        "dateLogged": 20250408,
                        "mealTime":"Dinner",
                        "id": 1058,
                        "fdcId": 1058,
                        "created": 20201106184426
                    },
                    {
                        "fdcNumber": "323",
                        "name": "Vitamin E (alpha-tocopherol)",
                        "amount": 0.359999985,
                        "unitName": "mg",
                        "dateLogged": 20250408,
                        "mealTime":"Dinner",
                        "id": 1059,
                        "fdcId": 1059,
                        "created": 20201106184426
                    },
                    {
                        "fdcNumber": "328",
                        "name": "Vitamin D (D2 + D3)",
                        "amount": 0.56,
                        "unitName": "μg",
                        "dateLogged": 20250408,
                        "mealTime":"Dinner",
                        "id": 1060,
                        "fdcId": 1060,
                        "created": 20201106184426
                    },
                    {
                        "fdcNumber": "404",
                        "name": "Thiamin",
                        "amount": 0.102400005,
                        "unitName": "mg",
                        "dateLogged": 20250408,
                        "mealTime":"Dinner",
                        "id": 1061,
                        "fdcId": 1061,
                        "created": 20201106184426
                    },
                    {
                        "fdcNumber": "405",
                        "name": "Riboflavin",
                        "amount": 0.0704,
                        "unitName": "mg",
                        "dateLogged": 20250408,
                        "mealTime":"Dinner",
                        "id": 1062,
                        "fdcId": 1062,
                        "created": 20201106184426
                    },
                    {
                        "fdcNumber": "406",
                        "name": "Niacin",
                        "amount": 2.448,
                        "unitName": "mg",
                        "dateLogged": 20250408,
                        "mealTime":"Dinner",
                        "id": 1063,
                        "fdcId": 1063,
                        "created": 20201106184426
                    },
                    {
                        "fdcNumber": "415",
                        "name": "Vitamin B-6",
                        "amount": 0.078,
                        "unitName": "mg",
                        "dateLogged": 20250408,
                        "mealTime":"Dinner",
                        "id": 1064,
                        "fdcId": 1064,
                        "created": 20201106184426
                    },
                    {
                        "fdcNumber": "417",
                        "name": "Folate, total",
                        "amount": 0.4,
                        "unitName": "μg",
                        "dateLogged": 20250408,
                        "mealTime":"Dinner",
                        "id": 1065,
                        "fdcId": 1065,
                        "created": 20201106184426
                    },
                    {
                        "fdcNumber": "418",
                        "name": "Vitamin B-12",
                        "amount": 0.39200002,
                        "unitName": "μg",
                        "dateLogged": 20250408,
                        "mealTime":"Dinner",
                        "id": 1066,
                        "fdcId": 1066,
                        "created": 20201106184426
                    },
                    {
                        "fdcNumber": "421",
                        "name": "Choline, total",
                        "amount": 24.92,
                        "unitName": "mg",
                        "dateLogged": 20250408,
                        "mealTime":"Dinner",
                        "id": 1067,
                        "fdcId": 1067,
                        "created": 20201106184426
                    },
                    {
                        "fdcNumber": "432",
                        "name": "Folate, food",
                        "amount": 0.4,
                        "unitName": "μg",
                        "dateLogged": 20250408,
                        "mealTime":"Dinner",
                        "id": 1068,
                        "fdcId": 1068,
                        "created": 20201106184426
                    },
                    {
                        "fdcNumber": "435",
                        "name": "Folate, DFE",
                        "amount": 0.4,
                        "unitName": "μg",
                        "dateLogged": 20250408,
                        "mealTime":"Dinner",
                        "id": 1069,
                        "fdcId": 1069,
                        "created": 20201106184426
                    }
                ]
            },
            {
                "fdcNumber": "950",
                "name": "Lipids",
                "rank": 4,
                "nutrients": [
                    {
                        "fdcNumber": "601",
                        "name": "Cholesterol",
                        "amount": 34.4,
                        "unitName": "mg",
                        "dateLogged": 20250408,
                        "mealTime":"Dinner",
                        "id": 1070,
                        "fdcId": 1070,
                        "created": 20201106184426
                    },
                    {
                        "fdcNumber": "606",
                        "name": "Saturated Fat",
                        "amount": 3.532,
                        "unitName": "g",
                        "dateLogged": 20250408,
                        "mealTime":"Dinner",
                        "id": 1071,
                        "fdcId": 1071,
                        "created": 20201106184426
                    },
                    {
                        "fdcNumber": "609",
                        "name": "8:0",
                        "amount": 0.000400000019,
                        "unitName": "g",
                        "dateLogged": 20250408,
                        "mealTime":"Dinner",
                        "id": 1072,
                        "fdcId": 1072,
                        "created": 20201106184426
                    },
                    {
                        "fdcNumber": "610",
                        "name": "10:0",
                        "amount": 0.0096,
                        "unitName": "g",
                        "dateLogged": 20250408,
                        "mealTime":"Dinner",
                        "id": 1073,
                        "fdcId": 1073,
                        "created": 20201106184426
                    },
                    {
                        "fdcNumber": "611",
                        "name": "12:0",
                        "amount": 0.008,
                        "unitName": "g",
                        "dateLogged": 20250408,
                        "mealTime":"Dinner",
                        "id": 1074,
                        "fdcId": 1074,
                        "created": 20201106184426
                    },
                    {
                        "fdcNumber": "612",
                        "name": "14:0",
                        "amount": 0.1288,
                        "unitName": "g",
                        "dateLogged": 20250408,
                        "mealTime":"Dinner",
                        "id": 1075,
                        "fdcId": 1075,
                        "created": 20201106184426
                    },
                    {
                        "fdcNumber": "613",
                        "name": "16:0",
                        "amount": 2.216,
                        "unitName": "g",
                        "dateLogged": 20250408,
                        "mealTime":"Dinner",
                        "id": 1076,
                        "fdcId": 1076,
                        "created": 20201106184426
                    },
                    {
                        "fdcNumber": "614",
                        "name": "18:0",
                        "amount": 1.1,
                        "unitName": "g",
                        "dateLogged": 20250408,
                        "mealTime":"Dinner",
                        "id": 1077,
                        "fdcId": 1077,
                        "created": 20201106184426
                    },
                    {
                        "fdcNumber": "617",
                        "name": "18:1",
                        "amount": 4.24000025,
                        "unitName": "g",
                        "dateLogged": 20250408,
                        "mealTime":"Dinner",
                        "id": 1078,
                        "fdcId": 1078,
                        "created": 20201106184426
                    },
                    {
                        "fdcNumber": "618",
                        "name": "18:2",
                        "amount": 1.78,
                        "unitName": "g",
                        "dateLogged": 20250408,
                        "mealTime":"Dinner",
                        "id": 1079,
                        "fdcId": 1079,
                        "created": 20201106184426
                    },
                    {
                        "fdcNumber": "619",
                        "name": "18:3",
                        "amount": 0.0584,
                        "unitName": "g",
                        "dateLogged": 20250408,
                        "mealTime":"Dinner",
                        "id": 1080,
                        "fdcId": 1080,
                        "created": 20201106184426
                    },
                    {
                        "fdcNumber": "620",
                        "name": "20:4",
                        "amount": 0.0492000021,
                        "unitName": "g",
                        "dateLogged": 20250408,
                        "mealTime":"Dinner",
                        "id": 1081,
                        "fdcId": 1081,
                        "created": 20201106184426
                    },
                    {
                        "fdcNumber": "621",
                        "name": "22:6 n-3 (DHA)",
                        "amount": 0.0012,
                        "unitName": "g",
                        "dateLogged": 20250408,
                        "mealTime":"Dinner",
                        "id": 1082,
                        "fdcId": 1082,
                        "created": 20201106184426
                    },
                    {
                        "fdcNumber": "626",
                        "name": "16:1",
                        "amount": 0.2228,
                        "unitName": "g",
                        "dateLogged": 20250408,
                        "mealTime":"Dinner",
                        "id": 1083,
                        "fdcId": 1083,
                        "created": 20201106184426
                    },
                    {
                        "fdcNumber": "628",
                        "name": "20:1",
                        "amount": 0.1336,
                        "unitName": "g",
                        "dateLogged": 20250408,
                        "mealTime":"Dinner",
                        "id": 1084,
                        "fdcId": 1084,
                        "created": 20201106184426
                    },
                    {
                        "fdcNumber": "629",
                        "name": "20:5 n-3 (EPA)",
                        "amount": 0.000800000038,
                        "unitName": "g",
                        "dateLogged": 20250408,
                        "mealTime":"Dinner",
                        "id": 1085,
                        "fdcId": 1085,
                        "created": 20201106184426
                    },
                    {
                        "fdcNumber": "630",
                        "name": "22:1",
                        "amount": 0.0024,
                        "unitName": "g",
                        "dateLogged": 20250408,
                        "mealTime":"Dinner",
                        "id": 1086,
                        "fdcId": 1086,
                        "created": 20201106184426
                    },
                    {
                        "fdcNumber": "631",
                        "name": "22:5 n-3 (DPA)",
                        "amount": 0.0100000007,
                        "unitName": "g",
                        "dateLogged": 20250408,
                        "mealTime":"Dinner",
                        "id": 1087,
                        "fdcId": 1087,
                        "created": 20201106184426
                    },
                    {
                        "fdcNumber": "645",
                        "name": "Monounsaturated Fat",
                        "amount": 4.6,
                        "unitName": "g",
                        "dateLogged": 20250408,
                        "mealTime":"Dinner",
                        "id": 1088,
                        "fdcId": 1088,
                        "created": 20201106184426
                    },
                    {
                        "fdcNumber": "646",
                        "name": "Polyunsaturated Fat",
                        "amount": 2.048,
                        "unitName": "g",
                        "dateLogged": 20250408,
                        "mealTime":"Dinner",
                        "id": 1089,
                        "fdcId": 1089,
                        "created": 20201106184426
                    }
                ]
            }
        ],
        "id": 24,
        "created": 20201106184426
    }
    """
    
}
