//
//  Navigable.swift
//  TrophyCase
//
//  Created by gurtt on 8/1/2025.
//

protocol Navigable: AnyObject, InputHandling {
	/// The animation that a `NavigationController` will drive during a transition.
	var transitionAnimationController: AnimationController { get set }

	/// Whether the view completely covers any lower views when the transition is complete.
	var isOpaque: Bool { get }

	/// Called by the `NavigationController` every frame when the view may be visible on the screen. The view should update timers and possibly draw itself, calling `Game.requestScreenRefresh()` if needed.
	func update()

	/// Called by the `NavigationController` when the view will become current.
	func willBecomeCurrent()

	/// Called by the `NavigationController` when the view will no longer be current.
	func willResignCurrent()

	/// Called by the `NavigationController` just before removing the view from the stack.
	func willExit()
}

protocol InputHandling: AnyObject { func handleInputEvent(_ event: InputEvent) }
