//
//  Fade.swift
//  TrophyCase
//
//  Created by gurtt on 4/4/2025.
//

import PlaydateKit

final class Fade: Sprite.Sprite {
	override init() {
		lastIndex = isOpaque ? 0 : imageTable.imageCount - 1

		super.init()
		collisionsEnabled = false
		zIndex = 1999
		bounds = .screen
	}

	convenience init(isOpaque: Bool) {
		self.init()
		self.isOpaque = isOpaque
		lastIndex = isOpaque ? 0 : imageTable.imageCount - 1
	}

	override func update() {
		guard !isFinished else { return }

		if isOpaque {
			lastIndex -= 1
		} else {
			lastIndex += 1
		}
		markDirty()
	}

	override func draw(bounds _: Rect, drawRect _: Rect) {
		Graphics.drawMode = .copy
		Graphics.drawBitmap(
			imageTable[lastIndex]!,
			at: bounds.origin)
	}

	func fadeToOpaque() {
		isOpaque = true
	}

	func fadetoTransparent() {
		isOpaque = false
	}

	var isFinished: Bool {
		if isOpaque && lastIndex == 0 { return true }
		if !isOpaque && lastIndex == imageTable.imageCount - 1 { return true }

		return false
	}

	let imageTable = try! Graphics.BitmapTable(path: "fade/fade")
	var isOpaque = true
	var lastIndex: Int
}
