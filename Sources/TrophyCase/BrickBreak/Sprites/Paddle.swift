//
//  Paddle.swift
//  TrophyCase
//
//  Created by gurtt on 22/3/2025.
//

import PlaydateKit

final class Paddle: Sprite.Sprite {
	override init() {
		super.init()

		image = try! Graphics.Bitmap(path: "BrickBreak/paddle")
		bounds = Rect(x: 0, y: 0, width: 80, height: 16)
		collideRect = bounds
		tag = Sprite.type.paddle.rawValue
		moveTo(Paddle.initialPosition)
	}

	override func update() {
		guard BaseView.instance?.state == .inGame else { return }

		// TODO: Add menu option to change this
		let paddleButtonVelocity: Float = 8

		let buttons = System.buttonState.current
		let dx: Float =
			if buttons != .left, buttons == .right {
				paddleButtonVelocity
			} else if buttons == .left, buttons != .right {
				-paddleButtonVelocity
			} else {
				System.crankChange
			}

		if dx > 0 {
			hasMoved = true
		}

		let xPadding: Float = 4
		let minX = (self.bounds.width / 2) + xPadding
		let maxX = Float(Display.width) - (self.bounds.width / 2) - xPadding

		moveWithCollisions(goal: Point(x: (position.x + dx).clamped(to: minX...maxX), y: position.y))
	}

	func reset() {
		moveTo(Paddle.initialPosition)
		hasMoved = false
	}

	var hasMoved = false

	private static nonisolated(unsafe) var initialPosition = Point(
		x: Float(Display.width / 2), y: Float(Display.height - 16))
}
