import PlaydateKit

final class Game: PlaydateGame {
	#if DEBUG
		static nonisolated(unsafe) var timeScale: Float = 1
	#endif

	static nonisolated(unsafe) var preferences = PreferencesReader.readPreferences()
	static nonisolated(unsafe) var saveData = BrickBreakReader.readSaveData()

	static nonisolated(unsafe) var screenUpdateRequested: Bool = false

	static nonisolated(unsafe) let lockImage = try! Graphics.Bitmap(path: "lock")
	nonisolated(unsafe) static let defaultListIconImage = try! Graphics.Bitmap(
		path: "default-icon")

	static func requestScreenUpdate() { Game.screenUpdateRequested = true }

	static nonisolated(unsafe) var navigationController = NavigationController(withRoot: BaseView())

	static nonisolated(unsafe) var brickBreakBundle = Bundle(
		id: "dev.gurtt.trophycase.brickbreak",
		name: "Brick Break",
		description: "Brick Break is a game where you break bricks.",
		author: "gurtt",
		version: "1.0.0",
		cardPath: "BrickBreak/card",
		iconPath: "BrickBreak/icon",
		achievements: Game.saveData.effectiveAchievements,
		modifiedAt: 0,
		defaultIconPath: nil  // TODO: Calculate this
	)

	static nonisolated(unsafe) var bundles: [Bundle] {
		Game.saveData.hasPlayed ? [brickBreakBundle] + sharedBundles : sharedBundles
	}
	static nonisolated(unsafe) var sharedBundles: [Bundle] = []
	static nonisolated(unsafe) var analysisResults: [AnalysisResult] = []
	static nonisolated(unsafe) var statistics: [DisplayStatistic] = []
	static nonisolated(unsafe) var totalAchievementsUnlocked: UInt = 0

	var isDrilledDown: Bool = false

	var crankDelta: Float = 0

	var playMusicMenuItem: System.CheckmarkMenuItem

	var events: [InputEvent] = []
	var scrollDownRepeat = KeyRepeat(callback: {})
	var scrollUpRepeat = KeyRepeat(callback: {})

	init() {
		playMusicMenuItem = System.addCheckmarkMenuItem(
			title: "music", isChecked: Game.preferences.playMusic,
			callback: { isChecked in
				Game.preferences.playMusic = isChecked
			})

		Graphics.setFont(.roobert11Medium)

		scrollDownRepeat.endCallback = { [self] in events.append(.scrollDown) }
		scrollUpRepeat.endCallback = { [self] in events.append(.scrollUp) }

		#if DEBUG
			System.setSerialMessageCallback(callback: serialMessageCallback)
		#endif

		do {
			try File.mkdir(path: "DerivedData")
			try File.mkdir(path: "DerivedData/BundleSighting")
		} catch {
			log("Cound't make directories for analyser: \(error)")
		}

		LaunchInfo.setup()

		var analyser = Analyser()
		if Game.saveData.hasPlayed {  // Analyse the BrickBreak bundle
			analyser.ingest(Game.bundles.last!, index: Game.bundles.count - 1)
		}

		var pathsWithData: [String] = []
		do { pathsWithData = try findBundles() } catch {
			log("Can't search for bundles: \(error)")
		}
		if !pathsWithData.isEmpty {
			for path in pathsWithData {
				do {
					try Game.sharedBundles.append(decodeBundle(at: path))

					analyser.ingest(Game.bundles.last!, index: Game.bundles.count - 1)
				} catch {
					log("Can't decode bundle at \"\(path)\": \(error)")
				}
			}
		}
		guard !Game.bundles.isEmpty else {
			return
		}
		Game.analysisResults = analyser.analyse(limit: 20)
		(Game.totalAchievementsUnlocked, Game.statistics) = analyser.getStatistics()

		if !System.buttonState.current.contains(.down) {
			Game.navigationController = NavigationController(withRoot: BundlesView())
		}
	}

	static func goToMain() {
		// Set the nav controller to the main view and re-analyse achievements in case brick break updated its save data
		var analyser = Analyser()
		for (offset, element) in Game.bundles.enumerated() {
			analyser.ingest(element, index: offset)
		}
		Game.analysisResults = analyser.analyse(limit: 20)
		(Game.totalAchievementsUnlocked, Game.statistics) = analyser.getStatistics()

		Game.navigationController = NavigationController(withRoot: BundlesView())
	}

	func update() -> Bool {
		Graphics.clearClipRects()
		Game.screenUpdateRequested = false

		// MARK: Input events

		/// The amount, in degrees, the crank must turn to trigger a scroll event.
		let crankDetentAngle: Float = 30

		crankDelta += System.crankChange
		if crankDelta > crankDetentAngle {
			events.append(.scrollUp)
			crankDelta = 0
		} else if crankDelta < -crankDetentAngle {
			events.append(.scrollDown)
			crankDelta = 0
		}

		if System.buttonState.pushed.contains(.a) { events.append(.a) }

		if System.buttonState.pushed.contains(.b) { events.append(.b) }

		if System.buttonState.pushed.contains(.up) {
			events.append(.scrollUp)
			scrollUpRepeat.start()
		}

		if System.buttonState.pushed.contains(.down) {
			events.append(.scrollDown)
			scrollDownRepeat.start()
		}

		if System.buttonState.released.contains(.down) {
			scrollDownRepeat.stop()
		}

		if System.buttonState.released.contains(.up) {
			scrollUpRepeat.stop()
		}

		scrollUpRepeat.tick()
		scrollDownRepeat.tick()

		for event in events { Game.navigationController.handleInputEvent(event) }

		Game.navigationController.update()

		events = []

		return Game.screenUpdateRequested
	}

	func gameWillTerminate() {
		PreferencesReader.writePreferences(Game.preferences)
		BrickBreakReader.writeSaveData(Game.saveData)
	}

	func deviceWillSleep() {
		PreferencesReader.writePreferences(Game.preferences)
		BrickBreakReader.writeSaveData(Game.saveData)
	}

	func deviceWillLock() {
		PreferencesReader.writePreferences(Game.preferences)
		BrickBreakReader.writeSaveData(Game.saveData)
	}
}
