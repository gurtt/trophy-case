//
//  Comparable+Extensions.swift
//  TrophyCase
//
//  Created by gurtt on 30/10/2024.
//

extension Comparable {
	/// Returns a clamped value within a specified range.
	///
	/// - Parameter range: the range to clamp the value to.
	/// - Returns: the clamped value.
	func clamped(to range: ClosedRange<Self>) -> Self {
		max(min(self, range.upperBound), range.lowerBound)
	}

	/// Mutates a value to be clamped within a specified range.
	///
	/// - Parameter range: the range to clamp the value to.
	mutating func clamp(to range: ClosedRange<Self>) { self = self.clamped(to: range) }
}
