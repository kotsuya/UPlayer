//
//  UPUtilities.swift
//  UPlayer
//
//  Created by YooSeunghwan on 2017/12/27.
//  Copyright © 2017年 YooSeunghwan. All rights reserved.
//

import UIKit

class UPUtilities: NSObject {
  
    static func isIpad() -> Bool
    {
        return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.pad)
    }
    
    static func isIPhone() -> Bool
    {
        return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.phone)
    }
    
    static func iOSMajorVersion() -> Int {
        guard let ver:String = UIDevice.current.systemVersion as String! else {
            return 0
        }
        let array = ver.components(separatedBy: ".")
        guard array.count > 0 else {
            return 0
        }
        return Int(array[0])!
    }
    
    
    static func isDeviceLandscape() -> Bool {
        switch UIDevice.current.orientation {
        case .portrait:
            return false
        case .landscapeLeft, .landscapeRight:
            return true
        default:
            return UIScreen.main.bounds.size.width > UIScreen.main.bounds.size.height
        }
    }
}

