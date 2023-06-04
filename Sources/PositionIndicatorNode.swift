//
//  PositionIndicatorNode.swift
//  RBR360ImageViewer
//
//  Created by Rohan Bimal Raj on 04/05/2023.
//  Copyright © 2023 Rohan Bimal Raj. All rights reserved.
//

import Foundation
import SceneKit

class PositionIndicatorNode: SCNNode {
    
    var cameraNode: SCNNode?
    override init() {
        super.init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    convenience init(cameraNode: SCNNode) {
        self.init()
        self.cameraNode = cameraNode
        self.createIndicator()
    }
    
    private func createIndicator() {
        
        self.name = "positionIndicator"
        
        let shape = UIBezierPath()
        
        shape.move(to: CGPoint(x: 6.80, y: -0.2786))
        shape.addCurve(to: CGPoint(x: 3.2943, y: 6.7143), controlPoint1: CGPoint(x: 6.80, y: -0.26), controlPoint2: CGPoint(x: 3.3001, y: 6.7213))
        shape.addCurve(to: CGPoint(x: -0.20, y: -0.2829), controlPoint1: CGPoint(x: 3.2748, y: 6.6907), controlPoint2: CGPoint(x: -0.2064, y: -0.2803))
        shape.addCurve(to: CGPoint(x: 1.5529, y: 0.4695), controlPoint1: CGPoint(x: -0.1958, y: -0.2846), controlPoint2: CGPoint(x: 0.593, y: 0.054))
        shape.addLine(to: CGPoint(x: 3.2981, y: 1.225))
        shape.addLine(to: CGPoint(x: 5.0406, y: 0.4697))
        shape.addCurve(to: CGPoint(x: 6.7915, y: -0.2857), controlPoint1: CGPoint(x: 5.9989, y: 0.0542), controlPoint2: CGPoint(x: 6.7868, y: -0.2857))
        shape.addCurve(to: CGPoint(x: 6.80, y: -0.2786), controlPoint1: CGPoint(x: 6.7962, y: -0.2857), controlPoint2: CGPoint(x: 6.80, y: -0.2825))
        shape.apply(CGAffineTransform(rotationAngle: .pi))
        
        let arrowGeo = SCNShape(path: shape, extrusionDepth: 0.1)
        let material = SCNMaterial()
        material.lightingModel = .physicallyBased
        material.diffuse.contents = UIColor.red
        arrowGeo.materials = [material]
        let arrow = SCNNode(geometry: arrowGeo)
        
        arrow.centerPivot()
        
        let contraint = SCNLookAtConstraint(target: cameraNode)
        contraint.isGimbalLockEnabled = true
        arrow.constraints = [contraint]
        self.addChildNode(arrow)
        
    }
    
    private func startIndicatorAnimation() {
                
        let moveUp = SCNAction.moveBy(x: 0, y: 1, z: 0, duration: 1)
        moveUp.timingMode = .easeInEaseOut;
        let moveDown = SCNAction.moveBy(x: 0, y: -1, z: 0, duration: 1)
        moveDown.timingMode = .easeInEaseOut;
        let moveSequence = SCNAction.sequence([moveUp,moveDown])
        let moveLoop = SCNAction.repeatForever(moveSequence)
        self.runAction(moveLoop)
    }
    
    private func stopIndicatorAnimation() {
        self.removeAllActions()
    }
    
    public func addIndicator(to node: SCNNode) {
        
        node.addChildNode(self)
        self.position = SCNVector3(x: 0, y: (node.height), z: 0)
        startIndicatorAnimation()
    }
    
    public func removeIndicator() {
        stopIndicatorAnimation()
        self.scale = SCNVector3(x: 1, y: 1, z: 1)
        self.position = SCNVector3(x: 0, y: 0, z: 0)
        self.removeFromParentNode()
    }
}
