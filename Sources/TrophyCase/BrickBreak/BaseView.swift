//
//  BaseView.swift
//  TrophyCase
//
//  Created by gurtt on 22/3/2025.
//

import PlaydateKit

final class BaseView: Navigable {
	// MARK: Lifecycle

	static nonisolated(unsafe) var instance: BaseView?
	var score: Int = 0 {
		didSet {
			statusBarSprite.markDirty()
		}
	}

	init() {
		BaseView.instance = self
		fadeSprite.addToDisplayList()
	}

	// MARK: Internal

	var transitionAnimationController = AnimationController(
		startValue: 0, endValue: 1, duration: 1000)
	var isOpaque = true
	var firstDraw = true

	func update() {
		if firstDraw {
			Game.alertSfx.play()
			firstDraw = false
		}

		if state == .exiting && fadeSprite.isFinished {
			Game.goToMain()
			return
		}

		// TODO: Don't show the "no achievements" insterstitial if there are actually achievements
		guard state != .interstitial else {
			Graphics.clear(color: .black)
			interstitialView.draw()
			return
		}

		#if DEBUG
			if System.buttonState.pushed.contains(.down) {
				score += 10
			}
		#endif

		if blockSprites.contains(where: { blockSprite in blockSprite.position.y > Block.maxY - 25 }) {
			warningSprite.addToDisplayList()
		} else {
			warningSprite.removeFromDisplayList()
		}

		if blockSprites.contains(where: { blockSprite in blockSprite.position.y > Block.maxY }) {
			endGame()
		}

		Sprite.updateAndDrawDisplayListSprites()
	}

	func endGame() {
		guard state == .inGame else { return }
		state = .gameOver
		Game.saveData.saveScore(score: score)

		gameOverSprite.addToDisplayList()

	}

	func startGame() {
		// TODO: Start the game, possibly again
		score = 0
		ballSprite.reset()
		paddleSprite.reset()

		// wildly inefficient, but 🤷‍♂️
		for blockSprite in blockSprites {
			blockSprite.removeFromDisplayList()
		}
		blockSprites.removeAll()
		let blockColumns = 10
		let blockRows = 7
		for i in 0..<(blockColumns * blockRows) {
			let x = (i % 10) * 40 + 40 / 2
			let y = ((i / 10) * 24 + 24 / 2) - 72

			let sprite = Block()
			sprite.moveTo(Point(x: x, y: y))
			sprite.addToDisplayList()
			blockSprites.append(sprite)
		}

		state = .inGame
		gameOverSprite.removeFromDisplayList()
	}

	func exit() {
		// TODO: Deinitialise this view?
		fadeSprite.fadeToOpaque()
		state = .exiting
	}

	func willBecomeCurrent() {
		Display.refreshRate = 50
	}

	func willResignCurrent() {
		//
	}

	func willExit() {
		//
	}

	func handleInputEvent(_ event: InputEvent) {
		switch event {
			case .a:
				guard state == .interstitial else { break }

				Game.actionSfx.play()

				// TODO: Start the game 'properly' in a reusable way
				state = .inGame
				backgroundSprite.addToDisplayList()
				paddleSprite.addToDisplayList()
				ballSprite.addToDisplayList()

				for wall in wallSprites {
					wall.addToDisplayList()
				}

				let blockColumns = 10
				let blockRows = 7
				for i in 0..<(blockColumns * blockRows) {
					let x = (i % 10) * 40 + 40 / 2
					let y = ((i / 10) * 24 + 24 / 2) - 72

					let sprite = Block()
					sprite.moveTo(Point(x: x, y: y))
					sprite.addToDisplayList()
					blockSprites.append(sprite)
				}
				statusBarSprite.addToDisplayList()
				warningSprite.moveTo(Point(x: 200, y: 180))
				gameOverSprite.moveTo(Point(x: 200, y: 120))
				fadeSprite.fadetoTransparent()

			default:
				break
		}
	}

	// MARK: Private
	private let interstitialView = InterstitalView()
	var state: GameState = .interstitial

	private let backgroundSprite = Background()
	private let paddleSprite = Paddle()
	private let ballSprite = Ball()
	private let wallSprites = [
		Wall(in: Rect(x: 0, y: 0, width: 20, height: 240), at: Point(x: -20, y: 0)),  // left
		Wall(in: Rect(x: 0, y: 0, width: 20, height: 240), at: Point(x: 400, y: 0)),  // right
		Wall(in: Rect(x: 0, y: 0, width: 440, height: 20), at: Point(x: -20, y: -4)),  // top
	]
	private var blockSprites: [Block] = [
		Block(at: Point(x: 50, y: 50))
	]
	private let statusBarSprite = StatusBar()
	private let warningSprite = Warning()
	private let gameOverSprite = GameOver()
	private let fadeSprite = Fade()

	enum GameState {
		case interstitial
		case inGame
		case gameOver
		case exiting
	}
}
