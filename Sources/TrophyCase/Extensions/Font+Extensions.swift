//
//  Font+Extensions.swift
//  TrophyCase
//
//  Created by gurtt on 8/11/2024.
//

import PlaydateKit

extension Graphics.Font {
	static nonisolated(unsafe) let roobert11Medium = try! Graphics.Font(
		path: "/System/Fonts/Roobert-11-Medium.pft")
	static nonisolated(unsafe) let roobert11Bold = try! Graphics.Font(
		path: "/System/Fonts/Roobert-11-Bold.pft")
	static nonisolated(unsafe) let roobert10Bold = try! Graphics.Font(
		path: "/System/Fonts/Roobert-10-Bold.pft")
	static nonisolated(unsafe) let showtime = try! Graphics.Font(path: "showtime.pft")
}
