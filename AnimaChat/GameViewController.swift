//
//  GameViewController.swift
//  AnimaChat
//
//  Created by guillaume on 05/09/2017.
//  Copyright © 2017 Guillaume Stagnaro. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit

//import SwiftOSC

//let IP = "192.168.1.2" //239.0.0.66"
//let PORT = 8080

let DEFAULT_IP = "192.168.1.2" // chat ESP12
let DEFAULT_PORT = 8080
let DEFAULT_PATH = "chat/"

class GameViewController: UIViewController {
   // @IBOutlet weak var address: UITextField!
    //@IBOutlet weak var skview: SKView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let view = self.view as! SKView? {
 
            let scene = RemoteControlScene(size: view.frame.size)
            // Set the scale mode to scale to fit the window
            scene.scaleMode = .aspectFill
            scene.name = "remoteControlScene"
            // Present the scene
            view.presentScene(scene)
            
            view.ignoresSiblingOrder = true
            view.showsFPS = false
            view.showsNodeCount = false
            
            view.ignoresSiblingOrder = true
            
            view.showsFPS = false
            view.showsNodeCount = false
        }
    }

  
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }
    
    override var shouldAutorotate: Bool {
        return false
    }
}

class RemoteControlScene: SKScene {
    enum TrackingMode {
        case speed
        case relative
        case absolute
    }
    
    var ip = DEFAULT_IP
    var port = DEFAULT_PORT
    var oscPath = DEFAULT_PATH
    
    var client:OSCClient!
    var trackingMode = TrackingMode.relative
    
    var controlPoint = CGPoint.zero
    private var mouseNode : SKShapeNode?
    private var followNode : SKShapeNode?
    private var logNode : SKLabelNode?
    
    override func didMove(to view: SKView) {
        
        
        client = OSCClient(address: ip, port: port)
        
        registerSettingsBundle()
        updateFromDefaults()
        
        UserDefaults.standard.addObserver(self,
                                          forKeyPath: "savedPort",
                                          options: [.new, .old, .initial, .prior],
                                          context: nil)
        
        UserDefaults.standard.addObserver(self,
                                          forKeyPath: "savedIP",
                                          options: [.new, .old, .initial, .prior],
                                          context: nil)
        
        UserDefaults.standard.addObserver(self,
                                          forKeyPath: "savedPath",
                                          options: [.new, .old, .initial, .prior],
                                          context: nil)
        
        let crossPath = CGMutablePath()
        crossPath.move(to: CGPoint(x: -self.size.width/3, y: 0))
        crossPath.addLine(to: CGPoint(x: self.size.width/3, y: 0))
        crossPath.move(to: CGPoint(x: 0, y: -self.size.height/4))
        crossPath.addLine(to: CGPoint(x: 0, y: self.size.height/4))
        
        let crossNode = SKShapeNode(path: crossPath)
        crossNode.fillColor = .clear
        crossNode.strokeColor = #colorLiteral(red: 0.4509804249, green: 0.4509804249, blue: 0.4509804249, alpha: 1)
        crossNode.lineWidth = 2
        
        self.addChild(crossNode)
        crossNode.position.x = self.size.width/2.0
        crossNode.position.y = self.size.height/2.0
        
            
        mouseNode = SKShapeNode(circleOfRadius: self.size.width * 0.07)
        mouseNode?.fillColor = #colorLiteral(red: 0.5882353187, green: 0.5882353187, blue: 0.5882353187, alpha: 1)
        mouseNode?.lineWidth = 0
        mouseNode?.glowWidth = 0.0
        
        followNode = SKShapeNode(circleOfRadius: self.size.width * 0.07)
        followNode?.fillColor = UIColor.clear
        followNode?.strokeColor = #colorLiteral(red: 0.5882353187, green: 0.5882353187, blue: 0.5882353187, alpha: 1)
        followNode?.lineWidth = 0.1
        followNode?.glowWidth = 0.0
        
        self.backgroundColor = #colorLiteral(red: 0.3215686381, green: 0.3215686381, blue: 0.3215686381, alpha: 1)
        self.addChild(mouseNode!)
        self.addChild(followNode!)
        
        mouseNode?.position = CGPoint(x: self.size.width/2, y: self.size.height/2)
        followNode?.position = CGPoint(x: self.size.width/2, y: self.size.height/2)
        
        client = OSCClient(address: ip, port: port)
        
        logNode = SKLabelNode(text: "Log")
        logNode?.fontSize = 20
          self.addChild(logNode!)
        
        logNode?.position = CGPoint(x: self.size.width/2, y: 50)
        
        logNode?.text = "\(ip):\(port)"
    
    }
    
    
    func touchMoved(toPoint pos : CGPoint) {
        mouseNode?.position = pos
    }
    
    func touchUp(atPoint pos : CGPoint) {
        //if self.trackingMode == TrackingMode.speed { // speed
            self.touchMoved(toPoint: CGPoint(x: self.size.width/2.0, y: self.size.height/2.0))
        //}
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
        guard let follow = followNode as SKShapeNode! else {
            return
        }
        guard let mouse = mouseNode as SKShapeNode! else {
            return
        }
        
        let xDif = abs(follow.position.x - mouse.position.x)
        let yDif = abs(follow.position.y - mouse.position.y)
        
        if mouse.position == CGPoint(x: self.size.width/2.0, y: self.size.height/2.0) {
            if xDif < 1.0 && yDif < 1.0 {
                return
            }
        }
        
        if follow.position.x > mouse.position.x {
            follow.position.x -= xDif / 10.0
        } else if follow.position.x < mouse.position.x {
            follow.position.x += xDif / 10.0
        }
        
        if follow.position.y > mouse.position.y {
            follow.position.y -= yDif / 10.0
        } else if follow.position.y < mouse.position.y {
            follow.position.y += yDif / 10.0
        }
        
        let x = max(min(follow.position.x/self.size.width,1.0),0.0)
        let y = max(min(follow.position.y/self.size.height,1.0),0.0)
        
        let yaw:OSCType = Float(y)
        let pitch:OSCType = Float(x)
        
        let message = OSCMessage(
            OSCAddressPattern("\(self.oscPath)/speed"),
            yaw,
            pitch
        )
        
        client.send(message)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        print(keyPath ?? "nil nil")
        
        if keyPath == "savedPort" || keyPath == "savedIP" || keyPath == "savedPath" {
            updateFromDefaults()
            client.address = ip
            client.port = port
        }
    }
    
    func registerSettingsBundle(){
        //let appDefaults =
        
        //let defaultPort = UserDefaults.standard.integer(forKey: "savedPort")
        
        UserDefaults.standard.register(defaults: ["savedPort":DEFAULT_PORT, "savedIP":DEFAULT_IP, "savedPath":DEFAULT_PATH])
        UserDefaults.standard.synchronize()
        
    }
    
    func updateFromDefaults(){
        
        //Get the defaults
        let defaults = UserDefaults.standard
        
        //Set the controls to the default values.
        
        if let savedIP = defaults.string(forKey: "savedIP"){
            ip = savedIP
            print("saved ip ok \(ip)")
        } else{
            ip = DEFAULT_IP
            print("saved ip error")
        }
        
        if let savedPath = defaults.string(forKey: "savedPath") {
            oscPath = savedPath
            print("saved path ok \(oscPath)")
        } else {
            oscPath = DEFAULT_PATH
            print("saved path error")
        }
        
        port = defaults.integer(forKey: "savedPort")
        print(port)
        
         logNode?.text = "\(ip):\(port)"
    }
    
}
