//
//  HeroView.swift
//  TrophyCase
//
//  Created by gurtt on 3/2/2025.
//

import PlaydateKit

typealias DisplayStatistic = (title: String, body: String)

class HeroView {

	// MARK: Lifecycle

	init(totalAchievementsUnlocked: UInt, statistics: [DisplayStatistic]) {
		self.totalAchievementsUnlocked = Int(totalAchievementsUnlocked)
		self.statistics = statistics

		self.previousTotalAchievementsUnlocked = Int(StatsReader.read() ?? totalAchievementsUnlocked)
		self.totalUnlockedDisplay = previousTotalAchievementsUnlocked
		StatsReader.write(UInt(self.totalAchievementsUnlocked))
		print("DELTA: \(self.totalAchievementsUnlocked) - \(self.previousTotalAchievementsUnlocked)")
		let delta = self.totalAchievementsUnlocked - self.previousTotalAchievementsUnlocked
		log("Total unlock delta: \(delta)")

		totalUnlockedDisplayInitialDelay.endCallback = {
			let delta = self.totalAchievementsUnlocked - self.previousTotalAchievementsUnlocked

			if delta > 0 {
				self.totalUnlockedAnimationController = AnimationController(
					startValue: 0, endValue: 1, duration: delta > 30 ? 25 : 200, isRepeating: true,
					endCallback: self.incrementTotalUnlockedDisplay)
				self.totalUnlockedSizeAnimationController = AnimationController(
					startValue: 0, endValue: 1, duration: delta > 30 ? (25 * 30) : 200 * Int(delta),
					easing: .outExpo)
			}
			if delta < 4 {
				self.totalUnlockedSizeAnimationController.skip(to: .start)
			}
		}

		revolvingStatisticsAnimationController.endCallback = switchToNextStatistic
	}

	// MARK: Internal

	func draw(in viewBounds: Rect) {
		defer {
			// Update timers
			revolvingStatisticsAnimationController.tick()
			statisticsTransitionAnimationController.tick()
			trophyAnimationController.tick()
			totalUnlockedAnimationController?.tick()
			totalUnlockedSizeAnimationController.tick()
			totalUnlockedDisplayInitialDelay.tick()
		}

		// Draw background image
		Graphics.drawMode = .copy
		Graphics.drawBitmap(backgroundImage, at: viewBounds.origin)

		// Draw spinning trophy
		Graphics.drawBitmap(
			trophyImageTable[Int(trophyAnimationController.value)] ?? trophyImageTable[0]!,
			at: viewBounds.origin.translatedBy(dx: 17, dy: 34))

		// Draw total unlocked
		// TODO: Draw these relative to the view bounds
		Graphics.setFont(.roobert10Bold)
		Graphics.drawMode = .inverted
		Graphics.drawText("TOTAL UNLOCKED", at: viewBounds.origin.translatedBy(dx: 386 - 117, dy: 33))  // 117px wide

		let totalUnlockedTextWidth = Float(
			Graphics.Font.showtime.getTextWidth(for: String(totalUnlockedDisplay), tracking: 0))
		let image = Graphics.Bitmap(
			width: Int(totalUnlockedTextWidth), height: Graphics.Font.showtime.height)
		Graphics.pushContext(image)
		Graphics.drawMode = .inverted
		Graphics.setFont(.showtime)
		Graphics.drawText(String(totalUnlockedDisplay), at: .zero)
		Graphics.popContext()

		let totalUnlockedPosition = viewBounds.origin.translatedBy(dx: 386, dy: 48)
		let scale = lerp(from: 1, to: 1.7, using: totalUnlockedSizeAnimationController.value)
		Graphics.drawMode = .copy
		Graphics.drawBitmap(
			image, at: totalUnlockedPosition, degrees: 0, center: Point(x: 1, y: 0), xScale: scale,
			yScale: scale)

		// Draw revolving statistics
		guard !statistics.isEmpty else { return }
		let statistic = statistics[currentStatisticIndex]

		let offset = lerp(from: 0, to: 15, using: totalUnlockedSizeAnimationController.value)

		let statisticTitleTextWidth = Float(
			Graphics.Font.roobert10Bold.getTextWidth(for: statistic.title, tracking: 0))
		let statisticTitleDrawY =
			lerp(
				from: Float(100 - Graphics.Font.roobert10Bold.height), to: 100,
				using: statisticsTransitionAnimationController.value) + offset
		// TODO: Make this rectangle smaller so that it minimises the updated area
		let statisticTitleClipRect = Rect(
			x: 0, y: viewBounds.origin.y + 100 + offset, width: 400,
			height: Float(Graphics.Font.roobert10Bold.height))
		let statisticBodyTextWidth = Float(
			Graphics.Font.showtime.getTextWidth(for: statistic.body, tracking: 0))
		let statisticBodyDrawY =
			lerp(
				from: Float(115 - Graphics.Font.showtime.height), to: 115,
				using: statisticsTransitionAnimationController.value) + offset
		// TODO: Make this rectangle smaller so that it minimises the updated area
		let statisticBodyClipRect = Rect(
			x: viewBounds.origin.x, y: viewBounds.origin.y + 115 + offset, width: 400,
			height: Float(Graphics.Font.showtime.height))

		Graphics.setFont(.roobert10Bold)
		Graphics.drawMode = .inverted
		Graphics.setClipRect(statisticTitleClipRect)
		Graphics.drawText(
			statistic.title,
			at: viewBounds.origin.translatedBy(dx: 386 - statisticTitleTextWidth, dy: statisticTitleDrawY)
		)
		Graphics.setFont(.showtime)
		Graphics.setClipRect(statisticBodyClipRect)
		Graphics.drawText(
			statistic.body,
			at: viewBounds.origin.translatedBy(dx: 386 - statisticBodyTextWidth, dy: statisticBodyDrawY))
		Graphics.clearClipRect()

		// TODO: Refresh only this area by drawing the background image in the clipped parts
		if statisticsTransitionAnimationController.isAnimating {
			let previousStatistic = statistics[previousStatisticIndex]

			let previousStatisticTitleTextWidth = Float(
				Graphics.Font.roobert10Bold.getTextWidth(for: previousStatistic.title, tracking: 0))
			let previousStatisticBodyTextWidth = Float(
				Graphics.Font.showtime.getTextWidth(for: previousStatistic.body, tracking: 0))

			Graphics.setFont(.roobert10Bold)
			Graphics.drawMode = .inverted
			Graphics.setClipRect(statisticTitleClipRect)
			Graphics.drawText(
				previousStatistic.title,
				at: viewBounds.origin.translatedBy(
					dx: 386 - previousStatisticTitleTextWidth,
					dy: statisticTitleDrawY + Float(Graphics.Font.roobert10Bold.height)))
			Graphics.setFont(.showtime)
			Graphics.setClipRect(statisticBodyClipRect)
			Graphics.drawText(
				previousStatistic.body,
				at: viewBounds.origin.translatedBy(
					dx: 386 - previousStatisticBodyTextWidth,
					dy: statisticBodyDrawY + Float(Graphics.Font.showtime.height)))
			Graphics.clearClipRect()
		}
	}

	// MARK: Private

	private let backgroundImage = try! Graphics.Bitmap(path: "hero-bg-trophy")
	private let trophyImageTable = try! Graphics.BitmapTable(path: "trophy-handles/trophy-handles")

	private var totalAchievementsUnlocked: Int = 0
	private let statistics: [DisplayStatistic]
	private let previousTotalAchievementsUnlocked: Int

	private var revolvingStatisticsAnimationController = AnimationController(
		startValue: 0, endValue: 1, duration: 7000, isRepeating: true)
	private var statisticsTransitionAnimationController = AnimationController(
		startValue: 0, endValue: 1, duration: 1000, easing: .inOutCirc)
	private var currentStatisticIndex: Array.Index = 0

	private func switchToNextStatistic() {
		if currentStatisticIndex < statistics.count - 1 {
			currentStatisticIndex += 1
		} else {
			currentStatisticIndex = 0
		}

		statisticsTransitionAnimationController.skip(to: .start)
		statisticsTransitionAnimationController.animate(to: .end)
	}

	private var previousStatisticIndex: Array.Index {
		if currentStatisticIndex == 0 {
			return statistics.count - 1
		} else {
			return currentStatisticIndex - 1
		}
	}

	private var trophyAnimationController = AnimationController(
		startValue: 1, endValue: 60, duration: 2000, isRepeating: true)

	private func incrementTotalUnlockedDisplay() {
		guard
			totalUnlockedDisplay < totalAchievementsUnlocked - 1 && totalUnlockedDisplayIterations <= 30
		else {
			totalUnlockedAnimationController = nil
			totalUnlockedDisplay = totalAchievementsUnlocked

			let delta = totalAchievementsUnlocked - self.previousTotalAchievementsUnlocked
			if delta >= 4 {
				self.totalUnlockedSizeAnimationController = AnimationController(
					startValue: 1, endValue: 0, duration: 250, easing: .outBack)
			}

			return
		}

		totalUnlockedDisplayIterations += 1
		totalUnlockedDisplay += 1
	}

	private var totalUnlockedAnimationController: AnimationController?
	private var totalUnlockedSizeAnimationController = AnimationController(
		startValue: 0, endValue: 0, duration: 0)
	private var totalUnlockedDisplay: Int
	private var totalUnlockedDisplayIterations: UInt = 0
	private var totalUnlockedDisplayInitialDelay = AnimationController(
		startValue: 0, endValue: 1, duration: 1000)
}
