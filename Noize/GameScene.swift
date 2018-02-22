//
//  GameScene.swift
//  Noize
//
//  Created by Chandan Siyag on 20/02/2018.
//  Copyright © 2018 xqz. All rights reserved.
//

import SpriteKit
import GameplayKit
import AudioKit
//import UIKit
import ARKit


class GameScene: SKScene, SKPhysicsContactDelegate, ARSessionDelegate {
	
	var label : SKLabelNode?
	var spinnyNode : SKShapeNode?
	
	var mic: AKMicrophoneTracker?
	var mic_label: SKLabelNode?
	var is_mic_on: Bool = false
	var mic_amplitude: Double {
		get {
			if is_mic_on {
				return self.mic!.amplitude
			}else {
				return 0
			}
		}
	}
	
	var cam: SKCameraNode?
	var cam_move_speed: CGFloat = 10
	var cam_player_shift: CGFloat?
	
	var player: SKSpriteNode?
	var player_spawn_position: CGPoint?
	var player_initial_velocity = CGVector(dx: 0, dy: -100)
	var is_player_dead = false
	var player_jump_force = CGVector(dx: 0, dy: 750)
	
	
	var player_category_mask: UInt32 = 0x1 << 0
	var platform_category_mask: UInt32 = 0x1 << 1
	var spikes_category_mask: UInt32 = 0x1 << 2
	var rainbow_mode = true
	
	var frame_count: Int = 0
	
	var ar_session: ARSession?
	var ar_configuration =  ARFaceTrackingConfiguration()
	var face_anchor: ARFaceAnchor?
	var is_ar_on: Bool {
		get {
			return self.is_mic_on && self.ar_session != nil
		}
	}
	
	
	override func didMove(to view: SKView) {
		
		// Get label node from scene and store it for use later
		self.label = self.childNode(withName: "//helloLabel") as? SKLabelNode
		if let label = self.label {
			label.alpha = 0.0
			label.run(SKAction.fadeIn(withDuration: 2.0))
		}
		
		// Create shape node to use during mouse interaction
		let w = CGFloat(50)
		self.spinnyNode = SKShapeNode.init(rectOf: CGSize.init(width: w, height: w), cornerRadius: w * 0.3)
		
		if let spinnyNode = self.spinnyNode {
			spinnyNode.lineWidth = 2.5
			
			spinnyNode.run(SKAction.repeatForever(SKAction.rotate(byAngle: CGFloat(Double.pi), duration: 1)))
			spinnyNode.run(SKAction.group([SKAction.scale(to: 0, duration: 1),
										   SKAction.sequence([SKAction.wait(forDuration: 0.5),
															  SKAction.fadeOut(withDuration: 0.5),
															  SKAction.removeFromParent()])]))
		}
		
		self.player = childNode(withName: "Player") as? SKSpriteNode
		self.player?.physicsBody?.categoryBitMask = self.player_category_mask
		self.player_spawn_position = self.player?.position
//		self.player?.isHidden = true
		
		self.cam = childNode(withName: "Player Cam") as? SKCameraNode
		self.cam_player_shift = abs(self.player!.position.x-self.cam!.position.x)
		
		self.mic = AKMicrophoneTracker()
		self.mic_label = self.cam?.childNode(withName: "Freq and Amp") as? SKLabelNode
		
		self.physicsWorld.contactDelegate = self
		
		
		var i = 0
		self.enumerateChildNodes(withName: "Platform") { (node, _) in
			node.physicsBody?.categoryBitMask = self.platform_category_mask
			i = i+1
		}
		print("# of platforms: \(i)")
		i = 0
		self.enumerateChildNodes(withName: "Spikes") { (node, _) in
			node.physicsBody?.categoryBitMask = self.spikes_category_mask
			i = i+1
		}
		print("# of spikes: \(i)")
		i = 0
		self.enumerateChildNodes(withName: "Spike") { (node, _) in
			node.physicsBody?.categoryBitMask = self.spikes_category_mask
			node.run(SKAction.repeatForever(SKAction.sequence([SKAction.moveBy(x: 0, y: self.size.height/2, duration: 1.0),
															   SKAction.rotate(byAngle: CGFloat(Double.pi), duration: 0),
															   SKAction.moveBy(x: 0, y: -self.size.height/2, duration: 1.0),
															   SKAction.rotate(byAngle: CGFloat(Double.pi), duration: 0),
															   ])))
			i = i+1
		}
		print("# moving spikes: \(i)")
		
		
		start_AR()
	}
	
	
	func touchDown(atPoint pos : CGPoint) {
		if let n = self.spinnyNode?.copy() as! SKShapeNode? {
			n.position = pos
			n.strokeColor = SKColor.green
			self.addChild(n)
		}
		
		if !self.is_mic_on {
			self.mic?.start()
			self.is_mic_on = true
		}else {
			self.mic?.stop()
			self.is_mic_on = false
		}
		
		if self.is_ar_on {
			self.ar_session?.run(self.ar_configuration)
		} else {
			self.ar_session?.pause()
		}
	}
	
	func touchMoved(toPoint pos : CGPoint) {
		if let n = self.spinnyNode?.copy() as! SKShapeNode? {
			n.position = pos
			n.strokeColor = SKColor.blue
			self.addChild(n)
		}
	}
	
	func touchUp(atPoint pos : CGPoint) {
		if let n = self.spinnyNode?.copy() as! SKShapeNode? {
			n.position = pos
			n.strokeColor = SKColor.red
			self.addChild(n)
		}
	}
	
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		if let label = self.label {
			label.run(SKAction.init(named: "Pulse")!, withKey: "fadeInOut")
		}
		
		for t in touches { self.touchDown(atPoint: t.location(in: self)) }
		
		
	}
	
	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		for t in touches { self.touchMoved(toPoint: t.location(in: self)) }
	}
	
	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		for t in touches { self.touchUp(atPoint: t.location(in: self)) }
	}
	
	override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
		for t in touches { self.touchUp(atPoint: t.location(in: self)) }
	}
	
	
	override func update(_ currentTime: TimeInterval) {
		// Called before each frame is rendered
		
		self.checkIfPlayerIsDead()
		self.updateLabelText()
		
		self.movePlayer()

		self.drawTrail()
		self.updateFrameCount()
	}
	
	func checkIfPlayerIsDead() {
		if self.is_player_dead {
			self.player?.physicsBody?.isDynamic = false
			self.player?.run(SKAction.move(to: self.player_spawn_position!, duration: 1.0),
							 completion: {
								self.player?.physicsBody?.isDynamic = true
								self.player?.physicsBody?.velocity = CGVector()
								self.is_player_dead = false
								
			})
		}
		
	}
	
	func updateLabelText() {
		if let mic = self.mic{
			self.mic_label?.text = String(format: "freq: %.3f, amp: %.3f", mic.frequency, mic.amplitude)
		}
	}
	
	func movePlayer() {
		self.player?.position.x = self.player!.position.x
			+ self.cam_move_speed * getMovementFromMic(amplitude: self.mic_amplitude)
		self.cam?.position.x = self.player!.position.x + self.cam_player_shift!
		
		if let player = self.player, let cam = self.cam {
			if !cam.contains(player) {
				reset_level()
			}
		}
	}
	
	func drawTrail() {
		if let track = self.spinnyNode?.copy() as? SKShapeNode {
			track.position = self.player!.position
			track.strokeColor = hexStringToSKColor(hex: colors[frame_count])
			self.addChild(track)
		}
	}
	
	func updateFrameCount() {
		if rainbow_mode {
			frame_count += 1
			frame_count = frame_count % colors.count
		}
	}
	
	func getMovementFromMic(amplitude: Double, min: Double = 0.1, max: Double = 0.8) -> CGFloat {
		if amplitude - min < 0 {
			return CGFloat(0)
		}else {
			var adjusted_amplitude = amplitude - min
			adjusted_amplitude = adjusted_amplitude / (max - min)
			return CGFloat(adjusted_amplitude)
		}
	}
	
	func didBegin(_ contact: SKPhysicsContact) {
		let body_names = [contact.bodyB.node?.name, contact.bodyA.node?.name]
		if body_names.contains(where: {$0 == "Player"}) {
			let first_node = contact.bodyA.node
			let second_node = contact.bodyB.node
			let player_node: SKSpriteNode?
			
			if first_node?.name == "Player" {
				player_node = first_node as? SKSpriteNode
			}else {
				player_node = second_node as? SKSpriteNode
			}
			
			if body_names.contains(where: {$0 == "Platform"}){
				player_node?.physicsBody?.applyImpulse(self.player_jump_force)
				
				let player_size = player_node!.size
				//				player_node?.run(SKAction.rotate(byAngle: CGFloat(Double.pi), duration: 0.4))
				player_node?.run(SKAction.sequence([SKAction.resize(byWidth: player_size.width/2,
																	height: -player_size.height/2,
																	duration: 0.2),
													SKAction.resize(byWidth: -player_size.width/2,
																	height: player_size.height/2,
																	duration: 0.2)]))
			}else if body_names.contains(where: {$0 == "Spikes" || $0 == "Spike"}) {
				// Bug in SpriteKit does not let you change nodes's position from this func
				self.is_player_dead = true
//				reset_level()
			}
			
		}

	}
	
	func reset_level() {
		if let player = self.player {
			player.position = self.player_spawn_position!
			player.physicsBody?.velocity = CGVector()
		}
	}
	
	func start_AR() {
		guard ARFaceTrackingConfiguration.isSupported else { return }
		self.ar_session = ARSession()
		self.ar_session?.delegate = self
		self.ar_configuration.isLightEstimationEnabled = false
		self.ar_session?.run(self.ar_configuration, options: [.resetTracking, .removeExistingAnchors])
	}
	
	func session(_ session: ARSession, didUpdate frame: ARFrame) {
//		if frame.anchors.count == 0 {
//			self.face_anchor = nil
//		}
		
	}
	
	func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
		for anchor in anchors {
			guard let faceAnchor = anchor as? ARFaceAnchor else { return }
			self.face_anchor = faceAnchor
		}
	}
	
	func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
		for anchor in anchors {
			if anchor == self.face_anchor {
				print("Removing")
				self.face_anchor = nil
			}
		}
	}
	
	
}
