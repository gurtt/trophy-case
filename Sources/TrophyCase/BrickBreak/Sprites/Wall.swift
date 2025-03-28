//
//  Wall.swift
//  TrophyCase
//
//  Created by gurtt on 23/3/2025.
//

import PlaydateKit

final class Wall: Sprite.Sprite {
	override init() {
		super.init()

		isVisible = false
		tag = Sprite.type.wall.rawValue
	}

	convenience init(in bounds: Rect, at location: Point) {
		self.init()
		self.bounds = bounds
		collideRect = self.bounds
		center = .zero
		moveTo(location)
	}

	override func collisionResponse(other _: Sprite.Sprite) -> Sprite.CollisionResponseType {
		.bounce
	}
}
