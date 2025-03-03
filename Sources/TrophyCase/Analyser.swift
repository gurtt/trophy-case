//
//  Analyser.swift
//  TrophyCase
//
//  Created by gurtt on 23/1/2025.
//

import PlaydateKit

enum AnalysisResult {
	case achievementProgressInterval(bundleIndex: Int, achievementIndex: Int, progressInterval: Float)
	case achievementSecretUnlock(bundleIndex: Int, achievementIndex: Int, secondsSince: Int)
	case bundleProgressInterval(bundleIndex: Int, progressInterval: Float)
	case bundleCompletion(bundleIndex: Int, secondsSince: Int)
	case bundleAge(bundleIndex: Int, age: Int)
	case text(text: String)
}

extension AnalysisResult: Comparable {
	/// Get a relevance score. The result is only meaningful among results of the same category. Larger scores are better for some categories, while smaller scores are better for other categories.
	var score: Float {
		switch self {
			case .achievementProgressInterval(_, _, let progressInterval):
				progressInterval
			case .achievementSecretUnlock(_, _, let secondsSince):
				Float(secondsSince)
			case .bundleProgressInterval(_, let progressInterval):
				progressInterval
			case .bundleCompletion(_, let secondsSince):
				Float(secondsSince)
			case .bundleAge(_, let age):
				Float(age)
			case .text:
				0
		}
	}

	static func < (lhs: Self, rhs: Self) -> Bool {
		lhs.score < rhs.score
	}

	static func == (lhs: Self, rhs: Self) -> Bool {
		lhs.score == rhs.score
	}
}

struct Analyser {
	// MARK: Internal

	/// Ingest the supplied ``Bundle``, collecting data points for later analysis.
	/// - Parameters:
	///   - bundle: The Bundle to analyse.
	///   - bundleIndex: The index of the Bundle within the data set.
	mutating func ingest(
		_ bundle: borrowing Bundle, index bundleIndex: Int,
		timeBase: Int = Int(System.secondsSinceEpoch)
	) {
		log("Ingesting bundle with ID \(bundle.id)")
		totalBundles += 1
		var totalUnlocked: Int = 0
		var lastUnlockAt: Int?
		for (index, achievement) in bundle.achievements.enumerated() {
			if achievement.isUnlocked {
				totalUnlocked += 1
				log("Achievement \"\(achievement.id)\" contributed to stat totalAchievementsUnlocked")
				lastUnlockAt = max(lastUnlockAt ?? 0, achievement.unlockedAt ?? 0)
				let secondsSinceUnlock = timeBase - (achievement.unlockedAt ?? 0)
				log(
					"Achievement \"\(achievement.id)\" unlocked \(TimeInterval(spanning: secondsSinceUnlock)) \(secondsSinceUnlock > 0 ? "ago" : "in the future")"
				)
				switch secondsSinceUnlock {
					case 0...86_400:
						achievementsUnlockedToday += 1
						log("Achievement \"\(achievement.id)\" contributed to stat achievementsUnlockedToday")
						fallthrough
					case 86_401...604_800:
						achievementsUnlockedThisWeek += 1
						log(
							"Achievement \"\(achievement.id)\" contributed to stat achievementsUnlockedThisWeek")
						fallthrough
					case 604_801...31_536_000:
						achievementsUnlockedThisYear += 1
						log(
							"Achievement \"\(achievement.id)\" contributed to stat achievementsUnlockedThisYear")
					default: break
				}
				if achievement.isSecret {
					guard secondsSinceUnlock < 5259492 else {  // two months
						continue
					}
					achievementSecretUnlockCandidates.append(
						AnalysisResult.achievementSecretUnlock(
							bundleIndex: bundleIndex, achievementIndex: index, secondsSince: secondsSinceUnlock))
					log("Achievement \"\(achievement.id)\" qualified for achievementSecretUnlockCandidates")
				}
				continue
			}
			if achievement.isSecret {
				lockedSecretAchievements += 1
				log("Achievement \"\(achievement.id)\" contributed to stat lockedSecretAchievements")
			} else {
				guard let progress = achievement.progress, let maxProgress = achievement.maxProgress else {
					continue
				}
				if achievement.progressInterval > 0.5 && (maxProgress - progress <= 2) {  // prevent every single in-progress achievement from being eligible
					achievementProgressIntervalCandidates.append(
						AnalysisResult.achievementProgressInterval(
							bundleIndex: bundleIndex, achievementIndex: index,
							progressInterval: achievement.progressInterval
						))
					log(
						"Achievement \"\(achievement.id)\" qualified for achievementProgressIntervalCandidates")
				}
			}
		}
		let bundleProgressInterval = Float(totalUnlocked) / Float(bundle.achievements.count)
		averageCompletionIntervalRunningTotal += bundleProgressInterval
		totalAchievementsUnlocked += totalUnlocked
		switch bundleProgressInterval {
			case 0..<0.5:
				let age = getSecondsSinceDetection(for: bundle.id)
				if age < 0 {
					log("Age is negative for bundle \"\(bundle.id)\". Did the time zone change recently?")
				}
				let secondsInAWeek = 60 * 60 * 24 * 7
				if age < secondsInAWeek {  // Achievement is less than a week old and may have some achievements unlocked
					bundleAgeCandidates.append(AnalysisResult.bundleAge(bundleIndex: bundleIndex, age: age))
					log("Bundle \"\(bundle.id)\" qualified for bundleAgeCandidates (less than a week old)")
				} else if age < secondsInAWeek * 4 && totalUnlocked == 0 {  // Achievement is between a week and a month old, but hasn't got any unlocked achievements yet
					bundleAgeCandidates.append(AnalysisResult.bundleAge(bundleIndex: bundleIndex, age: age))
					log(
						"Bundle \"\(bundle.id)\" qualified for bundleAgeCandidates (less than 4 weeks old and 0 unlocked achievements)"
					)

				}
			case 0.5..<0.8:
				break
			case 0.8..<1:
				bundleProgressIntervalCandidates.append(
					AnalysisResult.bundleProgressInterval(
						bundleIndex: bundleIndex, progressInterval: bundleProgressInterval))
				log("Bundle \"\(bundle.id)\" qualified for bundleProgressIntervalCandidates")
			case 1:
				let secondsSinceLastUnlock = timeBase - (lastUnlockAt ?? 0)
				bundleCompletionCandidates.append(
					AnalysisResult.bundleCompletion(
						bundleIndex: bundleIndex, secondsSince: secondsSinceLastUnlock))
				log("Bundle \"\(bundle.id)\" qualified for bundleCompletionCandidates")
				perfectGames += 1
				log("Bundle \"\(bundle.id)\" contributed to stat perfectGames")
			default:
				break
		}
	}
	/// Analyse the data collected from previously ingested Bundles.
	/// - Parameters:
	///   - limit: The maximum number of results to return.
	/// - Returns: An array of ``AnalysisResult`` structures.
	func analyse(limit: Int) -> [AnalysisResult] {
		let maximumCandidatesPerType = Int(limit / 5)

		// TODO: Perform a partial sort on these candidate lists and more efficiently take the first n of each

		log(
			"""
			Analysis:
			\tachievementProgressIntervalCandidates: \(achievementProgressIntervalCandidates.count)
			\tachievementSecretUnlockCandidates:     \(achievementSecretUnlockCandidates.count)
			\tbundleProgressIntervalCandidates:      \(bundleProgressIntervalCandidates.count)
			\tbundleCompletionCandidates:            \(bundleCompletionCandidates.count)
			\tbundleAgeCandidates:                   \(bundleAgeCandidates.count)
			""")

		let a = achievementProgressIntervalCandidates.sorted(by: { $0.score > $1.score }).prefix(
			maximumCandidatesPerType)
		let b = achievementSecretUnlockCandidates.sorted(by: { $0.score < $1.score }).prefix(
			maximumCandidatesPerType)
		let c = bundleProgressIntervalCandidates.sorted(by: { $0.score > $1.score }).prefix(
			maximumCandidatesPerType)
		let d = bundleCompletionCandidates.sorted(by: { $0.score < $1.score }).prefix(
			maximumCandidatesPerType)
		let e = bundleAgeCandidates.sorted(by: { $0.score < $1.score }).prefix(maximumCandidatesPerType)

		return (a + b + c + d + e).shuffled()
	}

	func getStatistics(
		timeBase: Int = Int(System.secondsSinceEpoch)
	) -> (total: Int, stats: [DisplayStatistic]) {
		var displayStatistics: [DisplayStatistic] = []

		let avgCompletion = Int((averageCompletionIntervalRunningTotal / Float(totalBundles)) * 100)
		displayStatistics.append(DisplayStatistic(title: "AVG. COMPLETION", body: "\(avgCompletion)%"))

		if achievementsUnlockedToday > 0 {
			displayStatistics.append(
				DisplayStatistic(title: "UNLOCKED TODAY", body: "\(achievementsUnlockedToday)"))
		}

		let month = System.convertEpochToDateTime(CUnsignedInt(timeBase)).month
		if month == 12 && achievementsUnlockedThisYear > 0 {
			displayStatistics.append(
				DisplayStatistic(title: "UNLOCKED THIS YEAR", body: "\(achievementsUnlockedThisYear)"))
		} else if achievementsUnlockedThisWeek > 0 {
			displayStatistics.append(
				DisplayStatistic(title: "UNLOCKED THIS WEEK", body: "\(achievementsUnlockedThisWeek)"))
		}

		if perfectGames > 0 {
			displayStatistics.append(DisplayStatistic(title: "PERFECT GAMES", body: "\(perfectGames)"))
		}

		if lockedSecretAchievements > 0 {
			displayStatistics.append(
				DisplayStatistic(title: "LOCKED SECRETS", body: "\(lockedSecretAchievements)"))
		}

		log(
			"""
			Statistics:
			\ttotalAchievementsUnlocked:    \(totalAchievementsUnlocked)
			\ttotalBundles:                 \(totalBundles)
			\tavgCompletion:                \(avgCompletion)
			\tachievementsUnlockedToday:    \(achievementsUnlockedToday)
			\tachievementsUnlockedThisWeek: \(achievementsUnlockedThisWeek)
			\tachievementsUnlockedThisYear: \(achievementsUnlockedThisYear)
			\tperfectGames:                 \(perfectGames)
			\tlockedSecretAchievements:     \(lockedSecretAchievements)
			""")

		return (totalAchievementsUnlocked, displayStatistics)
	}
	// MARK: Private

	// Analysis results
	private var achievementProgressIntervalCandidates: [AnalysisResult] = []
	private var achievementSecretUnlockCandidates: [AnalysisResult] = []
	private var bundleProgressIntervalCandidates: [AnalysisResult] = []
	private var bundleCompletionCandidates: [AnalysisResult] = []
	private var bundleAgeCandidates: [AnalysisResult] = []

	// Statistics
	private var totalAchievementsUnlocked: Int = 0
	private var totalBundles: Int = 0
	private var averageCompletionIntervalRunningTotal: Float = 0
	private var achievementsUnlockedToday: Int = 0
	private var achievementsUnlockedThisWeek: Int = 0
	private var achievementsUnlockedThisYear: Int = 0
	private var perfectGames: Int = 0
	private var lockedSecretAchievements: Int = 0

	private func getSecondsSinceDetection(for bundleID: String) -> Int {
		let path = "/DerivedData/BundleSighting/\(bundleID)"
		if let stat = try? File.stat(path: path) {
			let dateTime = System.DateTime(fileStat: stat)
			return Int(System.secondsSinceEpoch) - Int(System.convertDateTimeToEpoch(dateTime))
		}
		log("Bundle \"\(bundleID)\" is new for this launch")
		try? touchFile(at: path)

		return 0
	}
}
