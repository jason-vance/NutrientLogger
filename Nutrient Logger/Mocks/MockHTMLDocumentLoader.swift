//
//  MockHtmlDocumentLoader.swift
//  MockHtmlDocumentLoader
//
//  Created by Jason Vance on 9/13/21.
//

import Foundation
import SwiftSoup

public class MockHTMLDocumentLoader: HTMLDocumentLoader {
    public var doc: Document!
    
    public func load(_ url: String) async -> Document {
        return doc
    }
}
