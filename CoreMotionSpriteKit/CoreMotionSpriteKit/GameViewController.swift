//
//  GameViewController.swift
//  CoreMotionSpriteKit
//
//  Created by xuan zhai on 10/13/21.
//

import UIKit
import SpriteKit


protocol GameViewControllerDelegate : NSObject {
    func CatchResult(controller:GameViewController, data:Int)
}


class GameViewController: UIViewController {
 
    var delegate: GameViewControllerDelegate?
    
    static var ispassed = 1
    var scene:GameScene?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        GameViewController.ispassed = 1
        //setup game scene
    
        
        
        print(GameViewController.ispassed)
        scene = GameScene(size:view.bounds.size)
        scene?.gameVC = self
        let skView = view as! SKView      // the view in storyboard must be an SKView
        skView.showsFPS = true
        skView.ignoresSiblingOrder = true
        scene?.scaleMode = .resizeFill
        skView.presentScene(scene)
        
    }

    
    override func viewDidDisappear(_ animated: Bool) {
        scene?.removeAllChildren()    // Destory all the nodes, actions
        scene?.removeAllActions()
        scene?.removeFromParent()
        scene = nil
        
        if(delegate != nil){       // Pass the game result back to the root view controler
            let result = GameViewController.ispassed
            delegate?.CatchResult(controller: self, data: result)
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
}
