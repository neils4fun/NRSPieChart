//
//  NRSPieChartViewSliceIndex.swift
//  Pods
//
//  Created by Neil Schreiber on 2/6/17.
//
//

import Foundation

@objc public class NRSPieChartViewSliceIndex: NSObject {
    public var major: UInt
    public var minor: UInt
    
    public init(major: UInt, minor: UInt) {
        self.major = major
        self.minor = minor
    }
}
