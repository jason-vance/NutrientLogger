//
//  HtmlDocumentLoader.swift
//  HtmlDocumentLoader
//
//  Created by Jason Vance on 9/13/21.
//

import Foundation
import SwiftSoup

// SwiftSoup's Document is not marked Sendable, but it is safe to pass across
// the Task boundary here since each call produces its own isolated instance.
extension Document: @retroactive @unchecked Sendable { }

public protocol HTMLDocumentLoader {
    func load(_ url: String) async -> Document
}

public class SwiftSoupHTMLDocumentLoader: HTMLDocumentLoader {
    public func load(_ url: String) async -> Document {
        return await Task.init(priority: .userInitiated) {
            do {
                let html = try String(contentsOf: URL(string: url)!, encoding: .utf8)
                return try SwiftSoup.parse(html)
            } catch {
                print("Error parsing html: \(error.localizedDescription)")
            }
            return Document("")
        }.value
    }
}
