//
//  NRSPieChartViewEndPoints.swift
//  Pods
//
//  Created by Neil Schreiber on 2/6/17.
//
//

import Foundation
import UIKit

@objc public class NRSPieChartViewEndPoints: NSObject {
    public var start: CGFloat
    public var end: CGFloat
    
    public init(start: CGFloat, end: CGFloat) {
        self.start = start
        self.end = end
    }
}
