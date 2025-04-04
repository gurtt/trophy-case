//
//  DateTime+CustomStringConvertible.swift
//  TrophyCase
//
//  Created by gurtt on 22/2/2025.
//

import PlaydateKit

extension System.DateTime: @retroactive CustomStringConvertible {
	public var description: String {
		let displayHour =
			System.shouldDisplay24HourTime ? hour : (hour == 0 ? 12 : hour > 12 ? hour - 12 : hour)
		let displayMinute = "\(minute < 10 ? "0" : "")\(minute)"
		let meridiem = System.shouldDisplay24HourTime ? "" : (hour < 12 ? " pm" : " am")

		return "\(year)/\(month)/\(day) \(displayHour):\(displayMinute)\(meridiem)"
	}
}
