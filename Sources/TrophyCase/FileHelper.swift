//
//  FileHelper.swift
//
//
//  Created by gurtt on 10/9/2024.
//

import PlaydateKit

/// Performs a shallow search of the specified directory and returns the names of any contained items.
///
/// - Parameters:
///   - path: The path to the directory whose contents you want to enumerate.
///   - skipHidden: An option to skip hidden files and directories.
/// - Returns: An array of `String` objects, each of which identifies a file or directory contained in `path`. Returns an empty array if the directory exists but has no contents. Subdirectories are indicated by a trailing slash *'/'*.
/// - Throws: `Playdate.Error` if no folder exists at `path` or it can't be opened.
func contentsOfDirectory(
	atPath path: String, skipHidden: Bool = true
) throws(Playdate.Error) -> [String] {
	class ArrayContainer { var contents: [String] = [] }

	let container = ArrayContainer()
	let containerPointer = UnsafeMutableRawPointer(Unmanaged.passUnretained(container).toOpaque())

	try File.listFiles(
		path: path,
		callback: {
			(fileNamePointer: UnsafePointer<CChar>?, containerPointer: UnsafeMutableRawPointer?) in
			guard let containerPointer else { return }
			let container = Unmanaged<ArrayContainer>.fromOpaque(containerPointer).takeUnretainedValue()

			guard let fileNamePointer else { return }
			let fileName = String(cString: fileNamePointer)

			container.contents.append(fileName)
		}, userdata: containerPointer, showHidden: !skipHidden)

	return container.contents
}

/// Returns a Boolean value that indicates whether a file or directory exists at a specified path.
///
/// - Parameters:
///   - path: The path of the file or directory.
/// - Returns: `true` if a file at the specified path exists, or `false` if the file doesn't exist or its existence could not be determined.
///
/// If the file is inaccessible for any reason or an error is encountered, this method returns `false`.
func fileExists(atPath path: String) -> Bool {
	do { try _ = File.stat(path: path) } catch { return false }
	return true
}

/// Update the access and modification times of the file at `path` to the current time.
///
/// - Parameter path: The path of the file to create.
/// - Throws: Any errors encountered while opening or closing the file.
///
/// If no file exists at the supplied `path`,  a new, empty file will be created.
func touchFile(at path: String) throws(Playdate.Error) {
	let handle = try File.open(path: path, mode: .write)
	try handle.close()
}
