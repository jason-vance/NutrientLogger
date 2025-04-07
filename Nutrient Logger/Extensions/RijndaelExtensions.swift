//
//  RijndaelExtensions.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/7/25.
//

import Foundation
import RijndaelSwift

public extension Rijndael {
    func decryptString(data: Data, blockSize: Int, iv: Data?) -> Data? {
        let stringData = self.decrypt(data: data, blockSize: blockSize, iv: iv)!
        return stringData.prefix(while: { byte in
            return byte != 0x00
        })
    }
}
