//
//  String+Extensions.swift
//  TrophyCase
//
//  Created by gurtt on 26/10/2024.
//
//

extension String.UTF8View: @retroactive Equatable {}
extension String.UTF8View: @retroactive Hashable {
	public static func == (lhs: Self, rhs: Self) -> Bool { lhs.elementsEqual(rhs) }

	static func ~= (lhs: Self, rhs: Self) -> Bool { lhs == rhs }

	static func ~= (lhs: String, rhs: Self) -> Bool { lhs.utf8 == rhs }

	static func ~= (lhs: Self, rhs: String) -> Bool { lhs == rhs.utf8 }

	func hasPrefix(_ prefix: Self) -> Bool { self.starts(with: prefix) }

	func hasPrefix(_ prefix: String) -> Bool { self.hasPrefix(prefix.utf8) }

	func hasSuffix(_ suffix: Self) -> Bool {
		self.dropFirst(self.count - suffix.count).elementsEqual(suffix)
	}

	func hasSuffix(_ suffix: String) -> Bool { self.hasSuffix(suffix.utf8) }

	public func hash(into hasher: inout Hasher) {
		hasher.combine(0xFF as UInt8)
		for element in self { hasher.combine(element) }
	}

	public var hashValue: Int {
		var hasher = Hasher()
		self.hash(into: &hasher)
		return hasher.finalize()
	}
}
