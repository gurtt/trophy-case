//
//  Achievement.swift
//  TrophyCase
//
//  Created by gurtt on 17/10/2024.
//

struct Achievement: Identifiable {
	let id: String
	let name: String
	let lockedDescription: String?
	let unlockedDescription: String
	let isSecret: Bool
	let progress: Int?
	let maxProgress: Int?
	let unlockedAt: Int?
	let lockedIconPath: String?
	let unlockedIconPath: String?

	var isUnlocked: Bool {
		if unlockedAt != nil { return true }

		guard let maxProgress else { return false }
		if progress ?? 0 >= maxProgress { return true }

		return false
	}

	var progressInterval: Float {
		if self.isUnlocked { return 1 }

		if let maxProgress, let progress { return Float(progress) / Float(maxProgress) }

		return 0
	}

	var description: String {
		if !self.isUnlocked, let lockedDescription {
			return lockedDescription
		}

		return unlockedDescription
	}

	var iconPath: String? {
		self.isUnlocked ? unlockedIconPath : lockedIconPath
	}
}
