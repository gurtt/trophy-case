//
//  DateTime+Int.swift
//  TrophyCase
//
//  Created by gurtt on 22/2/2025.
//

import PlaydateKit

extension System.DateTime {
	/// Initialise a new DateTime from the supplied epoch value.
	///
	/// - Parameter epoch: The epoch value to create the DateTime from.
	init(epoch: CUnsignedInt) {
		self = System.convertEpochToDateTime(epoch)
	}
}
