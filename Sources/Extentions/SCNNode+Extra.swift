//
//  SCNNode+Extra.swift
//  RBR360ImageViewer
//
//  Created by Rohan Bimal Raj on 04/05/2023.
//  Copyright © 2023 Rohan Bimal Raj. All rights reserved.
//

import Foundation
import SceneKit


extension SCNNode {
    
    var height: Float {
        self.boundingBox.max.y - self.boundingBox.min.y
    }
    
    var width: Float {
        return self.boundingBox.max.x - self.boundingBox.min.x
    }
    
    var depth: Float {
        return self.boundingBox.max.z - self.boundingBox.min.z
    }
    
    var isSelected: Bool {
        return self.childNode(withName: "positionIndicator", recursively: true) != nil
    }
    
    func getRoot() -> SCNNode? {
        if let node = self.parent {
            if node.name == "root" {
                return node
            }else {
                return node.getRoot()
            }
        }
        else {
            return self
        }
    }
    
    func centerPivot() {
        let maxBounds = self.boundingBox.max
        let minBounds = self.boundingBox.min
        
        let maximum = SIMD3(x: maxBounds.x, y: maxBounds.y, z: maxBounds.z)
        let minimum = SIMD3(x: minBounds.x, y: minBounds.y, z: minBounds.z)
        
        let newPivot = (maximum + minimum) * 0.5
        self.pivot = SCNMatrix4MakeTranslation(newPivot.x, newPivot.y, newPivot.z)
    }
    
    func stopAnimation() {
        self.animationKeys.forEach { key in
            guard self.animationPlayer(forKey: key) != nil else {return}
            let player = self.animationPlayer(forKey: key)
            player?.speed = 0
        }
        self.childNodes.forEach { node in
            node.stopAnimation()
        }
    }
    
    func startAnimation() {
        self.animationKeys.forEach { key in
            guard self.animationPlayer(forKey: key) != nil else {return}
            let player = self.animationPlayer(forKey: key)
            player?.speed = 1
        }
        self.childNodes.forEach { node in
            node.startAnimation()
        }
    }
}
