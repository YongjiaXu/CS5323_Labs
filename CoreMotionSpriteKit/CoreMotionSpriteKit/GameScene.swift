//
//  GameScene.swift
//  CoreMotionSpriteKit
//
//  Created by xuan zhai on 10/13/21.
//


import UIKit
import SpriteKit
import CoreMotion

class GameScene: SKScene, SKPhysicsContactDelegate {

    let motion = CMMotionManager()
    let Floatboard = SKSpriteNode()
    let TimerLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    var Ball = SKShapeNode()
    var ChanceRemaining = 3                         // Number of chances
    var GameFinished = false
    weak var gameVC: GameViewController?            // The reference to the view Controller
    
    
    
    // timer counts down. reference: https://stackoverflow.com/questions/23978209/spritekit-creating-a-timer
    private var counter = 11 {
        didSet {
            self.TimerLabel.text = "Remaining: \(self.counter) sec"
            
            if(counter == 0){                           // If remaining time is 0 sec
                GameViewController.ispassed = 2          // Return true cus the player won the game
                self.isPaused = true
                self.gameVC?.dismiss(animated: true)        // Go back to viewcontroller
            }
            
        }
    }
    
    
    func AddTimer() {
        self.TimerLabel.fontSize = 20
        TimerLabel.fontColor = SKColor.black
        TimerLabel.position = CGPoint(x: frame.midX, y: size.height*0.88)
        self.addChild(TimerLabel)
        let waitaSecond = SKAction.wait(forDuration: 1)     // Let 1s duration then update the label
        let UpdateCounter = SKAction.run { [weak self] in
            self?.counter = self!.counter - 1
        }
        
        let sequence = SKAction.sequence([waitaSecond, UpdateCounter])
        let repeatForever = SKAction.repeatForever(sequence)    // Run 15 times
        self.run(repeatForever)
    }
    
    
    func startMotionUpdates(){
        // some internal inconsistency here: we need to ask the device manager for device
        
        if(GameFinished == false){
            if self.motion.isDeviceMotionAvailable{
                self.motion.deviceMotionUpdateInterval = 0.1
                self.motion.startDeviceMotionUpdates(to: OperationQueue.main, withHandler: self.handleMotion )
            }
        }
    }
    
    
    func handleMotion(_ motionData:CMDeviceMotion?, error:Error?){
        if let gravity = motionData?.gravity {              // Add gravity
            var ydata = gravity.y
            
            if(ydata > 0){
                ydata = 0 - ydata           // Let the gravity always be in one direction
            }
            
            self.physicsWorld.gravity = CGVector(dx: 0, dy: CGFloat(9.8*ydata))
        }
        
        
        if let userAccel = motionData?.userAcceleration{
            if(Floatboard.position.x < 0 && userAccel.x < 0) || (Floatboard.position.x > self.size.width && userAccel.x > 0){
                return
            }
            
            let action = SKAction.moveTo(x: CGFloat(Double(size.width)*0.5+userAccel.x*200), duration: 0.2)
            
            self.Floatboard.run(action, withKey: "temp")     // Add Accelection if there's one
        }
        
        
        if let userRotate = motionData?.rotationRate{       // Add gyroscope setting
            if(abs(userRotate.z) > 0.1){
                let raction = SKAction.rotate(toAngle: CGFloat(userRotate.z), duration: 0.2, shortestUnitArc: true)
                self.Floatboard.run(raction,withKey: "tempr") // do rotation based on the gyroscope
            }
        }
    }
    
    
    override func didMove(to view: SKView) {
        physicsWorld.contactDelegate = self
        backgroundColor = SKColor.white
        
        // start motion for gravity
        self.startMotionUpdates()
        
        // make sides to the screen
        self.addSidesAndTop()
        
        // add a spinning block
        self.addBoard(CGPoint(x: size.width * 0.5, y: size.height * 0.35))
        
        self.addBall()          // Add the first ball
        self.AddTimer()         // Add the timer
    }

    
    
    func addBall(){
        Ball = SKShapeNode(circleOfRadius: size.width*0.05) // Make it a circle
        
        let x = size.width*0.05
        
        Ball.position = CGPoint(x: size.width * 0.5, y: size.height * 0.75)
        Ball.fillColor = SKColor.orange
        Ball.strokeColor = SKColor.yellow           // Set the property
        
        Ball.physicsBody = SKPhysicsBody(circleOfRadius: x)
        Ball.physicsBody?.restitution = 1.0             // Make the collison elastic
        Ball.physicsBody?.isDynamic = true
        Ball.physicsBody?.contactTestBitMask = 0x00000001
        Ball.physicsBody?.collisionBitMask = 0x00000001
        Ball.physicsBody?.categoryBitMask = 0x00000001
        
        self.addChild(Ball)
    }
    
    
    func addBoard(_ point:CGPoint){
        
        Floatboard.color = UIColor.green
        Floatboard.size = CGSize(width:size.width*0.4,height:size.height * 0.02)
        Floatboard.position = point
        
        Floatboard.physicsBody = SKPhysicsBody(rectangleOf:Floatboard.size)
        Floatboard.physicsBody?.contactTestBitMask = 0x00000001
        Floatboard.physicsBody?.collisionBitMask = 0x00000001
        Floatboard.physicsBody?.categoryBitMask = 0x00000001
        Floatboard.physicsBody?.isDynamic = false
        Floatboard.physicsBody?.pinned = false      // It is not pinned and you can move it
        Floatboard.physicsBody?.affectedByGravity = false  // Let it never fall
        
        self.addChild(Floatboard)

    }
    
    
    func addSidesAndTop(){
        let left = SKSpriteNode()     // Create the border
        let right = SKSpriteNode()
        let top = SKSpriteNode()
        let bottom = SKSpriteNode()
        
        left.size = CGSize(width:size.width*0.1,height:size.height)
        left.position = CGPoint(x:0, y:size.height*0.5)
        left.color = SKColor.red
        
        right.size = CGSize(width:size.width*0.1,height:size.height)
        right.position = CGPoint(x:size.width, y:size.height*0.5)
        right.color = SKColor.red
        
        top.size = CGSize(width:size.width,height:size.height*0.3)
        top.position = CGPoint(x:size.width*0.5, y:size.height)
        top.color = SKColor.red
        
        bottom.size = CGSize(width:size.width,height:size.height*0.1)
        bottom.position = CGPoint(x:size.width*0.5, y:0)
        bottom.color = SKColor.cyan
        
        for obj in [left,right,top,bottom]{
            obj.physicsBody = SKPhysicsBody(rectangleOf:obj.size)
            obj.physicsBody?.isDynamic = false
            obj.physicsBody?.pinned = true
            obj.physicsBody?.allowsRotation = false
            self.addChild(obj)
        }
    }
    
    
    
    // Collison detection through delegation
    func didBegin(_ contact: SKPhysicsContact) {
        if contact.bodyA.node == Ball || contact.bodyB.node == Ball { // If collide
            // If the collide node with ball is the bottom border
            if(contact.bodyA.node?.position.y == 0 || contact.bodyB.node?.position.y == 0){
                Ball.removeFromParent() // remove the node
                if(ChanceRemaining != 0){
                    ChanceRemaining-=1
                    addBall()       // Update the chance, add a new ball
                }
                else{
                    // If ran out of chance, game failed
                    self.isPaused = true
                    self.gameVC?.dismiss(animated: true);
                }
            }
        }
    }

}
