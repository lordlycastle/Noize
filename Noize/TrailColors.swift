//
//  TrailColors.swift
//  Noize
//
//  Created by Chandan Siyag on 21/02/2018.
//  Copyright © 2018 xqz. All rights reserved.
//

import SpriteKit
import UIKit
import Foundation

let colors: [String] = ["#4c70f0",
						"#d082dc",
						"#f8b2c6",
						"#d3a337",
						"#88fb69",
						]


func hexStringToSKColor (hex:String) -> SKColor {
	var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
	
	if (cString.hasPrefix("#")) {
		cString.remove(at: cString.startIndex)
	}
	
	if ((cString.count) != 6) {
		return UIColor.gray
	}
	
	var rgbValue:UInt32 = 0
	Scanner(string: cString).scanHexInt32(&rgbValue)
	
	return SKColor(
		red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
		green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
		blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
		alpha: CGFloat(1.0)
	)
}
