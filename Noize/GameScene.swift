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

class GameScene: SKScene {
    
    private var label : SKLabelNode?
    private var spinnyNode : SKShapeNode?
	private var mic: AKMicrophoneTracker?
	private var mic_label: SKLabelNode?
	private var player: SKSpriteNode?
	private var cam: SKCameraNode?
	private var cam_move_speed: CGFloat = 10
	private var cam_player_shift: CGFloat?
	private var player_spawn_position: CGPoint?
	
    
    override func didMove(to view: SKView) {
        
        // Get label node from scene and store it for use later
        self.label = self.childNode(withName: "//helloLabel") as? SKLabelNode
        if let label = self.label {
            label.alpha = 0.0
            label.run(SKAction.fadeIn(withDuration: 2.0))
        }
        
        // Create shape node to use during mouse interaction
        let w = (self.size.width + self.size.height) * 0.05
        self.spinnyNode = SKShapeNode.init(rectOf: CGSize.init(width: w, height: w), cornerRadius: w * 0.3)
        
        if let spinnyNode = self.spinnyNode {
            spinnyNode.lineWidth = 2.5
            
            spinnyNode.run(SKAction.repeatForever(SKAction.rotate(byAngle: CGFloat(Double.pi), duration: 1)))
            spinnyNode.run(SKAction.sequence([SKAction.wait(forDuration: 0.5),
                                              SKAction.fadeOut(withDuration: 0.5),
                                              SKAction.removeFromParent()]))
        }
		
		self.mic = AKMicrophoneTracker()
//		self.mic_label = SKLabelNode(fontNamed: "Helvetica Neue")
//		self.mic_label?.fontSize = 30
//		self.mic_label?.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
////		print(UIApplication.shared.keyWindow!.safeAreaInsets.left, self.view!.safeAreaInsets.bottom)
//		self.mic_label?.position = CGPoint(x: self.view!.safeAreaInsets.left+self.frame.minX,
//										   y: self.view!.safeAreaInsets.bottom+self.frame.minY)
//		self.mic_label?.fontColor = SKColor.white
//		self.mic_label?.text = "Mic"
//		self.mic_label?.zPosition = 1000
//		self.addChild(self.mic_label!)
		
		self.player = childNode(withName: "Player") as? SKSpriteNode
		self.player_spawn_position = self.player?.position
		self.cam = childNode(withName: "Player Cam") as? SKCameraNode
		self.mic_label = self.cam?.childNode(withName: "Freq and Amp") as? SKLabelNode
		self.cam_player_shift = abs(self.player!.position.x-self.cam!.position.x)
    }
    
    
    func touchDown(atPoint pos : CGPoint) {
        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
            n.position = pos
            n.strokeColor = SKColor.green
            self.addChild(n)
        }
		
		self.mic?.start()

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
//		self.mic?.stop()
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
		
		if let mic = self.mic{
			self.mic_label?.text = String(format: "freq: %.3f, amp: %.3f", mic.frequency, mic.amplitude)
		}
		
		self.player?.position.x = self.player!.position.x
								+ self.cam_move_speed * getMovementFromMic(amplitude: self.mic!.amplitude)
		self.cam?.position.x = self.player!.position.x + self.cam_player_shift!
		
		if let player = self.player, let cam = self.cam {
			if !cam.contains(player) {
				player.position = self.player_spawn_position!
				player.physicsBody?.velocity = CGVector()
			}
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
}
