//
//  Float+Extra.swift
//  VRTest3
//
//  Created by Rohan Bimal Raj on 13/05/23.
//

import Foundation

extension Float {
  var radians: Float {
    return self * .pi / 180
  }

  var degrees: Float {
    return self  * 180 / .pi
  }
}
