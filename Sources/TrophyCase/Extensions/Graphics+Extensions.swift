//
//  Graphics+Extensions.swift
//  TrophyCase
//
//  Created by gurtt on 3/11/2024.
//

import PlaydateKit

extension Graphics {
	/// Draws a filled rectangle with rounded corners of the specified radius and color.
	static func fillRoundRect(_ rect: Rect, radius: Float = 0, color: Color = .black) {
		// let radius = min(radius, min(rect.width / 2, rect.height / 2))
		let diameter = radius * 2

		Graphics.fillEllipse(
			in: Rect(x: rect.x, y: rect.y, width: diameter, height: diameter), color: color)
		Graphics.fillEllipse(
			in: Rect(x: rect.x + rect.width - diameter, y: rect.y, width: diameter, height: diameter),
			color: color)
		Graphics.fillEllipse(
			in: Rect(
				x: rect.x + rect.width - diameter, y: rect.y + rect.height - diameter, width: diameter,
				height: diameter), color: color)
		Graphics.fillEllipse(
			in: Rect(x: rect.x, y: rect.y + rect.height - diameter, width: diameter, height: diameter),
			color: color)
		Graphics.fillRect(
			Rect(x: rect.x + radius, y: rect.y, width: rect.width - diameter, height: rect.height),
			color: color)
		Graphics.fillRect(
			Rect(x: rect.x, y: rect.y + radius, width: rect.width, height: rect.height - diameter),
			color: color)
	}

	/// Draws a filled rectangle with rounded corners of the specified radius and color.
	static func drawRoundRect(
		_ rect: Rect, lineWidth: Int = 1, radius: Float = 0, color: Color = .black
	) {
		// let radius = min(radius, min(rect.width / 2, rect.height / 2))
		let diameter = radius * 2
		let halfWidth = Float(lineWidth / 2)

		Graphics.drawEllipse(
			in: Rect(
				x: rect.x - halfWidth, y: rect.y - halfWidth, width: diameter + Float(lineWidth),
				height: diameter + Float(lineWidth)), lineWidth: lineWidth, startAngle: 270, endAngle: 360,
			color: color)
		Graphics.drawEllipse(
			in: Rect(
				x: rect.x + rect.width - diameter - halfWidth, y: rect.y - halfWidth,
				width: diameter + Float(lineWidth), height: diameter + Float(lineWidth)),
			lineWidth: lineWidth, startAngle: 0, endAngle: 90, color: color)
		Graphics.drawEllipse(
			in: Rect(
				x: rect.x + rect.width - diameter - halfWidth,
				y: rect.y + rect.height - diameter - halfWidth, width: diameter + Float(lineWidth),
				height: diameter + Float(lineWidth)), lineWidth: lineWidth, startAngle: 90, endAngle: 180,
			color: color)
		Graphics.drawEllipse(
			in: Rect(
				x: rect.x - halfWidth, y: rect.y + rect.height - diameter - halfWidth,
				width: diameter + Float(lineWidth), height: diameter + Float(lineWidth)),
			lineWidth: lineWidth, startAngle: 180, endAngle: 270, color: color)
		Graphics.drawLine(
			Line(
				start: Point(x: rect.x + radius, y: rect.y),
				end: Point(x: rect.x + rect.width - radius, y: rect.y)), lineWidth: lineWidth, color: color)
		Graphics.drawLine(
			Line(
				start: Point(x: rect.x + radius, y: rect.y + rect.height),
				end: Point(x: rect.x + rect.width - radius, y: rect.y + rect.height)), lineWidth: lineWidth,
			color: color)
		Graphics.drawLine(
			Line(
				start: Point(x: rect.x, y: rect.y + radius),
				end: Point(x: rect.x, y: rect.y + rect.height - radius)), lineWidth: lineWidth, color: color
		)
		Graphics.drawLine(
			Line(
				start: Point(x: rect.x + rect.width, y: rect.y + radius),
				end: Point(x: rect.x + rect.width, y: rect.y + rect.height - radius)), lineWidth: lineWidth,
			color: color)
	}
}
