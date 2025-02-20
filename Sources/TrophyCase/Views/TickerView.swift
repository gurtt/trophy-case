//
//  TickerView.swift
//  TrophyCase
//
//  Created by gurtt on 16/2/2025.
//

import PlaydateKit

class TickerView {
	// MARK: Lifecycle

	init(results: [AnalysisResult]) {
		self.results = results
		lastTime = Int(System.currentTimeMilliseconds)

		// TODO: Add something interesting if there's zero items
		guard results.count > 0 else { return }
		// TODO: Don't just render all of these because that might be massive. Instead render items as-needed when they enter the view
		for result in results {
			tickerItems.append(renderItem(result, small: isSmall))
		}

	}

	// MARK: Public

	// TODO: Add a didSet to trigger re-rendering all of these (or detect it in the draw call?)
	public var isSmall: Bool = false {
		didSet {
			guard results.count > 0 else { return }
			tickerItems = []
			// TODO: Don't just render all of these because that might be massive. Instead render items as-needed when they enter the view
			for result in results {
				tickerItems.append(renderItem(result, small: isSmall))
			}
		}
	}

	// MARK: Internal

	func draw(in viewBounds: Rect) {
		Graphics.setClipRect(viewBounds)
		defer {
			Graphics.clearClipRect()
		}

		Graphics.drawMode = .copy

		Graphics.fillRect(viewBounds, color: .white)
		defer {
			Graphics.drawRect(viewBounds, color: .black)
		}

		guard tickerItems.count > 0 else {
			return
		}

		// Draw ticker items
		let currentTime = Int(System.currentTimeMilliseconds)
		let deltaTime = currentTime - lastTime
		lastTime = currentTime
		let pixelsPerMs: Float = 0.025
		let paddingBetweenItems = 32

		// TODO: This float/int conversion feels silly
		// TODO: The rounding errors cause ticker items to 'wiggle'
		frontItemDisplayOffset += Float(deltaTime) * pixelsPerMs
		if Int(frontItemDisplayOffset) >= tickerItems[frontItemIndex].getData(mask: nil, data: nil)
			.width + paddingBetweenItems
		{
			// TODO: Get some kind of circular index thing here
			if frontItemIndex == tickerItems.count - 1 {
				frontItemIndex = 0
			} else {
				frontItemIndex += 1
			}
			frontItemDisplayOffset = 0
		}

		// TODO: Heads up: this doesn't account for the view not being the entire width of the screen because I know it always will be and adding the maths to account for that is annoying and unreadable
		var screenCursor = -frontItemDisplayOffset
		var indexCursor = frontItemIndex
		while Int(screenCursor) < Display.width {
			Graphics.drawBitmap(
				tickerItems[indexCursor], at: Point(x: Float(screenCursor), y: viewBounds.origin.y))
			screenCursor += Float(
				tickerItems[indexCursor].getData(mask: nil, data: nil).width + paddingBetweenItems)
			// TODO: Get some kind of circular index thing here
			if indexCursor == tickerItems.count - 1 {
				indexCursor = 0
			} else {
				indexCursor += 1
			}
		}
	}

	// MARK: Private
	private let results: [AnalysisResult]
	private var tickerItems: [Graphics.Bitmap] = []
	private var frontItemDisplayOffset: Float = 0
	private var frontItemIndex: Array.Index = 0
	private var lastTime: Int

	private func renderItem(_ result: AnalysisResult, small: Bool) -> Graphics.Bitmap {
		let text = getText(for: result)

		let font: Graphics.Font = small ? .roobert10Bold : .roobert11Medium
		Graphics.setFont(font)
		let textWidth = font.getTextWidth(for: text, tracking: 0)

		// TODO: If appropriate, get the bitmap for the result
		// TODO: Instead of checking eligibility for the bitmap at every site, do this at decode time somehow

		let icon = small ? nil : getIcon(for: result)

		let bitmapWidth = textWidth + ((icon != nil) ? 32 + 8 : 0)
		var bitmap = Graphics.Bitmap(width: bitmapWidth, height: small ? 15 : 36, bgColor: .white)

		Graphics.pushContext(bitmap)
		defer { Graphics.popContext() }
		if icon != nil {
			Graphics.drawBitmap(icon!, at: Point(x: 0, y: 2))
		}
		Graphics.drawText(text, at: Point(x: ((icon != nil) ? 32 + 8 : 0), y: small ? 0 : 7))

		return bitmap
	}

	private func getText(for result: AnalysisResult) -> String {
		switch result {
			case .achievementProgressInterval(let bundleIndex, let achievementIndex, _):
				let bundleName = Game.bundles[bundleIndex].name
				let achievementName = Game.bundles[bundleIndex].achievements[achievementIndex].name
				return "\"\(achievementName)\" from \(bundleName): z/a"  // TODO: Actually calculate achievement thing

			case .achievementSecretUnlock(let bundleIndex, let achievementIndex, let secondsSince):
				let bundleName = Game.bundles[bundleIndex].name
				let achievementName = Game.bundles[bundleIndex].achievements[achievementIndex].name
				let timeInterval = TimeInterval(spanning: secondsSince)
				return "Secret: \"\(achievementName)\" from \(bundleName) unlocked \(timeInterval) ago"

			case .bundleProgressInterval(let bundleIndex, _):
				let bundleName = Game.bundles[bundleIndex].name
				let lockedAchievementsCount = 0  // TODO: Actually calculate this or change the verbiage
				return "\(bundleName): \(lockedAchievementsCount) left to unlock"

			case .bundleCompletion(let bundleIndex, let secondsSince):
				return
					"\(Game.bundles[bundleIndex].name) 100% completed \(TimeInterval(spanning: secondsSince)) ago"

			case .bundleAge(let bundleIndex, _):
				return "New game: \(Game.bundles[bundleIndex].name)"
		}
	}

	private func getIcon(for result: AnalysisResult) -> Graphics.Bitmap? {
		func getBundleIcon(for index: Array.Index) -> Graphics.Bitmap? {
			guard let iconPath = Game.bundles[index].iconPath else {
				return Game.defaultListIconImage
			}
			do {
				let image = Graphics.Bitmap(width: 32, height: 32)
				try image.load(from: iconPath)

				return image
			} catch {
				return Game.defaultListIconImage
			}
		}

		switch result {
			case .achievementProgressInterval(let bundleIndex, let achievementIndex, let progressInterval):
				return nil  // TODO: Load the achievement icon, or default, etc.

			case .achievementSecretUnlock(let bundleIndex, let achievementIndex, let secondsSince):
				return nil  // TODO: Load the achievement icon, or default, etc.

			case .bundleProgressInterval(let bundleIndex, let progressInterval):
				return getBundleIcon(for: bundleIndex)

			case .bundleCompletion(let bundleIndex, let secondsSince):
				return getBundleIcon(for: bundleIndex)

			case .bundleAge(let bundleIndex, let age):
				return getBundleIcon(for: bundleIndex)
		}
	}
}
