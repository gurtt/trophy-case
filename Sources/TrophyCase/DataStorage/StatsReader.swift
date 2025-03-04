//
//  StatsReader.swift
//  TrophyCase
//
//  Created by gurtt on 4/3/2025.
//

import PlaydateKit

enum StatsReader {
	private static let path = "DerivedData/UnlockHistory"

	struct DecodeError: Error, CustomStringConvertible {
		init(_ description: String = "") {
			self.description = description
		}

		let description: String
	}

	static func write(_ newValue: UInt) {
		do {
			try File.mkdir(path: "DerivedData")
		} catch {
			log("Cound't make directories for UnlockHistory: \(error)")
		}

		guard let handle = try? File.open(path: path, mode: .write) else {
			log("Couldn't open UnlockHistory")
			return
		}
		defer { try? handle.close() }

		// TODO: Log these errors
		_ = [newValue].withUnsafeBufferPointer { bufferPointer in
			try? handle.write(buffer: UnsafeRawBufferPointer(bufferPointer))
		}
	}

	static func read() -> UInt? {
		guard let handle = try? File.open(path: path, mode: .readData) else {
			log("Couldn't open UnlockHistory")
			return nil
		}
		defer { try? handle.close() }

		let dataPointer = UnsafeMutablePointer<UInt>.allocate(capacity: 1)
		defer { dataPointer.deallocate() }
		let bytesRead = try? handle.read(
			buffer: dataPointer, length: CUnsignedInt(MemoryLayout<UInt>.stride))
		guard bytesRead == MemoryLayout<UInt>.stride else {
			return nil
		}
		return dataPointer.pointee
	}
}
