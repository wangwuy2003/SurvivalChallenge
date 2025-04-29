//
//  MTArray.swift
//  MiTuKit
//
//  Created by Hồ Minh Tường on 21/11/21.
//  Copyright © 2021 - Present MiTu Ultra

#if os(iOS)
import UIKit
import Foundation

public extension Array {
    func split(to: Int) -> [[Element]] {
        if self.count == 0 {return [self, []]}
        if self.count <= to {
            return [Array(self), []]
        }
        let leftSplit = self[0 ..< to]
        let rightSplit = self[to ..< self.count]
        return [Array(leftSplit), Array(rightSplit)]
    }
    
    func split(from: Int) -> [Element] {
        if self.count == 0 {return self}
        let split = self[Swift.min(from, self.count - 1) ..< self.count]
        return Array(split)
    }
    
    func split(from: Int, to: Int) -> [Element] {
        if self.count == 0 {return self}
        let split = self[Swift.min(from, self.count - 1) ..< Swift.min(self.count, to)]
        return Array(split)
    }
}


public extension Sequence where Element: Hashable {
    func uniqued() -> [Element] {
        var set = Set<Element>()
        return filter { set.insert($0).inserted }
    }
}

public extension Array {
    static func fromTuple<Tuple> (_ tuple: Tuple) -> [Element] {
        let val = Array<Element>.fromTupleOptional(tuple)
        return val.allSatisfy({ $0 != nil }) ? val.map { $0! } : []
    }
    
    static func fromTupleOptional<Tuple> (_ tuple: Tuple) -> [Element?] {
        return Mirror(reflecting: tuple)
            .children
            .filter { child in
                (child.label ?? "x").allSatisfy { char in ".1234567890".contains(char) }
            }.map { $0.value as? Element }
    }
}

#endif

