//
//  Float+Extra.swift
//  RBR360ImageViewer
//
//  Created by Rohan Bimal Raj on 04/05/2023.
//  Copyright © 2023 Rohan Bimal Raj. All rights reserved.
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
