//
//  IntersititalView.swift
//  TrophyCase
//
//  Created by gurtt on 22/3/2025.
//

import PlaydateKit

struct InterstitalView {

	func draw() {
		Graphics.drawMode = .copy
		let xMargin = 32
		let yMargin = 32
		let bounds = Rect(
			x: xMargin, y: yMargin, width: Display.width - (xMargin * 2),
			height: Display.height - (yMargin * 2))
		let padding: Float = 16
		let text = "You don't have any achievements yet. Want to earn one now?"
		let actionText = "Ⓐ OK"

		// Draw backing
		Graphics.fillRoundRect(bounds, radius: 3, color: .white)
		Graphics.drawRoundRect(bounds, lineWidth: 3, radius: 3, color: .black)

		// Draw icon
		Graphics.drawBitmap(
			InterstitalView.image,
			at: bounds.origin.translatedBy(dx: (bounds.width / 2) - 16, dy: padding))

		// Draw text
		let textBounds = Rect(
			origin: bounds.origin.translatedBy(dx: padding, dy: padding + 32 + padding),
			width: bounds.width - (padding * 2), height: bounds.height - (padding * 3) - 32)
		Graphics.setFont(.roobert11Medium)
		Graphics.drawTextInRect(text, in: textBounds, wrap: .word, aligned: .center)

		// Draw action
		let actionWidth: Float = 107
		let actionHeight: Float = 38
		let actionBounds = Rect(
			x: bounds.origin.x + (bounds.width / 2) - (actionWidth / 2),
			y: bounds.origin.y + bounds.height - padding - actionHeight, width: actionWidth,
			height: actionHeight)
		Graphics.fillRoundRect(actionBounds, radius: 3, color: .black)
		Graphics.drawMode = .nxor
		Graphics.drawTextInRect(
			actionText,
			in: actionBounds.translatedBy(
				dx: 0, dy: Float(actionBounds.height / 2) - Float(Graphics.Font.roobert11Medium.height / 2)),
			wrap: .word, aligned: .center)
	}

	static nonisolated(unsafe) let image = try! Graphics.Bitmap(path: "trophy-tiny-huh")
}
