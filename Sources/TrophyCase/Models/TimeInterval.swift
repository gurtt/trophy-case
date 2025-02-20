//
//  TimeInterval.swift
//  TrophyCase
//
//  Created by gurtt on 10/11/2024.
//

struct TimeInterval: CustomStringConvertible {
	let seconds: Int

	init(spanning seconds: Int = 0) { self.seconds = seconds }

	var years: Int { seconds / 31_556_952 }

	var months: Int { seconds / 2_629_746 }

	var weeks: Int { seconds / 604800 }

	var days: Int { seconds / 86400 }

	var hours: Int { seconds / 3600 }

	var minutes: Int { seconds / 60 }

	var description: String {
		abs(years) > 0
			? "\(years)y"
			: abs(months) > 0
				? "\(months)mo"
				: abs(weeks) > 0
					? "\(weeks)w"
					: abs(days) > 0
						? "\(days)d"
						: abs(hours) > 0 ? "\(hours)h" : abs(minutes) > 0 ? "\(minutes)min" : "\(seconds)s"
	}
}
