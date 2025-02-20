//
//  Scene.swift
//  TrophyCase
//
//  Created by gurtt on 3/11/2024.
//

import PlaydateKit

protocol Scene {
	/// Update the scene, possibly drawing to the screen.
	func update()

	/// Handle input from the system.
	///
	/// The caller is responsible for validting that the scene should respond to the event.
	///
	/// This will always be called for all pending input events before update is called in the same frame.
	/// - Parameter event: the event that was raised.
	func handleInputEvent(_ event: InputEvent)

	func willExitScene()
	func didExitScene()
	func willEnterScene()
	func didEnterScene()
}
