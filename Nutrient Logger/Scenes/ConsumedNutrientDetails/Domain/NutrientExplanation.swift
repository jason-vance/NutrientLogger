//
//  NutrientExplanation.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/6/25.
//

import Foundation

public class NutrientExplanation {
    public var nihUrl: String
    public var sections: [Section] = []
    
    public init(_ nihUrl: String) {
        self.nihUrl = nihUrl
    }

//    public class Link {
//        public var url: String
//        public var text: String
//        public var start: Int
//
//        public init(url: String, text: String, start: Int) {
//            self.url = url
//            self.text = text
//            self.start = start
//        }
//    }

    public class Section {
        public var header: String = ""
        public var text: String = ""
//        public var links = [Link]()
        public var table: SectionTable?
        public var list: BulletedList?
        public var subsections: [Section] = []
        
        public init(header: String = "", text: String = "") {
            self.header = header
            self.text = text
        }
        
        public init(header: String = "", text: String = "", table: SectionTable) {
            self.header = header
            self.text = text
            self.table = table
        }
        
        public init(header: String = "", text: String = "", list: BulletedList) {
            self.header = header
            self.text = text
            self.list = list
        }
        
        public init(header: String = "", text: String = "", subsections: [Section]) {
            self.header = header
            self.text = text
            self.subsections = subsections
        }
        
//        public init(header: String = "", text: String = "", links: [Link]) {
//            self.header = header
//            self.text = text
//            self.links = links
//        }

        public class BulletedList {
            public var items = [Item]()
            
            public init () {}

            public init(_ itemTexts: [String]) {
                items = itemTexts.map { Item($0) }
            }

            public init(_ items: [Item]) {
                self.items = items
            }

            public class Item {
                public var text: String
//                public var links = [Link]()
                public var sublist: BulletedList?
                
                public init(_ text: String) {
                    self.text = text
                }
                
                public init(text: String, sublist: BulletedList? = nil) {
                    self.text = text
                    self.sublist = sublist
                }
                
//                public init(text: String, links: [Link] = [], sublist: BulletedList? = nil) {
//                    self.text = text
//                    self.links = links
//                    self.sublist = sublist
//                }
            }
        }

        public class SectionTable {
            public var rows: Int { cells.count / columns }
            public var columns: Int = 0
            public var cells = [Cell]()

            public init() { }

            public init(_ columns: Int, _ cellContents: [String]) {
                self.columns = columns

                for i in 0..<cellContents.count {
                    let row = i / columns
                    let column = i % columns
                    cells.append(Cell(
                        row: row,
                        column: column,
                        text: cellContents[i]
                    ))
                }
            }

            public func getRow(_ row: Int) -> [Cell] {
                return Array<Cell>(cells.dropFirst(row * columns).prefix(columns))
            }

            public class Cell {
                public var row: Int
                public var column: Int
                public var text: String
                
                public init(row: Int, column: Int, text: String) {
                    self.row = row
                    self.column = column
                    self.text = text
                }
                
                convenience init(text: String) {
                    self.init(row: 0, column: 0, text: text)
                }
            }
        }
    }
}
