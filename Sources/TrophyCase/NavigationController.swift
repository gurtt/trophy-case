//
//  NavigationController.swift
//  TrophyCase
//
//  Created by gurtt on 28/12/2024.
//

struct NavigationController {
	private var views: [any Navigable]
	private var activeViewIndex: Array.Index {
		didSet {
			views[oldValue].willResignCurrent()
			views[activeViewIndex].willBecomeCurrent()
		}
	}

	private var activeView: any Navigable { views[activeViewIndex] }
	var isTransitioning: Bool {
		views.last!.transitionAnimationController.isAnimating
	}

	// TODO: Rename 'current' to 'active' and keep track of which view is active
	// TODO: Separate things into lifecycle, internal, private
	// TODO: Support overlay view (the ticker) (how do we pass it events?)
	init(withRoot view: any Navigable) {
		views = [view]
		activeViewIndex = 0
		activeView.transitionAnimationController.skip(to: .end)

		// Initialising activeViewIndex doesn't call didSet
		activeView.willBecomeCurrent()
	}

	/// Adds a new view to the stack and starts a transition animation.
	/// - Parameters:
	///   - view: The view to push to the stack.
	///   - animated: If true, the controller will use the new view's ``transitionAnimationController`` to animate the transition. If false, the transition animation will skip to the end immediately.
	mutating func push(_ view: any Navigable, animated: Bool = true) {
		// TODO: If we're in the middle of popping a view and the new one being pushed is the same, ignore the change reverse the transition instead.

		views.append(view)
		activeViewIndex = views.count - 1

		if animated {
			activeView.transitionAnimationController.animate(to: .end)
		} else {
			activeView.transitionAnimationController.skip(to: .end)
		}
	}

	/// Removes the frontmost view from the stack and starts a transition in reverse.
	mutating func pop() {
		guard views.count > 1 else {
			log("Cannot remove the root view of a NavigationController")
			return
		}

		activeViewIndex = views.count - 2
		views.last!.transitionAnimationController.animate(to: .start)
	}

	mutating func update() {
		guard let frontmostView = views.last else { return }

		// If the front view's transition is finished and at the start, we just finished a pop transition
		if !frontmostView.transitionAnimationController.isAnimating
			&& frontmostView.transitionAnimationController.targetState == .start
		{
			frontmostView.willExit()
			views.removeLast()
		}

		for view in views { view.update() }

		// TODO: This is temporary, but for the views we have now, the screen will always need an update.
		Game.requestScreenUpdate()
	}

	func handleInputEvent(_ event: InputEvent) {
		guard !views.isEmpty else { return }

		let frontmostViewIndex = views.count - 1
		views[frontmostViewIndex].handleInputEvent(event)
	}
}
