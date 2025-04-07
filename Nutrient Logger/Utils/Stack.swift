//
//  Stack.swift
//  Stack
//
//  Created by Jason Vance on 9/13/21.
//

import Foundation

public class Stack<Element> {
    private var items = [Element]()
    
    public init() {}
    
    public func push(_ item: Element) {
        items.append(item)
    }
    
    @discardableResult public func pop() -> Element {
        return items.removeLast()
    }
    
    public func peek() -> Element {
        return items.last!
    }
}
