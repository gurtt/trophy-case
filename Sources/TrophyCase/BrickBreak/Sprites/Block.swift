//
//  Block.swift
//  TrophyCase
//
//  Created by gurtt on 23/3/2025.
//

import PlaydateKit

final class Block: Sprite.Sprite {
	override init() {
		super.init()

		image = try! Graphics.Bitmap(path: "BrickBreak/block")
		bounds = Rect(x: 0, y: 0, width: 34, height: 18)
		collideRect = bounds
		tag = Sprite.type.block.rawValue
	}

	convenience init(at location: Point) {
		self.init()
		moveTo(location)
	}

	override func update() {
		guard BaseView.instance?.state == .inGame else { return }

		moveBy(dx: 0, dy: 0.01 * (System.buttonState.current.contains(.b) ? 50 : 1))

		guard position.y < Block.maxY - (bounds.height / 2) else {
			BaseView.instance?.endGame()
			return
		}
	}

	func hit() {
		moveBy(dx: 0, dy: -168)
		BaseView.instance?.score += 1
	}

	static let maxY: Float = 180
}
