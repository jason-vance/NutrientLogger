//
//  FdcNutrientLink.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/7/25.
//

import Foundation

public struct FdcNutrientLink: Hashable {
//    [Column("id")]
    public let id: Int

//    [Column("fdc_id")]
    public let fdcId: Int

//    [Column("nutrient_id")]
    public let nutrientId: Int

//    [Column("amount")]
    public let amount: Double
}
