//
//  KeyRepeat.swift
//  TrophyCase
//
//  Created by gurtt on 21/2/2025.
//

class KeyRepeat {
	// MARK: Lifecycle

	init(initialDelay: Int = 300, repeatInterval: Int = 100, callback: @escaping () -> Void) {
		self.preTimer = AnimationController(startValue: 0, endValue: 1, duration: initialDelay)
		self.repeatTimer = AnimationController(
			startValue: 0, endValue: 1, duration: repeatInterval, isRepeating: true)
		self.endCallback = callback

		preTimer.endCallback = { [self] in repeatTimer.animate(to: .end) }
		repeatTimer.endCallback = { [self] in endCallback() }

		preTimer.skip(to: .start)
		repeatTimer.skip(to: .start)
	}

	// MARK: Internal

	func tick() {
		preTimer.tick()
		repeatTimer.tick()
	}

	func start() {
		preTimer.animate(to: .end)
	}

	func stop() {
		preTimer.skip(to: .start)
		repeatTimer.skip(to: .start)
	}

	// MARK: Private

	private var preTimer: AnimationController
	private var repeatTimer: AnimationController

	var endCallback: () -> Void
}
