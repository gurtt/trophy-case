//
//  Bundle.swift
//  TrophyCase
//
//  Created by gurtt on 17/10/2024.
//

struct Bundle: Identifiable {
	let id: String
	let name: String
	let description: String
	let author: String
	let version: String
	let cardPath: String?
	let iconPath: String?
	let achievements: [Achievement]
	let modifiedAt: Int
}
