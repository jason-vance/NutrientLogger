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
            return ColorPalettes.indigo
        }
        if (FdcNutrientGroupMapper.GroupNumber_Minerals == groupNumber) {
            return ColorPalettes.cyan
        }
        if (FdcNutrientGroupMapper.GroupNumber_VitaminsAndOtherComponents == groupNumber) {
            return ColorPalettes.orange
        }
        if (FdcNutrientGroupMapper.GroupNumber_Lipids == groupNumber) {
            return ColorPalettes.red
        }
        if (FdcNutrientGroupMapper.GroupNumber_AminoAcids == groupNumber) {
            return ColorPalettes.green
        }

        return nil
    }
    
    public static func getColorPaletteAt(_ index: Int) -> ColorPalette {
        let i = index % ColorPalettes.palettes.count;
        return ColorPalettes.palettes[i]
    }
}

public class ColorPalette {
    public let accent: Color
    public let background: Color
    public let text: Color
    
    init(accent: Color, background: Color, text: Color) {
        self.accent = accent
        self.background = background
        self.text = text
    }
    
    convenience init(accent: Color) {
        self.init(accent: accent, background: Color.background, text: Color.text)
    }
}

public class AppColorPalette: ColorPalette {
    public var success: Color
    public var error: Color
    
    init(accent: Color, background: Color, text: Color, success: Color, error: Color) {
        self.success = success
        self.error = error
        super.init(accent: accent, background: background, text: text)
    }
}

public class ColorPalettes {
    public static let app = AppColorPalette(
        accent: .accentColor,
        background: .background,
        text: .text,
        success: .green,
        error: .red
    )
    public static let red = ColorPalette(accent: .red)
    public static let yellow = ColorPalette(accent: .yellow)
    public static let blue = ColorPalette(accent: .blue)
    public static let purple = ColorPalette(accent: .purple)
    public static let orange = ColorPalette(accent: .orange)
    public static let green = ColorPalette(accent: .green)
    public static let indigo = ColorPalette(accent: .indigo)
    public static let pink = ColorPalette(accent: .pink)
    public static let teal = ColorPalette(accent: .teal)
    public static let mint = ColorPalette(accent: .mint)
    public static let cyan = ColorPalette(accent: .cyan)
    public static let brown = ColorPalette(accent: .brown)
    public static let gray = ColorPalette(accent: .gray)

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
