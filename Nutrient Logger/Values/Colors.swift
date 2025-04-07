//
//  Colors.swift
//  Colors
//
//  Created by Jason Vance on 8/8/21.
//

import Foundation
import UIKit

public class ColorPaletteService {
    public static func getColorPaletteFor(number: Int) -> ColorPalette {
        return getColorPaletteAt(number)
    }
    
    public static func getColorPaletteFor(number: String) -> ColorPalette {
        if let palette = getColorPaletteFor(groupNumber: number) {
            return palette
        }
        
        return getColorPaletteAt(Int(Double(number)!))
    }
    
    private static func getColorPaletteFor(groupNumber: String) -> ColorPalette? {
        if (FdcNutrientGroupMapper.GroupNumber_Proximates == groupNumber) {
            return ColorPalettes.indigo
        }
        if (FdcNutrientGroupMapper.GroupNumber_Carbohydrates == groupNumber) {
            return ColorPalettes.orange
        }
        if (FdcNutrientGroupMapper.GroupNumber_Minerals == groupNumber) {
            return ColorPalettes.green
        }
        if (FdcNutrientGroupMapper.GroupNumber_VitaminsAndOtherComponents == groupNumber) {
            return ColorPalettes.blue
        }
        if (FdcNutrientGroupMapper.GroupNumber_Lipids == groupNumber) {
            return ColorPalettes.red
        }
        if (FdcNutrientGroupMapper.GroupNumber_AminoAcids == groupNumber) {
            return ColorPalettes.teal
        }

        return nil
    }
    
    public static func getColorPaletteAt(_ index: Int) -> ColorPalette {
        let i = index % ColorPalettes.palettes.count;
        return ColorPalettes.palettes[i]
    }
}

public class ColorPalette {
    public let primary: UIColor
    public let secondary: UIColor
    public let text: UIColor
    
    init(primary: UIColor, secondary: UIColor, text: UIColor) {
        self.primary = primary
        self.secondary = secondary
        self.text = text
    }
    
    convenience init(primary: UIColor) {
        self.init(primary: primary, secondary: .white, text: .white)
    }
}

public class AppColorPalette: ColorPalette {
    public var success: UIColor
    public var error: UIColor
    
    init(primary: UIColor, secondary: UIColor, text: UIColor, success: UIColor, error: UIColor) {
        self.success = success
        self.error = error
        super.init(primary: primary, secondary: secondary, text: text)
    }
}

public class ColorPalettes {
    public static let app = AppColorPalette(
        primary: .systemBackground,
        secondary: .systemBackground,
        text: .label,
        success: .systemGreen,
        error: .systemRed
    )
    public static let red = ColorPalette(primary: .systemRed)
    public static let yellow = ColorPalette(primary: .systemYellow)
    public static let blue = ColorPalette(primary: .systemBlue)
    public static let purple = ColorPalette(primary: .systemPurple)
    public static let orange = ColorPalette(primary: .systemOrange)
    public static let green = ColorPalette(primary: .systemGreen)
    public static let indigo = ColorPalette(primary: .systemIndigo)
    public static let pink = ColorPalette(primary: .systemPink)
    public static let teal = ColorPalette(primary: .systemTeal)
    public static let mint = ColorPalette(primary: .systemMint)
    public static let cyan = ColorPalette(primary: .systemCyan)
    public static let brown = ColorPalette(primary: .systemBrown)
    
    public static let palettes: [ColorPalette] = [red, teal, blue, indigo, green, pink, purple, orange, mint, cyan]
    
    public static let allColors: [(ColorName,UIColor)] = [
        (ColorName.red, .systemRed),
        (ColorName.indigo, .systemIndigo),
        (ColorName.blue, .systemBlue),
        (ColorName.green, .systemGreen),
        (ColorName.pink, .systemPink),
        (ColorName.purple, .systemPurple),
        (ColorName.teal, .systemTeal),
        (ColorName.mint, .systemMint),
        (ColorName.orange, .systemOrange),
        (ColorName.yellow, .systemYellow),
        (ColorName.cyan, .systemCyan),
        (ColorName.brown, .systemBrown),
    ]
    
    public static func colorFrom(name: ColorName) -> UIColor { allColors.first(where: { $0.0 == name })!.1 }
}

public final class ColorName {
    
    private static let redName = "red"
    private static let yellowName = "yellow"
    private static let blueName = "blue"
    private static let purpleName = "purple"
    private static let orangeName = "orange"
    private static let greenName = "green"
    private static let indigoName = "indigo"
    private static let pinkName = "pink"
    private static let tealName = "teal"
    private static let mintName = "mint"
    private static let cyanName = "cyan"
    private static let brownName = "brown"
    
    public static let red = ColorName.from(redName)!
    public static let yellow = ColorName.from(yellowName)!
    public static let blue = ColorName.from(blueName)!
    public static let purple = ColorName.from(purpleName)!
    public static let orange = ColorName.from(orangeName)!
    public static let green = ColorName.from(greenName)!
    public static let indigo = ColorName.from(indigoName)!
    public static let pink = ColorName.from(pinkName)!
    public static let teal = ColorName.from(tealName)!
    public static let mint = ColorName.from(mintName)!
    public static let cyan = ColorName.from(cyanName)!
    public static let brown = ColorName.from(brownName)!

    private static let validNames = [
        redName, yellowName, blueName, purpleName, orangeName, greenName,
        indigoName, pinkName, tealName, mintName, cyanName, brownName
    ]
    
    let value: String
    
    private init?(_ value: String) {
        guard Self.validNames.contains(value) else { return nil }
        self.value = value
    }
    
    public static func from(_ value: String) -> ColorName? {
        return ColorName(value)
    }
}

extension ColorName: Equatable {
    public static func == (lhs: ColorName, rhs: ColorName) -> Bool {
        lhs.value == rhs.value
    }
}

extension ColorName: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }
}

extension ColorName: Codable { }
