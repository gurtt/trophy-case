//
//  Background.swift
//  TrophyCase
//
//  Created by gurtt on 23/3/2025.
//

import PlaydateKit

final class Background: Sprite.Sprite {
	override init() {
		super.init()

		image = try! Graphics.Bitmap(path: "list-bg")
		bounds = Rect(x: 0, y: 0, width: 400, height: 240)
		collisionsEnabled = false
	}
}
