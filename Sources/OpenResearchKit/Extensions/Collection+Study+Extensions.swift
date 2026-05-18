//
//  Collection+Study+Extensions.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 10.04.26.
//


public extension Collection where Element == Study {
    
    func randomStudy<R: RandomNumberGenerator>(using randomNumberGenerator: inout R) -> Study? {
        
        guard !isEmpty else {
            return nil
        }
        
        let next = randomNumberGenerator.next()
        let offset = Int(next % UInt64(count))
        let index = self.index(startIndex, offsetBy: offset)
        
        return self[index]
    }
    
}
