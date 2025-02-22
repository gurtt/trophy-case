//
//  Preferences.swift
//  TrophyCase
//
//  Created by gurtt on 22/12/2024.
//

import PlaydateKit

func loadPreferences() -> Preferences {
	var preferences = Preferences()

	let filePath = "preferences.dat"
	let fileIdentifier = "TCP"

	guard let fileHandle = try? File.open(path: filePath, mode: .readData) else {
		log("Can't open preferences file; using defaults")
		return preferences
	}
	defer { try? fileHandle.close() }

	// MARK: File identifier

	let p = UnsafeMutableRawPointer.allocate(
		byteCount: fileIdentifier.count + 1, alignment: MemoryLayout<UInt8>.alignment)
	defer { p.deallocate() }

	do { _ = try fileHandle.read(buffer: p, length: 4) } catch {
		log("Can't read identifier from preferences file: \(error.description)")
		return preferences
	}

	let boundPointer: UnsafeMutablePointer<CChar> = p.bindMemory(
		to: CChar.self, capacity: fileIdentifier.count + 1)
	let readFileIdentifier = String(cString: boundPointer)

	guard readFileIdentifier == fileIdentifier else {
		log(
			"Preferences file identifier is invalid (expected \"\(fileIdentifier)\", got \"\(readFileIdentifier)\""
		)
		return preferences
	}

	// MARK: viewMode

	let viewModePref = UnsafeMutableRawPointer.allocate(
		byteCount: 1, alignment: MemoryLayout<UInt8>.alignment)
	defer { viewModePref.deallocate() }

	do { _ = try fileHandle.read(buffer: viewModePref, length: 1) } catch {
		log("Can't read viewModePref from file: \(error.description)")
	}

	let viewModePrefBoundPointer: UnsafeMutablePointer<UInt8> = viewModePref.bindMemory(
		to: UInt8.self, capacity: 1)
	let readViewModePref = Int(viewModePrefBoundPointer.pointee)

	if 0 <= readViewModePref && readViewModePref < BundlesViewMode.allCases.count {
		preferences.bundlesViewMode = BundlesViewMode.allCases[readViewModePref]
	} else {
		log("Invalid viewModePref value: \(readViewModePref)")
	}

	// MARK: sortOrder

	let sortOrderPref = UnsafeMutableRawPointer.allocate(
		byteCount: 1, alignment: MemoryLayout<UInt8>.alignment)
	defer { sortOrderPref.deallocate() }

	do {
		_ = try fileHandle.seek(to: 5, seek: .beginning)
		_ = try fileHandle.read(buffer: sortOrderPref, length: 1)
	} catch {
		log("Couldn't read sortOrderPref from file: \(error.description)")
	}

	let sortOrderPrefBoundPointer: UnsafeMutablePointer<UInt8> = sortOrderPref.bindMemory(
		to: UInt8.self, capacity: 1)
	let readSortOrderPref = Int(sortOrderPrefBoundPointer.pointee)

	if 0 <= readSortOrderPref && readSortOrderPref < BundlesSortOrder.allCases.count {
		preferences.bundlesSortOrder = BundlesSortOrder.allCases[readSortOrderPref]
	} else {
		log("Invalid sortOrderPref value: \(readSortOrderPref)")
	}

	// MARK: showFullTime

	let showFullTimePref = UnsafeMutableRawPointer.allocate(
		byteCount: 1, alignment: MemoryLayout<UInt8>.alignment)
	defer { showFullTimePref.deallocate() }

	do {
		_ = try fileHandle.seek(to: 6, seek: .beginning)
		_ = try fileHandle.read(buffer: showFullTimePref, length: 1)
	} catch {
		log("Couldn't read showFullTimePref from file: \(error.description)")
	}

	let showFullTimePrefBoundPointer: UnsafeMutablePointer<UInt8> = showFullTimePref.bindMemory(
		to: UInt8.self, capacity: 1)
	let readShowFullTimePref = Int(showFullTimePrefBoundPointer.pointee)

	if readShowFullTimePref == 1 { preferences.showFullTime = true }

	// MARK: showHiddenAchievements

	let showHiddenAchievementsPref = UnsafeMutableRawPointer.allocate(
		byteCount: 1, alignment: MemoryLayout<UInt8>.alignment)
	defer { showHiddenAchievementsPref.deallocate() }

	do { _ = try fileHandle.seek(to: 7, seek: .beginning) } catch {
		log("Couldn't read showHiddenAchievementsPref from file: \(error.description)")
	}

	let showHiddenAchievementsPrefBoundPointer: UnsafeMutablePointer<UInt8> =
		showHiddenAchievementsPref.bindMemory(to: UInt8.self, capacity: 1)
	let readShowHiddenAchievementsPref = Int(showHiddenAchievementsPrefBoundPointer.pointee)

	if readShowHiddenAchievementsPref == 1 { preferences.showHiddenAchievements = true }

	return preferences
}

func savePreferences(_ preferences: Preferences) {
	let filePath = "preferences.dat"
	let fileIdentifier = "TCP"

	guard let fileHandle = try? File.open(path: filePath, mode: .write) else {
		log("Couldn't open in write mode")
		return
	}
	defer { try? fileHandle.close() }

	fileIdentifier.withCString { stringPointer in
		let bp = UnsafeRawBufferPointer.init(start: stringPointer, count: 4)
		_ = try! fileHandle.write(buffer: bp)
	}

	[preferences.bundlesViewMode].withUnsafeBufferPointer { bufferPointer in
		_ = try! fileHandle.write(buffer: UnsafeRawBufferPointer(bufferPointer))
	}

	[preferences.bundlesSortOrder].withUnsafeBufferPointer { bufferPointer in
		_ = try! fileHandle.write(buffer: UnsafeRawBufferPointer(bufferPointer))
	}

	[preferences.showFullTime ? 1 : 0].withUnsafeBufferPointer { bufferPointer in
		_ = try! fileHandle.write(buffer: UnsafeRawBufferPointer(bufferPointer))
	}

	[preferences.showHiddenAchievements ? 1 : 0].withUnsafeBufferPointer { bufferPointer in
		_ = try! fileHandle.write(buffer: UnsafeRawBufferPointer(bufferPointer))
	}
}
