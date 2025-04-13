//
//  PRAttributedString.swift
//  PRAttributedString
//
//  Created by Jason Vance on 9/13/21.
//

import Foundation
import UIKit

public class AttributedStringBuilder {
    public enum Style {
        case none
        case bold
        case italic
        case boldItalic
    }

    public struct BulletPoint {
        public let text: String
        public let indentationLevel: Int
        
        public init(text: String, indentationLevel: Int) {
            self.text = text
            self.indentationLevel = indentationLevel
        }
    }

    public class TwoColumnTable {
        public var headerRow: Row?

        public var hasHeader: Bool { headerRow != nil }

        private(set) var rows: [Row] = []

        public var rowCount: Int { rows.count }
        
        public init() {}

        public func addHeader(_ row: Row) {
            headerRow = row
        }

        public func addRow(_ row: Row) {
            rows.append(row)
        }

        public struct Row {
            public let leftText: String
            public let rightText: String
            public let fontSize: CGFloat
            
            public init(leftText: String, rightText: String, fontSize: CGFloat) {
                self.leftText = leftText
                self.rightText = rightText
                self.fontSize = fontSize
            }
        }
    }
    
    private let Native: NSMutableAttributedString

    public init() {
        Native = NSMutableAttributedString()
    }

    public init(_ text: String) {
        Native = NSMutableAttributedString(string: text)
    }

    public func toNative() -> NSAttributedString {
        return Native
    }

    public var length: Int { Native.length }

    @discardableResult public func addTextColorSpan(_ color: UIColor, _ start: Int, _ length: Int) -> AttributedStringBuilder {
        addSpan(Native, { attr in
            attr[.foregroundColor] = color
        }, start, length)
        return self
    }

    @discardableResult public func addStrikeThroughSpan(_ start: Int, _ length: Int) -> AttributedStringBuilder {
        addSpan(Native, { attr in
            attr[.strikethroughStyle] = NSUnderlineStyle.single
        }, start, length)
        return self
    }

    @discardableResult public func addFontSizeSpan(_ label: UILabel, _ fontSize: CGFloat, _ start: Int, _ length: Int) -> AttributedStringBuilder {
        addSpan(Native, { attr in
            attr[.font] = label.font.withSize(fontSize)
        }, start, length)
        return self
    }

    @discardableResult public func addBoldTextSpan(_ start: Int, _ length: Int, _ fontSize: CGFloat) -> AttributedStringBuilder {
        addSpan(Native, { attr in
            attr[.font] = UIFont.boldSystemFont(ofSize: fontSize)
        }, start, length)
        return self
    }

    private func addSpan(_ str: NSMutableAttributedString, _ modAttrs: (inout [NSAttributedString.Key: Any]) -> Void, _ start: Int, _ length: Int) {
        var attr = [NSAttributedString.Key: Any]()
        modAttrs(&attr)

        let range = NSRange(location: start, length: length)

        str.addAttributes(attr, range: range)
    }

    @discardableResult public func appendText(_ text: String, _ fontSize: CGFloat, _ style: Style = Style.none) -> AttributedStringBuilder {
        let span = NSMutableAttributedString(string: text)
        addSpan(span, { attr in
            var traits = UIFontDescriptor.SymbolicTraits()
            if (style == .bold) {
                traits.update(with: .traitBold)
            } else if (style == .italic) {
                traits.update(with: .traitItalic)
            } else if (style == .boldItalic) {
                traits.update(with: .traitBold)
                traits.update(with: .traitItalic)
            }

            let font = UIFont.italicSystemFont(ofSize: fontSize)
            let descriptor = font.fontDescriptor.withSymbolicTraits(traits)

            attr[.font] = UIFont.init(descriptor: descriptor!, size: fontSize)
        }, 0, text.count)

        Native.append(span)
        return self
    }

    @discardableResult public func appendBulletPoints(_ points: [BulletPoint], _ fontSize: CGFloat) -> AttributedStringBuilder {
        let indentation: CGFloat = 15
        let paragraphSpacing: CGFloat = 3

        var text = ""
        for point in points {
            for _ in 0..<point.indentationLevel {
                text.append(" ")
            }
            text.append("• \(point.text)\n")
        }

        let span = NSMutableAttributedString(string: text)
        addSpan(span, { attr in
            attr[.font] = UIFont.systemFont(ofSize: fontSize)

            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.tabStops = [ NSTextTab(textAlignment: .left, location: indentation, options: [:]) ]
            paragraphStyle.defaultTabInterval = indentation
            paragraphStyle.firstLineHeadIndent = 0
            paragraphStyle.headIndent = indentation
            paragraphStyle.paragraphSpacing = paragraphSpacing
            attr[.paragraphStyle] = paragraphStyle
        }, 0, text.count)
        Native.append(span)

        return self
    }

    @discardableResult public func appendTwoColumnLine(_ leftText: String, _ rightText: String) -> AttributedStringBuilder {
        let leftSpan = NSMutableAttributedString(string: leftText)
        addSpan(leftSpan, { attr in
            let style = (attr[.paragraphStyle] as? NSMutableParagraphStyle) ?? NSMutableParagraphStyle()
            style.alignment = .left
        }, 0, leftText.count)
        Native.append(leftSpan)

        let rightSpan = NSMutableAttributedString(string: rightText)
        addSpan(rightSpan, { attr in
            let style = (attr[.paragraphStyle] as? NSMutableParagraphStyle) ?? NSMutableParagraphStyle()
            style.alignment = .right
        }, 0, rightText.count)
        Native.append(rightSpan)

        return self
    }

    @discardableResult public func appendTable(_ table: TwoColumnTable, _ fontSize: CGFloat) async -> AttributedStringBuilder {
        var sb = ""
        sb.append("<table style=\"font:\(fontSize)px arial;width:100%;border-collapse:collapse;\"><tbody>")
        if (table.hasHeader) {
            addTableRow(&sb, table.headerRow!, true)
        }
        for row in table.rows {
            addTableRow(&sb, row)
        }
        sb.append("</tbody></table>")
        await appendFromHtml(sb)

        return self
    }

    private func addTableRow(_ sb: inout String, _ row: TwoColumnTable.Row, _ isHeader: Bool = false) {
        let tag = (isHeader) ? "th" : "td"
        
        sb.append("<tr>")
        sb.append("<\(tag)><span>\(row.leftText):</span>")
        sb.append("<span style=\"font-weight:bold;\"> \(row.rightText)</span></\(tag)>")
        sb.append("</tr>")
    }

    @discardableResult private func appendFromHtml(_ html: String) async -> AttributedStringBuilder {
        let data = Data(html.utf8)
        if let result = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil) {
            Native.append(result)
        }
        return self
    }
    
    private func colorToHex(_ color: UIColor) -> String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02x%02x%02x%02x", (Int)(r * 255), (Int)(g * 255), (Int)(b * 255), (Int)(a * 255))
    }
}
