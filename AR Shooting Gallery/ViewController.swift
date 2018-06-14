//
//  ViewController.swift
//  AR Shooting Gallery
//
//  Created by Steven Hedges on 5/30/18.
//  Copyright © 2018 Steven Hedges. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

// Create a body type enum - which bodies can collide with one another
enum BodyType : Int {
    case projectile = 1
    case target = 2
}

class ViewController: UIViewController, ARSCNViewDelegate, SCNPhysicsContactDelegate {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var startGameButton: UIButton!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var countLabel: UILabel!
    
    var lastContactNode: SCNNode!
    var timer = Timer()
    
    private var userScore: Int = 0 {
        didSet {
            // ensure UI update runs on main thread
            DispatchQueue.main.async {
                self.scoreLabel.text = String(self.userScore)
            }
        }
    }
    
    private var timerCount: Int = 0 {
        didSet {
            DispatchQueue.main.async {
                self.countLabel.text = String(self.timerCount)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scoreLabel.isHidden = true
        countLabel.isHidden = true
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
        
        // Adding the contact physics
        sceneView.scene.physicsWorld.contactDelegate = self
        
        // add lighting
        self.sceneView.autoenablesDefaultLighting = true
        
        // Need to recgonize gestures
        registerGestureRecognizers()
    }
    
    @IBAction func startGame(_ sender: Any) {
        startGameButton.isHidden = true
        scoreLabel.isHidden = false
        countLabel.isHidden = false
        self.userScore = 0
        self.timerCount = 10
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(counter), userInfo: nil, repeats: true)
        addTarget()
    }
    
    @objc func counter() {
        self.timerCount -= 1
        
        if timerCount == 0 {
            print("Game Over")
            countLabel.isHidden = true
        }
    }
    
    // Creates a random float
    func floatBetween(_ first: Float,  and second: Float) -> Float {
        return (Float(arc4random()) / Float(UInt32.max)) * (first - second) + second
    }
    
    func addTarget() {
        guard let targetScene = SCNScene(named: "art.scnassets/target.scn") else {
            return
        }
        
        guard let targetNode = targetScene.rootNode.childNode(withName: "TargetModel", recursively: false) else {
            return
        }
        
        targetNode.name = "Target" // Name for collision
        
        // Call a random position
        let posX = floatBetween(-0.3, and: 0.3)
        let posY = floatBetween(-0.3, and: 0.3)
        let posZ = floatBetween(-1.0, and: -1.4)
        targetNode.position = SCNVector3(posX, posY, posZ)
        
        targetNode.physicsBody = SCNPhysicsBody(type: .static, shape: nil) // Add physics body to the node
        targetNode.physicsBody?.categoryBitMask = BodyType.target.rawValue  // Add body type enum
        sceneView.scene.rootNode.addChildNode(targetNode)
    }
    
    
    // Recognizing when the screen is tapped
    private func registerGestureRecognizers() {
        // gesture recognizer that targest the current seceene "self"
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(shoot))
        // Add it to the scene, takes one arg, the gesture recognizer above
        sceneView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    // #selector is part of the objective-c
    // shoot func called inside registerGestureRecognizer()
    @objc func shoot(gestureRecognier: UIGestureRecognizer) {
        
        guard let currentFrame = self.sceneView.session.currentFrame else {
            // If it can't find the current frame then just return
            return
        }
        
        // translation matrix
        var translationMatrix = matrix_identity_float4x4
        translationMatrix.columns.3.z = -0.3
        
        // Create the projectile model and material
        let projectileSphere = SCNSphere(radius: 0.01)
        let projectileMaterial = SCNMaterial()
        projectileMaterial.diffuse.contents = UIColor.red
        projectileSphere.materials = [projectileMaterial]
        
        // Create the projectil node
        // All objects set in AR must be nodes
        let projectileNode = SCNNode(geometry: projectileSphere)
        // Give it a name for collision detection
        projectileNode.name = "Projectile"
        
        // Need the physics body on the node
        projectileNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        // Add bit mask enum
        projectileNode.physicsBody?.categoryBitMask = BodyType.projectile.rawValue
        // Add the contact bit mask to detect collision with target
        projectileNode.physicsBody?.contactTestBitMask = BodyType.target.rawValue
        // Turn off gravity to keep the projectile from dropping
        projectileNode.physicsBody?.isAffectedByGravity = false
        // Orient to face the current frame
        projectileNode.simdTransform = matrix_multiply(currentFrame.camera.transform, translationMatrix)
        // Need to make a force on the projectile obj - might need to make it faster
        let forceVector = SCNVector3(projectileNode.worldFront.x * 2, projectileNode.worldFront.y * 2, projectileNode.worldFront.z * 2)
        projectileNode.physicsBody?.applyForce(forceVector, asImpulse: true)
        
        // Add node to the scnene
        sceneView.scene.rootNode.addChildNode(projectileNode)
        
    }
    
    // For the collision detection - didBegin get triggered when a collision between two objects happens
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        
        var contactNode: SCNNode!
        
        if contact.nodeA.name == "Projectile" {
            contactNode = contact.nodeB
        } else {
            contactNode = contact.nodeA
        }
        
        if self.lastContactNode != nil && self.lastContactNode == contactNode { return }
        
        self.lastContactNode = contactNode
        
        print("Hit Target")
        self.removeNode(contact.nodeB) // Remove the bullet
        self.userScore += 1
        
        // removes target - replaces target after 0.5 seconds - adds new target
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
            self.removeNode(self.lastContactNode)
            self.addTarget()
        })
        
    }
    
    func removeNode(_ node: SCNNode) {
        node.removeFromParentNode()
    }
    
    // Settings for supported and unsupported phones
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if ARWorldTrackingConfiguration.isSupported {
            // Create session configuration
            let configuration = ARWorldTrackingConfiguration()
            configuration.planeDetection = ARWorldTrackingConfiguration.PlaneDetection.horizontal
            sceneView.session.run(configuration) // Run the view's session
        } else {
            let configuration = AROrientationTrackingConfiguration() // For lower end processors
            sceneView.session.run(configuration) // Run the view's session
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause() // Pause the view's session
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
}
