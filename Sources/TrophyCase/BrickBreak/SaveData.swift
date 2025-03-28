//
//  SaveData.swift
//  TrophyCase
//
//  Created by gurtt on 28/3/2025.
//

import PlaydateKit

struct SaveData {
	var hasPlayed: Bool = false
	var maxScore: Int = 0
	var hundredUnlockedAt: Int = 0
	var thousandUnlockedAt: Int = 0
}

extension SaveData {
	mutating func saveScore(score: Int) {
		if maxScore < 100, score >= 100 {
			hundredUnlockedAt = Int(System.secondsSinceEpoch)
		}

		if maxScore < 1000, score >= 1000 {
			thousandUnlockedAt = Int(System.secondsSinceEpoch)
		}

		maxScore = max(maxScore, score)
		hasPlayed = true
	}

	var hasUnlockedSomething: Bool {
		maxScore >= 100
	}

	var effectiveAchievements: [Achievement] {
		guard hasPlayed else { return [] }

		return [
			Achievement(
				id: "100",
				name: "Hectobrick",
				lockedDescription: "Break 100 bricks in a single round.",
				unlockedDescription: "Broke 100 bricks in a single round.",
				isSecret: false,
				progress: min(100, maxScore),
				maxProgress: 100,
				unlockedAt: maxScore >= 100 ? hundredUnlockedAt : nil,
				lockedIconPath: nil,
				unlockedIconPath: nil
			),
			Achievement(
				id: "1000",
				name: "Kilobrick",
				lockedDescription: "Break 1000 bricks in a single round.",
				unlockedDescription: "Broke 1000 bricks in a single round.",
				isSecret: false,
				progress: min(1000, maxScore),
				maxProgress: 1000,
				unlockedAt: maxScore >= 1000 ? thousandUnlockedAt : nil,
				lockedIconPath: nil,
				unlockedIconPath: nil
			),
		]
	}
}
