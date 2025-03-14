//
//  Graphics+ClipRectStack.swift
//  TrophyCase
//
//  Created by gurtt on 22/2/2025.
//

import PlaydateKit

extension Graphics {
	// MARK: Internal

	/// Push a new clip rectangle to the stack.
	///
	/// The resulting clip rect for draw calls is the intersection of all rects on the stack.
	///
	/// - Parameter rect: The rect to add to the stack.
	static func pushClipRect(_ rect: Rect) {
		guard let last = clipRectStack.last else {
			clipRectStack.append(rect)
			return
		}
		clipRectStack.append(rect.intersecting(last))
	}

	/// Pop the last clip rect from the stack.
	///
	/// The resulting clip rect for draw calls is the intersection of all rects on the stack.
	static func popClipRect() { clipRectStack.removeLast() }

	/// Remove all clip rects from the stack.
	static func clearClipRects() { clipRectStack.removeAll() }

	// MARK: Private

	static private nonisolated(unsafe) var clipRectStack: [Rect] = [] {
		didSet {
			guard let last = clipRectStack.last else {
				Graphics.clearClipRect()
				return
			}
			Graphics.setClipRect(last)
		}
	}
}
