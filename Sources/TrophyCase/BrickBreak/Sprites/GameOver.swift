//
//  GameOver.swift
//  TrophyCase
//
//  Created by gurtt on 27/3/2025.
//

import PlaydateKit

final class GameOver: Sprite.Sprite {
	override init() {
		super.init()
		collisionsEnabled = false
		zIndex = 2000

		let xMargin = 32
		let yMargin = 32
		bounds = Rect(
			x: xMargin, y: yMargin, width: Display.width - (xMargin * 2),
			height: Display.height - (yMargin * 2))
	}

	override func update() {
		if System.buttonState.pushed.contains(.a) {
			if isReplaySelected {
				BaseView.instance?.startGame()
			} else {
				BaseView.instance?.exit()
			}
			return
		}

		let canExitToMain = Game.saveData.hasUnlockedSomething || !Game.sharedBundles.isEmpty
		guard canExitToMain else { return }

		if isReplaySelected && System.buttonState.pushed.contains(.right) {
			isReplaySelected = false
			markDirty()
			return
		}

		if !isReplaySelected && System.buttonState.pushed.contains(.left) {
			isReplaySelected = true
			markDirty()
			return
		}
	}

	override func draw(bounds _: Rect, drawRect _: Rect) {
		let padding: Float = 16

		let score = BaseView.instance?.score ?? 0
		let best = Game.saveData.hasPlayed ? Game.saveData.maxScore : nil
		let canExitToMain = Game.saveData.hasUnlockedSomething || !Game.sharedBundles.isEmpty

		let titleText = "Game Over"
		let titleTextWidth = Graphics.Font.roobert11Bold.getTextWidth(for: titleText, tracking: 0)
		let scoreText = "Score: \(score)\(best != nil ? " Best: \(best!)" : "")"
		let scoreTextWidth = Graphics.Font.roobert10Bold.getTextWidth(for: scoreText, tracking: 0)
		let backToTitleText =
			canExitToMain
			? "Do you want to play another round or head back to Trophy Case?"
			: "Get a score of at least 100 to earn an achievement."

		Graphics.drawMode = .copy

		// Draw backing
		Graphics.fillRoundRect(bounds, radius: 3, color: .white)
		Graphics.drawRoundRect(bounds, lineWidth: 3, radius: 3, color: .black)

		// Draw title
		let titleLocation = bounds.origin.translatedBy(
			dx: (bounds.width / 2) - (Float(titleTextWidth) / 2), dy: padding)
		Graphics.setFont(.roobert11Bold)
		Graphics.drawText(titleText, at: titleLocation)

		// Draw score
		let scoreLocation = bounds.origin.translatedBy(
			dx: (bounds.width / 2) - (Float(scoreTextWidth) / 2),
			dy: padding + Float(Graphics.Font.roobert11Bold.height))
		Graphics.setFont(.roobert10Bold)
		Graphics.drawText(scoreText, at: scoreLocation)

		// Draw back to title prompt
		let backToTitleBounds = Rect(
			origin: bounds.origin.translatedBy(
				dx: padding,
				dy: padding + Float(Graphics.Font.roobert11Bold.height)
					+ Float(Graphics.Font.roobert10Bold.height) + padding), width: bounds.width - padding * 2,
			height: 50)
		Graphics.setFont(.roobert11Medium)
		Graphics.drawTextInRect(backToTitleText, in: backToTitleBounds, wrap: .word, aligned: .center)

		// Draw buttons
		// TODO: Draw the buttons

		// Draw play again action

		let actionWidth: Float = 137
		let actionHeight: Float = 38

		let replayActionText = "Play again"
		let replayActionBounds = Rect(
			origin: bounds.origin.translatedBy(dx: canExitToMain ? 27 : 98, dy: 122),
			width: actionWidth,
			height: actionHeight)
		Graphics.fillRoundRect(replayActionBounds, radius: 3, color: isReplaySelected ? .black : .white)
		if !isReplaySelected {
			Graphics.drawRoundRect(replayActionBounds, lineWidth: 3, radius: 3, color: .black)
		}

		Graphics.drawMode = .nxor
		Graphics.drawTextInRect(
			replayActionText,
			in: replayActionBounds.translatedBy(
				dx: 0,
				dy: Float(replayActionBounds.height / 2) - Float(Graphics.Font.roobert11Medium.height / 2)),
			wrap: .word, aligned: .center)

		guard canExitToMain else { return }

		// Draw exit action
		let exitActionText = "Trophy Case"
		let exitActionBounds = Rect(
			origin: bounds.origin.translatedBy(dx: 172, dy: 122),
			width: actionWidth,
			height: actionHeight)
		Graphics.fillRoundRect(exitActionBounds, radius: 3, color: isReplaySelected ? .white : .black)
		if isReplaySelected {
			Graphics.drawRoundRect(exitActionBounds, lineWidth: 3, radius: 3, color: .black)
		}
		Graphics.drawMode = .nxor
		Graphics.drawTextInRect(
			exitActionText,
			in: exitActionBounds.translatedBy(
				dx: 0,
				dy: Float(exitActionBounds.height / 2) - Float(Graphics.Font.roobert11Medium.height / 2)),
			wrap: .word, aligned: .center)
	}

	private var isReplaySelected = true
}
