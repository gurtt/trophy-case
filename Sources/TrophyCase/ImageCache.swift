//
//  ImageCache.swift
//  TrophyCase
//
//  Created by gurtt on 17/1/2025.
//

import PlaydateKit

/// A structure that manages a set of integer-keyed image optionals.
///
/// When adding a new value to the cache and the number of values in the cache exceed its maximum, it will remove any items whose index is further away from the new value's index than the cache's `distance`.
///
/// Because this check is only performed when the cache is full, in some situations the cache may contain values whose index is outside the range specified by `distance`.
///
/// The total number of values the cache will retain is:
/// ```swift
///(distance * 2) + 1
///```
struct ImageCache {

	// MARK: Lifecycle

	/// Creates an empty cache that will automatically trim images based on the supplied `distance`.
	/// - Parameter distance: The maximum distance between the index of a new value and an already-cached value before the cached value is eligible to be removed from the cache.
	init(distance: Int) {
		self.distance = distance

		cache = [Int: Graphics.Bitmap?](minimumCapacity: (distance * 2) + 1)
	}

	// MARK: Internal

	/// Removes all values from the cache.
	mutating func removeAll() { cache.removeAll(keepingCapacity: true) }

	/// Accesses a value with the supplied `index` in the cache.
	subscript(index: Int) -> Graphics.Bitmap?? {
		get { return cache[index] }

		set {
			if cache.count >= (distance * 2) + 1 {
				cache = cache.filter({ (cachedIndex, image) in return abs(cachedIndex - index) <= distance }
				)
			}

			cache[index] = newValue
		}
	}

	// MARK: Private

	private var cache: [Int: Graphics.Bitmap?]
	private var distance: Int
}
