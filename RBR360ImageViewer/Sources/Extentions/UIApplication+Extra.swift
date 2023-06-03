//
//  UIApplication+Extra.swift
//  VRTest3
//
//  Created by Rohan Bimal Raj on 13/05/23.
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
