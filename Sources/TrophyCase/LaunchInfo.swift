//
//  LaunchInfo.swift
//  TrophyCase
//
//  Created by gurtt on 26/2/2025.
//

import PlaydateKit

enum LaunchInfo {
	// MARK: Internal
	
	/// Generate launch info, if it's not already present.
	static func setup() {
		log("Doing setup!")
		do {
			try File.mkdir(path: "DerivedData")
		} catch {
			log("Cound't make directories for LaunchInfo: \(error)")
		}
		guard !fileExists(atPath: path) else { return }

		guard let handle = try? File.open(path: path, mode: .write) else {
			log("Couldn't open LaunchInfo")
			return
		}
		defer { try? handle.close() }

		// TODO: Log these errors
		_ = [UInt(System.secondsSinceEpoch)].withUnsafeBufferPointer { bufferPointer in
			try? handle.write(buffer: UnsafeRawBufferPointer(bufferPointer))
		}
	}

	// MARK: Private

	private static let path = "DerivedData/LaunchInfo"
}
