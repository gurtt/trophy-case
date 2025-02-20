//
//  BundleDetailHeroView.swift
//  TrophyCase
//
//  Created by gurtt on 10/11/2024.
//

import PlaydateKit

struct BundleDetailHeroView {

	// MARK: Lifecycle

	init(bundleAuthor: String, bundleDescription: String) {
		self.bundleAuthor = bundleAuthor
		self.bundleDescription = bundleDescription
	}

	// MARK: Internal

	func draw(in bounds: Rect) {
		Graphics.drawMode = .inverted
		Graphics.fillRect(bounds, color: .black)

		Graphics.setFont(.roobert10Bold)
		Graphics.drawText("by \(bundleAuthor)", at: bounds.origin.translatedBy(dx: 14, dy: 0))

		let descriptionBounds = Rect(
			x: bounds.origin.x + 14, y: bounds.origin.y + 19, width: bounds.width - 24, height: 44)
		Graphics.setFont(.roobert11Medium)
		Graphics.drawTextInRect(bundleDescription, in: descriptionBounds, wrap: .word, aligned: .left)
	}

	// MARK: Private

	private let bundleAuthor: String
	private let bundleDescription: String
}
