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
		self.results =
			results.isEmpty
			? [.text(text: "Achievements are staying steady. Try playing some games!")] : results
		lastTime = Int(System.currentTimeMilliseconds)

		for result in results {
			tickerItems.append(renderItem(result, small: isSmall))
		}
	}

	// MARK: Public

	public var isSmall: Bool = false {
		didSet {
			guard !results.isEmpty else { return }

			tickerItems = []
			for result in results {
				tickerItems.append(renderItem(result, small: isSmall))
			}
		}
	}

	// MARK: Internal

	func draw(in viewBounds: Rect) {
		Graphics.pushClipRect(viewBounds)
		Graphics.drawMode = .copy

		Graphics.fillRect(viewBounds, color: .white)

		guard !tickerItems.isEmpty else { return }

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

		Graphics.popClipRect()

		Graphics.drawLine(
			Line(
				start: viewBounds.origin, end: viewBounds.origin.translatedBy(dx: viewBounds.width, dy: 0)
			), lineWidth: 1, color: .black)
		Graphics.drawLine(
			Line(
				start: viewBounds.origin.translatedBy(dx: 0, dy: viewBounds.height),
				end: viewBounds.origin.translatedBy(dx: viewBounds.width, dy: viewBounds.height)),
			lineWidth: 1, color: .black)
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
		let bitmap = Graphics.Bitmap(width: bitmapWidth, height: small ? 15 : 36, bgColor: .white)

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
				let achievement = Game.bundles[bundleIndex].achievements[achievementIndex]
				return
					"\"\(achievement.name)\" from \(bundleName): \(achievement.progress!)/\(achievement.maxProgress!)"

			case .achievementSecretUnlock(let bundleIndex, let achievementIndex, let secondsSince):
				let bundleName = Game.bundles[bundleIndex].name
				let achievementName = Game.bundles[bundleIndex].achievements[achievementIndex].name
				let timeInterval = TimeInterval(spanning: secondsSince)
				return "Secret: \"\(achievementName)\" from \(bundleName) unlocked \(timeInterval) ago"

			case .bundleProgressInterval(let bundleIndex, _):
				let bundle = Game.bundles[bundleIndex]
				let lockedAchievementsCount = bundle.achievements.count(where: { !$0.isUnlocked })
				return "\(bundle.name): \(lockedAchievementsCount) left to unlock"

			case .bundleCompletion(let bundleIndex, let secondsSince):
				return
					"\(Game.bundles[bundleIndex].name) 100% completed \(TimeInterval(spanning: secondsSince)) ago"

			case .bundleAge(let bundleIndex, _):
				return "New game: \(Game.bundles[bundleIndex].name)"

			case .text(let text):
				return text
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
			case .achievementProgressInterval(_, _, _):
				return nil  // TODO: Load the achievement icon, or default, etc.

			case .achievementSecretUnlock(_, _, _):
				return nil  // TODO: Load the achievement icon, or default, etc.

			case .bundleProgressInterval(let bundleIndex, _):
				return getBundleIcon(for: bundleIndex)

			case .bundleCompletion(let bundleIndex, _):
				return getBundleIcon(for: bundleIndex)

			case .bundleAge(let bundleIndex, _):
				return getBundleIcon(for: bundleIndex)

			case .text(_):
				return nil
		}
	}
}
