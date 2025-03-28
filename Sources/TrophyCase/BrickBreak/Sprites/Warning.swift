//
//  Warning.swift
//  TrophyCase
//
//  Created by gurtt on 23/3/2025.
//

import PlaydateKit

final class Warning: Sprite.Sprite {
	override init() {
		super.init()
		collisionsEnabled = false
		bounds = Rect(x: 0, y: 0, width: 400, height: 18)
		zIndex = 1000
	}

	override func update() {
		let flashFrequency = 300
		if System.currentTimeMilliseconds - lastTime >= flashFrequency {
			isOpaque.toggle()
			markDirty()
			lastTime = System.currentTimeMilliseconds
		}
	}

	override func draw(bounds _: Rect, drawRect _: Rect) {
		Graphics.drawLine(
			Line(
				start: bounds.origin.translatedBy(dx: 0, dy: 9),
				end: bounds.origin.translatedBy(dx: bounds.width, dy: 9)), lineWidth: 2, color: .black)

		guard isOpaque else { return }
		Graphics.drawMode = .copy
		Graphics.drawBitmap(
			warningImage, at: bounds.origin.translatedBy(dx: bounds.width - 22 - 5, dy: 0))
	}

	private let warningImage = try! Graphics.Bitmap(path: "BrickBreak/warning")
	private var isOpaque = true
	private var lastTime = System.currentTimeMilliseconds
}
