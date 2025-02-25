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

	init(totalAchievementsUnlocked: Int, statistics: [DisplayStatistic]) {
		self.totalAchievementsUnlocked = totalAchievementsUnlocked
		self.statistics = statistics

		revolvingStatisticsAnimationController.endCallback = switchToNextStatistic
	}

	// MARK: Internal

	func setTotalAchievementsUnlocked(to number: Int) {
		totalAchievementsUnlocked = number
	}

	func draw(in viewBounds: Rect) {
		defer {
			// Update timers
			revolvingStatisticsAnimationController.tick()
			statisticsTransitionAnimationController.tick()
			trophyAnimationController.tick()
		}

		// Draw background image
		Graphics.drawMode = .copy
		Graphics.drawBitmap(backgroundImage, at: viewBounds.origin)

		// Draw spinning trophy
		Graphics.drawBitmap(
			trophyImageTable[Int(trophyAnimationController.value)] ?? trophyImageTable[0]!,
			at: viewBounds.origin.translatedBy(dx: 17, dy: 34))

		// Draw total unlocked
		let totalUnlockedTextWidth = Float(
			Graphics.Font.showtime.getTextWidth(for: totalAchievementsUnlocked.description, tracking: 0))

		// TODO: Draw these relative to the view bounds
		Graphics.setFont(.roobert10Bold)
		Graphics.drawMode = .inverted
		Graphics.drawText("TOTAL UNLOCKED", at: viewBounds.origin.translatedBy(dx: 386 - 117, dy: 18))  // 117px wide
		Graphics.setFont(.showtime)
		Graphics.drawText(
			totalAchievementsUnlocked.description,
			at: viewBounds.origin.translatedBy(dx: 386 - totalUnlockedTextWidth, dy: 33))

		// Draw revolving statistics
		guard !statistics.isEmpty else { return }
		let statistic = statistics[currentStatisticIndex]

		let statisticTitleTextWidth = Float(
			Graphics.Font.roobert10Bold.getTextWidth(for: statistic.title, tracking: 0))
		let statisticTitleDrawY = lerp(
			from: Float(85 - Graphics.Font.roobert10Bold.height), to: 85,
			using: statisticsTransitionAnimationController.value)
		// TODO: Make this rectangle smaller so that it minimises the updated area
		let statisticTitleClipRect = Rect(
			x: 0, y: viewBounds.origin.y + 85, width: 400,
			height: Float(Graphics.Font.roobert10Bold.height))
		let statisticBodyTextWidth = Float(
			Graphics.Font.showtime.getTextWidth(for: statistic.body, tracking: 0))
		let statisticBodyDrawY = lerp(
			from: Float(100 - Graphics.Font.showtime.height), to: 100,
			using: statisticsTransitionAnimationController.value)
		// TODO: Make this rectangle smaller so that it minimises the updated area
		let statisticBodyClipRect = Rect(
			x: viewBounds.origin.x, y: viewBounds.origin.y + 100, width: 400,
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
}
