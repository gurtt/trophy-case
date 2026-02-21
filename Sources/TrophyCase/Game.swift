import PlaydateKit

final class Game: PlaydateGame {
	#if DEBUG
		static nonisolated(unsafe) var timeScale: Float = 1
	#endif

	static nonisolated(unsafe) var preferences = PreferencesReader.readPreferences()
	static nonisolated(unsafe) var saveData = BrickBreakReader.readSaveData()

	static nonisolated(unsafe) var screenUpdateRequested: Bool = false

	nonisolated(unsafe) static let defaultListIconImage = try! Graphics.Bitmap(
		path: "default-icon")

	static func requestScreenUpdate() { Game.screenUpdateRequested = true }

	static nonisolated(unsafe) var navigationController: NavigationController = NavigationController()

	static nonisolated(unsafe) var bgFilePlayer = Sound.FilePlayer()
	static nonisolated(unsafe) let scrollDownSfx = Sound.SamplePlayer()
	static nonisolated(unsafe) let scrollUpSfx = Sound.SamplePlayer()
	static nonisolated(unsafe) let actionSfx = Sound.SamplePlayer()
	static nonisolated(unsafe) let actionReverseSfx = Sound.SamplePlayer()
	static nonisolated(unsafe) let denialSfx = Sound.SamplePlayer()
	static nonisolated(unsafe) let alertSfx = Sound.SamplePlayer()

	static nonisolated(unsafe) var bundles: [Bundle] = []
	static nonisolated(unsafe) var analysisResults: [AnalysisResult] = []
	static nonisolated(unsafe) var statistics: [DisplayStatistic] = []
	static nonisolated(unsafe) var totalAchievementsUnlocked: UInt = 0

	// MARK: Loading state machine

	enum LoadingState {
		case listingDirectory
		case checkingFiles(index: Int)
		case decodingBundle(index: Int)
		case analysing
		case done
	}

	var loadingState: LoadingState = .listingDirectory
	var loadingStartTime: UInt32 = 0
	var directoryContents: [String] = []
	var validPaths: [String] = []
	var loadingAnalyser: Analyser = Analyser()

	var isDrilledDown: Bool = false

	var crankDelta: Float = 0

	var playMusicMenuItem: System.CheckmarkMenuItem

	var events: [InputEvent] = []
	var scrollDownRepeat = KeyRepeat(callback: {})
	var scrollUpRepeat = KeyRepeat(callback: {})

	init() {
		Game.scrollDownSfx.setSample(path: "SystemSfx/select")
		Game.scrollUpSfx.setSample(path: "SystemSfx/select-reverse")
		Game.actionSfx.setSample(path: "SystemSfx/action")
		Game.actionReverseSfx.setSample(path: "SystemSfx/action-reverse")
		Game.denialSfx.setSample(path: "SystemSfx/denial")
		Game.alertSfx.setSample(path: "SystemSfx/alert")

		playMusicMenuItem = System.addCheckmarkMenuItem(
			title: "music", isChecked: Game.preferences.playMusic,
			callback: { isChecked in
				Game.preferences.playMusic = isChecked
				if Game.preferences.playMusic {
					Game.bgFilePlayer.play(repeat: 0)
				} else {
					Game.bgFilePlayer.stop()
				}
			})
		Game.bgFilePlayer = Sound.FilePlayer()

		Graphics.setFont(.roobert11Medium)

		scrollDownRepeat.endCallback = { [self] in events.append(.scrollDown) }
		scrollUpRepeat.endCallback = { [self] in events.append(.scrollUp) }

		System.setSerialMessageCallback(callback: serialMessageCallback)

		do {
			try File.mkdir(path: "DerivedData")
			try File.mkdir(path: "DerivedData/BundleSighting")
		} catch {
			log("Cound't make directories for analyser: \(error)")
		}

		LaunchInfo.setup()

		Display.refreshRate = 0
		loadingStartTime = System.currentTimeMilliseconds
	}

	static func goToMain() {
		// Set the nav controller to the main view and re-analyse achievements in case brick break updated its save data
		Game.updateBrickBreakBundle()
		var analyser = Analyser()
		for (offset, element) in Game.bundles.enumerated() {
			analyser.ingest(element, index: offset)
		}
		Game.analysisResults = analyser.analyse(limit: 20)
		(Game.totalAchievementsUnlocked, Game.statistics) = analyser.getStatistics()

		BaseView.instance = nil  // manually kill the instance so it goes away
		Game.navigationController = NavigationController(withRoot: BundlesView())
	}

	@discardableResult
	static func updateBrickBreakBundle() -> Bool {
		guard Game.saveData.hasPlayed else { return false }

		let bundle = Bundle(
			id: "dev.gurtt.trophycase.brickbreak",
			name: "Brick Break",
			description: "Brick Break is a game where you break bricks.",
			author: "gurtt",
			version: "1.0.0",
			cardPath: "BrickBreak/card",
			iconPath: "BrickBreak/icon",
			achievements: Game.saveData.effectiveAchievements,
			modifiedAt: 0  // TODO: Calculate this
		)

		guard let i = Game.bundles.firstIndex(where: { $0.id == "dev.gurtt.trophycase.brickbreak" })
		else {
			Game.bundles.append(bundle)
			return true
		}

		Game.bundles[i] = bundle
		return true
	}

	// MARK: Loading

	private func advanceLoading() {
		switch loadingState {
			case .listingDirectory:
				do {
					directoryContents = try contentsOfDirectory(atPath: "/Shared/Achievements/")
				} catch {
					log("Can't search for bundles: \(error)")
					directoryContents = []
				}
				if directoryContents.isEmpty {
					loadingState = .analysing
				} else {
					loadingState = .checkingFiles(index: 0)
				}

			case .checkingFiles(let index):
				let path = directoryContents[index]
				if fileExists(atPath: "/Shared/Achievements/" + path + "Achievements.json") {
					validPaths.append(path)
				}
				let nextIndex = index + 1
				if nextIndex < directoryContents.count {
					loadingState = .checkingFiles(index: nextIndex)
				} else if validPaths.isEmpty {
					loadingState = .analysing
				} else {
					loadingState = .decodingBundle(index: 0)
				}

			case .decodingBundle(let index):
				let path = validPaths[index]
				do {
					try Game.bundles.append(decodeBundle(at: path))
					loadingAnalyser.ingest(Game.bundles.last!, index: Game.bundles.count - 1)
				} catch {
					log("Can't decode bundle at \"\(path)\": \(error)")
				}
				let nextIndex = index + 1
				if nextIndex < validPaths.count {
					loadingState = .decodingBundle(index: nextIndex)
				} else {
					loadingState = .analysing
				}

			case .analysing:
				finishLoading()

			case .done:
				break
		}
	}

	private func finishLoading() {
		guard !Game.bundles.isEmpty || Game.saveData.hasUnlockedSomething else {
			Display.refreshRate = 30
			Game.navigationController = NavigationController(withRoot: BaseView())
			loadingState = .done
			return
		}
		guard !System.buttonState.current.contains(.down) else {
			Display.refreshRate = 30
			Game.navigationController = NavigationController(withRoot: BaseView())
			loadingState = .done
			return
		}

		let didInsertBundle = Game.updateBrickBreakBundle()
		if didInsertBundle {
			loadingAnalyser.ingest(Game.bundles.last!, index: Game.bundles.count - 1)
		}

		Game.analysisResults = loadingAnalyser.analyse(limit: 20)
		(Game.totalAchievementsUnlocked, Game.statistics) = loadingAnalyser.getStatistics()

		Display.refreshRate = 30
		Game.navigationController = NavigationController(withRoot: BundlesView())
		loadingState = .done

		directoryContents = []
		validPaths = []
		loadingAnalyser = Analyser()
	}

	private func drawLoadingScreen() {
		Graphics.clear(color: .black)
		let elapsed = System.currentTimeMilliseconds - loadingStartTime
		guard elapsed >= 1500 else { return }

		Graphics.drawMode = .inverted
		Graphics.drawBitmap(
			try! Graphics.Bitmap(path: "trophy-tiny-sherlock"), at: Point(x: 101, y: 150))
		Graphics.drawText("Polishing trophies...", at: Point(x: 143, y: 157))
		Graphics.drawMode = .copy
	}

	// MARK: Update

	func update() -> Bool {
		guard case .done = loadingState else {
			advanceLoading()
			drawLoadingScreen()
			return true
		}

		Graphics.clearClipRects()
		Game.screenUpdateRequested = false

		// MARK: Input events

		/// The amount, in degrees, the crank must turn to trigger a scroll event.
		let crankDetentAngle: Float = 30

		crankDelta += System.crankChange
		if crankDelta > crankDetentAngle {
			events.append(.scrollDown)
			crankDelta = 0
		} else if crankDelta < -crankDetentAngle {
			events.append(.scrollUp)
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
