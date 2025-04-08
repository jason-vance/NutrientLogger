//
//  NutrientExplanationLoaderTests.swift
//  NutrientExplanationLoaderTests
//
//  Created by Jason Vance on 9/13/21.
//

import Testing
import SwiftSoup

class NutrientExplanationLoaderTests {
    
    private let knownNutrient = FdcNutrientGroupMapper.NutrientNumber_VitaminA_IU
    
    private var loader = MockHTMLDocumentLoader()
    
    @Test func testExtractHeaderAndText() async throws {
        let html = """
        <body
            <div class='center' id='center_content'>
                <h2 id='h1'>What is vitamin A and what does it do?</h2>
                <p>Vitamin A is a fat-soluble vitamin that is naturally present in many foods.</p>
            </div>
        </body>"
        """
        loader.doc = try SwiftSoup.parse(html)

        let explanation = try await NutrientExplanationLoader.load(knownNutrient, with: loader)

        #expect(1 == explanation.sections.count)
        let section = explanation.sections[0]
        #expect("What is vitamin A and what does it do?" == section.header)
        #expect("Vitamin A is a fat-soluble vitamin that is naturally present in many foods." == section.text)
    }
    
    @Test func testExtractHeaderAndTextWithParentheses() async throws {
        let html = """
        <body
            <div class='center' id='center_content'>
                <h2>Age-Related Macular Degeneration</h2>
                <p>Age-related macular degeneration (AMD), or the loss of central vision as people age, is one of the most common causes of vision loss in older people. Among people with AMD who are at high risk of developing advanced AMD, a supplement containing antioxidants, zinc, and copper with or without beta-carotene has shown promise for slowing down the rate of vision loss.</p>
            </div>
        </body>"
        """
        loader.doc = try SwiftSoup.parse(html)

        let explanation = try await NutrientExplanationLoader.load(knownNutrient, with: loader)

        #expect(1 == explanation.sections.count)
        let section = explanation.sections[0]
        #expect("Age-Related Macular Degeneration" == section.header)
        #expect("Age-related macular degeneration (AMD), or the loss of central vision as people age, is one of the most common causes of vision loss in older people. Among people with AMD who are at high risk of developing advanced AMD, a supplement containing antioxidants, zinc, and copper with or without beta-carotene has shown promise for slowing down the rate of vision loss." == section.text)
    }
    
    @Test func testExtractHeaderAndTextWithComplexHTML() async throws {
        let html = """
        <body
            <div class='center' id='center_content'>
                <h2>Age-Related Macular Degeneration</h2>
                <ul>
                    <li>Orlistat (Alli&reg;, Xenical&reg;), a weight-loss drug, can decrease the <a href="#" onClick="showTerm('/factsheets/showterm.aspx?tID=255')" class="fscopy">absorption</a> of vitamin A, causing low blood levels in some people.</li>
                    <li>Several synthetic forms of vitamin A are used in <a href="#" onClick="showTerm('/factsheets/showterm.aspx?tID=409')" class="fscopy">prescription</a> medicines. Examples are the <a href="#" onClick="showTerm('/factsheets/showterm.aspx?tID=329')" class="fscopy">psoriasis</a> treatment acitretin (Soriatane&reg;) and bexarotene (Targretin&reg;), used to treat the skin effects of T-<a href="#" onClick="showTerm('/factsheets/showterm.aspx?tID=205')" class="fscopy">cell</a> lymphoma. Taking these medicines in combination with a vitamin A supplement can cause dangerously high levels of vitamin A in the blood.</li>
                </ul>
            </div>
        </body>"
        """
        loader.doc = try SwiftSoup.parse(html)

        let explanation = try await NutrientExplanationLoader.load(knownNutrient, with: loader)

        #expect(1 == explanation.sections.count)
        let section = explanation.sections[0]
        #expect("Age-Related Macular Degeneration" == section.header)
        #expect(section.list != nil)
        let list = section.list!
        #expect(2 == list.items.count)
        #expect("Orlistat (Alli®, Xenical®), a weight-loss drug, can decrease the absorption of vitamin A, causing low blood levels in some people." == list.items[0].text)
        #expect("Several synthetic forms of vitamin A are used in prescription medicines. Examples are the psoriasis treatment acitretin (Soriatane®) and bexarotene (Targretin®), used to treat the skin effects of T-cell lymphoma. Taking these medicines in combination with a vitamin A supplement can cause dangerously high levels of vitamin A in the blood." == list.items[1].text)
    }
    
    @Test func testIgnoresComments() async throws {
        let html = """
        <body
            <div class='center' id='center_content'>
                <h2 id='h1'>What is vitamin A and what does it do?</h2>
                <!-- docid = 5066 -->
                <p>Vitamin A is a fat-soluble vitamin that is naturally present in many foods.</p>
            </div>
        </body>"
        """
        loader.doc = try SwiftSoup.parse(html)

        let explanation = try await NutrientExplanationLoader.load(knownNutrient, with: loader)

        #expect(1 == explanation.sections.count)
        let section = explanation.sections[0]
        #expect("What is vitamin A and what does it do?" == section.header)
        #expect("Vitamin A is a fat-soluble vitamin that is naturally present in many foods." == section.text)
    }
    
    @Test func testExtractsHeaderAndMultilineText() async throws {
        let html = """
        <body
            <div class='center' id='center_content'>
                <h2 id='h1'>What is vitamin A and what does it do?</h2>
                <p>Vitamin A is a fat-soluble vitamin that is naturally present in many foods.</p>
                <p>There are two different types of vitamin A.</p>
            </div>
        </body>"
        """
        loader.doc = try SwiftSoup.parse(html)

        let explanation = try await NutrientExplanationLoader.load(knownNutrient, with: loader)

        #expect(1 == explanation.sections.count)
        let section = explanation.sections[0]
        #expect("What is vitamin A and what does it do?" == section.header)
        #expect("Vitamin A is a fat-soluble vitamin that is naturally present in many foods.\n\nThere are two different types of vitamin A." == section.text)
    }
    
    @Test func testExtractsMultipleSections() async throws {
        let html = """
        <body
            <div class='center' id='center_content'>
                <h2 id='h1'>What is vitamin A and what does it do?</h2>
                <p>Vitamin A is a fat-soluble vitamin that is naturally present in many foods.</p>
                <p>There are two different types of vitamin A.</p>
                <!-- docid = 5066 -->
                <h2 id='h2'>What is vitamin A and what does it do?</h2>
                <p>Vitamin A is a fat-soluble vitamin that is naturally present in many foods.</p>
            </div>
        </body>
        """
        loader.doc = try SwiftSoup.parse(html)

        let explanation = try await NutrientExplanationLoader.load(knownNutrient, with: loader)

        #expect(2 == explanation.sections.count)
        let firstSection = explanation.sections[0]
        #expect("What is vitamin A and what does it do?" == firstSection.header)
        #expect("Vitamin A is a fat-soluble vitamin that is naturally present in many foods.\n\nThere are two different types of vitamin A." == firstSection.text)
        let secondSection = explanation.sections[1]
        #expect("What is vitamin A and what does it do?" == secondSection.header)
        #expect("Vitamin A is a fat-soluble vitamin that is naturally present in many foods." == secondSection.text)
    }
    
    @Test func testExtractsTable() async throws {
        let html = """
        <body
            <div class='center' id='center_content'>
                <h2 id='h1'>What is vitamin A and what does it do?</h2>
                <table border='1'>
                    <thead>
                        <tr>
                            <th scope='col'>Life Stage</th>
                            <th scope='col'>Recommended Amount</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr>
                            <td scope='row'>Birth to 6 months</td>
                            <td align='right'>400 mcg RAE</td>
                        </tr>
                        <tr>
                            <td scope='row'>Infants 7–12 months</td>
                            <td align='right'>500 mcg RAE</td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </body>
        """
        loader.doc = try SwiftSoup.parse(html)

        let explanation = try await NutrientExplanationLoader.load(knownNutrient, with: loader)

        #expect(1 == explanation.sections.count)
        let section = explanation.sections[0]
        #expect("What is vitamin A and what does it do?" == section.header)
        #expect(section.table != nil)
        let table = section.table!
        #expect(3 == table.rows)
        #expect(2 == table.columns)
        #expect(6 == table.cells.count)
        #expect("Life Stage" == table.cells[0].text)
        #expect("Recommended Amount" == table.cells[1].text)
        #expect("Birth to 6 months" == table.cells[2].text)
        #expect("400 mcg RAE" == table.cells[3].text)
        #expect("Infants 7-12 months" == table.cells[4].text)
        #expect("500 mcg RAE" == table.cells[5].text)
    }
    
    @Test func testExtractsList() async throws {
        let html = """
        <body
            <div class='center' id='center_content'>
                <h2 id='h1'>What is vitamin A and what does it do?</h2>
                <ul>
                    <li>Beef liver and other organ meats (but these foods are also high in cholesterol, so limit the amount you eat).</li>
                    <li>Some types of fish, such as salmon.</li>
                    <li>Green leafy vegetables and other green, orange, and yellow vegetables, such as broccoli, carrots, and squash.</li>
                </ul>
            </div>
        </body>
        """
        loader.doc = try SwiftSoup.parse(html)

        let explanation = try await NutrientExplanationLoader.load(knownNutrient, with: loader)

        #expect(1 == explanation.sections.count)
        let section = explanation.sections[0]
        #expect("What is vitamin A and what does it do?" == section.header)
        #expect(section.list != nil)
        let list = section.list!
        #expect(3 == list.items.count)
        #expect("Beef liver and other organ meats (but these foods are also high in cholesterol, so limit the amount you eat)." == list.items[0].text)
        #expect("Some types of fish, such as salmon." == list.items[1].text)
        #expect("Green leafy vegetables and other green, orange, and yellow vegetables, such as broccoli, carrots, and squash." == list.items[2].text)
    }
    
    @Test func testExtractsSublist() async throws {
        let html = """
        <body
            <div class='center' id='center_content'>
                <h2 id='h1'>What is vitamin A and what does it do?</h2>
                <ul>
                    <li>
                        For more information on vitamin A:
                        <ul>
                            <li>Office of Dietary Supplements</li>
                            <li>Vitamin A</li>
                        </ul>
                    </li>
                    <li>
                        For more information on food sources of vitamin A:
                    </li>
                </ul>
            </div>
        </body>
        """
        loader.doc = try SwiftSoup.parse(html)

        let explanation = try await NutrientExplanationLoader.load(knownNutrient, with: loader)

        #expect(1 == explanation.sections.count)
        let section = explanation.sections[0]
        #expect("What is vitamin A and what does it do?" == section.header)
        #expect(section.list != nil)
        let list = section.list!
        #expect(2 == list.items.count)
        var item = list.items[0]
        #expect("For more information on vitamin A:" == item.text)
        #expect(item.sublist != nil)
        let sublist = item.sublist!
        #expect(2 == sublist.items.count)
        #expect("Office of Dietary Supplements" == sublist.items[0].text)
        #expect("Vitamin A" == sublist.items[1].text)
        item = list.items[1]
        #expect("For more information on food sources of vitamin A:" == item.text)
    }
    
    @Test func testExtractsSubsection() async throws {
        let html = """
        <body
            <div class='center' id='center_content'>
                <h2 id='h1'>What is vitamin A and what does it do?</h2>
                <h4>Cancer</h4>
                <p>People who eat a lot of <em>foods</em> containing beta-carotene might have a lower risk of certain kinds of cancer, such as lung cancer or prostate cancer. But studies to date have not shown that vitamin A or beta-carotene <em>supplements</em> can help prevent cancer or lower the chances of dying from this disease. In fact, studies show that smokers who take high doses of beta-carotene supplements have an <em>increased</em> risk of lung cancer.</p>
                <h4>Measles</h4>
                <p>When children with vitamin A deficiency (which is rare in North America) get measles, the disease tends to be more severe. In these children, taking supplements with high doses of vitamin A can shorten the fever and diarrhea caused by measles. These supplements can also lower the risk of death in children with measles who live in developing countries where vitamin A deficiency is common.</p>
            </div>
        </body>
        """
        loader.doc = try SwiftSoup.parse(html)

        let explanation = try await NutrientExplanationLoader.load(knownNutrient, with: loader)

        #expect(1 == explanation.sections.count)
        let section = explanation.sections[0]
        #expect("What is vitamin A and what does it do?" == section.header)
        #expect(section.text.isEmpty)
        #expect(2 == section.subsections.count)
        var subsection = section.subsections[0]
        #expect("Cancer" == subsection.header)
        #expect("People who eat a lot of foods containing beta-carotene might have a lower risk of certain kinds of cancer, such as lung cancer or prostate cancer. But studies to date have not shown that vitamin A or beta-carotene supplements can help prevent cancer or lower the chances of dying from this disease. In fact, studies show that smokers who take high doses of beta-carotene supplements have an increased risk of lung cancer." == subsection.text)
        subsection = section.subsections[1]
        #expect("Measles" == subsection.header)
        #expect("When children with vitamin A deficiency (which is rare in North America) get measles, the disease tends to be more severe. In these children, taking supplements with high doses of vitamin A can shorten the fever and diarrhea caused by measles. These supplements can also lower the risk of death in children with measles who live in developing countries where vitamin A deficiency is common." == subsection.text)
    }
    
    @Test func testDetectsNewSectionAfterSubsection() async throws {
        let html = """
        <body
            <div class='center' id='center_content'>
                <h2 id='h1'>What is vitamin A and what does it do?</h2>
                <h4>Cancer</h4>
                <p>People who eat a lot of <em>foods</em> containing beta-carotene might have a lower risk of certain kinds of cancer, such as lung cancer or prostate cancer. But studies to date have not shown that vitamin A or beta-carotene <em>supplements</em> can help prevent cancer or lower the chances of dying from this disease. In fact, studies show that smokers who take high doses of beta-carotene supplements have an <em>increased</em> risk of lung cancer.</p>
                <h4>Measles</h4>
                <p>When children with vitamin A deficiency (which is rare in North America) get measles, the disease tends to be more severe. In these children, taking supplements with high doses of vitamin A can shorten the fever and diarrhea caused by measles. These supplements can also lower the risk of death in children with measles who live in developing countries where vitamin A deficiency is common.</p>
                <h2 id='h2'>New Section</h2>
            </div>
        </body>
        """
        loader.doc = try SwiftSoup.parse(html)

        let explanation = try await NutrientExplanationLoader.load(knownNutrient, with: loader)

        #expect(2 == explanation.sections.count)
        var section = explanation.sections[0]
        #expect("What is vitamin A and what does it do?" == section.header)
        #expect(section.text.isEmpty)
        #expect(2 == section.subsections.count)
        var subsection = section.subsections[0]
        #expect("Cancer" == subsection.header)
        #expect("People who eat a lot of foods containing beta-carotene might have a lower risk of certain kinds of cancer, such as lung cancer or prostate cancer. But studies to date have not shown that vitamin A or beta-carotene supplements can help prevent cancer or lower the chances of dying from this disease. In fact, studies show that smokers who take high doses of beta-carotene supplements have an increased risk of lung cancer." == subsection.text)
        subsection = section.subsections[1]
        #expect("Measles" == subsection.header)
        #expect("When children with vitamin A deficiency (which is rare in North America) get measles, the disease tends to be more severe. In these children, taking supplements with high doses of vitamin A can shorten the fever and diarrhea caused by measles. These supplements can also lower the risk of death in children with measles who live in developing countries where vitamin A deficiency is common." == subsection.text)
        section = explanation.sections[1]
        #expect("New Section" == section.header)
    }
    
    @Test func testDetectsNewSectionTextAfterTable() async throws {
        let html = """
        <body
            <div class='center' id='center_content'>
                <h2 id='h1'>What is vitamin A and what does it do?</h2>
                <table border='1'>
                    <thead>
                        <tr>
                            <th scope='col'>Life Stage</th>
                            <th scope='col'>Recommended Amount</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr>
                            <td scope='row'>Birth to 6 months</td>
                            <td align='right'>400 mcg RAE</td>
                        </tr>
                        <tr>
                            <td scope='row'>Infants 7–12 months</td>
                            <td align='right'>500 mcg RAE</td>
                        </tr>
                    </tbody>
                </table>
                <p>New section text</p>
            </div>
        </body>
        """
        loader.doc = try SwiftSoup.parse(html)

        let explanation = try await NutrientExplanationLoader.load(knownNutrient, with: loader)

        #expect(2 == explanation.sections.count)
        let secondSection = explanation.sections[1]
        #expect(secondSection.header.isEmpty)
        #expect("New section text" == secondSection.text)
    }
    
    @Test func testDetectsNewSectionsAfterList() async throws {
        let html = """
        <body
            <div class='center' id='center_content'>
                <h2 id='h1'>What is vitamin A and what does it do?</h2>
                <ul>
                    <li>Beef liver and other organ meats (but these foods are also high in cholesterol, so limit the amount you eat).</li>
                    <li>Some types of fish, such as salmon.</li>
                    <li>Green leafy vegetables and other green, orange, and yellow vegetables, such as broccoli, carrots, and squash.</li>
                </ul>
                <p>New section text</p>
                <h2 id='h2'>Third section</h2>
            </div>
        </body>
        """
        loader.doc = try SwiftSoup.parse(html)

        let explanation = try await NutrientExplanationLoader.load(knownNutrient, with: loader)

        #expect(3 == explanation.sections.count)
        let secondSection = explanation.sections[1]
        #expect(secondSection.header.isEmpty)
        #expect("New section text" == secondSection.text)
        let thirdSection = explanation.sections[2]
        #expect("Third section" == thirdSection.header)
        #expect(thirdSection.text.isEmpty)
    }
    
    @Test func testExtractsItalicizedTextInLists() async throws {
        let html = """
        <body
            <div class='center' id='center_content'>
                <h2 id='h1'>What is vitamin A and what does it do?</h2>
                <ul>
                    <li>Chloramphenicol (<em>Chloromycetin</em>®), an antibiotic that is used to treat certain infections.</li>
                </ul>
            </div>
        </body>
        """
        loader.doc = try SwiftSoup.parse(html)

        let explanation = try await NutrientExplanationLoader.load(knownNutrient, with: loader)

        let item = explanation.sections[0].list!.items[0]
        #expect("Chloramphenicol (Chloromycetin®), an antibiotic that is used to treat certain infections." == item.text)
    }
    
//    @Test func testDetectsLinkInSectionText() async throws {
//        let html = """
//        <body
//            <div class='center' id='center_content'>
//                <h2 id='h1'>New section</h2>
//                <p>New section text <a href='www.food.com'>food</a> or by <a href='www.content.com'>content</a></p>
//            </div>
//        </body>
//        """
//        loader.doc = try SwiftSoup.parse(html)
//
//        let explanation = try await NutrientExplanationLoader.load(knownNutrient, with: loader)
//
//        #expect(1, explanation.sections.count)
//        let section = explanation.sections[0]
//        #expect("New section", section.header)
//        #expect("New section text food or by content", section.text)
//        #expect(2, section.links.count)
//        var link = section.links[0]
//        #expect("www.food.com", link.url)
//        #expect("food", link.text)
//        #expect(17, link.start)
//        link = section.links[1]
//        #expect("www.content.com", link.url)
//        #expect("content", link.text)
//        #expect(28, link.start)
//    }
    
//    @Test func testDetectsLinkInSectionText2() async throws {
//        let html = """
//        <body
//            <div class='center' id='center_content'>
//                <h2 id="h10">Vitamin A and healthful eating</h2>
//
//                <p>People should get most of their nutrients from food and beverages, according to the federal government’s <em>Dietary Guidelines for Americans.</em> Foods contain vitamins, minerals, dietary fiber and other components that benefit health. In some cases, fortified foods and dietary supplements are useful when it is not possible to meet needs for one or more nutrients (e.g., during specific life stages such as pregnancy). For more information about building a healthy dietary pattern, see the <a href="https://www.dietaryguidelines.gov" target="external"><em>Dietary Guidelines for Americans</em></a><a href="/About/exit_disclaimer.aspx" title="External Website"><img src="/images/Common/externallink.png" height="12" width="12" alt="external link disclaimer" class="externallink"></a> and the U.S. Department of Agriculture’s <a href="http://www.choosemyplate.gov/" target="external">MyPlate</a><a href="/About/exit_disclaimer.aspx" title="External Website"><img src="/images/Common/externallink.png" height="12" width="12" alt="external link disclaimer" class="externallink"></a>.</p>
//            </div>
//        </body>
//        """
//        loader.doc = try SwiftSoup.parse(html)
//
//        let explanation = try await NutrientExplanationLoader.load(knownNutrient, with: loader)
//
//        #expect(1, explanation.sections.count)
//        let section = explanation.sections[0]
//        #expect("Vitamin A and healthful eating", section.header)
//        #expect("People should get most of their nutrients from food and beverages, according to the federal government's Dietary Guidelines for Americans. Foods contain vitamins, minerals, dietary fiber and other components that benefit health. In some cases, fortified foods and dietary supplements are useful when it is not possible to meet needs for one or more nutrients (e.g., during specific life stages such as pregnancy). For more information about building a healthy dietary pattern, see the Dietary Guidelines for Americans and the U.S. Department of Agriculture's MyPlate.", section.text)
//        #expect(2, section.links.count)
//        var link = section.links[0]
//        #expect("https://www.dietaryguidelines.gov", link.url)
//        #expect("Dietary Guidelines for Americans", link.text)
//        #expect(485, link.start)
//        link = section.links[1]
//        #expect("http://www.choosemyplate.gov/", link.url)
//        #expect("MyPlate", link.text)
//        #expect(559, link.start)
//    }
    
//    @Test func testDetectsLinkInListText() async throws {
//        let html = """
//        <body
//            <div class='center' id='center_content'>
//                <h2 id='h1'>New section</h2>
//                <ul>
//                    <li>
//                        List item text <a href='www.food.com'>food</a></a>
//                        <ul>
//                            <li>Office of Dietary Supplements</li>
//                            <li><a href='www.vitamina.com'>Vitamin A</a></li>
//                        </ul>
//                    </li>
//                </ul>
//            </div>
//        </body>
//        """
//        loader.doc = try SwiftSoup.parse(html)
//
//        let explanation = try await NutrientExplanationLoader.load(knownNutrient, with: loader)
//
//        #expect(1, explanation.sections.count)
//        let list = explanation.sections[0].list
//        XCTAssertNotNil(list)
//        #expect(1, list!.items.count)
//        let item = list!.items[0]
//        #expect("List item text food", item.text)
//        #expect(1, item.links.count)
//        var link = item.links[0]
//        #expect("www.food.com", link.url)
//        #expect("food", link.text)
//        #expect(15, link.start)
//        let sublist = item.sublist
//        XCTAssertNotNil(sublist)
//        #expect(2, sublist!.items.count)
//        let subItem = sublist!.items[1]
//        #expect("Vitamin A", subItem.text)
//        #expect(1, subItem.links.count)
//        link = subItem.links[0]
//        #expect("www.vitamina.com", link.url)
//        #expect("Vitamin A", link.text)
//        #expect(0, link.start)
//    }
}
