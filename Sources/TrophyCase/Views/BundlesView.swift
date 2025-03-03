//
//  BundlesView.swift
//  TrophyCase
//
//  Created by gurtt on 12/1/2025.
//

import PlaydateKit

final class BundlesView: Navigable {

	// MARK: Lifecycle

	init() {
		focusRingAnimationController = AnimationController(startValue: 0, endValue: 0, duration: 0)
		listView = ListView(drawItem: { (_, _, _) in }, totalItems: Game.bundles.count, itemHeight: 0)
		tickerView = TickerView(results: Game.analysisResults)
		orderProxy = BundlesView.getOrderProxy(for: Game.preferences.bundlesSortOrder)
		setupListView(for: Game.preferences.bundlesViewMode)
		heroViewAnimationController.skip(to: .start)
		focusRingAnimationController = AnimationController(
			startValue: 0, endValue: 1, duration: 500, isRepeating: true,
			endCallback: { [self] in showFocusRing.toggle() })
		heroViewAnimationController.endCallback = { [self] in
			tickerView.isSmall = true
		}
		heroViewAnimationController.startCallback = { [self] in
			tickerView.isSmall = false
		}
	}
	// MARK: Internal

	let isOpaque = true
	var transitionAnimationController = AnimationController(startValue: 0, endValue: 0, duration: 0)

	func update() {
		defer {
			heroViewAnimationController.tick()
			transitionAnimationController.tick()
			focusRingAnimationController.tick()
		}
		// TODO: Selectively call Game.requestScreenRefresh() if hreo view is animating or the transition is going or the list view is animating or the focus ring just changed
		// TODO: Guard so that we can skip drawing functions if there's no update needed
		//        guard transitionAnimationController.isAnimating || heroViewAnimationController.isAnimating else { return }
		//        defer { Game.requestScreenUpdate() }
		// ^ re. the above guard, not sure if this possibly prevents the last frame of the animation from being drawn. also heroview animation will not be animating when the scene starts, so need to find a way to force the first update to always draw???

		if heroViewAnimationController.value > 0 {
			let listViewDrawLocation = lerp(from: 240, to: 15, using: heroViewAnimationController.value)
			listView.draw(
				in: Rect(
					origin: Point(x: 0, y: listViewDrawLocation), width: Float(Display.width),
					height: Float(Display.height - 15)))
		}
		if heroViewAnimationController.value < 1 {
			let heroviewDrawLocation = lerp(from: 0, to: -240, using: heroViewAnimationController.value)
			heroView.draw(
				in: Rect(
					origin: Point(x: 0, y: heroviewDrawLocation), width: Float(Display.width),
					height: Float(Display.height)))
		}

		let largeTickerViewBounds = Rect(x: 0, y: Display.height - 36, width: Display.width, height: 36)
		let smallTickerViewBounds = Rect(x: 0, y: 0, width: Display.width, height: 15)
		let tickerViewDrawBounds = lerp(
			from: largeTickerViewBounds, to: smallTickerViewBounds,
			using: heroViewAnimationController.value)
		tickerView.draw(in: tickerViewDrawBounds)

	}
	func willBecomeCurrent() {
		isCurrent = true
		viewModeMenuItem = addOptionsMenuItem(
			"view as", options: BundlesViewMode.allCases.map({ $0.description }),
			initialValue: Game.preferences.bundlesViewMode.rawValue,
			callback: { [self] selectedOptionNumber in
				Game.preferences.bundlesViewMode = BundlesViewMode(rawValue: selectedOptionNumber) ?? .cards
				setupListView(for: Game.preferences.bundlesViewMode)
			})
		sortOrderMenuItem = addOptionsMenuItem(
			"sort by", options: BundlesSortOrder.allCases.map({ $0.description }),
			initialValue: Game.preferences.bundlesSortOrder.rawValue,
			callback: { [self] selectedOptionNumber in
				Game.preferences.bundlesSortOrder =
					BundlesSortOrder(rawValue: selectedOptionNumber) ?? .recent
				cache.removeAll()
				orderProxy = BundlesView.getOrderProxy(for: Game.preferences.bundlesSortOrder)
			})
	}
	func willResignCurrent() {
		isCurrent = false
		if viewModeMenuItem != nil {
			System.removeMenuItem(viewModeMenuItem!)
			viewModeMenuItem = nil
		}
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
				guard listView.selectedItemIndex != nil else { break }

				guard listView.selectedItemIndex! > 0 else {
					listView.selectedItemIndex = nil
					heroViewAnimationController.animate(to: .start)
					break
				}

				listView.selectedItemIndex! -= 1
				listView.selectedItemIndex!.clamp(to: 0...listView.totalItems - 1)

			case .scrollDown:
				guard listView.selectedItemIndex != nil else {
					listView.selectedItemIndex = 0
					heroViewAnimationController.animate(to: .end)
					break
				}

				listView.selectedItemIndex! += 1
				listView.selectedItemIndex!.clamp(to: 0...listView.totalItems - 1)

			case .a:
				guard let index = listView.selectedItemIndex, let selectedItemBounds else { break }
				let originalBundleIndex = orderProxy[index]
				Game.navigationController.push(
					BundleDetailView(for: originalBundleIndex, from: selectedItemBounds))

			default:
				break
		}
	}
	// MARK: Private

	private var isCurrent: Bool = false
	private var heroViewAnimationController = AnimationController(
		startValue: 0, endValue: 1, duration: 250, easing: .inOutQuad)
	// TODO: When the view is idle, run a callback to pre-cache all (relevant) images.
	private var cache = ImageCache(distance: 5)
	private var heroView = HeroView(
		totalAchievementsUnlocked: Game.totalAchievementsUnlocked, statistics: Game.statistics)
	private var listView: ListView
	private var tickerView: TickerView
	private var selectedItemBounds: Rect? = nil
	private var viewModeMenuItem: System.OptionsMenuItem? = nil
	private var sortOrderMenuItem: System.OptionsMenuItem? = nil
	private var orderProxy: OrderProxy
	private var showFocusRing: Bool = false
	private var focusRingAnimationController: AnimationController
	private func setupListView(for viewMode: BundlesViewMode) {
		cache.removeAll()
		switch viewMode { case .cards:
			listView.itemHeight = 122
			listView.backgroundImage = try! Graphics.Bitmap(path: "list-bg")
			listView.itemHorizontalSpacing = 10
			listView.itemVerticalSpacing = 10
			listView.drawItem = drawCardItem
			case .list:
				listView.itemHeight = 32
				listView.backgroundImage = nil
				listView.itemHorizontalSpacing = 6
				listView.itemVerticalSpacing = 2
				listView.drawItem = drawListItem
		}
	}
	private func drawCardItem(forItem: Int, in bounds: Rect, isSelected: Bool) {
		let bundle = Game.bundles[orderProxy, forItem]
		let unlocked = bundle.achievements.filter({ $0.isUnlocked }).count
		let total = bundle.achievements.count
		let summaryText = "\(unlocked)/\(total)"
		let summaryWidth = Float(
			Graphics.Font.roobert11Bold.getTextWidth(for: summaryText, tracking: 0))
		let nameRect = Rect(
			x: bounds.origin.x + 4, y: bounds.origin.y + 96,
			width: bounds.width - 4 - 4 - 6 - summaryWidth,
			height: Float(Graphics.Font.roobert11Medium.height))

		if isSelected {
			selectedItemBounds = bounds
			if isCurrent && showFocusRing {
				Graphics.drawRoundRect(bounds, lineWidth: 8, radius: 6, color: .black)
			}
		}
		Graphics.fillRoundRect(bounds, radius: 6, color: .black)
		if bundle.cardPath != nil, let image = getBundleCardImage(i: forItem, path: bundle.cardPath!) {
			Graphics.drawMode = .copy
			Graphics.drawBitmap(image, at: bounds.origin)
		}

		Graphics.setFont(.roobert11Medium)
		Marquee.draw(bundle.name, in: nameRect, inverted: true)
		Graphics.setFont(.roobert11Bold)
		Graphics.drawMode = .nxor
		Graphics.drawText(
			summaryText, at: Point(x: bounds.x + bounds.width - 4 - summaryWidth, y: bounds.y + 96))
	}
	private func drawListItem(forItem: Int, in bounds: Rect, isSelected: Bool) {
		let bundle = Game.bundles[orderProxy, forItem]
		let unlocked = bundle.achievements.filter({ $0.isUnlocked }).count
		let total = bundle.achievements.count
		let summaryText = "\(unlocked)/\(total)"
		let summaryWidth = Float(
			Graphics.Font.roobert11Bold.getTextWidth(for: summaryText, tracking: 0))
		let nameRect = Rect(
			x: bounds.origin.x + 40, y: bounds.origin.y + 6,
			width: bounds.width - 40 - 10 - 6 - summaryWidth,
			height: Float(Graphics.Font.roobert11Medium.height))
		Graphics.drawMode = .copy
		if bundle.iconPath != nil, let image = getBundleIconImage(i: forItem, path: bundle.iconPath!) {
			Graphics.drawBitmap(image, at: bounds.origin)
		} else {
			Graphics.drawBitmap(Game.defaultListIconImage, at: bounds.origin)
		}
		if isSelected {
			Graphics.fillRoundRect(
				Rect(
					origin: bounds.origin.translatedBy(dx: 36, dy: 0), width: bounds.width - 36,
					height: bounds.height), radius: 3, color: .black)
			selectedItemBounds = bounds
		}
		Graphics.drawMode = .nxor
		Graphics.setFont(.roobert11Medium)
		Marquee.draw(bundle.name, in: nameRect, inverted: isSelected)
		Graphics.setFont(.roobert11Bold)
		Graphics.drawMode = .nxor
		Graphics.drawText(
			summaryText, at: Point(x: bounds.x + bounds.width - 10 - summaryWidth, y: bounds.y + 6))
	}
	private func getBundleCardImage(i: Int, path: String) -> Graphics.Bitmap? {
		if let cachedImage = cache[i] { return cachedImage }
		do {
			let image = Graphics.Bitmap(width: 380, height: 90, bgColor: .white)
			try image.load(from: path)
			let bundleCardImageMask = Graphics.Bitmap(width: 380, height: 90, bgColor: .black)
			Graphics.pushContext(bundleCardImageMask)
			Graphics.fillRoundRect(Rect(origin: .zero, width: 380, height: 96), radius: 6, color: .white)
			Graphics.popContext()
			image.mask = bundleCardImageMask

			cache[i] = image
			return image
		} catch {
			log("Couldn't load card image at \"\(path)\": \(error)")
			let c: Graphics.Bitmap? = nil
			cache[i] = c
			return nil
		}
	}
	private func getBundleIconImage(i: Int, path: String) -> Graphics.Bitmap? {
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
	/// Create an ``OrderProxy`` for bundles, sorted by the specified order.
	///
	/// - Parameter order: The order to sort bundles by.
	/// - Returns: An ``OrderProxy`` for bundles.
	private static func getOrderProxy(for order: BundlesSortOrder) -> OrderProxy {
		switch order { case .recent:
			return Game.bundles.enumerated().sorted(by: {
				return $0.element.modifiedAt > $1.element.modifiedAt
			}).map({ $0.offset })
			case .progress:
				return Game.bundles.enumerated().sorted(by: {
					let progressA =
						Float($0.element.achievements.filter({ $0.isUnlocked }).count)
						/ Float($0.element.achievements.count)
					let progressB =
						Float($1.element.achievements.filter({ $0.isUnlocked }).count)
						/ Float($1.element.achievements.count)
					return progressA > progressB
				}).map({ $0.offset })
			case .alphabetical:
				return Game.bundles.enumerated().sorted(by: { $0.element.name < $1.element.name }).map({
					$0.offset
				})
		}
	}
}
