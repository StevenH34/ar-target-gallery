//
//  CustomButton.swift
//  AR Shooting Gallery
//
//  Created by Steven Hedges on 5/31/18.
//  Copyright © 2018 Steven Hedges. All rights reserved.
//

import UIKit

class CustomButton: UIButton {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        customizeButton()
    }
    
    func customizeButton() {
        backgroundColor = UIColor.lightGray
        layer.cornerRadius = 10.0
        layer.borderWidth = 2.0
        layer.borderColor = UIColor.white.cgColor
    }

}
