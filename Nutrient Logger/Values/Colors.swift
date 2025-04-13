//
//  Colors.swift
//  Colors
//
//  Created by Jason Vance on 8/8/21.
//

import Foundation
import SwiftUI

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
    public let primary: Color
    public let secondary: Color
    public let text: Color
    
    init(primary: Color, secondary: Color, text: Color) {
        self.primary = primary
        self.secondary = secondary
        self.text = text
    }
    
    convenience init(primary: Color) {
        self.init(primary: primary, secondary: .white, text: .white)
    }
}

public class AppColorPalette: ColorPalette {
    public var success: Color
    public var error: Color
    
    init(primary: Color, secondary: Color, text: Color, success: Color, error: Color) {
        self.success = success
        self.error = error
        super.init(primary: primary, secondary: secondary, text: text)
    }
}

public class ColorPalettes {
    public static let app = AppColorPalette(
        primary: .primary,
        secondary: .primary,
        text: .secondary,
        success: .green,
        error: .red
    )
    public static let red = ColorPalette(primary: .red)
    public static let yellow = ColorPalette(primary: .yellow)
    public static let blue = ColorPalette(primary: .blue)
    public static let purple = ColorPalette(primary: .purple)
    public static let orange = ColorPalette(primary: .orange)
    public static let green = ColorPalette(primary: .green)
    public static let indigo = ColorPalette(primary: .indigo)
    public static let pink = ColorPalette(primary: .pink)
    public static let teal = ColorPalette(primary: .teal)
    public static let mint = ColorPalette(primary: .mint)
    public static let cyan = ColorPalette(primary: .cyan)
    public static let brown = ColorPalette(primary: .brown)
    
    public static let palettes: [ColorPalette] = [red, teal, blue, indigo, green, pink, purple, orange, mint, cyan]
    
    public static let allColors: [(ColorName,Color)] = [
        (ColorName.red, .red),
        (ColorName.indigo, .indigo),
        (ColorName.blue, .blue),
        (ColorName.green, .green),
        (ColorName.pink, .pink),
        (ColorName.purple, .purple),
        (ColorName.teal, .teal),
        (ColorName.mint, .mint),
        (ColorName.orange, .orange),
        (ColorName.yellow, .yellow),
        (ColorName.cyan, .cyan),
        (ColorName.brown, .brown),
    ]
    
    public static func colorFrom(name: ColorName) -> Color { allColors.first(where: { $0.0 == name })!.1 }
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
