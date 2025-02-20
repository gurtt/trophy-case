//
//  MenuItemHelper.swift
//  TrophyCase
//
//  Created by gurtt on 21/1/2025.
//

import PlaydateKit

/// Adds an options menu item.
/// - Parameters:
///   - title: The title of the menu item.
///   - options: The names of the options to show.
///   - initialValue: The index of the option to set as the initial selection.
///   - callback: The callback to run when the selected option changes. The callback is passed the index of the `options` item that was selected.
/// - Returns: The menu item.
func addOptionsMenuItem(
	_ title: String, options: [String], initialValue: Int = 0,
	callback: @escaping (_ selectedOptionNumber: Int) -> Void
) -> System.OptionsMenuItem {
	let menuItem = options.withUnsafeCStringBufferPointer({ pointer in
		System.addOptionsMenuItem(title: title, options: pointer, callback: callback)
	})
	menuItem.selectedOption = initialValue

	return menuItem
}
