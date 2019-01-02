//
//  GameScene.swift
//  FlappyBird_wiwi
//
//  Created by Wei Lin on 2018/12/23.
//  Copyright © 2018 Wei Lin. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene,SKPhysicsContactDelegate {
    
        private var label : SKLabelNode?
        private var spinnyNode : SKShapeNode?
    
        var bird :SKSpriteNode!
    
        let verticalPipeGap = 150.0;
        let pipeLift=80.0;
    
        let birdCategory: UInt32 = 1 << 0  //1
        let worldCategory: UInt32 = 1 << 1  //2
        let pipeCategory: UInt32 = 1 << 2  //4
    
        var pipeTextureUp:SKTexture!
    
        var pipeTextureDown:SKTexture!
    
        var pipes:SKNode!
    
        enum GameStatus {
            case idle
            case running 
            case over
        }
    
    
        override func didMove(to view: SKView) {
        self.backgroundColor =  SKColor(red: 81.0/255.0, green: 192.0/255.0, blue: 201.0/255.0, alpha: 1.0)
            
        self.physicsBody = SKPhysicsBody(edgeLoopFrom: self.frame)
        self.physicsWorld.contactDelegate = self;
        self.physicsWorld.gravity = CGVector(dx: 0.0, dy: -3.0)
       
    
        let groundTexture = SKTexture(imageNamed: "land")
        groundTexture.filteringMode = .nearest
        for i in 0..<2 + Int(self.frame.size.width / (groundTexture.size().width * 2)) {
            let i = CGFloat(i)
            let sprite = SKSpriteNode(texture: groundTexture)
            sprite.setScale(2.0)
            sprite.anchorPoint = CGPoint(x: 0, y: 0)
            sprite.position = CGPoint(x: i * sprite.size.width, y: 0)
            self.moveGround(sprite: sprite, timer: 0.02)
            self.addChild(sprite)
        }
            
            
        let skyTexture = SKTexture(imageNamed: "sky")
        skyTexture.filteringMode = .nearest
        for i in 0..<2 + Int(self.frame.size.width / (skyTexture.size().width * 2)) {
            let i = CGFloat(i)
            let sprite = SKSpriteNode(texture: skyTexture)
            sprite.setScale(2.0)
            sprite.zPosition = -20
            sprite.anchorPoint = CGPoint(x: 0, y:0)
            sprite.position = CGPoint(x: i * sprite.size.width, y:groundTexture.size().height * 2.0)
            self.moveGround(sprite: sprite, timer: 0.1)
            self.addChild(sprite)
        }

        bird = SKSpriteNode(imageNamed: "bird-01")
        bird.setScale(1.5)
        bird.position = CGPoint(x: self.frame.size.width * 0.35, y:self.frame.size.height * 0.6)
        self.addChild(bird)
        self.birdStartFly()
        
            
        let ground = SKNode()
        ground.position = CGPoint(x: 0, y: groundTexture.size().height)
        ground.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: self.frame.size.width, height: groundTexture.size().height * 2.0))
        ground.physicsBody?.isDynamic = false
        ground.physicsBody?.categoryBitMask = worldCategory
        self.addChild(ground)
            
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2.0)
        bird.physicsBody?.allowsRotation = false
        bird.physicsBody?.categoryBitMask = birdCategory
        bird.physicsBody?.contactTestBitMask = worldCategory
        
        pipes = SKNode()
        self.addChild(pipes)
        startCreateRandomPipes()
            
    }
    
    func moveGround(sprite:SKSpriteNode,timer:CGFloat) {
        let moveGroupSprite = SKAction.moveBy(x: -sprite.size.width, y: 0, duration: TimeInterval(timer * sprite.size.width))
        let resetGroupSprite = SKAction.moveBy(x: sprite.size.width, y: 0, duration: 0.0)
        let moveGroundSpritesForever = SKAction.repeatForever(SKAction.sequence([moveGroupSprite,resetGroupSprite]))
        sprite.run(moveGroundSpritesForever)
    }
    
    
    func birdStartFly()  {
        let birdTexture1 = SKTexture(imageNamed: "bird-01")
        birdTexture1.filteringMode = .nearest
        let birdTexture2 = SKTexture(imageNamed: "bird-02")
        birdTexture2.filteringMode = .nearest
        let birdTexture3 = SKTexture(imageNamed: "bird-03")
        birdTexture3.filteringMode = .nearest
        let anim = SKAction.animate(with: [birdTexture1,birdTexture2,birdTexture3], timePerFrame: 0.2)
        bird.run(SKAction.repeatForever(anim), withKey: "fly")
    }

    func birdStopFly()  {
        bird.removeAction(forKey: "fly")
    }


    func creatSpawnPipes() {
 
        pipeTextureUp = SKTexture(imageNamed: "PipeUp")
        pipeTextureUp.filteringMode = .nearest
        pipeTextureDown = SKTexture(imageNamed: "PipeDown")
        pipeTextureDown.filteringMode = .nearest
        
        let pipePair = SKNode()
        pipePair.position = CGPoint(x: self.frame.size.width + pipeTextureUp.size().width * 2, y: 0)
        pipePair.zPosition = -10;
        
        let height = UInt32(self.frame.size.height/5)
        let y = Double(arc4random_uniform(height) + height)
        
        let pipeDown = SKSpriteNode(texture: pipeTextureDown)
        pipeDown.setScale(2.0)
        pipeDown.position = CGPoint(x: 0.0, y: y + Double(pipeDown.size.height)+verticalPipeGap+pipeLift)
        pipePair.addChild(pipeDown)
        
        let pipeUp = SKSpriteNode(texture: pipeTextureUp)
        pipeUp.setScale(2.0)
        pipeUp.position = CGPoint(x: 0.0, y: y+pipeLift/3)
        pipePair.addChild(pipeUp)
        
        
        pipeDown.physicsBody = SKPhysicsBody(rectangleOf: pipeDown.size)
        pipeDown.physicsBody?.isDynamic = false
        pipeDown.physicsBody?.categoryBitMask = pipeCategory
        pipeDown.physicsBody?.contactTestBitMask = birdCategory
        
        pipeUp.physicsBody = SKPhysicsBody(rectangleOf: pipeUp.size)
        pipeUp.physicsBody?.isDynamic = false
        pipeUp.physicsBody?.categoryBitMask = pipeCategory
        pipeUp.physicsBody?.contactTestBitMask = birdCategory
        
        
        let distanceToMove = CGFloat(self.size.width + 2.0*pipeTextureUp.size().width)
        let movePipes = SKAction.moveBy(x: -distanceToMove, y: 0.0, duration: TimeInterval(0.01 * distanceToMove))
        let removePipes = SKAction.removeFromParent()
        let movePipesAndRemove = SKAction.sequence([movePipes,removePipes])
        pipePair.run(movePipesAndRemove)
        
        pipes.addChild(pipePair)
    }
    
    func startCreateRandomPipes() {
        let spawn = SKAction.run {
            self.creatSpawnPipes()
        }
        let delay = SKAction.wait(forDuration: TimeInterval(2.0))
        let spawnThenDelay = SKAction.sequence([spawn,delay])
        let spawnThenDelayForever = SKAction.repeatForever(spawnThenDelay)
        self.run(spawnThenDelayForever, withKey: "createPipe")
    }
    
    func stopCreateRandomPipes() {
        self.removeAction(forKey: "createPipe")
    }

    func removeAllPipesNode() {
        pipes.removeAllChildren()
    }
    
    override func update(_ currentTime: TimeInterval) {
        
    }
}
