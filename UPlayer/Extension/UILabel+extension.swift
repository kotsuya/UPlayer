//
//  UILabel+extension.swift
//  UPlayer
//
//  Created by YooSeunghwan on 2017/11/29.
//  Copyright © 2017年 YooSeunghwan. All rights reserved.
//

import UIKit

extension UILabel {    
    func setupLabel() {
        self.backgroundColor = .clear
        self.font = UIFont.systemFont(ofSize: 10)
        self.textColor = .white
        self.shadowColor = .gray
        self.textAlignment = .center
        self.text = "00:00"
    }
}
