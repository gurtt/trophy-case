//
//  Array+Extensions.swift
//  TrophyCase
//
//  Created by gurtt on 3/11/2024.
//

extension Array where Element == String {
	@inlinable @discardableResult func withUnsafeCStringBufferPointer<R>(
		_ body: (UnsafeMutableBufferPointer<UnsafePointer<CChar>?>) throws -> R
	) rethrows -> R {
		func translate(
			_ slice: inout Self.SubSequence, _ offset: inout Int,
			_ buffer: UnsafeMutableBufferPointer<UnsafePointer<CChar>?>,
			_ body: (UnsafeMutableBufferPointer<UnsafePointer<CChar>?>) throws -> R
		) rethrows -> R {
			guard let string = slice.popFirst() else { return try body(buffer) }

			return try string.withCString { cStringPtr in
				buffer.baseAddress!.advanced(by: offset).initialize(to: cStringPtr)
				offset += 1
				return try translate(&slice, &offset, buffer, body)
			}
		}

		var slice = self[...]
		var offset: Int = 0
		let buffer = UnsafeMutableBufferPointer<UnsafePointer<CChar>?>.allocate(capacity: count)
		defer { buffer.deallocate() }
		return try translate(&slice, &offset, buffer, body)
	}
}
