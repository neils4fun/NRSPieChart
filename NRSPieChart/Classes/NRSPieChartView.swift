//
//  NRSPieChart.swift
//  Pods
//
//  Created by Neil Schreiber on 2/6/17.
//
//

import Foundation
import QuartzCore
import UIKit

@objc public protocol NRSPieChartViewDataSourceProtocol : NSObjectProtocol {
    
    // Return the number of major slices in the chart
    func numberOfMajorSlicesInPieChartView(_ pieChartView: NRSPieChartView) -> UInt
    
    // Return the number of minor slices for the given major slice
    func numberOfMinorSlicesInPieChartView(_ pieChartView: NRSPieChartView, forMajorSlice majorSlice: UInt) -> UInt
    
    // Return the color for the major/minor slice
    func pieChartColorForSlice(_ pieChartView: NRSPieChartView, sliceIndex: NRSPieChartViewSliceIndex) -> CGColor
    
    // Return end points of a major/minor slice index These end points are in terms of circumfrencial percentage of a full circle
    func pieChartEndPointsForSlice(_ pieChartView: NRSPieChartView, sliceIndex: NRSPieChartViewSliceIndex) -> NRSPieChartViewEndPoints
    
    // Return the major slice that will remain after slices are removed on a refresh. This is to support allowing the slices to grow out
    // from their current position when one is transitioning between slices that represent some kind of a hierarchy
    @objc optional func pieChartMajorSliceToKeepHint(_ pieChartView: NRSPieChartView) -> UInt // Default is 0 if not implemented
    
    // Return whether the major/minor slice should highlight. Highlighted slices are displayed slightly wider than their unhighlighted presentation
    @objc optional func pieChartShouldHighlightSlice(_ pieChartView: NRSPieChartView, sliceIndex: NRSPieChartViewSliceIndex) -> Bool // Default is false if not implemented
    
    @objc optional func pieChartDidFinishRendering(_ pieChartView: NRSPieChartView)
    
}

@objc public protocol NRSPieChartViewDelegateProtocol : NSObjectProtocol {
    
    @objc optional func pieChartDidSingleTapSlice(_ pieChartView: NRSPieChartView, sliceIndex: NRSPieChartViewSliceIndex)
    @objc optional func pieChartDidDoubleTapSlice(_ pieChartView: NRSPieChartView, sliceIndex: NRSPieChartViewSliceIndex)
    
}

@objcMembers @IBDesignable // IB_DESIGNABLE
public class NRSPieChartView: UIView {
    #if !TARGET_INTERFACE_BUILDER
    weak public var dataSource: NRSPieChartViewDataSourceProtocol?
    weak public var delegate: NRSPieChartViewDelegateProtocol?
    #else
    // If IB the datasource isn't working if declared as weak because since
    // the datasource gets assigned within this classes init (see addBehavior()
    // below) the property is immediately released since afer the assignment
    // ARC sees no need to retain a weak property. So if IB I declare the
    // property as strong.
    public var dataSource: NRSPieChartViewDataSourceProtocol?
    public var delegate: NRSPieChartViewDelegateProtocol?
    #endif
    
    public var shouldAnimate: Bool = false
    
    @IBInspectable var bInset: CGFloat = 5 {
        didSet { updateLayerProperties() }
    }
    @IBInspectable var sInset: CGFloat = 10 {
        didSet { updateLayerProperties() }
    }
    @IBInspectable var bLineWidth: CGFloat = 30.0 {
        didSet { updateLayerProperties() }
    }
    @IBInspectable var sLineWidth: CGFloat = 20.0 {
        didSet { updateLayerProperties() }
    }
    @IBInspectable var bColor: UIColor = UIColor(white: 0.0, alpha: 1.0) {
        didSet { updateLayerProperties() }
    }
    @IBInspectable var bSRadius: CGFloat = 0.0 {
        didSet { updateLayerProperties() }
    }
    @IBInspectable var bSOpacity: Float = 5.0 {
        didSet { updateLayerProperties() }
    }
    @IBInspectable var sSRadius: CGFloat = 0.0 {
        didSet { updateLayerProperties() }
    }
    @IBInspectable var sSOpacity: Float = 5.0 {
        didSet { updateLayerProperties() }
    }
    @IBInspectable var duration: Float = 0.3 {
        didSet { updateLayerProperties() }
    }
    
    fileprivate var backgroundRingLayer: CAShapeLayer!
    fileprivate var pieSegments = [CAShapeLayer]()
    fileprivate var dirty = true
    
    override init (frame : CGRect) {
        super.init(frame : frame)
        commonInit()
    }
    
    required public init!(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func commonInit (){
        
        #if !TARGET_INTERFACE_BUILDER
            // this code will run in the app itself
        #else
            // this code will execute only in IB
            dataSource = PieChartViewDataSource()
        #endif
        
        let pieChartSingleTapGestureRecoginize = UITapGestureRecognizer()
        pieChartSingleTapGestureRecoginize.addTarget(self, action: #selector(NRSPieChartView.pieChartTapped(_:)))
        pieChartSingleTapGestureRecoginize.numberOfTapsRequired = 1
        self.addGestureRecognizer(pieChartSingleTapGestureRecoginize)
        
        let pieChartDoubleTapGestureRecoginize = UITapGestureRecognizer()
        pieChartDoubleTapGestureRecoginize.addTarget(self, action: #selector(NRSPieChartView.pieChartTapped(_:)))
        pieChartDoubleTapGestureRecoginize.numberOfTapsRequired = 2
        self.addGestureRecognizer(pieChartDoubleTapGestureRecoginize)
        
        pieChartSingleTapGestureRecoginize.require(toFail: pieChartDoubleTapGestureRecoginize)
        
        // Create the background layer
        backgroundRingLayer = CAShapeLayer()
        
        backgroundRingLayer.rasterizationScale = 2.0 * UIScreen.main.scale;
        backgroundRingLayer.shouldRasterize = true;
        
        layer.addSublayer(backgroundRingLayer)
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        
        let totalInset: CGFloat = bInset + bLineWidth/2.0
        let rect = bounds.insetBy(dx: totalInset, dy: totalInset)
        let center = CGPoint(x: bounds.width/2.0, y: bounds.height/2.0)
        let twoPi = 2.0 * Double.pi
        let startAngle = -Double.pi/2 //Double(fractionOfCircle) * Double(twoPi) - Double(M_PI_2)
        let endAngle = twoPi - Double.pi/2
        let clockwise: Bool = true
        let path = UIBezierPath(arcCenter: center, radius: rect.height/2.0, startAngle: CGFloat(startAngle), endAngle: CGFloat(endAngle), clockwise: clockwise)
        
        backgroundRingLayer.path = path.cgPath
        backgroundRingLayer.lineWidth = bLineWidth
        backgroundRingLayer.fillColor = nil;
        backgroundRingLayer.strokeColor = bColor.cgColor
        
        backgroundRingLayer.shadowColor = UIColor.black.cgColor
        backgroundRingLayer.shadowRadius = bSRadius
        backgroundRingLayer.shadowOpacity = bSOpacity/10.0
        backgroundRingLayer.shadowOffset = CGSize(width: -3, height: 3)
        backgroundRingLayer.frame = layer.bounds
        
        if dirty {
            for layer in pieSegments {
                layer.removeFromSuperlayer()
            }
            pieSegments.removeAll()
            
            self.refreshSlices()
            shouldAnimate = false
            dirty = false
        }
    }
    
    public func refreshSlices() {
        let numLinearSlices = self.numLinearSlices()
        
        // Disable implicit CALayer animiations
        CATransaction.setDisableActions(true)
        
        // Determine if layers are going to be removed, added, or remain the same
        if (numLinearSlices == UInt(pieSegments.count)) {
            // Same number of slices, just update all the endpoints
            
            for (index, ringLayer) in pieSegments.enumerated() {
                let sliceIndex = self.sliceIndexForLinearIndex(UInt(index))
                if let strokeColor = dataSource?.pieChartColorForSlice(self, sliceIndex: sliceIndex) {
                    // Setup a custom animation for the color change, for which we can set a programmable "duration" value
                    animateLayer(ringLayer, strokeColor: strokeColor, shouldAnimate: shouldAnimate, duration: duration)
                }
                
                if let endPoints = dataSource?.pieChartEndPointsForSlice(self, sliceIndex:sliceIndex) {
                    animateLayer(ringLayer, strokeStart: endPoints.start/100, shouldAnimate: shouldAnimate, duration: duration)
                    animateLayer(ringLayer, strokeEnd: endPoints.end/100, shouldAnimate: shouldAnimate, duration: duration)
                }
                
                let shouldHighlight = dataSource?.pieChartShouldHighlightSlice?(self, sliceIndex: sliceIndex) ?? false
                if (shouldHighlight) {
                    ringLayer.lineWidth = sLineWidth + 4
                } else {
                    ringLayer.lineWidth = sLineWidth
                }
            }
        } else if (numLinearSlices < UInt(pieSegments.count)) {
            // There are fewer slices now. Update the endpoints of the existing
            // ones and then remove any extras
            
            let refreshSliceOffset = dataSource?.pieChartMajorSliceToKeepHint?(self) ?? 0
            
            for index in 0..<UInt(pieSegments.count) {
                let ringLayer = pieSegments[Int(index)]
                ringLayer.removeAllAnimations()
                
                if (index < refreshSliceOffset) {
                    // This segment is going away, animate it out
                    animateLayer(ringLayer, strokeStart: 0.0, shouldAnimate: shouldAnimate, duration: duration)
                    animateLayer(ringLayer, strokeEnd: 0.0, shouldAnimate: shouldAnimate, duration: duration)
                } else if (index >= refreshSliceOffset + numLinearSlices) {
                    // This segment is going away, animate it out
                    animateLayer(ringLayer, strokeStart: 1.0, shouldAnimate: shouldAnimate, duration: duration)
                    animateLayer(ringLayer, strokeEnd: 1.0, shouldAnimate: shouldAnimate, duration: duration)
                } else {
                    
                    let sliceIndex = self.sliceIndexForLinearIndex(UInt(index - refreshSliceOffset))
                    if let strokeColor = dataSource?.pieChartColorForSlice(self, sliceIndex: sliceIndex) {
                        animateLayer(ringLayer, strokeColor: strokeColor, shouldAnimate: shouldAnimate, duration: duration)
                    }
                    
                    if let endPoints = dataSource?.pieChartEndPointsForSlice(self, sliceIndex:sliceIndex) {
                        animateLayer(ringLayer, strokeStart: endPoints.start/100, shouldAnimate: shouldAnimate, duration: duration)
                        animateLayer(ringLayer, strokeEnd: endPoints.end/100, shouldAnimate: shouldAnimate, duration: duration)
                    }
                    let shouldHighlight = dataSource?.pieChartShouldHighlightSlice?(self, sliceIndex: sliceIndex) ?? false
                    if (shouldHighlight) {
                        ringLayer.lineWidth = sLineWidth + 4
                    } else {
                        ringLayer.lineWidth = sLineWidth
                    }
                }
            }
            
            // Remove the extra layers, but defer it until the animations are complete
            var beforeSectionSlicesToRemove = [CAShapeLayer]()
            var afterSectionSlicesToRemove = [CAShapeLayer]()
            
            for index in 0..<refreshSliceOffset {
                beforeSectionSlicesToRemove.append(pieSegments[Int(index)])
            }
            for index in Int(refreshSliceOffset + numLinearSlices)..<pieSegments.count {
                afterSectionSlicesToRemove.append(pieSegments[Int(index)])
            }
            
            let delayTime = DispatchTime.now() + Double(Int64(Double(duration) * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: delayTime) {
                beforeSectionSlicesToRemove.forEach { layer in
                    layer.removeFromSuperlayer()
                }
                
                afterSectionSlicesToRemove.forEach { layer in
                    layer.removeFromSuperlayer()
                }
            }
            
            pieSegments[Int(refreshSliceOffset + numLinearSlices)..<pieSegments.count] = []
            pieSegments[0..<Int(refreshSliceOffset)] = []
        } else {
            // There are more slices now. Add new ones.
            // Set the current colors and sizes of all the segments
            
            for (index, ringLayer) in pieSegments.enumerated() {
                let sliceIndex = self.sliceIndexForLinearIndex(UInt(index))
                if let strokeColor = dataSource?.pieChartColorForSlice(self, sliceIndex: sliceIndex) {
                    animateLayer(ringLayer, strokeColor: strokeColor, shouldAnimate: shouldAnimate, duration: duration)
                }
                
                if let endPoints = dataSource?.pieChartEndPointsForSlice(self, sliceIndex:sliceIndex) {
                    animateLayer(ringLayer, strokeStart: endPoints.start/100, shouldAnimate: shouldAnimate, duration: duration)
                    animateLayer(ringLayer, strokeEnd: endPoints.end/100, shouldAnimate: shouldAnimate, duration: duration)
                }
                let shouldHighlight = dataSource?.pieChartShouldHighlightSlice?(self, sliceIndex: sliceIndex) ?? false
                if (shouldHighlight) {
                    ringLayer.lineWidth = sLineWidth + 4
                } else {
                    ringLayer.lineWidth = sLineWidth
                }
            }
            
            for index in UInt(pieSegments.count)..<numLinearSlices {
                let ringLayer = CAShapeLayer()
                
                let totalInset: CGFloat = sInset + sLineWidth/2.0
                let innerRect = bounds.insetBy(dx: totalInset, dy: totalInset)
                
                let center = CGPoint(x: bounds.width/2.0, y: bounds.height/2.0)
                let twoPi = 2.0 * Double.pi
                let startAngle = -Double.pi/2 //Double(fractionOfCircle) * Double(twoPi) - Double(M_PI_2)
                let endAngle = twoPi - Double.pi/2
                let clockwise: Bool = true
                let innerPath = UIBezierPath(arcCenter: center, radius: innerRect.height/2.0, startAngle: CGFloat(startAngle), endAngle: CGFloat(endAngle), clockwise: clockwise)
                
                ringLayer.rasterizationScale = 2.0 * UIScreen.main.scale;
                ringLayer.shouldRasterize = true;
                
                ringLayer.path = innerPath.cgPath
                ringLayer.fillColor = nil
                
                let sliceIndex = self.sliceIndexForLinearIndex(UInt(index))
                let shouldHighlight = dataSource?.pieChartShouldHighlightSlice?(self, sliceIndex: sliceIndex) ?? false
                if (shouldHighlight) {
                    ringLayer.lineWidth = sLineWidth + 4
                } else {
                    ringLayer.lineWidth = sLineWidth
                }
                
                ringLayer.shadowColor = UIColor.black.cgColor
                ringLayer.shadowRadius = sSRadius
                ringLayer.shadowOpacity = sSOpacity/10.0
                ringLayer.shadowOffset = CGSize.zero
                
                ringLayer.strokeColor = dataSource!.pieChartColorForSlice(self, sliceIndex:sliceIndex)
                
                ringLayer.strokeStart = 1.0
                ringLayer.strokeEnd = 1.0
                
                layer.addSublayer(ringLayer)
                
                ringLayer.frame = layer.bounds
                
                pieSegments.append(ringLayer)
                
                if let endPoints = dataSource?.pieChartEndPointsForSlice(self, sliceIndex:sliceIndex) {
                    animateLayer(ringLayer, strokeStart: endPoints.start/100, shouldAnimate: shouldAnimate, duration: duration)
                    animateLayer(ringLayer, strokeEnd: endPoints.end/100, shouldAnimate: shouldAnimate, duration: duration)
                }
            }
        }
        
        // Re-enable implicit CALayer animiations
        CATransaction.setDisableActions(false)
        
        dataSource?.pieChartDidFinishRendering?(self)
    }
    
    public func centerPointFor(_ majorSlice: UInt) -> CGPoint {
        guard majorSlice < dataSource?.numberOfMajorSlicesInPieChartView(self) ?? 0 else {
            return CGPoint(x: 0, y: 0)
        }
        
        var numLinearSlices: UInt = 0
        var segmentAtStart: CAShapeLayer
        var segmentAtEnd: CAShapeLayer
        
        // Find the pieSegment for the first minor slice of the specified major
        for majorIndex in 0..<majorSlice {
            let numMinorSlices = dataSource?.numberOfMinorSlicesInPieChartView(self, forMajorSlice: majorIndex) ?? 0
            
            for _ in 0..<numMinorSlices {
                numLinearSlices += 1
            }
        }
        segmentAtStart = pieSegments[Int(numLinearSlices)];
        
        // Find the pieSegment for the last minor slice of the specfied major
        let numMinorSlices = dataSource?.numberOfMinorSlicesInPieChartView(self, forMajorSlice: majorSlice) ?? 0
        
        for _ in 0..<numMinorSlices {
            numLinearSlices += 1
        }
        
        // Note, -1 index to get the last minor slice in the major
        segmentAtEnd = pieSegments[Int(numLinearSlices - 1)];
        
        // Midpoint of major slice in terms of stroke distance
        let sliceStrokeMid = segmentAtStart.strokeStart + (segmentAtEnd.strokeEnd - segmentAtStart.strokeStart)/2.0
        
        // Convert stroke terms to angle terms. NOTE: rotate left by 90 degrees to account for 0 degrees defined as vertical/up
        let twoPi = 2.0 * Double.pi
        let midAngle = Double(sliceStrokeMid) * twoPi - Double.pi/2;
        
        // Compute the x,y coordinate (in view coordinates) from the radial coordinate
        let x = bounds.origin.x + bounds.size.width/2.0 + (frame.height/2 - sInset - sLineWidth/2.0) * CGFloat(cos(midAngle))
        let y = bounds.size.height - (bounds.origin.y + bounds.size.height/2 - ((frame.height/2.0 - sInset - sLineWidth/2.0) * CGFloat(sin(midAngle))))
        
        return CGPoint(x: x, y: y)
    }
    
    func updateLayerProperties() {
        dirty = true
        setNeedsLayout()
    }
    
}

// MARK: - Animate Layer Properties
extension NRSPieChartView {
    func animateLayer(_ layer: CAShapeLayer, strokeColor: CGColor, shouldAnimate: Bool, duration: Float) {
        // Setup a custom animation for layers strokeColor property
        if (shouldAnimate) {
            let strokeColorAnimation = CABasicAnimation(keyPath: "strokeColor")
            strokeColorAnimation.fromValue = layer.strokeColor
            strokeColorAnimation.toValue = strokeColor
            strokeColorAnimation.duration = CFTimeInterval(duration)
            layer.add(strokeColorAnimation, forKey: "StrokeColorAnimation")
        }
        layer.strokeColor = strokeColor
    }
    
    func animateLayer(_ layer: CAShapeLayer, strokeStart: CGFloat, shouldAnimate: Bool, duration: Float) {
        // Setup a custom animination for the layer's strokeStart property
        if (shouldAnimate) {
            let strokeStartAnimation = CABasicAnimation(keyPath: "strokeStart")
            strokeStartAnimation.fromValue = layer.strokeStart
            strokeStartAnimation.toValue = strokeStart
            strokeStartAnimation.duration = CFTimeInterval(duration)
            layer.add(strokeStartAnimation, forKey: "StrokeStartAnimation")
        }
        layer.strokeStart = strokeStart
    }
    
    func animateLayer(_ layer: CAShapeLayer, strokeEnd: CGFloat, shouldAnimate: Bool, duration: Float) {
        // Setup a custom animination for the layer's strokeEnd property
        if (shouldAnimate) {
            let strokeEndAnimation = CABasicAnimation(keyPath: "strokeEnd")
            strokeEndAnimation.fromValue = layer.strokeEnd
            strokeEndAnimation.toValue = strokeEnd
            strokeEndAnimation.duration = CFTimeInterval(duration)
            layer.add(strokeEndAnimation, forKey: "StrokeEndAnimation")
        }
        layer.strokeEnd = strokeEnd
    }
}

// MARK: - Slice Index to Linear Index conversions

extension NRSPieChartView {
    func numLinearSlices() -> UInt {
        var numLinearSlices: UInt = 0
        var numMajorSlices: UInt
        numMajorSlices = dataSource?.numberOfMajorSlicesInPieChartView(self) ?? 0
        
        for majorIndex in 0..<numMajorSlices {
            let numMinorSlices = dataSource?.numberOfMinorSlicesInPieChartView(self, forMajorSlice: majorIndex) ?? 0
            
            for _ in 0..<numMinorSlices {
                numLinearSlices += 1
            }
        }
        return numLinearSlices
    }
    
    func sliceIndexForLinearIndex(_ linearIndex: UInt) -> NRSPieChartViewSliceIndex {
        var linearIndex = linearIndex
        var majorIndex: UInt = 0
        let numMajorSlices = dataSource?.numberOfMajorSlicesInPieChartView(self) ?? 0
        
        for index in 0..<numMajorSlices {
            majorIndex = index
            let numMinorSlices = dataSource?.numberOfMinorSlicesInPieChartView(self, forMajorSlice: index) ?? 0
            
            if linearIndex < numMinorSlices {
                break
            }
            linearIndex -= numMinorSlices
        }
        return NRSPieChartViewSliceIndex(major: majorIndex, minor: linearIndex)
    }
}

// MARK: - Gesture Recognizer Handling

extension NRSPieChartView {
    @objc func pieChartTapped(_ sender:UITapGestureRecognizer) {
        let touchPoint = sender.location(in: self)
        let center = CGPoint(x: bounds.width/2.0, y: bounds.height/2.0)
        
        // Since our frame of reference is rotated -90 compute deltaX as the change in Y,
        // and deltaY as the change X (confusing, but should work).
        let deltaX = (center.y - touchPoint.y)
        let deltaY = (center.x - touchPoint.x)
        let thetaRadians = atan2(Double(deltaY),Double(deltaX))
        let thetaDegrees = thetaRadians * 180/Double.pi
        let theta360Degrees = 360.0 - (thetaDegrees > 0.0 ? thetaDegrees : (360.0 + thetaDegrees))
        let theta360Percent = theta360Degrees / 360.0
        
        for (index,layer) in pieSegments.enumerated() {
            if (layer.hitTest(touchPoint) != nil) {
                if (CGFloat(theta360Percent) > layer.strokeStart &&
                    CGFloat(theta360Percent) <= layer.strokeEnd) {
                    let sliceIndex = self.sliceIndexForLinearIndex(UInt(index))
                    if (sender.numberOfTapsRequired == 1) {
                        delegate?.pieChartDidSingleTapSlice?(self, sliceIndex:sliceIndex)
                    } else {
                        delegate?.pieChartDidDoubleTapSlice?(self, sliceIndex:sliceIndex)
                    }
                    return;
                }
            }
        }
    }
}

