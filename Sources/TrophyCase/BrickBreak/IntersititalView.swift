//
//  IntersititalView.swift
//  TrophyCase
//
//  Created by gurtt on 22/3/2025.
//

import PlaydateKit

struct InterstitalView {
	static func draw() {
		Graphics.drawMode = .copy
		let bounds = Rect(x: 0, y: 0, width: 304, height: 144)
		let padding: Float = 16
		let text = "You don't have any achievements yet. Want to earn one now?"

		// Draw icon
		Graphics.drawBitmap(
			InterstitalView.image,
			at: bounds.origin.translatedBy(dx: (bounds.width / 2) - 16, dy: 0))

		// Draw text
		let textBounds = Rect(
			origin: bounds.origin.translatedBy(dx: 0, dy: 32 + padding),
			width: bounds.width, height: 50)
		Graphics.setFont(.roobert11Medium)
		Graphics.drawTextInRect(text, in: textBounds, wrap: .word, aligned: .center)
	}

	static nonisolated(unsafe) let image = try! Graphics.Bitmap(path: "trophy-tiny-huh")
}
