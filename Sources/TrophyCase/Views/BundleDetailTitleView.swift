//
//  BundleDetailTitleView.swift
//  TrophyCase
//
//  Created by gurtt on 4/11/2024.
//

import PlaydateKit

struct BundleDetailTitleView {

	// MARK: Lifecycle

	init(bundleName: String, summaryText: String) {
		self.bundleName = bundleName
		self.summaryText = summaryText

		self.summaryWidth = Float(
			Graphics.Font.roobert11Bold.getTextWidth(for: summaryText, tracking: 0))
	}

	// MARK: Internal

	func draw(in bounds: Rect) {
		let nameRect = Rect(
			x: bounds.origin.x + 14, y: bounds.origin.y + 6,
			width: bounds.width - 14 - 14 - 6 - summaryWidth,
			height: Float(Graphics.Font.roobert11Medium.height))

		Graphics.fillRect(bounds, color: .black)

		Graphics.setFont(.roobert11Medium)
		Marquee.draw(bundleName, in: nameRect, inverted: true)

		Graphics.drawMode = .inverted
		Graphics.setFont(.roobert11Bold)
		Graphics.drawText(
			summaryText, at: bounds.origin.translatedBy(dx: bounds.width - summaryWidth - 14, dy: 6))
	}

	// MARK: Private

	private let bundleName: String
	private let summaryText: String
	private let summaryWidth: Float
}
