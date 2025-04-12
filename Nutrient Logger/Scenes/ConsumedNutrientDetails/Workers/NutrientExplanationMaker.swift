//
//  NutrientExplanationMaker.swift
//  NutrientExplanationMaker
//
//  Created by Jason Vance on 9/13/21.
//

import Foundation
import UIKit

public class NutrientExplanationMaker {
    public static func canMakeFor(_ fdcNumber: String) -> Bool {
        return NutrientExplanationLoader.canLoad(fdcNumber)
    }

    public static func make(_ fdcNumber: String, _ palette: ColorPalette, _ fontSize: CGFloat) async throws -> NSAttributedString {
        let str = AttributedStringBuilder()

        let explanation = try await NutrientExplanationLoader.loadForDisplay(fdcNumber)
        for i in 0..<explanation.sections.count {
            let section = explanation.sections[i]
            await addSection(palette, fontSize, str, i == 0, section)
        }

        return str.toNative()
    }

    private static func addSection(
        _ palette: ColorPalette,
        _ fontSize: CGFloat,
        _ str: AttributedStringBuilder,
        _ isFirstSection: Bool,
        _ section: NutrientExplanation.Section,
        _ isSubSection: Bool = false)
    async {
        if (!isFirstSection || isSubSection) {
            str.appendText("\n\n", fontSize - 2)
        }

        if (!section.header.isEmpty) {
            if (isSubSection) {
                str.appendText(section.header, fontSize - 2, .boldItalic)
            } else {
                str.appendText(section.header, fontSize, .bold)
            }
        }

        if (!section.text.isEmpty) {
            var text = ""
            text += !section.header.isEmpty ? "\n\n" : ""
            text += section.text
            str.appendText(text, fontSize - 2)
        }

        if (section.table != nil) {
            str.appendText("\n\n", fontSize - 2)

            let table = AttributedStringBuilder.TwoColumnTable()
            for row in 0..<section.table!.rows {
                let rowCells = section.table!.getRow(row)
                let tableRow = AttributedStringBuilder.TwoColumnTable.Row(
                    leftText: rowCells[0].text,
                    rightText: rowCells[1].text,
                    fontSize: fontSize - 2,
                    textColor: palette.text,
                    backgroundColor: (row % 2 == 0) ? palette.primary : palette.primary.lighter(by: 0.1)!
                )

                if (row == 0) {
                    table.addHeader(tableRow)
                } else {
                    table.addRow(tableRow)
                }
            }
            await str.appendTable(table, fontSize - 2)
        }


        if (section.list != nil) {
            str.appendText("\n", fontSize - 2)

            let items = makeBulletPoints(section.list!)

            str.appendBulletPoints(items, fontSize - 2)
        }

        if (section.subsections.isEmpty == false) {
            for i in 0..<section.subsections.count {
                let subSection = section.subsections[i]
                await addSection(palette, fontSize, str, i == 0, subSection, true)
            }
        }
    }

    private static func makeBulletPoints(_ list: NutrientExplanation.Section.BulletedList, _ indentation: Int = 0) -> [AttributedStringBuilder.BulletPoint] {
        var points = [AttributedStringBuilder.BulletPoint]()

        for item in list.items {
            points.append(AttributedStringBuilder.BulletPoint(
                text: item.text,
                indentationLevel: indentation
            ))
            
            if (item.sublist != nil) {
                points.append(contentsOf: makeBulletPoints(item.sublist!, indentation + 1))
            }
        }

        return points
    }
}
