//
//  Preferences.swift
//  TrophyCase
//
//  Created by gurtt on 22/12/2024.
//

enum BundlesSortOrder: Int, CaseIterable, CustomStringConvertible {
	case recent = 0
	case progress = 1
	case alphabetical = 2

	var description: String {
		switch self { case .recent: return "recent" case .progress: return "progress"
			case .alphabetical: return "name"
		}
	}
}

enum BundlesViewMode: Int, CaseIterable, CustomStringConvertible {
	case cards = 0
	case list = 1

	var description: String {
		switch self { case .cards: return "cards" case .list: return "list"
		}
	}
}

struct Preferences {
	/// The preferred view mode for the list of bundles in ``BundlesView``.
	var bundlesViewMode: BundlesViewMode = .cards

	/// The preferred sort order for bundles in ``BundlesView``.
	var bundlesSortOrder: BundlesSortOrder = .recent

	/// Whether to prefer showing the complete date and time that achievements were unlocked.
	var showFullTime: Bool = false

	/// Whether to show achievements that have ``isSecret`` set to true and aren't unlocked.
	var showHiddenAchievements: Bool = false

	/// Whether to play background music.
	var playMusic: Bool = true
}
