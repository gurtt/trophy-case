//
//  Timer.swift
//  TrophyCase
//
//  Created by gurtt on 2/11/2024.
//

import PlaydateKit

/// Time-based timer, useful for driving animations and doing things after a delay.
///
/// Each timer maintains its own timebase and updates independently, so in a single update cycle ocurring over several miliseconds, even timers with identical start times and durations may not share the same status.
struct Timer {
	/// The expected return of `value` when the timer starts.
	var startValue: Float = 0
	/// The expected return of `value` when the timer ends.
	var endValue: Float = 0
	/// How long, in miliseconds, the timer should run for.
	var duration: Float
	/// If provided, `value` will be eased over the duration of the timer.
	var easing: Easing? = nil
	/// A closeure to be called when the timer ends.
	var endCallback: (() -> Void)? = nil
	/// Whether or not to reset the timer when it ends.
	var isRepeating: Bool = false
	/// Whether or not the timer is still running.
	var isActive: Bool = true

	var elapsed: Float = 0
	var lastTime: Int? = nil

	/// The progress through the duration of the timer, expressed as a number between 0 and 1.
	var progress: Float { easing?.ease(elapsed, duration: duration) ?? elapsed / duration }

	/// The current value of the timer, eased by `easing` if provided.
	var value: Float { lerp(from: startValue, to: endValue, using: progress) }

	/// Starts the timer again.
	mutating func reset() {
		elapsed = 0
		lastTime = nil
		isActive = true
	}

	/// Swap the start and end values of the timer with each other while inverting the progress of the timer.
	mutating func swap() {
		Swift.swap(&startValue, &endValue)
		elapsed = duration * (1 - progress)
		lastTime = nil
		isActive = true
	}

	/// Call this function once per 'tick'. The timer will update its values and call the `endCallback` if provided.
	mutating func update() {
		guard isActive else { return }

		let currentTime = Int(System.currentTimeMilliseconds)
		let deltaTime = (lastTime != nil) ? (currentTime - lastTime!) : 0
		lastTime = currentTime
		#if DEBUG
			elapsed += Float(deltaTime) * Game.timeScale
		#else
			elapsed += Float(deltaTime)
		#endif

		if elapsed >= duration {
			elapsed = duration
			endCallback?()

			if isRepeating { reset() } else { isActive = false }
		}
	}
}
