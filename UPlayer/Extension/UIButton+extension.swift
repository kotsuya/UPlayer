//
//  UIButton+extension.swift
//  UPlayer
//
//  Created by YooSeunghwan on 2017/11/29.
//  Copyright © 2017年 YooSeunghwan. All rights reserved.
//

import UIKit

extension UIButton {
    func setupBtn() {
        self.backgroundColor = .clear
        self.tintColor = .white
        self.layer.masksToBounds = true
        self.layer.cornerRadius = 15
        self.layer.borderWidth = 1
        self.layer.borderColor = UIColor.white.cgColor
    }
}
