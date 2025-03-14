//
//  Rect+Intersection.swift
//  TrophyCase
//
//  Created by gurtt on 22/2/2025.
//

import PlaydateKit

public extension Rect {
	func intersecting(_ other: Rect) -> Rect {
		let x = max(self.x, other.x)
		let w1 = min(self.x + self.width, other.x + other.width)
		let y = max(self.y, other.y)
		let h1 = min(self.y + self.height, other.y + other.height)

		guard x < w1, y < h1 else {
			return .zero
		}

		return Rect(x: x, y: y, width: w1 - x, height: h1 - y)
	}
}
