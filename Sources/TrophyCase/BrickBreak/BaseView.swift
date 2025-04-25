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
		backgroundSprite.addToDisplayList()
		paddleSprite.addToDisplayList()
		ballSprite.addToDisplayList()

		for wall in wallSprites {
			wall.addToDisplayList()
		}

		statusBarSprite.addToDisplayList()
		warningSprite.moveTo(Point(x: 200, y: 180))
		gameOverSprite.moveTo(Point(x: 200, y: 120))

		fadeSprite.addToDisplayList()
		gameOverSprite.addToDisplayList()

		let canExitToMain = Game.saveData.hasUnlockedSomething || !Game.bundles.isEmpty
		exitMenuItem = canExitToMain ? System.addMenuItem(title: "exit game", callback: exit) : nil
		guard !canExitToMain else {
			dismissInterstitial()
			return
		}
		interstitialSprite.primaryAction = dismissInterstitial
		Graphics.pushContext(interstitialSprite.content)
		InterstitalView.draw()
		Graphics.popContext()
		interstitialSprite.show()
		interstitialSprite.addToDisplayList()
	}

	// MARK: Internal

	var transitionAnimationController = AnimationController(
		startValue: 0, endValue: 1, duration: 1000)
	var isOpaque = true

	func update() {
		if state == .exiting && fadeSprite.isFinished {
			Game.goToMain()
			return
		}

		// TODO: Don't show the "no achievements" insterstitial if there are actually achievements

		#if DEBUG
			if System.buttonState.pushed.contains(.down) {
				score += 10
			}
		#endif

		let cutoffTime =
			System.buttonState.current.contains(.b) ? msBetweenFastBlockMoves : msBetweenBlockMoves
		if state == .inGame && Int(System.currentTimeMilliseconds) - lastBlockMoveTime >= cutoffTime {
			for block in blockSprites {
				block.moveBy(dx: 0, dy: 1)
			}
			lastBlockMoveTime = Int(System.currentTimeMilliseconds)
		}

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

		let canExitToMain = Game.saveData.hasUnlockedSomething || !Game.bundles.isEmpty

		if exitMenuItem == nil {
			exitMenuItem = canExitToMain ? System.addMenuItem(title: "exit game", callback: exit) : nil
		}
		gameOverSprite.primaryAction =
			canExitToMain ? BaseView.instance!.exit : BaseView.instance!.startGame
		gameOverSprite.primaryActionText = canExitToMain ? "Trophy Case" : "Play Again"
		gameOverSprite.secondaryAction = canExitToMain ? BaseView.instance!.startGame : nil

		Graphics.pushContext(gameOverSprite.content)
		Graphics.clear(color: .white)
		Graphics.drawMode = .copy
		let bounds = Rect(origin: .zero, width: 304, height: 144)
		let score = BaseView.instance?.score ?? 0
		let best = Game.saveData.hasPlayed ? Game.saveData.maxScore : nil
		let titleText = "Game Over"
		let titleTextWidth = Graphics.Font.roobert11Bold.getTextWidth(for: titleText, tracking: 0)
		let scoreText = "Score: \(score)\(best != nil ? " Best: \(best!)" : "")"
		let scoreTextWidth = Graphics.Font.roobert10Bold.getTextWidth(for: scoreText, tracking: 0)
		let backToTitleText =
			canExitToMain
			? "Do you want to play another round or head back to Trophy Case?"
			: "Get a score of at least 100 to earn an achievement."

		// Draw title
		let titleLocation = bounds.origin.translatedBy(
			dx: (bounds.width / 2) - (Float(titleTextWidth) / 2), dy: 0)
		Graphics.setFont(.roobert11Bold)
		Graphics.drawText(titleText, at: titleLocation)

		// Draw score
		let scoreLocation = bounds.origin.translatedBy(
			dx: (bounds.width / 2) - (Float(scoreTextWidth) / 2),
			dy: Float(Graphics.Font.roobert11Bold.height))
		Graphics.setFont(.roobert10Bold)
		Graphics.drawText(scoreText, at: scoreLocation)

		// Draw back to title prompt
		let backToTitleBounds = Rect(
			origin: bounds.origin.translatedBy(
				dx: 0,
				dy: Float(Graphics.Font.roobert11Bold.height)
					+ Float(Graphics.Font.roobert10Bold.height) + 16), width: bounds.width,
			height: 50)
		Graphics.setFont(.roobert11Medium)
		Graphics.drawTextInRect(backToTitleText, in: backToTitleBounds, wrap: .word, aligned: .center)
		Graphics.popContext()
		gameOverSprite.show()
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
		lastBlockMoveTime = Int(System.currentTimeMilliseconds)

		state = .inGame
	}

	func exit() {
		// TODO: Deinitialise this view?
		if exitMenuItem != nil {
			System.removeMenuItem(exitMenuItem!)
			exitMenuItem = nil
		}
		fadeSprite.fadeToOpaque()
		state = .exiting
	}

	func dismissInterstitial() {
		startGame()
		fadeSprite.fadetoTransparent()
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
		//
	}

	// MARK: Private
	private let interstitialSprite = Dialog(content: nil, primaryAction: {})
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
	private let gameOverSprite = Dialog(
		content: nil, primaryAction: {}, primaryActionText: "Trophy Case", secondaryAction: nil,
		secondaryActionText: "Play Again")
	private let fadeSprite = Fade()
	private var lastBlockMoveTime = 0
	private let msBetweenBlockMoves = 2000
	private let msBetweenFastBlockMoves = 40

	private var exitMenuItem: System.MenuItem? = nil

	enum GameState {
		case interstitial
		case inGame
		case gameOver
		case exiting
	}
}
