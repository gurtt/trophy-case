import PlaydateKit

final class Game: PlaydateGame {
	#if DEBUG
		static nonisolated(unsafe) var timeScale: Float = 1
	#endif

	static nonisolated(unsafe) var preferences = PreferencesReader.readPreferences()

	static nonisolated(unsafe) var screenUpdateRequested: Bool = false

	static nonisolated(unsafe) let lockImage = try! Graphics.Bitmap(path: "lock")
	nonisolated(unsafe) static let defaultListIconImage = try! Graphics.Bitmap(
		path: "default-icon")

	static func requestScreenUpdate() { Game.screenUpdateRequested = true }

	static nonisolated(unsafe) var navigationController = NavigationController(
		withRoot: BundlesView())

	static nonisolated(unsafe) var bundles: [Bundle] = []
	static nonisolated(unsafe) var analysisResults: [AnalysisResult] = []
	static nonisolated(unsafe) var statistics: [DisplayStatistic] = []
	static nonisolated(unsafe) var totalAchievementsUnlocked: UInt = 0

	var isDrilledDown: Bool = false

	var fallbackScene: FallbackScene

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

		fallbackScene = FallbackScene()

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

		var analyser = Analyser()

		LaunchInfo.setup()

		var pathsWithData: [String] = []
		do { pathsWithData = try findBundles() } catch {
			fallbackScene.variant = .broken
			fallbackScene.identifier = "err_find_bundles"
			fallbackScene.message = "Error while enumerating bundles."
			log("Can't search for bundles: \(error)")
			return
		}

		guard !pathsWithData.isEmpty else {
			fallbackScene.variant = .missing
			fallbackScene.identifier = "unimplemented_empty"
			fallbackScene.message = "No bundles were found in 'Shared/'."
			return
		}

		for path in pathsWithData {
			do {
				try Game.bundles.append(decodeBundle(at: path))

				analyser.ingest(Game.bundles.last!, index: Game.bundles.count - 1)
			} catch {
				log("Can't decode bundle at \"\(path)\": \(error)")
			}
		}

		guard !Game.bundles.isEmpty else {
			fallbackScene.variant = .missing
			fallbackScene.identifier = "err_decode_all_fail"
			fallbackScene.message = "0/\(pathsWithData.count) bundles had valid data."
			return
		}
		Game.analysisResults = analyser.analyse(limit: 20)
		(Game.totalAchievementsUnlocked, Game.statistics) = analyser.getStatistics()
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

	func gameWillTerminate() { PreferencesReader.writePreferences(Game.preferences) }

	func deviceWillSleep() { PreferencesReader.writePreferences(Game.preferences) }

	func deviceWillLock() { PreferencesReader.writePreferences(Game.preferences) }
}
