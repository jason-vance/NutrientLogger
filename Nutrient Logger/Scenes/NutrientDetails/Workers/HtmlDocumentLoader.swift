//
//  HtmlDocumentLoader.swift
//  HtmlDocumentLoader
//
//  Created by Jason Vance on 9/13/21.
//

import Foundation
import SwiftSoup

public protocol HTMLDocumentLoader {
    func load(_ url: String) async -> Document
}

public class SwiftSoupHTMLDocumentLoader: HTMLDocumentLoader {
    public func load(_ url: String) async -> Document {
        return await Task.init(priority: .userInitiated) {
            do {
                let html = try String(contentsOf: URL(string: url)!)
                return try SwiftSoup.parse(html)
            } catch {
                print("Error parsing html: \(error.localizedDescription)")
            }
            return Document("")
        }.value
    }
}
