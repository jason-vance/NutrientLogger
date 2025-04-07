//
//  FdcPortion.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/6/25.
//

import Foundation

public struct FdcPortion {
//    [Column("id")]
    public let id: Int

//    [Column("fdc_id")]
    public let fdcId: Int

//    [Column("seq_num")]
    public let sequenceNumber: Int
    
//    [Column("amount")]
    public let amount: Double?

//    [Column("portion_description")]
    public let description: String?

//    [Column("modifier")]
    public let modifier: String?

//    [Column("gram_weight")]
    public let gramWeight: Double
}
