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
	
	var eye_moving_filter: BoxFilter = BoxFilter(withSize: 20)
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
	
	var mouth_moving_filter = BoxFilter(withSize: 20)
	var mouth_open = 0.0
	

	
	override func didMove(to view: SKView) {
		super.didMove(to: view)
		
		self.mic_label?.numberOfLines = 5
		self.mic_label?.preferredMaxLayoutWidth = 500
		
	}
	
	override func update(_ currentTime: TimeInterval) {
		super.update(currentTime)
		
//		if let frame = self.ar_session?.currentFrame {
//			for anchor in frame.anchors {
//				guard let faceAnchor = anchor as? ARFaceAnchor else { return }
//	//			self.face_anchor = faceAnchor
//				print(face_anchor?.geometry.triangleCount)
//				//			self.update_with_face_anchor(face_anchor: self.face_anchor!)
//			}
//		}
	}
	
	override func updateLabelText() {
		if let face_anchor = self.face_anchor {
//			if face_anchor.geometry.triangleCount == 0 {  }
//			print(face_anchor.geometry.triangleCount)
			self.mouth_open = face_anchor.blendShapes[.mouthClose] as! Double
			self.eye_right = face_anchor.blendShapes[.eyeWideRight] as! Double
			self.eye_left = face_anchor.blendShapes[.eyeWideLeft] as! Double
			let blink_right = face_anchor.blendShapes[.eyeSquintRight] as! Float
			let blink_left = face_anchor.blendShapes[.eyeSquintLeft] as! Float
//			let eye_average = (self.eye_left + self.eye_right) / 2
//			print(eye_average)
			var text = String(format:"mouth: %.3f,\n eye: %.3f, %.3f,\n squint: %.3f, %.3f",
							  mouth_open,
							  self.eye_left, self.eye_right,
							  blink_left, blink_right
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
		self.player?.position.x = self.player!.position.x
			+ self.cam_move_speed * getSpeedModiferFromEyes()
			- self.cam_move_speed * getSpeedModifierFromMouth()
		self.cam?.position.x = self.player!.position.x + self.cam_player_shift!
		
		if let player = self.player, let cam = self.cam {
			if !cam.contains(player) {
				reset_level()
			}
		}
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
