//
//  Dialog.swift
//  TrophyCase
//
//  Created by gurtt on 4/4/2025.
//

import PlaydateKit

final class Dialog: Sprite.Sprite {
	// MARK: Lifecycle

	override init() {
		super.init()
		collisionsEnabled = false
		zIndex = 2000

		let xMargin = 32
		let yMargin = 32
		bounds = Rect(
			x: xMargin, y: yMargin, width: Display.width - (xMargin * 2),
			height: Display.height - (yMargin * 2))
		moveTo(Point(x: 200, y: 340))
		transitionAnimationController.skip(to: .start)
	}

	convenience init(
		content: Graphics.Bitmap?, primaryAction: @escaping () -> Void,
		primaryActionText: String = "OK", secondaryAction: (() -> Void)? = nil,
		secondaryActionText: String? = nil
	) {
		self.init()

		self.content = content ?? self.content
		self.primaryAction = primaryAction
		self.primaryActionText = primaryActionText
		self.secondaryAction = secondaryAction
		self.secondaryActionText = secondaryActionText
	}

	// MARK: Internal

	var primaryAction: () -> Void = {}

	var secondaryAction: (() -> Void)? = nil

	func show() {
		transitionAnimationController.animate(to: .end)
		Game.alertSfx.play()
		selectedActionOutlineAnimationController.endCallback = {
			self.drawThickOutlines.toggle()
			self.markDirty()
		}
	}

	func dismiss() {
		transitionAnimationController.animate(to: .start)
		// Very gross, but these cause strong ref cycles because weak references aren't allowed 😐
		primaryAction = {}
		secondaryAction = nil
		selectedActionOutlineAnimationController.endCallback = {}
	}

	override func update() {
		moveTo(Point(x: 200, y: transitionAnimationController.value))

		transitionAnimationController.tick()
		selectedActionOutlineAnimationController.tick()

		guard transitionAnimationController.targetState == .end else { return }
		if System.buttonState.pushed.contains(.a) {
			if primaryActionIsSelected {
				primaryAction()
			} else {
				secondaryAction?()
			}
			Game.actionSfx.play()
			dismiss()
			return
		}

		if secondaryAction != nil {
			if primaryActionIsSelected && System.buttonState.pushed.contains(.left) {
				Game.scrollDownSfx.play()
				primaryActionIsSelected = false
				markDirty()
				return
			}

			if !primaryActionIsSelected && System.buttonState.pushed.contains(.right) {
				Game.scrollDownSfx.play()
				primaryActionIsSelected = true
				markDirty()
				return
			}
		}
	}

	override func draw(bounds _: Rect, drawRect _: Rect) {
		let lineWidth: Float = 3
		let halfLineWidth: Float = lineWidth / 2
		let transformedBounds = Rect(
			x: bounds.origin.x + halfLineWidth, y: bounds.origin.y + halfLineWidth,
			width: bounds.width - lineWidth, height: bounds.height - lineWidth)
		Graphics.drawMode = .copy

		// Draw backing
		Graphics.fillRoundRect(transformedBounds, radius: 4, color: .white)
		Graphics.drawRoundRect(transformedBounds, lineWidth: 3, radius: 4, color: .black)

		// TODO: Draw content
		Graphics.drawBitmap(content, at: bounds.origin.translatedBy(dx: 16, dy: 16))

		// Draw buttons
		func drawAction(at origin: Point, text: String, isSelected: Bool) {
			let actionWidth: Float = 137
			let actionHeight: Float = 38
			let actionBounds = Rect(origin: origin, width: actionWidth, height: actionHeight)

			Graphics.drawMode = .copy
			Graphics.fillRoundRect(actionBounds, radius: 2, color: isSelected ? .black : .white)
			Graphics.drawRoundRect(
				actionBounds,
				lineWidth: isSelected && drawThickOutlines ? 5 : 3,
				radius: 2, color: .black)

			Graphics.drawMode = .nxor
			Graphics.setFont(.roobert11Medium)
			Graphics.drawTextInRect(
				text,
				in: actionBounds.translatedBy(
					dx: 0,
					dy: Float(actionBounds.height / 2) - Float(Graphics.Font.roobert11Medium.height / 2)),
				wrap: .word, aligned: .center)
		}

		let hasSecondaryAction = secondaryAction != nil && secondaryActionText != nil
		drawAction(
			at: bounds.origin.translatedBy(dx: hasSecondaryAction ? 172 : 98, dy: 122),
			text: primaryActionText, isSelected: primaryActionIsSelected)
		if hasSecondaryAction {
			drawAction(
				at: bounds.origin.translatedBy(dx: 27, dy: 122), text: secondaryActionText!,
				isSelected: !primaryActionIsSelected)
		}
	}

	let padding: Float = 16
	var content = Graphics.Bitmap(width: 304, height: 144)

	// MARK: Private

	var primaryActionText: String = "OK"
	var secondaryActionText: String?
	private var primaryActionIsSelected = true
	private var drawThickOutlines = false

	private var transitionAnimationController = AnimationController(
		startValue: 340, endValue: 120, duration: 350, easing: .outBack)
	private var selectedActionOutlineAnimationController = AnimationController(
		startValue: 0, endValue: 1, duration: 500, isRepeating: true)
}
