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
            return ColorPalettes.mint
        }
        if (FdcNutrientGroupMapper.GroupNumber_VitaminsAndOtherComponents == groupNumber) {
            return ColorPalettes.cyan
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
}
