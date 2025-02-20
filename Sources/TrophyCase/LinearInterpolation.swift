//
//  LinearInterpolation.swift
//  TrophyCase
//
//  Created by gurtt on 4/11/2024.
//

import PlaydateKit

/// Returns the linear interpolation between the supplied numbers.
func lerp(from a: Float, to b: Float, using t: Float) -> Float { a * (1 - t) + b * t }

/// Returns the linear interpolation between the supplied rectangles.
func lerp(from a: Rect, to b: Rect, using t: Float) -> Rect {
	let x = lerp(from: a.x, to: b.x, using: t)
	let y = lerp(from: a.y, to: b.y, using: t)
	let width = lerp(from: a.width, to: b.width, using: t)
	let height = lerp(from: a.height, to: b.height, using: t)

	return Rect(x: x, y: y, width: width, height: height)
}
