//
//  StatusBar.swift
//  TrophyCase
//
//  Created by gurtt on 23/3/2025.
//

import PlaydateKit

final class StatusBar: Sprite.Sprite {
	override init() {
		super.init()
		collisionsEnabled = false
		setOpaque(true)
		bounds = Rect(x: 0, y: 0, width: 400, height: 16)
		zIndex = 1000
	}

	override func draw(bounds _: Rect, drawRect _: Rect) {
		Graphics.drawMode = .copy
		Graphics.fillRect(bounds, color: .black)

		Graphics.drawMode = .nxor
		Graphics.setFont(.roobert10Bold)
		Graphics.drawText("Ⓑ >>", at: bounds.origin.translatedBy(dx: 5, dy: 1))

		let scoreText = "Score: \(BaseView.instance?.score ?? 0)"
		let scoreWidth = Graphics.Font.roobert10Bold.getTextWidth(for: scoreText, tracking: 0)
		Graphics.drawText(
			scoreText, at: bounds.origin.translatedBy(dx: (bounds.width - Float(scoreWidth) - 5), dy: 1))
	}
}
