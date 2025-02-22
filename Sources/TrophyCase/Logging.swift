//
//  Logging.swift
//  TrophyCase
//
//  Created by gurtt on 27/12/2024.
//

/// Log a message that only appears when built for debugging.
///
/// In production builds, this function does nothing.
///
/// - Parameter message: The message to log.
func log(_ message: String) {
	#if DEBUG
		print(message)
	#endif
}
