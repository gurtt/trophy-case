//
//  Reader.swift
//  TrophyCase
//
//  Created by gurtt on 23/1/2025.
//

import CPlaydate
import PlaydateKit

extension Playdate.Error {

}

enum PreferencesReader {
	static let preferencesFilePath = "default.preferences"

	// MARK: Read
	struct DecodeError: Error, CustomStringConvertible {
		init(_ description: String = "") {
			self.description = description
		}

		let description: String
	}

	struct Options: OptionSet {
		static let showFullTime = Options(rawValue: 1 << 0)
		static let showHiddenAchievements = Options(rawValue: 1 << 1)
		static let playMusic = Options(rawValue: 1 << 2)

		let rawValue: UInt8
	}

	typealias StructHeader = (
		dataSectionOffset: UInt32, dataSectionSize: UInt16, pointerSectionSize: UInt16
	)

	static func readPreferences() -> Preferences {
		guard let fileHandle = try? File.open(path: preferencesFilePath, mode: .readData) else {
			log("Can't open preferences file")
			return Preferences()
		}
		defer { try? fileHandle.close() }

		guard let header = try? readHeader(from: fileHandle) else {
			log("Can't read preferences file")
			return Preferences()
		}

		guard header.dataSectionSize == 1 else {
			log("Preferences file has invalid size \(header.dataSectionSize)")
			return Preferences()
		}

		let bundlesViewModeRaw: UInt16 = read(from: fileHandle) ?? 0
		let bundlesViewMode = BundlesViewMode(rawValue: Int(bundlesViewModeRaw))!
		let bundlesSortOrderRaw: UInt16 = read(from: fileHandle) ?? 0
		let bundlesSortOrder = BundlesSortOrder(rawValue: Int(bundlesSortOrderRaw))!

		let optionsRaw: UInt8 = read(from: fileHandle) ?? 0b00000001
		let options = Options(rawValue: UInt8(optionsRaw))

		return Preferences(
			bundlesViewMode: bundlesViewMode,
			bundlesSortOrder: bundlesSortOrder,
			showFullTime: options.contains(.showFullTime),
			showHiddenAchievements: options.contains(.showHiddenAchievements),
			playMusic: options.contains(.playMusic)
		)
	}

	static private func readHeader(from handle: File.FileHandle) throws(DecodeError) -> StructHeader {
		// Get data section offset
		let dataSectionOffsetPointer = UnsafeMutablePointer<UInt32>.allocate(capacity: 1)
		defer { dataSectionOffsetPointer.deallocate() }
		guard ((try? handle.read(buffer: dataSectionOffsetPointer, length: 4) == 8) != nil) else {
			throw DecodeError("Unexpected end of file")
		}

		let maxOffset: UInt32 = 0b00111111111111111111111111111111
		guard dataSectionOffsetPointer.pointee <= maxOffset else {
			throw DecodeError("Invalid struct pointer flags")
		}
		// Get data section size
		let dataSectionSizePointer = UnsafeMutablePointer<UInt16>.allocate(capacity: 1)
		defer { dataSectionSizePointer.deallocate() }
		guard ((try? handle.read(buffer: dataSectionSizePointer, length: 2) == 2) != nil) else {
			throw DecodeError("Unexpected end of file")
		}
		// Get pointer section size
		let pointerSectionSizePointer = UnsafeMutablePointer<UInt16>.allocate(capacity: 1)
		defer { pointerSectionSizePointer.deallocate() }
		guard ((try? handle.read(buffer: pointerSectionSizePointer, length: 2) == 2) != nil) else {
			throw DecodeError("Unexpected end of file")
		}

		return (
			dataSectionOffsetPointer.pointee, dataSectionSizePointer.pointee,
			pointerSectionSizePointer.pointee
		)
	}

	static private func read<T>(from handle: File.FileHandle) -> T? {
		let dataPointer = UnsafeMutablePointer<T>.allocate(capacity: 1)
		defer { dataPointer.deallocate() }
		let bytesRead = try? handle.read(
			buffer: dataPointer, length: CUnsignedInt(MemoryLayout<T>.stride))
		guard bytesRead == MemoryLayout<T>.stride else {
			return nil
		}
		return dataPointer.pointee
	}

	// MARK: Write

	static func writePreferences(_ preferences: Preferences) {
		guard let fileHandle = try? File.open(path: preferencesFilePath, mode: .write) else {
			log("Can't open preferences file")
			return
		}
		defer { try? fileHandle.close() }

		// Write header
		let header = (
			dataSectionOffset: UInt32(0), dataSectionSize: UInt16(1), pointerSectionSize: UInt16(0)
		)
		do {
			try writeHeader(header, to: fileHandle)
		} catch {
			log("Can't write to preferences file")
		}

		// Write bundlesViewMode
		try? write(UInt16(preferences.bundlesViewMode.rawValue), to: fileHandle)

		// Write bundlesSortOrder
		try? write(UInt16(preferences.bundlesSortOrder.rawValue), to: fileHandle)

		// Write options
		var options = Options()
		if preferences.showFullTime { options.insert(.showFullTime) }
		if preferences.showHiddenAchievements { options.insert(.showHiddenAchievements) }
		if preferences.playMusic { options.insert(.playMusic) }

		try? write(options.rawValue, to: fileHandle)
	}

	static private func writeHeader(
		_ header: StructHeader, to handle: File.FileHandle
	) throws(DecodeError) {
		try write(header.dataSectionOffset, to: handle)
		try write(header.dataSectionSize, to: handle)
		try write(header.pointerSectionSize, to: handle)
	}

	static private func write<T>(_ data: T, to handle: File.FileHandle) throws(DecodeError) {
		guard
			(([data].withUnsafeBufferPointer { bufferPointer in
				try? handle.write(buffer: UnsafeRawBufferPointer(bufferPointer))
			}) != nil)
		else {
			throw DecodeError()
		}

	}
}
