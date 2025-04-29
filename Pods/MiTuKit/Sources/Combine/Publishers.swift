//
//  Publishers.swift
//  MiTuKit
//
//  Created by Hồ Minh Tường on 21/11/21.
//  Copyright © 2021 - Present MiTu Ultra

#if os(iOS)
import Combine

public extension Publishers {
    struct Zip6 <A: Publisher, B: Publisher, C: Publisher, D: Publisher, E: Publisher, F: Publisher>: Publisher
        where A.Failure == B.Failure, A.Failure == C.Failure, A.Failure == D.Failure, A.Failure == E.Failure, A.Failure == F.Failure {
            public typealias Output = (A.Output, B.Output, C.Output, D.Output, E.Output, F.Output)
            public typealias Failure = A.Failure
            
            private let a: A
            private let b: B
            private let c: C
            private let d: D
            private let e: E
            private let f: F
            
            init(_ a: A, _ b: B, _ c: C, _ d: D, _ e: E, _ f: F) {
                self.a = a
                self.b = b
                self.c = c
                self.d = d
                self.e = e
                self.f = f
            }
            
        public func receive<S>(subscriber: S) where S : Subscriber, Output == S.Input, Failure == S.Failure {
                Zip(Zip4(a, b, c, d), Zip(e, f))
                    .map {($0.0, $0.1, $0.2, $0.3, $1.0, $1.1)}
                    .receive(subscriber: subscriber)
            }
        }
}

#endif
