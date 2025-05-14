//
//  Mask.swift
//  confuse
//
//  Created by ppyupp on 2024/11/2.
//

import Foundation

class Mask<Element> {
	func firstIndex(where predicate: (Element) throws -> Bool) rethrows -> Int? {
		return nil
	}

	func first(where predicate: (Element) throws -> Bool) rethrows -> Element? {
		return nil
	}

	func reversed() -> ReversedCollection<[Element]>? {
		return nil
	}

	func enumerated() -> EnumeratedSequence<[Element]>? {
		return nil
	}
}
