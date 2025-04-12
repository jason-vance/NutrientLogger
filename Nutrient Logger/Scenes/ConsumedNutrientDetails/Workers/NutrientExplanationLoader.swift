//
//  NutrientExplanationLoader.swift
//  NutrientExplanationLoader
//
//  Created by Jason Vance on 9/13/21.
//

import Foundation
import SwiftSoup

public class NutrientExplanationLoader {
    public enum Errors: Error {
        case notInLibrary
        case failure
    }
    
    public static func canLoad(_ fdcNumber: String) -> Bool {
        return NutrientNumberToPropsMap.containsKey(fdcNumber)
    }

    public static func loadForDisplay(_ nutrientNumber: String, with loader: HTMLDocumentLoader? = nil) async throws -> NutrientExplanation {
        let explanation = try await load(nutrientNumber, with: loader)

        let props = NutrientNumberToPropsMap[nutrientNumber]!
        for rule in props.postLoadRules {
            rule.applyTo(explanation)
        }

        return explanation
    }

    public static func load(_ nutrientNumber: String, with loader: HTMLDocumentLoader? = nil) async throws -> NutrientExplanation {
        if (!canLoad(nutrientNumber)) {
            throw Errors.notInLibrary
        }

        let loader = (loader == nil) ? SwiftSoupHTMLDocumentLoader() : loader

        let props = NutrientNumberToPropsMap[nutrientNumber]!
        let doc = await loader!.load(props.url)
        if let mainContent = findMainContent(doc) {
            return turnContentIntoExplanation(props.url, mainContent)
        }
        throw Errors.failure
    }

    private static func findMainContent(_ node: Node) -> Node? {
        let id_CenterContent = "center_content"
        
        for child in node.getChildNodes() {
            let id = try? child.attr("id")
            if (id_CenterContent == id) {
                return child
            }

            if let found = findMainContent(child) {
                return found
            }
        }

        return nil
    }

    private static func turnContentIntoExplanation(_ nihUrl: String, _ mainContent: Node) -> NutrientExplanation {
        let explanation = NutrientExplanation(nihUrl)

        let processors = Stack<HtmlNodeProcessor>()
        processors.push(MainContentProcessor(explanation))

        var cursor = 0
        while cursor < mainContent.childNodeSize() {
            let node = mainContent.childNode(cursor)

            let handled = processors.peek().handleNode(processors, node)
            if (handled) {
                cursor += 1
            } else {
                processors.pop()
            }
        }

        return explanation
    }

    private static let sanitizationReplacements: [(String, String)] = [
        ("–", "-"),
        ("&ndash", "-"),
        ("&minus", "-"),
        ("—", "-"),
        ("&mdash", "-"),
        ("’", "\'"),
        ("&rsquo", "'"),
        ("&quot", "\""),
        ("&#39", "'"),
        ("&ldquo", "\""),
        ("&rdquo", "\""),
        ("&reg", "®")
    ]

    private static func sanitizedInnerText(_ node: Node) -> String {
        var innerText = innerText(node)

        for i in 0..<sanitizationReplacements.count {
            let replacement = sanitizationReplacements[i]
            innerText = innerText.replacingOccurrences(of: replacement.0, with: replacement.1)
        }

        return innerText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private static func innerText(_ node: Node) -> String {
        if let textNode = node as? TextNode {
            return textNode.text()
        }
        
        var text: String = ""
        for child in node.getChildNodes() {
            text += innerText(child)
        }

        return text
    }

    private class HtmlNodeProcessor {
        fileprivate let SectionHeaderName = "h2"
        fileprivate let SubsectionHeaderName = "h4"
        fileprivate let SectionTextName = "p"

        fileprivate let SectionTableName = "table"

        fileprivate let SectionListName = "ul"

        fileprivate let LinkName = "a"
        fileprivate let LinkHrefName = "href"

        public let explanation: NutrientExplanation

        public init(_ explanation: NutrientExplanation) {
            self.explanation = explanation
        }

        open func handleNode(_ processors: Stack<HtmlNodeProcessor>, _ node: Node) -> Bool {
            fatalError("Don't call this")
        }

//        public func findLinks(_ node: Node) -> [NutrientExplanation.Link] {
//            let expectedStartsWith = "https://"
//
//            var links = [NutrientExplanation.Link]()
//
//            var start = 0
//            let children = node.getChildNodes()
//            for child in children {
//                let text = sanitizedInnerText(child)
//                if (text.isEmpty) {
//                    continue
//                }
//
//                if let element = child as? Element {
//                    if (LinkName == element.tagName()) {
//                        if var url = try? element.attr(LinkHrefName) {
//                            if (url.first == "/") {
//                                var slashIndex = expectedStartsWith.count
//                                slashIndex += explanation.nihUrl.dropFirst(slashIndex).firstIndex(of: "/")?.utf16Offset(in: explanation.nihUrl) ?? 0
//                                let baseUrl = explanation.nihUrl.prefix(slashIndex)
//                                url = String(baseUrl) + url
//                            }
//
//                            links.append(NutrientExplanation.Link(
//                                url: url,
//                                text: text,
//                                start: start
//                            ))
//                        }
//                    }
//                }
//                start += text.count + 1
//            }
//
//            return links
//        }
    }

    private class MainContentProcessor : HtmlNodeProcessor {
        override func handleNode(_ processors: Stack<NutrientExplanationLoader.HtmlNodeProcessor>, _ node: Node) -> Bool {
            let tag = (node as? Element)?.tagName()
            
            if (SectionHeaderName == tag || (!explanation.sections.isEmpty && SectionTextName == tag)) {
                return foundNewSection(processors, node)
            }

            return true
        }

        private func foundNewSection(_ processors: Stack<HtmlNodeProcessor>, _ node: Node) -> Bool {
            explanation.sections.append(NutrientExplanation.Section())
            processors.push(SectionProcessor(explanation, explanation.sections.last!))
            return processors.peek().handleNode(processors, node)
        }
    }

    private class SectionProcessor : HtmlNodeProcessor {
        private var isStarted: Bool = false

        private let section: NutrientExplanation.Section
        private let isSubsection: Bool

        public init(_ explanation: NutrientExplanation, _ section: NutrientExplanation.Section, _ isSubsection: Bool = false) {
            self.section = section
            self.isSubsection = isSubsection
            super.init(explanation)
        }
        
        override func handleNode(_ processors: Stack<NutrientExplanationLoader.HtmlNodeProcessor>, _ node: Node) -> Bool {
            let tag = (node as? Element)?.tagName()
            
            if (SectionHeaderName == tag) {
                return foundHeader(node)
            }
            if (SectionTextName == tag) {
                return foundText(node)
            }
            if (SectionTableName == tag) {
                return foundTable(processors, node)
            }
            if (SectionListName == tag) {
                return foundList(processors, node)
            }
            if (SubsectionHeaderName == tag) {
                if (isSubsection) {
                    return foundHeader(node)
                } else {
                    return foundSubsection(processors, node)
                }
            }
            return true
        }

        private func foundSubsection(_ processors: Stack<HtmlNodeProcessor>, _ node: Node) -> Bool {
            section.subsections.append(NutrientExplanation.Section())
            processors.push(SectionProcessor(explanation, section.subsections.last!, true))
            return processors.peek().handleNode(processors, node)
        }

        private func foundList(_ processors: Stack<HtmlNodeProcessor>, _ node: Node) -> Bool {
            if (section.list != nil) {
                return false
            }

            section.list = NutrientExplanation.Section.BulletedList()
            let processor = ListProcessor(explanation, section.list!)
            return processor.handleNode(processors, node)
        }

        private func foundTable(_ processors: Stack<HtmlNodeProcessor>, _ node: Node) -> Bool {
            if (section.table != nil) {
                return false
            }

            section.table = NutrientExplanation.Section.SectionTable()
            let processor = TableProcessor(explanation, section.table!)
            return processor.handleNode(processors, node)
        }

        private func foundHeader(_ node: Node) -> Bool {
            if (isStarted) {
                return false
            }
            isStarted = true

            section.header = sanitizedInnerText(node)
            return true
        }

        private func foundText(_ node: Node) -> Bool {
            isStarted = true
            if (section.table != nil || section.list != nil) {
                return false
            }

            if (!section.text.isEmpty) {
                section.text += "\n\n"
            }

            section.text += sanitizedInnerText(node)
//            section.links.append(contentsOf: findLinks(node))

            return true
        }
    }

    private class TableProcessor : HtmlNodeProcessor {
        fileprivate let SectionTableHeadName = "thead"
        fileprivate let SectionTableBodyName = "tbody"
        fileprivate let SectionTableRowName = "tr"
        fileprivate let SectionTableHeadCellName = "th"
        fileprivate let SectionTableDataCellName = "td"

        private let table: NutrientExplanation.Section.SectionTable

        public init(_ explanation: NutrientExplanation, _ table: NutrientExplanation.Section.SectionTable) {
            self.table = table
            super.init(explanation)
        }

        override func handleNode(_ processors: Stack<NutrientExplanationLoader.HtmlNodeProcessor>, _ node: Node) -> Bool {
            let tag = (node as? Element)?.tagName()

            if (SectionTableName == tag) {
                return foundTable(node)
            }

            return false
        }

        private func foundTable(_ node: Node) -> Bool {
            handleNode(node)
            return true
        }

        private func handleNode(_ node: Node) {
            let headNode = node.getChildNodes().filter({ SectionTableHeadName == ($0 as? Element)?.tagName() }).first
            let bodyNode = node.getChildNodes().filter({ SectionTableBodyName == ($0 as? Element)?.tagName() }).first

            var rows = [Node]()
            rows.append(contentsOf: headNode?.getChildNodes().filter({ SectionTableRowName == ($0 as? Element)?.tagName() }) ?? [])
            rows.append(contentsOf: bodyNode?.getChildNodes().filter({ SectionTableRowName == ($0 as? Element)?.tagName() }) ?? [])

            table.rows = rows.count
            table.columns = rows[0].getChildNodes().filter({ SectionTableHeadCellName == ($0 as? Element)?.tagName() }).count

            table.cells = [NutrientExplanation.Section.SectionTable.Cell]()
            for row in rows {
                for cell in row.getChildNodes() {
                    let cellTag = (cell as? Element)?.tagName()
                    
                    if (SectionTableDataCellName == cellTag || SectionTableHeadCellName == cellTag) {
                        table.cells.append(NutrientExplanation.Section.SectionTable.Cell(
                            text: sanitizedInnerText(cell)
                        ))
                    }
                }
            }
        }
    }

    private class ListProcessor : HtmlNodeProcessor {
        fileprivate let SectionListItemName = "li"

        private let list: NutrientExplanation.Section.BulletedList

        public init(_ explanation: NutrientExplanation, _ list: NutrientExplanation.Section.BulletedList) {
            self.list = list
            super.init(explanation)
        }

        override func handleNode(_ processors: Stack<NutrientExplanationLoader.HtmlNodeProcessor>, _ node: Node) -> Bool {
            let tag = (node as? Element)?.tagName()

            if (SectionListName == tag) {
                return foundList(processors, node)
            }

            return false
        }

        private func foundList(_ processors: Stack<HtmlNodeProcessor>, _ node: Node) -> Bool {
            let itemNodes = node.getChildNodes().filter({ SectionListItemName == ($0 as? Element)?.tagName() })

            for item in itemNodes {
                let text = getItemText(item)
//                let links = findLinks(item)

                list.items.append(NutrientExplanation.Section.BulletedList.Item(
                    text: text,
//                    links: links,
                    sublist: findSublist(processors, item)
                ))
            }
            return true
        }

        private let acceptableChildren = [ "#text", "a", "em" ]

        private func getItemText(_ item: Node) -> String {
            let children = item.getChildNodes().filter { child in
                if child is TextNode {
                    return true
                }
                let tag = (child as? Element)?.tagName() ?? ""
                return acceptableChildren.contains(tag)
            }
            
            var sb = ""
            
            var endsWithOpeningPunctuation = false
            for child in children {
                let childText = sanitizedInnerText(child)
                let beginsWithPunctuation = (childText.first?.isPunctuation == true || childText.starts(with: "®"))
                if (!sb.isEmpty && !childText.isEmpty && !beginsWithPunctuation && !endsWithOpeningPunctuation) {
                    sb.append(" ")
                }
                sb.append(childText)
                endsWithOpeningPunctuation = ("(" == childText.last || "-" == childText.last)
            }

            return sb
        }

        private func findSublist(_ processors: Stack<HtmlNodeProcessor>, _ item: Node) -> NutrientExplanation.Section.BulletedList? {
            let sublistNode = item.getChildNodes().filter({ SectionListName == ($0 as? Element)?.tagName() })
            if (sublistNode.isEmpty == false) {
                let sublist = NutrientExplanation.Section.BulletedList()
                let processor = ListProcessor(explanation, sublist)
                _ = processor.handleNode(processors, sublistNode.first!)
                return sublist
            }

            return nil
        }
    }
}
