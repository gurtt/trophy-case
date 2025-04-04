//
//  Ball.swift
//  TrophyCase
//
//  Created by gurtt on 22/3/2025.
//

import PlaydateKit

final class Ball: Sprite.Sprite {
	override init() {
		super.init()

		image = try! Graphics.Bitmap(path: "BrickBreak/ball")
		collisionsEnabled = true
		bounds = Rect(x: 0, y: 0, width: 12, height: 12)
		collideRect = bounds
		tag = Sprite.type.ball.rawValue
		moveTo(Ball.initialPosition)
	}

	override func collisionResponse(other _: Sprite.Sprite) -> Sprite.CollisionResponseType {
		.bounce
	}

	override func update() {
		let goalPosition = position.translatedBy(dx: velocity.x, dy: velocity.y)

		let collisions = moveWithCollisions(goal: goalPosition)

		guard position.y < 240 else {
			BaseView.instance?.endGame()
			return
		}

		for collision in collisions.collisions {
			let other = collision.other
			var normal = Vector2D(collision.normal)

			guard let otherType = Sprite.type(rawValue: other.tag) else { break }
			switch otherType {
				case .block:
					(other as! Block).hit()
					break
				case .paddle:
					let paddleBounds = other.bounds
					let paddleHalfWidth = paddleBounds.width / 2
					let placement = (collision.touch.x - (paddleBounds.x + paddleHalfWidth)) / paddleHalfWidth
					let deflectionAngle = placement * (.pi / 6) * 0.75
					normal.rotate(by: deflectionAngle)
				default:
					break
			}

			velocity.reflect(along: normal)
		}
	}

	func reset() {
		moveTo(Ball.initialPosition)
		velocity = Ball.initialVelocity
	}

	private var velocity = Vector2D(radius: 0, theta: 0)

	private static let initialVelocity = Vector2D(radius: 2, theta: .pi / 2)
	private static nonisolated(unsafe) let initialPosition = Point(x: 206, y: 140)
}
