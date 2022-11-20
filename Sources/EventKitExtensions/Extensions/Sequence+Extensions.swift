//
//  Sequence+Extensions.swift
//  ReDo
//
//  Created by Paul Traylor on 2021/07/04.
//

import Foundation

// https://www.swiftbysundell.com/articles/sorting-swift-collections/

extension Sequence {
  public func sorted<T: Comparable>(
    by keyPath: KeyPath<Element, T>,
    using comparator: (T, T) -> Bool = (<)
  ) -> [Element] {
    sorted { a, b in
      comparator(a[keyPath: keyPath], b[keyPath: keyPath])
    }
  }
}
