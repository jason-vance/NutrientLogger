//
//  FdcFood.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/7/25.
//

import Foundation

public struct FdcFood {
//    [Column("fdc_id")]
    public let fdcId: Int

//    [Column("data_type")]
    public let dataType: String

//    [Column("description")]
    public let description: String

//    [Column("food_category_id")]
    public let foodCategoryId: Int?
}
