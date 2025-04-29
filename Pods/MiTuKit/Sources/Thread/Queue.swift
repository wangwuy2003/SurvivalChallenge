//
//  Queue.swift
//  MiTuKit
//
//  Created by Hồ Minh Tường on 21/11/21.
//  Copyright © 2021 - Present MiTu Ultra

#if os(iOS)
import UIKit
import Foundation

public class Queue {
    public static func main(execute work: @escaping @convention(block) () -> Void) {
        DispatchQueue.main.async {
            work()
        }
    }
    
    public static func global(qos: DispatchQoS.QoSClass = .default, execute work: @escaping @convention(block) () -> Void) {
        DispatchQueue.global(qos: qos).sync(execute: {
            work()
        })
    }
    
    public static func after(queue: DispatchQueue = DispatchQueue.main, deadline: DispatchTime, execute work: @escaping @convention(block) () -> Void) {
        queue.asyncAfter(deadline: deadline, execute: {
            work()
        })
    }
    
    public static func delay(_ seconds: Double, queue: DispatchQueue = DispatchQueue.main) async -> Void {
        return await withCheckedContinuation { continuation in
            queue.asyncAfter(deadline: .now() + seconds, execute: {
                continuation.resume()
            })
        }
    }
}

#endif
