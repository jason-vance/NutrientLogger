//
//  UIColorExtensions.swift
//  PlasmaRaptor
//
//  Created by Jason Vance on 9/23/21.
//

import Foundation
import UIKit

public extension UIColor {

    func lighter(by percentage: CGFloat = 0.3) -> UIColor? {
        return self.adjust(by: abs(percentage))
    }

    func darker(by percentage: CGFloat = 0.3) -> UIColor? {
        return self.adjust(by: -1 * abs(percentage))
    }

    func adjust(by percentage: CGFloat = 0.3) -> UIColor? {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        
        if self.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            return UIColor(red: min(red + percentage, 1.0),
                           green: min(green + percentage, 1.0),
                           blue: min(blue + percentage, 1.0),
                           alpha: alpha)
        } else {
            return nil
        }
    }
}
