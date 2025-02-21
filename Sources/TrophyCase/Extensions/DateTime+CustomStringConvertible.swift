//
//  DateTime+CustomStringConvertible.swift
//  TrophyCase
//
//  Created by gurtt on 22/2/2025.
//

import PlaydateKit

extension System.DateTime: @retroactive CustomStringConvertible {
	public var description: String {
		let hour =
			System.shouldDisplay24HourTime ? hour : (hour == 0 ? 12 : hour > 12 ? hour - 12 : hour)
		let meridiem = System.shouldDisplay24HourTime ? "" : (hour < 12 ? " AM" : " PM")

		return "\(year)/\(month)/\(day) \(hour):\(minute):\(second)\(meridiem)"
	}
}
