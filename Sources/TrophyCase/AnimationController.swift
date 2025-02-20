//
//  AnimationController.swift
//  TrophyCase
//
//  Created by gurtt on 8/1/2025.
//

import PlaydateKit

struct AnimationController {
	// TODO: Lifecycle, internal, private
	// TODO: Doc comments on all of this that are a bit more descriptive and actually correct
	// TODO: The reversing behaviour seems a bit wonky (like it's taking more data and computation than it should). Consider refactor.

	/// The length of time, in miliseconds, that the animation should last.
	let duration: Int

	/// Whether the animation is currently animating in either direction.
	var isAnimating: Bool { return value != targetValue }

	/// The value at which the animation starts.
	let startValue: Float

	/// The value at which the animation ends.
	let endValue: Float

	/// If provided, `value` will be eased over the duration of the timer.
	let easing: Easing?

	/// The current value of the animation.
	var value: Float {
		switch fromState { case .start:
			lerp(from: startValue, to: endValue, using: easing?.ease(progress) ?? progress)
			case .end:
				lerp(from: endValue, to: startValue, using: easing?.ease(1 - progress) ?? 1 - progress)
		}
	}

	/// How far along between startValue and endValue the animation is, expressed as a unit interval.
	private var progress: Float = 0

	private var isAnimatingForwards = true

	enum AnimationTargetState {
		case start
		case end
	}

	var targetState: AnimationTargetState { isAnimatingForwards ? .end : .start }

	var fromState: AnimationTargetState = .start

	/// Start dirving the animation towards the target state.
	/// - Parameter state: Which state to drive the animation towards. If the animation is already at the target state, nothing will happen.
	mutating func animate(to state: AnimationTargetState = .end) {
		if !isAnimating { fromState = targetState }
		isAnimatingForwards = state == .end
	}

	/// Drive the animation towards the target state by immediately skipping to the target state.
	/// - Parameter state: Which state to skip to. If the animation is already at the target state, nothing will happen.
	mutating func skip(to state: AnimationTargetState) {
		progress = state == .end ? 1 : 0
		animate(to: state)
	}

	private var targetValue: Float { return isAnimatingForwards ? endValue : startValue }

	/// Called when the animation reaches its `endValue`. Won't be called when the controller is repeating and its target is start.
	var endCallback: () -> Void

	/// Called when the animation reaches its `startValue`. Won't be called when the controller is repeating and its target is end.
	var startCallback: () -> Void

	/// If true, the timer will repeat once it reaches its target value.
	var isRepeating: Bool

	private var lastTime: Int? = nil

	/// Update the animation controller.
	/// - Parameter timeBase: The number of miliseconds since some point in time that is stable between calls.
	mutating func tick(using timeBase: Int = Int(System.currentTimeMilliseconds)) {
		guard isAnimating else {
			lastTime = nil  // Prevent the animation from considering time passed since it last finished
			return
		}

		let deltaTime = (lastTime != nil) ? (timeBase - lastTime!) : 0
		lastTime = timeBase

		let deltaProgress = Float(deltaTime) / Float(duration)
		let deltaFactor = isAnimatingForwards ? 1 : -1

		progress += deltaProgress * Float(deltaFactor)
		progress.clamp(to: 0...1)

		if !isAnimating {  // controller has reached the target
			switch targetState { case .start: startCallback() case .end: endCallback()
			}

			if isRepeating {
				// set progress to the opposite of whatever the target progress is
				progress = targetState == .end ? 0 : 1
			}
		}
	}

	init(
		startValue: Float, endValue: Float, duration: Int, easing: Easing? = nil,
		isRepeating: Bool = false, startCallback: @escaping () -> Void = {},
		endCallback: @escaping () -> Void = {}
	) {
		self.startValue = startValue
		self.endValue = endValue
		self.duration = duration
		self.easing = easing
		self.isRepeating = isRepeating
		self.startCallback = startCallback
		self.endCallback = endCallback
	}
}
