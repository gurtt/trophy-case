//
//  Logger.swift
//  TrophyCase
//
//  Created by gurtt on 27/12/2024.
//

struct Logger {
	enum Level: String, CaseIterable, CustomStringConvertible {
		/// Appropriate for messages that contain information normally of use only when tracing the execution of a program.
		case trace

		/// Appropriate for messages that contain information normally of use only when debugging a program.
		case debug

		/// Appropriate for informational messages.
		case info

		/// Appropriate for conditions that are not error conditions, but that may require special handling.
		case warning

		/// Appropriate for error conditions.
		case error

		var description: String {
			switch self { case .trace: return "TRACE" case .debug: return "DEBUG" case .info:
				return "INFO"
				case .warning: return "WARN"
				case .error: return "ERROR"
			}
		}
	}

	/// The log level.
	///
	/// Log levels are ordered by their severity, with `.trace` being the least severe and `.error` being the most severe.
	#if DEBUG
		static let level: Level = .trace
	#else
		static let level: Level = .info
	#endif

	@inlinable static func log(_ message: String, level: Level, file: String = #fileID) {
		if Logger.level <= level { print("\(file): \(message)") }
	}
}

extension Logger.Level {
	internal var naturalIntegralValue: Int {
		switch self { case .trace: return 0 case .debug: return 1 case .info: return 2 case .warning:
			return 3
			case .error: return 4
		}
	}
}

extension Logger.Level: Comparable {
	static func < (lhs: Logger.Level, rhs: Logger.Level) -> Bool {
		lhs.naturalIntegralValue < rhs.naturalIntegralValue
	}
}
