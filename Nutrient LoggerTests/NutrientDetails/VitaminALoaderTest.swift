//
//  VitaminALoaderTest.swift
//  VitaminALoaderTest
//
//  Created by Jason Vance on 9/14/21.
//


import Foundation
import Testing
import SwiftSoup

class VitaminALoaderTest {
    
    private let knownNutrient = FdcNutrientGroupMapper.NutrientNumber_VitaminA_IU
    
    private var htmlLoader: HTMLDocumentLoader!
    
    private func setupThe_Given_Phase() throws {
        let html = try readInVitaminAHtml()

        let htmlDoc = try SwiftSoup.parse(html)

        let loader = MockHTMLDocumentLoader()
        loader.doc = htmlDoc
        
        htmlLoader = loader
    }

    @Test func testRealWorldVitaminAForDisplay() async throws {
        try setupThe_Given_Phase()

        let explanation = try await NutrientExplanationLoader.loadForDisplay(knownNutrient, with: htmlLoader)

        let expected = VitaminAExplanation.preMade
        expected.sections = expected.sections.dropLast()
        #expect(expected.sections.count == explanation.sections.count)
        for i in 0..<expected.sections.count {
            let expectedSection = expected.sections[i]
            let actualSection = explanation.sections[i]
            deepAssertEquality(expectedSection, actualSection)
        }
    }

    @Test func testRealWorldVitaminA() async throws {
        try setupThe_Given_Phase()

        let explanation = try await NutrientExplanationLoader.load(knownNutrient, with: htmlLoader)

        let expected = VitaminAExplanation.preMade
        #expect(expected.sections.count == explanation.sections.count)
        for i in 0..<expected.sections.count {
            let expectedSection = expected.sections[i]
            let actualSection = explanation.sections[i]
            deepAssertEquality(expectedSection, actualSection)
        }
    }

    private func deepAssertEquality(_ expectedSection: NutrientExplanation.Section, _ actualSection: NutrientExplanation.Section) {
        #expect(expectedSection.header == actualSection.header)
        #expect(expectedSection.text == actualSection.text)
//        deepAssertEquality(expectedSection.links, actualSection.links)
        deepAssertEquality(expectedSection.list, actualSection.list)

        //Table
        if (expectedSection.table != nil) {
            #expect(expectedSection.table!.rows == actualSection.table!.rows)
            #expect(expectedSection.table!.columns == actualSection.table!.columns)
            for i in 0..<expectedSection.table!.cells.count {
                #expect(expectedSection.table!.cells[i].text == actualSection.table!.cells[i].text)
            }
        } else {
            #expect(actualSection.table == nil)
        }

        // Subsections
        if (!expectedSection.subsections.isEmpty) {
            #expect(expectedSection.subsections.count == actualSection.subsections.count)
            for i in 0..<expectedSection.subsections.count {
                let expectedSubsection = expectedSection.subsections[i]
                let actualSubsection = actualSection.subsections[i]
                deepAssertEquality(expectedSubsection, actualSubsection)
            }
        } else {
            #expect(expectedSection.subsections.isEmpty == actualSection.subsections.isEmpty)
        }
    }

//    private func deepAssertEquality(_ expectedLinks: [NutrientExplanation.Link], _ actualLinks: [NutrientExplanation.Link]) {
//        if (!expectedLinks.isEmpty) {
//            XCTAssertEqual(expectedLinks.count, actualLinks.count)
//            for i in 0..<expectedLinks.count {
//                let expectedLink = expectedLinks[i]
//                let actualLink = actualLinks[i]
//
//                XCTAssertEqual(expectedLink.text, actualLink.text)
//                XCTAssertEqual(expectedLink.url, actualLink.url)
//                XCTAssertEqual(expectedLink.start, actualLink.start)
//            }
//        } else {
//            XCTAssertEqual(expectedLinks.isEmpty, actualLinks.isEmpty)
//        }
//    }

    private func deepAssertEquality(_ expectedList: NutrientExplanation.Section.BulletedList!, _ actualList: NutrientExplanation.Section.BulletedList!) {
        if (expectedList != nil) {
            #expect(expectedList.items.count == actualList.items.count)
            for i in 0..<expectedList.items.count {
                let expectedItem = expectedList.items[i]
                let actualItem = actualList.items[i]

                #expect(expectedItem.text == actualItem.text)
//                deepAssertEquality(expectedItem.links, actualItem.links)
                deepAssertEquality(expectedItem.sublist, actualItem.sublist)
            }
        } else {
            #expect(actualList == nil)
        }
    }

    private func readInVitaminAHtml() throws -> String {
        let bundle = Bundle.init(for: VitaminALoaderTest.self)
        let url = bundle.url(forResource: "VitaminA.html", withExtension: nil)
        return try String(contentsOf: url!, encoding: .utf8)
    }
}
