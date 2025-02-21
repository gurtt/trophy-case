//
//  DateTime+FileStat.swift
//  TrophyCase
//
//  Created by gurtt on 21/2/2025.
//

import PlaydateKit

extension System.DateTime {
	/// Initialise a new DateTime from the supplied FileStat.
	///
	/// > Warning: The created DateTime's `weekday` property will always be set to zero.
	///
	/// - Parameter fileStat: The FileStat to create the DateTime from.
	init(fileStat: FileStat) {
		self.init(
			year: UInt16(fileStat.m_year),
			month: UInt8(fileStat.m_month),
			day: UInt8(fileStat.m_day),
			weekday: 0,
			hour: UInt8(fileStat.m_hour),
			minute: UInt8(fileStat.m_minute),
			second: UInt8(fileStat.m_second)
		)
	}
}
