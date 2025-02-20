//
//  Serial.swift
//  TrophyCase
//
//  Created by gurtt on 6/11/2024.
//

func serialMessageCallback(messagePointer: UnsafePointer<CChar>?) {
	let message = String(cString: messagePointer!)

	let parts = message.utf8.split(separator: " ".utf8.first!).map({ return String($0) ?? "" })

	switch parts[0].utf8 { case "bundle":
		guard parts.count >= 2 else {
			print("Missing argument <id>")
			return
		}

		guard let bundle = Game.bundles.first(where: { $0.id.utf8 == parts[1].utf8 }) else {
			print("No bundle found with ID \"\(parts[1])\"")
			return
		}
		print(
			"""
			id:           \(bundle.id)
			name:         \(bundle.name)
			description:  \(bundle.description)
			author:       \(bundle.author)
			version:      \(bundle.version)
			cardPath:     \(bundle.cardPath ?? "<nil>")
			iconPath:     \(bundle.iconPath ?? "<nil>")
			achievements: \(bundle.achievements.count) achievements
			modifiedAt:   \(bundle.modifiedAt)
			defaultIconPath: \(bundle.defaultIconPath ?? "<nil>")
			""")

		guard parts.count >= 3 && parts[2].utf8 == "-a".utf8 else { return }
		for achievement in bundle.achievements {
			print(
				"""
				\tid:          \(achievement.id)
				\tname:        \(achievement.name)
				\tdescription: \(achievement.description)
				\tisSecret:    \(achievement.isSecret ? "true" : "false")
				\tprogress:    \(achievement.progress?.description ?? "<nil>")
				\tmaxProgress: \(achievement.maxProgress?.description ?? "<nil>")
				\tunlockedAt:  \(achievement.unlockedAt?.description ?? "<nil>")
				""")
		}
		case "help":
			print(
				"""
				Usage:
				bundle <id> [-a]
				    List the data for the bundle with the specified ID, if it exists.
				    Use -a to include achievements.
				help
				    Print this messsage.
				timescale (fast|default|slow|slower)
				    Set the speed of animations as a multiple of the default speed:
				        - fast: 2.0
				        - default: 1.0
				        - slow: 0.5
				        - slower: 0.1
				secret
				    Toggle hiding or showing secret achievements. Persists between launches.
				""")
		case "timescale":
			guard parts.count >= 2 else {
				print("Missing argument <scale>")
				return
			}
			// Implementing string-to-float parsing is ridiculous for a tiny dev util
			let scale: Float =
				switch parts[1].utf8 { case "fast": 2.0 case "default": 1.0 case "slow": 0.5 case "slower":
					0.1
					default: 1.0
				}
			#if DEBUG
				Game.timeScale = scale
			#endif

		case "secret":
			Game.preferences.showHiddenAchievements.toggle()
			print(
				"\(Game.preferences.showHiddenAchievements ? "Showing" : "Hiding") hidden achievements.")

		default: print("Unknown command \"\(parts[0])\". Use 'help' for available commands.")
	}
}
