//  JSONDecoder.swift
//  TrophyCase
//
//  Created by gurtt on 26/10/2024.
//
//

import PlaydateKit

/// Casts a `CChar` type to a `json_value_type` enum.
/// - Parameter character: the raw value of `json_value_type` to cast.
/// - Returns: The enum case of the raw value.
func enumerateValueType(from character: CChar) -> json_value_type {
	// There's some wierd type fighting between UInt8 and UInt32 that prevents the enum from being initialised directly.
	switch UInt32(character) { case UInt32(json_value_type.null.rawValue): return .null
		case UInt32(json_value_type.true.rawValue): return .true
		case UInt32(json_value_type.false.rawValue): return .false
		case UInt32(json_value_type.integer.rawValue): return .integer
		case UInt32(json_value_type.float.rawValue): return .float
		case UInt32(json_value_type.string.rawValue): return .string
		case UInt32(json_value_type.array.rawValue): return .array
		case UInt32(json_value_type.table.rawValue): return .table
		default: return .null
	}
}

/// Casts a JSON.Value to a Swift integer.
/// - Parameter value: the value to cast.
/// - Returns: An integer depending on the underlying type of `value`. For `.integer` and `.float` values, returns the underlying number as an integer. For `.string` values, uses `strtol` to interpret the string value as an integer. For `.true` values, returns 1. Returns 0 for all other cases.
func decodeJsonIntValue(from value: JSON.Value) -> Int { return Int(json_intValue(value)) }

/// Casts a JSON.Value to a Swift float.
/// - Parameter value: the value to cast.
/// - Returns: A float depending on the underlying type of `value`. For `.integer` and `.float` values, returns the underlying number as a float. For `.true` values, returns 1. Returns 0 for all other cases.
func decodeJsonFloatValue(from value: JSON.Value) -> Float { return json_floatValue(value) }

/// Casts a JSON.Value to a Swift boolean.
/// - Parameter value: the value to cast.
/// - Returns: A boolean depending on the underlying type of `value`. For `.string` values, returns whether or not the value is an empty string. For all other cases, returns whether or not the integer value (determined by `decodeJsonIntValue`) is 0.
func decodeJsonBoolValue(from value: JSON.Value) -> Bool { return json_boolValue(value) != 0 }

/// Casts a JSON.Value to a Swift string.
/// - Parameter value: the value to cast.
/// - Returns: A string if the underlying type is `.string`, or an empty string for all other cases.
func decodeJsonStringValue(from value: JSON.Value) -> String {
	return String(cString: json_stringValue(value))
}

/// A container holding unformatted data for an Achievement, represented as a class container that can be passed to C.
class AchievementContainer {
	var id: String?
	var name: String?
	var description: String?
	var isSecret: Bool?
	var progress: Int?
	var maxProgress: Int?
	var unlockedAt: Int?
	var iconPath: String?
}

/// A container holding unformatted data for an Bundle, represented as a class container that can be passed to C.
class BundleContainer {
	var bundleId: String?
	var name: String?
	var description: String?
	var author: String?
	var version: String?
	var cardPath: String?
	var iconPath: String?
	var achievements: [AchievementContainer] = []
	var modifiedAt: Int?
	var defaultIcon: String?
}

func shouldDecodeTableValueForKey(
	_ decoderPointer: UnsafeMutablePointer<json_decoder>?, keyPointer: UnsafePointer<CChar>?
) -> Int32 {
	let bundleKeys: Set = [
		"bundleID", "gameID", "name", "description", "author", "version", "cardPath", "iconPath",
		"achievements", "defaultIcon",
	]
	let achievementKeys: Set = [
		"id", "name", "description", "isSecret", "progress", "progressMax", "grantedAt", "iconPath",
	]
	let decoder = decoderPointer!.pointee
	let key = String(cString: keyPointer!)

	let path = String(cString: decoder.path)

	if path.utf8 == "_root".utf8 {
		if bundleKeys.contains(where: { element in key.utf8 == element.utf8 }) {
			return 1
		}
	}

	if path.utf8.hasPrefix("achievements[") {  // decoding within achievement element
		if achievementKeys.contains(where: { element in key.utf8 == element.utf8 }) {
			return 1
		}
	}

	Logger.log("Unsupported \"\(key)\" at \"\(path)\"", level: .info)

	return 0
}

func willDecodeSublist(
	decoderPointer: UnsafeMutablePointer<json_decoder>?, namePointer: UnsafePointer<CChar>?,
	_: json_value_type
) {
	let decoder = decoderPointer!.pointee
	let container = Unmanaged<BundleContainer>.fromOpaque(decoder.userdata).takeUnretainedValue()
	let path = String(cString: decoder.path!)

	if path.utf8.hasPrefix("achievements[") {  // about to decode achievement element
		let newAchievement = AchievementContainer()
		container.achievements.append(newAchievement)
	}
}

func didDecodeTableValue(
	decoderPointer: UnsafeMutablePointer<json_decoder>?, keyPointer: UnsafePointer<CChar>?,
	rawValue: json_value
) {
	let decoder = decoderPointer!.pointee
	let container = Unmanaged<BundleContainer>.fromOpaque(decoder.userdata).takeUnretainedValue()
	let path = String(cString: decoder.path!)
	let key = String(cString: keyPointer!)

	let valueType = enumerateValueType(from: rawValue.type)

	if path.utf8 == "_root".utf8 {  // decoded bundle field
		switch key.utf8 { case "bundleID", "gameID":
			guard valueType == .string else { return }
			container.bundleId = decodeJsonStringValue(from: rawValue)
			case "name":
				guard valueType == .string else { return }
				container.name = decodeJsonStringValue(from: rawValue)
			case "description":
				guard valueType == .string else { return }
				container.description = decodeJsonStringValue(from: rawValue)
			case "author":
				guard valueType == .string else { return }
				container.author = decodeJsonStringValue(from: rawValue)
			case "version":
				guard valueType == .string else { return }
				container.version = decodeJsonStringValue(from: rawValue)
			case "cardPath":
				guard valueType == .string else { return }
				container.cardPath = decodeJsonStringValue(from: rawValue)
			case "iconPath":
				guard valueType == .string else { return }
				container.iconPath = decodeJsonStringValue(from: rawValue)
			case "achievements": guard valueType == .array else { return }
			case "defaultIcon":
				guard valueType == .string else { return }
				container.defaultIcon = decodeJsonStringValue(from: rawValue)
			default: Logger.log("Unexpected \"\(key)\" in bundle", level: .info)
		}
	}

	if path.utf8.hasPrefix("achievements[") {  // decoded achievement field
		let currentAchievement = container.achievements.last!

		switch key.utf8 { case "id":
			guard valueType == .string else { return }
			currentAchievement.id = decodeJsonStringValue(from: rawValue)
			case "name":
				guard valueType == .string else { return }
				currentAchievement.name = decodeJsonStringValue(from: rawValue)
			case "description":
				guard valueType == .string else { return }
				currentAchievement.description = decodeJsonStringValue(from: rawValue)
			case "isSecret":
				guard valueType == .true || valueType == .false else { return }
				currentAchievement.isSecret = decodeJsonBoolValue(from: rawValue)
			case "progress":
				guard valueType == .integer else { return }
				currentAchievement.progress = decodeJsonIntValue(from: rawValue)
			case "progressMax":
				guard valueType == .integer else { return }
				currentAchievement.maxProgress = decodeJsonIntValue(from: rawValue)
			case "grantedAt":
				guard valueType != .false else {
					Logger.log(
						"Incorrect type for key \"grantedAt\": should be omitted if not granted, not false",
						level: .warning)
					return
				}
				guard valueType == .integer else { return }
				currentAchievement.unlockedAt = decodeJsonIntValue(from: rawValue)
			case "iconPath":
				guard valueType == .string else { return }
				currentAchievement.iconPath = decodeJsonStringValue(from: rawValue)
			default: Logger.log("Unexpected \"\(key)\" in achievement", level: .info)
		}
	}
}

func decodeError(
	decoderPointer: UnsafeMutablePointer<json_decoder>?, errorPointer: UnsafePointer<CChar>?,
	lineNumber: Int32
) {
	let error = String(cString: errorPointer!)
	Logger.log("Can't decode JSON: \(error) at line \(lineNumber)", level: .error)
}
