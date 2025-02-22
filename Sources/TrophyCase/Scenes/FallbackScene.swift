//
//  FallbackScene.swift
//  TrophyCase
//
//  Created by gurtt on 3/11/2024.
//

import PlaydateKit

final class FallbackScene: Scene {
	private var image: Graphics.Bitmap
	private var hasDrawnCurrent = false

	var identifier: String = "" { didSet { hasDrawnCurrent = false } }
	var message: String = "" { didSet { hasDrawnCurrent = false } }

	enum Variant: String {
		case message = "trophy-mini"
		case missing = "trophy-mini-huh"
		case broken = "trophy-mini-crack"
	}
	var variant: Variant = .message {
		didSet {
			image = FallbackScene.loadImage(for: variant)
			hasDrawnCurrent = false
		}
	}

	init() { image = FallbackScene.loadImage(for: variant) }

	func update() {
		guard !hasDrawnCurrent else { return }

		Graphics.clear(color: .white)
		Graphics.drawBitmap(image, at: Point(x: 24, y: 48))
		Graphics.drawText(identifier, at: Point(x: 24, y: 124))
		Graphics.drawText(message, at: Point(x: 24, y: 148))

		Graphics.display()
		hasDrawnCurrent = true
	}

	static func loadImage(for variant: Variant) -> Graphics.Bitmap {
		do { return try Graphics.Bitmap(path: variant.rawValue) } catch {
			log("Can't load fallback scene image: \(error)")
			return Graphics.Bitmap(width: 64, height: 64, bgColor: .white)
		}
	}

	func handleInputEvent(_ event: InputEvent) {}
	func willExitScene() {}
	func didExitScene() {}
	func willEnterScene() {}
	func didEnterScene() {}
}
