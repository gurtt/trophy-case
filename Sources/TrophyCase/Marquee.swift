//
//  Marquee.swift
//  TrophyCase
//
//  Created by gurtt on 22/2/2025.
//

import PlaydateKit

struct Marquee {
    // MARK: Lifecycle
    
    init(_ text: String, inverted: Bool = false) {
        self.text = text
        self.inverted = inverted
        self.textWidth = Graphics.Font.roobert11Bold.getTextWidth(for: text, tracking: 0)
        dwellStartTime = System.currentTimeMilliseconds + UInt32(Marquee.dwellTime)
        
        let duration = Int(Float(textWidth) / Marquee.pixelsPerMs)
        scrollTimer = AnimationController(startValue: 0, endValue: Float(-(textWidth + Marquee.padding)), duration: duration)
    }
    
    // MARK: Internal
    
    static func draw(_ text: String, in bounds: Rect, offset: Float = 0, inverted: Bool = false) {
        Graphics.setClipRect(bounds)
        defer { Graphics.clearClipRect() }
        
        let textWidth = Graphics.Font.roobert11Bold.getTextWidth(for: text, tracking: 0)
        Graphics.drawMode = inverted ? .fillWhite : .copy
        Graphics.drawText(text, at: bounds.origin.translatedBy(dx: offset, dy: 0))
        
        guard Float(textWidth) > bounds.width else { return }
        defer {
            Graphics.drawMode = inverted ? .copy : .fillWhite
            Graphics.drawBitmap(Marquee.scrimImage, at: bounds.origin.translatedBy(dx: bounds.width - 5, dy: 0), flip: .flippedX)
        }
        
        guard offset < 0 else { return }
        Graphics.drawMode = inverted ? .copy : .fillWhite
        Graphics.drawBitmap(Marquee.scrimImage, at: bounds.origin)
        
        Graphics.drawMode = inverted ? .fillWhite : .copy
        Graphics.drawText(text, at: bounds.origin.translatedBy(dx: offset + Float(textWidth + Marquee.padding), dy: 0))
    }
    
    mutating func update(in bounds: Rect) {
        defer { Marquee.draw(text, in: bounds, offset: scrollTimer.value, inverted: inverted) }
        
        guard textWidth > Int(bounds.width) else { return }
        guard System.currentTimeMilliseconds >= dwellStartTime else { return }
        scrollTimer.animate(to: .end)
        defer { scrollTimer.tick() }
        
        guard !scrollTimer.isAnimating else { return }
        scrollTimer.skip(to: .start)
        dwellStartTime = System.currentTimeMilliseconds + UInt32(Marquee.dwellTime)
    }
    
    // MARK: Private
    
    private static nonisolated(unsafe) let scrimImage = try! Graphics.Bitmap(path: "scrim")
    private static let padding = 32
    private static let dwellTime = 3000
    private static let pixelsPerMs: Float = 0.05
    
    private let text: String
    private let inverted: Bool
    private let textWidth: Int
    
    private var dwellStartTime: UInt32
    private var scrollTimer: AnimationController
}
