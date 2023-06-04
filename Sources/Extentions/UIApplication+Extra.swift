//
//  UIApplication+Extra.swift
//  RBR360ImageViewer
//
//  Created by Rohan Bimal Raj on 04/05/2023.
//  Copyright © 2023 Rohan Bimal Raj. All rights reserved.
//

import Foundation
import UIKit

extension UIApplication {
    @available(iOS 13.0, *)
    var keyWindow: UIWindow? {
        return UIApplication.shared.connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .first(where: { $0 is UIWindowScene })
            .flatMap({ $0 as? UIWindowScene })?.windows
            .first(where: \.isKeyWindow)
    }
}
