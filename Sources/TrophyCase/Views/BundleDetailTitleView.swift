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
		Graphics.drawMode = .inverted
		Graphics.fillRect(bounds, color: .black)

		Graphics.setFont(.roobert11Medium)
		Graphics.drawText(bundleName, at: bounds.origin.translatedBy(dx: 14, dy: 6))

		Graphics.setFont(.roobert11Bold)
		Graphics.drawText(
			summaryText, at: bounds.origin.translatedBy(dx: bounds.width - summaryWidth - 14, dy: 6))
	}

	// MARK: Private

	private let bundleName: String
	private let summaryText: String
	private let summaryWidth: Float
}
