//
//  ThreadSafeArray.swift
//  bp-video-event-recorder
//
//  Created by Dominik Chmelík on 03.06.2022.
//

import Foundation

final class ThreadSafeArray<Element: Equatable> {
    
    private let dispatchQueue: DispatchQueue
    private var array: [Element]
    
    var all: [Element] {
        
        var all = [Element]()
        
        dispatchQueue.sync {
        
            all = array
        }
        
        return all
    }
    
    init(dispatchQueue: DispatchQueue) {
        
        self.dispatchQueue = dispatchQueue
        self.array = []
    }
    
    func append(_ element: Element) {
        
        dispatchQueue.async(flags: .barrier) {
            
            guard !self.array.contains(element) else {
                return
            }
            
            self.array.append(element)
        }
    }
    
    func clear() {
        
        dispatchQueue.async(flags: .barrier) {
        
            self.array = [Element]()
        }
    }
    
    func remove(_ element: Element) {
        
        dispatchQueue.async(flags: .barrier) {
            
            guard
                let index = self.array.firstIndex(of: element)
            else {
                return
            }
        
            self.array.remove(at: index)
        }
    }
    
    func first() -> Element? {
        
        var element: Element?
        
        dispatchQueue.sync {
            
            element = self.array.first
        }
        
        return element
    }
    
    func count() -> Int {
        
        var count: Int = 0
        
        dispatchQueue.sync {
            
            count = self.array.count
        }
        
        return count
    }
    
    func filter(_ condition: ((Element) -> Bool)) -> [Element] {
        
        var elements: [Element] = []
        
        dispatchQueue.sync {
            
            elements = self.array.filter { element in
                
                return condition(element)
            }
        }
        
        return elements
    }
    
    func contains(_ element: Element) -> Bool {
        
        var contains: Bool = false
        
        dispatchQueue.sync {
            
            contains = self.array.contains(element)
        }
        
        return contains
    }
    
    func sorted(_ condition: ((Element, Element) -> Bool)) -> [Element] {
        
        var sortedElements: [Element] = []
        
        dispatchQueue.sync {
            
            sortedElements = self.array.sorted(by: { lhs, rhs in
                
                return condition(lhs, rhs)
            })
        }
        
        return sortedElements
    }
}
