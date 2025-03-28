//
//  BundleDetailView.swift
//  TrophyCase
//
//  Created by gurtt on 14/1/2025.
//

import PlaydateKit

final class BundleDetailView: Navigable {

	// MARK: Lifecycle

	/// - Parameters:
	///   - bundleIndex: The unsorted index of the bundle this view details.
	///   - transitionRect: The rectangle from which this view's transition animation should start.
	init(for bundleIndex: Int, from transitionRect: Rect) {
		self.bundleIndex = bundleIndex
		let bundle = Game.bundles[bundleIndex]

		transitionStartRect = transitionRect

		// Only show icons if (a) some achievements have an icon and there's a default for the rest, or (b) all achievements have an icon
		let achievementsWithIcons = bundle.achievements.count(where: { $0.iconPath != nil })
		if achievementsWithIcons == bundle.achievements.count {
			defaultAchievementIcon = nil
			showIcons = true

			log(
				"Showing achievement icons for bundle \"\(bundle.name)\" because all achievements have icons"
			)
		} else if achievementsWithIcons > 0, let defaultIconPath = bundle.defaultIconPath {
			do {
				defaultAchievementIcon = try Graphics.Bitmap(
					path: "/Shared/Achievements/\(bundle.id)/AchievementImages/\(defaultIconPath)")
				showIcons = true

				log(
					"Showing achievement icons for bundle \"\(bundle.name)\" because some achievements have icons and a default icon was loaded"
				)
			} catch {
				defaultAchievementIcon = nil
				showIcons = false
				log("Couldn't load default icon image at \"\(defaultIconPath)\": \(error)")

				log(
					"Hiding achievement icons for bundle \"\(bundle.name)\" because some achievements have icons but an error occured while loading the default icon"
				)
			}
		} else {
			defaultAchievementIcon = nil
			showIcons = false

			log(
				"Hiding achievement icons for bundle \"\(bundle.name)\" because no achievements have icons")
		}

		orderProxy = BundleDetailView.getOrderProxy(for: sortOrder, in: bundleIndex)
		hiddenAchievementsCount = bundle.achievements.count - orderProxy.count

		let totalItems = orderProxy.count + (hiddenAchievementsCount > 0 ? 1 : 0)

		titleView = BundleDetailTitleView(
			bundleName: bundle.name,
			summaryText:
				"\(bundle.achievements.filter({ $0.isUnlocked }).count)/\(bundle.achievements.count)")

		heroView = BundleDetailHeroView(
			bundleAuthor: bundle.author, bundleDescription: bundle.description)

		if Game.preferences.bundlesViewMode == .cards && bundle.cardPath != nil {
			bundleCardImage = BundleDetailView.loadBundleCardImage(at: bundle.cardPath!)
		}

		listView = ListView(
			drawItem: { (_, _, _) in }, totalItems: totalItems, itemHeight: (showIcons ? 92 : 83),
			itemHorizontalSpacing: 8, itemVerticalSpacing: 10,
			backgroundImage: try! Graphics.Bitmap(path: "list-bg"))
		listView.drawItem = drawListItem
		listView.selectedItemIndex = 0

		heroViewAnimationController.skip(to: .start)
		timeDisplayPreAnimationController.skip(to: .start)
		timeDisplayPreAnimationController.endCallback = { [self] in
			Game.preferences.showFullTime.toggle()
			timeDisplayPostAnimationController.skip(to: .start)
			timeDisplayPostAnimationController.animate(to: .end)
		}
		timeDisplayPostAnimationController.skip(to: .start)
		timeDisplayPostAnimationController.endCallback = { [self] in
			timeDisplayPreAnimationController.skip(to: .start)
		}
	}

	deinit {
		// Check for reference cycles
		log("Deinitialising instance")
	}

	// MARK: Internal

	let isOpaque = true
	var transitionAnimationController = AnimationController(
		startValue: 0, endValue: 1, duration: 500, easing: .outBack)

	let bundleIndex: Int

	func update() {
		defer {
			heroViewAnimationController.tick()
			transitionAnimationController.tick()
			timeDisplayPreAnimationController.tick()
			timeDisplayPostAnimationController.tick()
		}

		// Update button hold timers
		let selectedAchievementIsUnlocked = { [self] in
			if hiddenAchievementsCount > 0 && listView.selectedItemIndex! == listView.totalItems - 1 {
				return false
			}

			return Game.bundles[bundleIndex].achievements[orderProxy, listView.selectedItemIndex!]
				.isUnlocked
		}()
		if System.buttonState.pushed.contains(.a) && selectedAchievementIsUnlocked {
			timeDisplayPreAnimationController.animate(to: .end)
		}
		if System.buttonState.released.contains(.a) {
			if timeDisplayPreAnimationController.isAnimating {
				timeDisplayPreAnimationController.animate(to: .start)
			}
		}

		// TODO: Selectively call Game.requestScreenRefresh() if hreo view is animating or the list view is animating
		// TODO: Guard so that we can skip drawing functions if there's no update needed
		// TODO: Identical TODO in bundlesView, so solve it there and copy the solution here

		// Clip drawing and draw outline if transitioning
		let transitionEndRect = Rect(
			x: 0, y: 15, width: Float(Display.width), height: Float(Display.height - 15))
		var transitionRect =
			transitionAnimationController.isAnimating
			? lerp(
				from: transitionStartRect, to: transitionEndRect, using: transitionAnimationController.value
			) : transitionEndRect
		transitionRect.y = max(transitionRect.y, transitionEndRect.y)
		Graphics.pushClipRect(transitionRect)
		defer { Graphics.popClipRect() }
		if transitionAnimationController.isAnimating {
			Graphics.fillRect(transitionRect, color: .black)
		}
		defer {
			if transitionAnimationController.isAnimating {
				let radius = lerp(from: 6, to: 0, using: transitionAnimationController.value)
				Graphics.drawRoundRect(transitionRect, lineWidth: 3, radius: radius)
			}
		}

		// Calculate draw locations
		let titleViewHeight = lerp(from: 28, to: 32, using: heroViewAnimationController.value)
		let titleViewY = lerp(
			from: Float(transitionStartRect.lcdRect.bottom) - titleViewHeight, to: 15,
			using: transitionAnimationController.value)

		let heroViewHeight: Float = 67
		let heroViewY = lerp(
			from: Float(titleViewY + titleViewHeight),
			to: Float(titleViewY + titleViewHeight - heroViewHeight),
			using: heroViewAnimationController.value)

		let listViewY = Int(heroViewY + heroViewHeight)

		// Draw views
		listView.draw(
			in: Rect(x: 0, y: listViewY, width: Display.width, height: Display.height - (32 + 15)))

		if heroViewAnimationController.value < 1 {
			heroView.draw(
				in: Rect(x: 0, y: heroViewY, width: Float(Display.width), height: heroViewHeight))
		}

		titleView.draw(
			in: Rect(x: 0, y: titleViewY, width: Float(Display.width), height: titleViewHeight))

		if transitionAnimationController.isAnimating && Game.preferences.bundlesViewMode == .cards
			&& bundleCardImage != nil
		{
			Graphics.drawMode = .copy
			Graphics.drawBitmap(bundleCardImage!, at: Point(x: transitionStartRect.x, y: titleViewY - 90))
		}
	}

	func willBecomeCurrent() {
		// Achievement sort order is intentionally ephemeral
		sortOrderMenuItem = addOptionsMenuItem(
			"sort by", options: AchievementSortOrder.allCases.map({ $0.description }),
			initialValue: AchievementSortOrder.original.rawValue,
			callback: { [self] selectedOptionNumber in
				sortOrder = AchievementSortOrder(rawValue: selectedOptionNumber) ?? .original
				orderProxy = BundleDetailView.getOrderProxy(for: sortOrder, in: bundleIndex)
			})
	}

	func willResignCurrent() {
		if sortOrderMenuItem != nil {
			System.removeMenuItem(sortOrderMenuItem!)
			sortOrderMenuItem = nil
		}
	}

	func willExit() {
		// Clean up reference cycle
		listView.drawItem = { (_, _, _) in }
	}

	func handleInputEvent(_ event: InputEvent) {
		switch event {
			case .scrollUp:
				if listView.selectedItemIndex == 1 {
					Game.scrollUpSfx.play()
					heroViewAnimationController.animate(to: .start)
				}

				if listView.selectedItemIndex! > 0 {
					currentItemMarquee = nil
				}

				if listView.selectedItemIndex == 0 {
					Game.denialSfx.play()
				} else {
					Game.scrollUpSfx.play()
				}

				listView.selectedItemIndex! -= 1
				listView.selectedItemIndex!.clamp(to: 0...listView.totalItems - 1)

			case .scrollDown:
				if listView.selectedItemIndex == 0 {
					Game.scrollDownSfx.play()
					heroViewAnimationController.animate(to: .end)
				}

				if listView.selectedItemIndex! < listView.totalItems - 1 {
					currentItemMarquee = nil
				}

				if listView.selectedItemIndex == listView.totalItems - 1 {
					Game.denialSfx.play()
				} else {
					Game.scrollDownSfx.play()
				}

				listView.selectedItemIndex! += 1
				listView.selectedItemIndex!.clamp(to: 0...listView.totalItems - 1)

			case .b:
				Game.scrollUpSfx.play()
				Game.navigationController.pop()

			default:
				break
		}
	}

	// MARK: Private

	private let titleView: BundleDetailTitleView
	private let heroView: BundleDetailHeroView
	private var listView: ListView

	private var heroViewAnimationController = AnimationController(
		startValue: 0, endValue: 1, duration: 250, easing: .outQuad)
	private var timeDisplayPreAnimationController = AnimationController(
		startValue: 0, endValue: 1, duration: 1000, easing: .outQuad)
	private var timeDisplayPostAnimationController = AnimationController(
		startValue: 0, endValue: 1, duration: 500, easing: .outElastic)

	private var transitionStartRect: Rect

	private var bundleCardImage: Graphics.Bitmap?
	private var sortOrder: AchievementSortOrder = .original
	private var orderProxy: OrderProxy

	/// The number of locked secret achievements in the view's bundle. Always zero if ``Game.preferences.showHiddenAchievements`` is true.
	private let hiddenAchievementsCount: Int

	/// Whether achievement icons should be shown for the view's bundle.
	private let showIcons: Bool

	private var cache = ImageCache(distance: 5)
	private let defaultAchievementIcon: Graphics.Bitmap?

	private var sortOrderMenuItem: System.OptionsMenuItem? = nil

	private var currentItemMarquee: Marquee?

	/// Load and mask a bundle card image.
	/// - Parameter path: The path to the image.
	/// - Returns: The masked image, or nil if it couldn't be loaded.
	private static func loadBundleCardImage(at path: String) -> Graphics.Bitmap? {
		let bundleCardImageMask = Graphics.Bitmap(width: 380, height: 90, bgColor: .black)
		Graphics.pushContext(bundleCardImageMask)
		Graphics.fillRoundRect(Rect(origin: .zero, width: 380, height: 96), radius: 6, color: .white)
		Graphics.popContext()

		do {
			let image = Graphics.Bitmap(width: 380, height: 90, bgColor: .white)
			try image.load(from: path)
			image.mask = bundleCardImageMask

			return image
		} catch { log("Couldn't load card image at \"\(path)\": \(error)") }

		return nil
	}

	private func drawListItem(forItem: Int, in bounds: Rect, isSelected: Bool) {
		if hiddenAchievementsCount > 0 && forItem == listView.totalItems - 1 {
			drawHiddenAchievementsHint(in: bounds)
			return
		}

		let achievement = Game.bundles[bundleIndex].achievements[orderProxy, forItem]

		Graphics.drawMode = .copy
		Graphics.fillRoundRect(bounds, radius: 6, color: .white)
		Graphics.drawRoundRect(bounds, lineWidth: 2, radius: 6, color: .black)

		// TODO: Change design for this to include a progress bar, maybe?

		if showIcons {
			Graphics.drawMode = .copy
			if achievement.iconPath != nil,
				let image = getAchievementIconImage(i: forItem, path: achievement.iconPath!)
			{
				Graphics.drawBitmap(image, at: bounds.origin.translatedBy(dx: 4, dy: 4))
			} else {
				// showIcons already guarantees that defaultAchievementIcon is a valid Bitmap
				Graphics.drawBitmap(defaultAchievementIcon!, at: bounds.origin.translatedBy(dx: 4, dy: 4))
			}
		}

		// Draw progress text
		let progressText: String = {
			if !achievement.isUnlocked {
				if let max = achievement.maxProgress, max > 1 {
					return "\(achievement.progress ?? 0)/\(max)"
				}

				return "Locked"
			}

			if achievement.unlockedAt == nil { return "Unlocked" }

			let interval = TimeInterval(spanning: Int(System.secondsSinceEpoch) - achievement.unlockedAt!)
			guard interval.seconds >= 0 else {
				log(
					"Achievement \"\(achievement.id)\" has an unlock date in the future (in \(interval.description))"
				)
				return "Unlocked"
			}
			if interval.seconds == 0 { return "just now" }
			if !Game.preferences.showFullTime { return "\(interval.description) ago" }

			return System.DateTime(epoch: CUnsignedInt(achievement.unlockedAt!)).description
		}()
		let progressWidth = Float(
			Graphics.Font.roobert10Bold.getTextWidth(for: progressText, tracking: 0))
		Graphics.setFont(.roobert10Bold)
		if (timeDisplayPreAnimationController.isAnimating
			|| timeDisplayPostAnimationController.isAnimating) && isSelected
		{
			let image = Graphics.Bitmap(
				width: Int(progressWidth), height: Graphics.Font.roobert10Bold.height)
			Graphics.pushContext(image)
			Graphics.drawText(progressText, at: .zero)
			Graphics.popContext()
			let xScale: Float =
				switch (Game.preferences.showFullTime, timeDisplayPreAnimationController.isAnimating) {
					case (false, true):  // short time, stretching to large
						lerp(from: 1, to: 1.5, using: timeDisplayPreAnimationController.value)
					case (true, true):  // long time, squishing to short
						lerp(from: 1, to: 0.7, using: timeDisplayPreAnimationController.value)
					case (false, false):  // short time, bouncing back from long
						lerp(from: 1.5, to: 1, using: timeDisplayPostAnimationController.value)
					case (true, false):  // long time, bouncing back from short
						lerp(from: 0.7, to: 1, using: timeDisplayPostAnimationController.value)
				}
			let yScale: Float =
				switch (Game.preferences.showFullTime, timeDisplayPreAnimationController.isAnimating) {
					case (false, true):  // short time, stretching to large
						lerp(from: 1, to: 0.7, using: timeDisplayPreAnimationController.value)
					case (true, true):  // long time, squishing to short
						lerp(from: 1, to: 1.1, using: timeDisplayPreAnimationController.value)
					case (false, false):  // short time, bouncing back from long
						lerp(from: 0.7, to: 1, using: timeDisplayPostAnimationController.value)
					case (true, false):  // long time, bouncing back from short
						lerp(from: 1.1, to: 1, using: timeDisplayPostAnimationController.value)
				}
			let progressPosition = Point(
				x: 0 + bounds.width - 6,
				y: bounds.origin.y + (showIcons ? 11 : 6) + 4
					+ Float(Graphics.Font.roobert10Bold.height / 2))
			Graphics.drawBitmap(
				image, at: progressPosition, degrees: 0, center: Point(x: 1, y: 0.5), xScale: xScale,
				yScale: yScale)
		} else {
			Graphics.drawText(
				progressText,
				at: Point(
					x: bounds.width - 6 - progressWidth, y: bounds.origin.y + 4 + (showIcons ? 11 : 6)))
		}

		// Draw achievement name
		Graphics.setFont(.roobert11Bold)
		let nameBounds = Rect(
			origin: bounds.origin.translatedBy(dx: 6 + (showIcons ? 36 : 0), dy: showIcons ? 11 : 6),
			width: bounds.width - progressWidth - 12 - 12 - (showIcons ? 36 : 0),
			height: Float(Graphics.Font.roobert11Bold.height))
		if isSelected {
			if currentItemMarquee == nil {
				currentItemMarquee = Marquee(achievement.name)
			}

			currentItemMarquee?.update(in: nameBounds)
		} else {
			Marquee.draw(achievement.name, in: nameBounds)
		}

		// TODO: Switch between showFullTime with bouncy effect if the current achievement is unlocked and has a date
		// TODO: Refactor all of this (bigly). Maybe make it a separate view thing?
		// NOTE: refer to implementation in old commits for timing and easing for bounciness

		// Draw description
		Graphics.setFont(.roobert11Medium)
		Graphics.drawMode = .copy
		let descriptionBounds = Rect(
			x: bounds.origin.x + 6, y: bounds.origin.y + (showIcons ? 42 : 33), width: bounds.width - 12,
			height: 44)
		Graphics.drawTextInRect(achievement.description, in: descriptionBounds, wrap: .word)

		// Draw progress bar
		let progressBarY: Float = bounds.origin.y + (showIcons ? 36 : 31)
		let progressBarStartX: Float = bounds.origin.x + 6 + (showIcons ? 36 : 0)
		let progressBarEndX: Float = bounds.origin.x + bounds.width - 6

		let progressBarStart = Point(x: progressBarStartX, y: progressBarY)
		let progressBarEnd = Point(x: progressBarEndX, y: progressBarY)
		let progressBarMiddle = Point(
			x: lerp(from: progressBarStartX, to: progressBarEndX, using: achievement.progressInterval),
			y: progressBarY)

		Graphics.setStencilImage(BundleDetailView.stencilImage, tile: true)
		Graphics.drawLine(
			Line(start: progressBarStart, end: progressBarEnd), lineWidth: 2, color: .black)
		Graphics.setStencil(nil)
		Graphics.drawLine(
			Line(start: progressBarStart, end: progressBarMiddle), lineWidth: 2, color: .black)
	}

	private func drawHiddenAchievementsHint(in bounds: Rect) {
		let text =
			"...and \(hiddenAchievementsCount) secret achievement\(hiddenAchievementsCount == 1 ? "" : "s")"
		let textWidth = Float(Graphics.Font.roobert10Bold.getTextWidth(for: text, tracking: 0))
		let textHeight: Float = 13

		/// The amount of padding between the text and the edge of the rectangle.
		let padding: Float = 10

		let rect = Rect(
			x: bounds.origin.x + (bounds.width - textWidth - (padding * 2)) / 2,
			y: bounds.origin.y + (bounds.height - textHeight - (padding * 2)) / 2,
			width: textWidth + (padding * 2), height: textHeight + (padding * 2))

		Graphics.drawMode = .copy
		Graphics.fillRoundRect(rect, radius: 6, color: .white)
		Graphics.drawRoundRect(rect, lineWidth: 2, radius: 6, color: .black)

		Graphics.setFont(.roobert10Bold)
		Graphics.drawText(text, at: rect.origin.translatedBy(dx: padding, dy: padding))
	}

	private enum AchievementSortOrder: Int, CaseIterable, CustomStringConvertible {
		case original = 0
		case recent = 1
		case progress = 2
		case alphabetical = 3

		var description: String {
			switch self { case .original: return "original" case .recent: return "recent" case .progress:
				return "progress"
				case .alphabetical: return "name"
			}
		}
	}

	/// Create an ``OrderProxy`` for the achievements in the view's bundle, sorted by the specified order.
	///
	/// The returned proxy automatically excludes locked secret achievements, if applicable.
	/// - Parameter order: The order to sort achievements by.
	/// - Returns: An ``OrderProxy`` for the achievements in the view's bundle.
	private static func getOrderProxy(for order: AchievementSortOrder, in bi: Int) -> OrderProxy {
		let bundle = Game.bundles[bi]
		let displayedAchievements =
			Game.preferences.showHiddenAchievements
			? Array(bundle.achievements.enumerated())
			: bundle.achievements.enumerated().filter({ !$0.element.isSecret || $0.element.isUnlocked })

		switch order {
			case .original:
				return displayedAchievements.map({ return $0.offset })
			case .recent:
				return displayedAchievements.sorted(by: {
					let timestampA = $0.element.unlockedAt ?? 0
					let timestampB = $1.element.unlockedAt ?? 0
					return timestampB < timestampA
				}).map({ $0.offset })
			case .progress:
				return displayedAchievements.sorted(by: {
					return $0.element.progressInterval > $1.element.progressInterval
				}).map({ $0.offset })
			case .alphabetical:
				return displayedAchievements.sorted(by: {
					return $0.element.name < $1.element.name
				}).map({ $0.offset })
		}
	}
	private static nonisolated(unsafe) let stencilImage: Graphics.Bitmap = try! Graphics.Bitmap(
		path: "stencil")

	private func getAchievementIconImage(i: Int, path: String) -> Graphics.Bitmap? {
		if let cachedImage = cache[i] { return cachedImage }

		do {
			let image = Graphics.Bitmap(width: 32, height: 32)
			try image.load(from: path)

			cache[i] = image
			return image
		} catch {
			log("Couldn't load icon image at \"\(path)\": \(error)")

			let c: Graphics.Bitmap? = nil
			cache[i] = c
			return nil
		}
	}
}
