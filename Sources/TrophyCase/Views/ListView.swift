//
//  ListView.swift
//  TrophyCase
//
//  Created by gurtt on 29/10/2024.
//

import PlaydateKit

/// Displays a one-dimensional list of items.
struct ListView {
	/// The function to call when the ListView needs to draw a cell. The first parameter is the index of the item to draw, the second parameter is the bounds in which the item is expected to be drawn, and the last parameter indicates if the item to be drawn is the currently selected item.
	var drawItem: (_ forItem: Int, _ in: Rect, _ isSelected: Bool) -> Void
	/// The index of the selected item.
	var selectedItemIndex: Int? {
		didSet {
			let currentScrollPosition = scrollTimer.value
			scrollTimer.reset()
			scrollTimer.startValue = currentScrollPosition
		}
	}
	/// The total number of items in the list.
	var totalItems: Int
	/// The drawn height of a single list item.
	var itemHeight: Float
	/// The space between the top and bottom edges of each item, and between the top and bottom edges of the view bounds when scrolled to the first and last item, respectively.
	var itemHorizontalSpacing: Float = 0.0
	/// The space between the left and right edges of the view bounds and the item bounds.
	var itemVerticalSpacing: Float = 0.0
	/// The image drawn behind list items. The background image doesn't scroll with content.
	var backgroundImage: Graphics.Bitmap? = nil

	var scrollTimer: Timer = Timer(duration: 250, easing: .outQuad)

	mutating func draw(in viewBounds: Rect) {
        Graphics.pushClipRect(viewBounds)
        defer { Graphics.popClipRect() }
        
		Graphics.drawMode = .copy

		if let backgroundImage {
			Graphics.drawBitmap(backgroundImage, at: .zero)
		} else {
			Graphics.fillRect(viewBounds, color: .white)
		}

		var targetScrollPosition: Float = 0
		if selectedItemIndex != nil {
			let topEdge =
				(Float(selectedItemIndex!) * (itemHeight + itemVerticalSpacing)) + itemVerticalSpacing
			let contentHeight =
				(Float(totalItems) * (itemHeight + itemVerticalSpacing)) + itemVerticalSpacing

			targetScrollPosition = (topEdge + itemHeight / 2) - viewBounds.height / 2

			if targetScrollPosition < 0 {
				targetScrollPosition = 0
			} else if targetScrollPosition > contentHeight - viewBounds.height {
				targetScrollPosition = max(0, contentHeight - viewBounds.height)
			}
		}

		scrollTimer.endValue = targetScrollPosition
		scrollTimer.update()

		var itemBounds = Rect(
			x: viewBounds.x + itemHorizontalSpacing,
			y: -scrollTimer.value + itemVerticalSpacing + viewBounds.y,
			width: viewBounds.width - itemHorizontalSpacing * 2, height: itemHeight)

		for i in 0..<totalItems {
			defer { itemBounds.y += itemHeight + itemVerticalSpacing }

			// If the bottom edge of the item is above the top edge of the view bounds, skip drawing
			guard Int32(itemBounds.y + itemHeight) >= viewBounds.lcdRect.top else { continue }

			// If the top of the item is below the bottom edge of the view bounds, stop drawing items
			guard Int32(itemBounds.y) <= viewBounds.lcdRect.bottom else { break }

			drawItem(i, itemBounds, selectedItemIndex == i)
		}
	}
}

/// Draws a rectangle with the provided text.
///
/// Items are drawn as a white rectangle with black text. When selected, items are drawn as a black rectangle with white text.
///
/// - Parameters:
///   - text: the text to draw.
///   - bounds: the rectangle within which to draw the text.
///   - isSelected: whether to draw the list item as selected.
func drawListItem(_ text: String, in bounds: Rect, isSelected: Bool) {
	Graphics.pushContext()
	defer { Graphics.popContext() }

	Graphics.fillRect(bounds, color: isSelected ? .black : .white)
	Graphics.drawMode = .nxor
	Graphics.drawText(text, at: bounds.origin.translatedBy(dx: 4, dy: 2))
}
