//
//  ARControlledGameScene.swift
//  Noize
//
//  Created by Chandan Siyag on 22/02/2018.
//  Copyright © 2018 xqz. All rights reserved.
//

import UIKit
import SpriteKit
import ARKit

class ARControlledGameScene: GameScene {
	
	var eye_min = 0.1
	var eye_max = 0.5
	var eye_right = 0.0
	var eye_left = 0.0
	var eye_current_average: Double {
		get {
			return (self.eye_right + self.eye_left) / 2
		}
		set {
			self.eye_right = newValue / 2
			self.eye_left = self.eye_right
		}
	}
	
	var mouth_min = 0.1
	var mouth_max = 1
	var mouth_open = 0.0
	
	var filter_size = 20
	var mouth_moving_filter = BoxFilter(withSize: 20)
	var eye_moving_filter: BoxFilter = BoxFilter(withSize: 20)
	var forwards_filter = BoxFilter(withSize: 20)
	var backwards_filter = BoxFilter(withSize: 20)
	
	var blendShapes: [ARFaceAnchor.BlendShapeLocation: NSNumber] = [ARFaceAnchor.BlendShapeLocation: NSNumber]()
	var forward_min = 0.2
	var forward_max = 0.85
	var move_forward_modifier: ARFaceAnchor.BlendShapeLocation {
		get {
			return .eyeWideRight
		}
	}
	var backward_min = 0.1
	var backward_max = 0.7
	var move_back_modifier: ARFaceAnchor.BlendShapeLocation {
		get {
			return .mouthSmileRight
		}
	}
	
	override func didMove(to view: SKView) {
		super.didMove(to: view)
		
		self.mic_label?.numberOfLines = 5
		self.mic_label?.preferredMaxLayoutWidth = 500
		
		self.rainbow_mode = false
		
	}
	
	override func update(_ currentTime: TimeInterval) {
		super.update(currentTime)
		
	}
	
	override func updateLabelText() {
		if let face_anchor = self.face_anchor {
			
			self.mouth_open = face_anchor.blendShapes[.mouthClose] as! Double
			self.eye_right = face_anchor.blendShapes[.eyeWideRight] as! Double
			self.eye_left = face_anchor.blendShapes[.eyeWideLeft] as! Double
			let blink_right = face_anchor.blendShapes[.eyeSquintRight] as! Float
			let blink_left = face_anchor.blendShapes[.eyeSquintLeft] as! Float
			let text = String(format:"left: %.3f, right:%.3f",
							  self.backwards_filter.average,
							  self.forwards_filter.average
							  )
			
			self.mic_label?.text = text
			
			return
		} else {
			self.mic_label?.text = "No face anchor found."
			self.eye_current_average = 0
			self.mouth_open = 0
		}
		
	}
	
	override func movePlayer() {
		if let face_anchor = self.face_anchor {
			self.blendShapes = face_anchor.blendShapes
			self.player?.position.x = self.player!.position.x
				+ self.cam_move_speed * getForwardsModifier()
//				- self.cam_move_speed * getBackwardsModifier()
			self.cam?.position.x = self.player!.position.x + self.cam_player_shift!
			
			if let player = self.player, let cam = self.cam {
				if !cam.contains(player) {
					reset_level()
				}
			}
		}
	}
	
	func getForwardsModifier() -> CGFloat{
		self.forwards_filter.add(value: self.blendShapes[self.move_forward_modifier] as! Double)
		let modifier = getShiftedAverage(withAverage: self.forwards_filter.average,
										 min: self.forward_min,
										 max: self.forward_max)
		return CGFloat(modifier)
	}
	
	func getBackwardsModifier() -> CGFloat{
		self.backwards_filter.add(value: self.blendShapes[self.move_back_modifier] as! Double)
		let modifier = getShiftedAverage(withAverage: self.backwards_filter.average,
										 min: self.backward_min,
										 max: self.backward_max)
		return CGFloat(modifier)
	}
	
	func getSpeedModiferFromEyes(min: Double = 0.1, max: Double = 0.7) -> CGFloat {
		self.eye_moving_filter.add(value: self.eye_current_average)
		
		var modifier: Double = 0
//		if self.eye_moving_filter.average < min {
//			modifier = 0
//		}else if self.eye_moving_filter.average > max {
//			modifier = 1
//		}else {
//			modifier = self.eye_moving_filter.average
//		}
		
		modifier = getShiftedAverage(withAverage: self.eye_moving_filter.average, min: min, max: max)
		return CGFloat(modifier)
	}
	
	func getSpeedModifierFromMouth(min: Double = 0.05, max: Double = 0.4) -> CGFloat {
		self.mouth_moving_filter.add(value: self.mouth_open)
		let modifier  = getShiftedAverage(withAverage: self.mouth_moving_filter.average, min: min, max: max)
		return CGFloat(modifier)
	}
	
	func getShiftedAverage(withAverage average: Double, min: Double, max: Double) -> Double{
		
		let difference = max - min
		var shifted_average = average - min
		if shifted_average < 0 { shifted_average = 0 }
		return shifted_average / difference
	}
	
	
	override func touchDown(atPoint pos : CGPoint) {
		if let n = self.spinnyNode?.copy() as! SKShapeNode? {
			n.position = pos
			n.strokeColor = SKColor.green
			self.addChild(n)
		}
		
		if !self.is_mic_on {
//			self.mic?.start()
			self.is_mic_on = true
		}else {
//			self.mic?.stop()
			self.is_mic_on = false
		}
		
		if self.is_ar_on {
			self.ar_session?.run(self.ar_configuration)
		} else {
			self.ar_session?.pause()
		}
	}
	
	

}




class BoxFilter {
	var size: Int
	var data: [Double] = []
	var current_index = 0
	var sum: Double = 0
	var average: Double {
		get {
			return self.sum / Double(self.size)
		}
	}
	
	init(withSize size: Int) {
		self.size = size
		self.data = [Double](repeating: 0, count: self.size)
	}
	
	func add(value: Double) {
		self.sum -= self.data[current_index]
		self.data[current_index] = value
		self.sum += self.data[current_index]
		
		self.current_index += 1
		self.current_index = self.current_index % self.size
	}
}
