//
//  Rect+Screen.swift
//  TrophyCase
//
//  Created by gurtt on 22/2/2025.
//

import PlaydateKit

extension Rect {
	/// A rectangle representing the entire display.
	public static var screen: Rect { Rect(x: 0, y: 0, width: Display.width, height: Display.height) }
}
