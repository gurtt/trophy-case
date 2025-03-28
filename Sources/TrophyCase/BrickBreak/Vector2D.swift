//
//  Vector2D.swift
//  TrophyCase
//
//  Created by gurtt on 22/3/2025.
//

import PlaydateKit

typealias Vector2D = SIMD2<Float>

extension Vector2D {
	init(radius: Float, theta: Float) {
		self = .init(radius * cosf(theta), radius * sinf(theta))
	}

	init(_ point: Point) {
		self = .init(point.x, point.y)
	}

	func reflected(along normal: Self) -> Self {
		self - (2 * (self • normal)) * normal
	}

	mutating func reflect(along normal: Self) {
		self = self.reflected(along: normal)
	}

	func rotated(by theta: Float) -> Self {
		.init(
			x: self.x * cosf(theta) + self.y * -sinf(theta),
			y: self.x * sinf(theta) + self.y * +cosf(theta))
	}

	mutating func rotate(by theta: Float) {
		self = self.rotated(by: theta)
	}
}

infix operator • : MultiplicationPrecedence

extension Vector2D {
	static func • (lhs: Self, rhs: Self) -> Float {
		(lhs.x * rhs.x) + (lhs.y * rhs.y)
	}
}
