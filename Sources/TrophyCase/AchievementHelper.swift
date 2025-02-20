//
//  AchievementHelper.swift
//  TrophyCase
//
//  Created by gurtt on 16/10/2024.
//

import PlaydateKit

struct DecodeError: Error, CustomStringConvertible { let description: String }

/// Performs a search of the shared data directory and returns a list of paths that contain achievement data.
///
/// - Returns: An array of `String` objects, each of which is the path to a JSON file.
///
/// Achievement data isn't validated when searching for bundles.
func findBundles() throws(Playdate.Error) -> [String] {
	let sharedDataDirectories = ["/Shared/", "/Shared/Achievements/"]
	let achievementDataFileName = "achievements.json"

	var pathsWithData: [String] = []

	for directory in sharedDataDirectories {
		let contents = try? contentsOfDirectory(atPath: directory)

		guard let contents else { continue }
		// TODO: Filter directories that aren't in a valid format (/[a-zA-Z0-9\-\.]+/)

		let dataPaths = contents.map { id in directory + id }.filter { path in
			fileExists(atPath: path + achievementDataFileName)
		}

		pathsWithData.append(contentsOf: dataPaths)
	}

	return pathsWithData
}

func decodeBundle(at path: String) throws(DecodeError) -> Bundle {
	let dataFilePath = path + "achievements.json"
	guard let bundleFile = try? File.open(path: dataFilePath, mode: .read) else {
		throw DecodeError(description: "Couldn't open file at \(dataFilePath)")
	}

	guard let fileStat = try? File.stat(path: dataFilePath) else {
		throw DecodeError(description: "Couldn't stat file at \(dataFilePath)")
	}
	var modifiedDateTime = System.DateTime()
	modifiedDateTime.year = UInt16(fileStat.m_year)
	modifiedDateTime.month = UInt8(fileStat.m_month)
	modifiedDateTime.day = UInt8(fileStat.m_day)
	modifiedDateTime.hour = UInt8(fileStat.m_hour)
	modifiedDateTime.minute = UInt8(fileStat.m_minute)
	modifiedDateTime.second = UInt8(fileStat.m_second)
	let modifiedAt = Int(System.convertDateTimeToEpoch(modifiedDateTime))

	let bundleContainer = BundleContainer()

	var decoder = JSON.Decoder()
	decoder.userdata = UnsafeMutableRawPointer(Unmanaged.passUnretained(bundleContainer).toOpaque())
	decoder.shouldDecodeTableValueForKey = shouldDecodeTableValueForKey
	decoder.willDecodeSublist = willDecodeSublist
	decoder.didDecodeTableValue = didDecodeTableValue
	decoder.decodeError = decodeError

	class FileHandleContainer {
		let contents: File.FileHandle

		init(handle: File.FileHandle) { self.contents = handle }
	}

	let container = FileHandleContainer(handle: bundleFile)
	let reader = JSON.Reader(
		read: {
			(
				containerPointer: UnsafeMutableRawPointer?, buffer: UnsafeMutablePointer<UInt8>?,
				length: Int32
			) in
			guard let containerPointer else { return -1 }
			let container = Unmanaged<FileHandleContainer>.fromOpaque(containerPointer)
				.takeUnretainedValue()

			guard let buffer else { return -1 }
			guard
				let bytesRead = try? container.contents.read(buffer: buffer, length: CUnsignedInt(length))
			else { return -1 }

			return Int32(bytesRead)
		}, userdata: UnsafeMutableRawPointer(Unmanaged.passUnretained(container).toOpaque()))

	var value = JSON.Value()

	_ = JSON.decode(using: &decoder, reader: reader, value: &value)

	do { try bundleFile.close() } catch { throw DecodeError(description: error.description) }

	guard !bundleContainer.achievements.isEmpty else {
		throw DecodeError(description: "No achievements in bundle")
	}

	let achievements = try bundleContainer.achievements.map {
		achievementContainer throws(DecodeError) in
		guard
			achievementContainer.id != nil && achievementContainer.name != nil
				&& achievementContainer.description != nil
			// && achievementContainer.isSecret != nil
			// && achievementContainer.progress != nil
			// && achievementContainer.maxProgress != nil
			// && achievementContainer.unlockedAt != nil
			// && achievementContainer.iconPath != nil
		else {
			throw DecodeError(description: "Missing or invalid required fields in achievement data")
		}

		return Achievement(
			id: achievementContainer.id!, name: achievementContainer.name!,
			description: achievementContainer.description!,
			isSecret: achievementContainer.isSecret ?? false, progress: achievementContainer.progress,
			maxProgress: achievementContainer.maxProgress, unlockedAt: achievementContainer.unlockedAt,
			iconPath: (achievementContainer.iconPath != nil) ? path + achievementContainer.iconPath! : nil
		)
	}

	guard
		bundleContainer.bundleId != nil && bundleContainer.name != nil
			&& bundleContainer.description != nil && bundleContainer.author != nil
			&& bundleContainer.version != nil
		// && bundleContainer.cardPath != nil
		// && bundleContainer.iconPath != nil
		// && bundleContainer.defaultIcon != nil
	else { throw DecodeError(description: "Missing or invalid required fields in bundle data") }

	let bundle = Bundle(
		id: bundleContainer.bundleId!, name: bundleContainer.name!,
		description: bundleContainer.description!, author: bundleContainer.author!,
		version: bundleContainer.version!,
		cardPath: (bundleContainer.cardPath != nil) ? path + bundleContainer.cardPath! : nil,
		iconPath: (bundleContainer.iconPath != nil) ? path + bundleContainer.iconPath! : nil,
		achievements: achievements, modifiedAt: modifiedAt,
		defaultIconPath: (bundleContainer.defaultIcon != nil)
			? path + bundleContainer.defaultIcon! : nil)

	return bundle
}
