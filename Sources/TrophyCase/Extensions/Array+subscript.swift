//
//  Array+subscript.swift
//  TrophyCase
//
//  Created by gurtt on 17/1/2025.
//

extension Array {
	/// Access the elements of an array as though they were ordered by the supplied proxy.
	subscript(sort: OrderProxy, index: Array.Index) -> Element {
		get { return self[sort[index]] }
		set { self[sort[index]] = newValue }
	}
}

/// An array of indexes that represents the order of the elements in another array.
///
/// Use this type to retain the results of an expensive sort operation without modifying the original order of the array or duplicating it.
typealias OrderProxy = [Array.Index]
