//
//  GameScene.swift
//  FlappyBird_wiwi
//
//  Created by Wei Lin on 2018/12/23.
//  Copyright © 2018 Wei Lin. All rights reserved.
//

import SpriteKit
import GameplayKit
import AVFoundation


class GameScene: SKScene,SKPhysicsContactDelegate {
    
        var avPlayer:AVAudioPlayer!
    
        var skyColor:SKColor!
    
        private var label : SKLabelNode?
        private var spinnyNode : SKShapeNode?
    
        var bird :SKSpriteNode!
    
        let verticalPipeGap = 150.0;
        let pipeLift=80.0;
    
        let birdCategory: UInt32 = 1 << 0  //1
        let worldCategory: UInt32 = 1 << 1  //2
        let pipeCategory: UInt32 = 1 << 2  //4
        let scoreCategory: UInt32 = 1 << 3  //8
    
        var pipeTextureUp:SKTexture!
    
        var pipeTextureDown:SKTexture!
    
        var pipes:SKNode!
    
        var score: NSInteger = 0
    
        lazy var gameOverLabel:SKLabelNode = {
        let label = SKLabelNode(fontNamed: "Chalkduster")
        label.text = "Game Over"
        return label
    }()
    
        lazy var scoreLabelNode:SKLabelNode = {
        let label = SKLabelNode(fontNamed: "MarkerFelt-Wide")
        label.zPosition = 100
        label.text = "0"
        return label
    }()
    
        var moving:SKNode!
    
        enum GameStatus {
            case idle
            case running
            case over
        }

        var gameStatus:GameStatus = .idle
    
        func idleStatus() {
            gameStatus = .idle
            removeAllPipesNode()
            
            gameOverLabel.removeFromParent()
            scoreLabelNode.removeFromParent()
            
            bird.position = CGPoint(x: self.frame.size.width * 0.35, y: self.frame.size.height * 0.6)
            bird.physicsBody?.isDynamic = false
            self.birdStopFly()
            moving.speed = 1
        }
    
        func runningStatus() {
            gameStatus = .running
            
            score = 0
            scoreLabelNode.text = String(score)
            self.addChild(scoreLabelNode)
            scoreLabelNode.position = CGPoint(x: self.frame.midX, y: 3 * self.frame.size.height / 4)

            bird.physicsBody?.isDynamic = true
            bird.physicsBody?.collisionBitMask = worldCategory | pipeCategory
            startCreateRandomPipes()
        }
    
        func overStatus() {
            gameStatus = .over
            birdStopFly()
            stopCreateRandomPipes()
            
            addChild(gameOverLabel)
            gameOverLabel.position = CGPoint(x: self.size.width * 0.5, y: self.size.height)
            isUserInteractionEnabled = false;
            
            let delay = SKAction.wait(forDuration: TimeInterval(1))
            let move = SKAction.move(by: CGVector(dx: 0, dy: -self.size.height * 0.5), duration: 1)
            gameOverLabel.run(SKAction.sequence([delay,move]), completion:{
                self.isUserInteractionEnabled = true
            })

        }
    
        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            switch gameStatus {
            case .idle:
                runningStatus()
                break
            case .running:
                for _ in touches {
                    bird.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
                    bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 10))
                }
                break
            case .over:
                idleStatus()
                break
            }
        }
    
        override func didMove(to view: SKView) {
            
            let path = Bundle.main.path(forResource: "background", ofType: "mp3")
            let pathUrl = URL(fileURLWithPath: path!)
            do {
                try avPlayer = AVAudioPlayer(contentsOf: pathUrl)
            }catch {
              
                print("mp3 error")
            }
            avPlayer.play()
            avPlayer.volume = 0.3
            
        skyColor  =  SKColor(red: 81.0/255.0, green: 192.0/255.0, blue: 201.0/255.0, alpha: 1.0)
        self.backgroundColor = skyColor
            
        self.physicsBody = SKPhysicsBody(edgeLoopFrom: self.frame)
        self.physicsWorld.contactDelegate = self;
        self.physicsWorld.gravity = CGVector(dx: 0.0, dy: -3.0)
       
        moving = SKNode()
        self.addChild(moving)
        pipes = SKNode()
        moving.addChild(pipes)
    
        let groundTexture = SKTexture(imageNamed: "land")
        groundTexture.filteringMode = .nearest
        for i in 0..<2 + Int(self.frame.size.width / (groundTexture.size().width * 2)) {
            let i = CGFloat(i)
            let sprite = SKSpriteNode(texture: groundTexture)
            sprite.setScale(2.0)
            sprite.anchorPoint = CGPoint(x: 0, y: 0)
            sprite.position = CGPoint(x: i * sprite.size.width, y: 0)
            self.moveGround(sprite: sprite, timer: 0.02)
            moving.addChild(sprite)
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
            moving.addChild(sprite)
        }
        
            
        let ground = SKNode()
        ground.position = CGPoint(x: 0, y: groundTexture.size().height)
        ground.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: self.frame.size.width, height: groundTexture.size().height * 2.0))
        ground.physicsBody?.isDynamic = false
        ground.physicsBody?.categoryBitMask = worldCategory
        self.addChild(ground)
            
        bird = SKSpriteNode(imageNamed: "bird-01")
        bird.setScale(1.5)
        self.addChild(bird)
        
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2.0)
        //bird.physicsBody = SKPhysicsBody(texture: bird.texture!, size: bird.size)
        bird.physicsBody?.allowsRotation = false
        bird.physicsBody?.categoryBitMask = birdCategory
        bird.physicsBody?.contactTestBitMask = worldCategory | pipeCategory
            
        self.idleStatus()
        
      
            
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
        
        let contactNode = SKNode()
        contactNode.position = CGPoint(x: pipeDown.size.width, y: self.frame.midY)
        contactNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: pipeUp.size.width, height: self.frame.size.height))
        contactNode.physicsBody?.isDynamic = false
        contactNode.physicsBody?.categoryBitMask = scoreCategory
        contactNode.physicsBody?.contactTestBitMask = birdCategory
        pipePair.addChild(contactNode)
        
        
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
    
    func didBegin(_ contact: SKPhysicsContact) {
        if gameStatus != .running {
            return
        }
        if (contact.bodyA.categoryBitMask & scoreCategory) == scoreCategory || (contact.bodyB.categoryBitMask & scoreCategory) == scoreCategory {
            score += 1
            print(score)
            scoreLabelNode.text = String(score)
            scoreLabelNode.run(SKAction.sequence([SKAction.scale(to: 1.5, duration: TimeInterval(0.1)),SKAction.scale(to: 1.0, duration: TimeInterval(0.1))]))
        }else{
            moving.speed = 0
            bird.physicsBody?.collisionBitMask = worldCategory
            bird.run(SKAction.rotate(byAngle: .pi * CGFloat(bird.position.y) * 0.01, duration: 1))
            bgFlash()
            overStatus()
        }
    }
    
    func bgFlash() {
        let bgFlash = SKAction.run({
            self.backgroundColor = SKColor(red: 1, green: 0, blue: 0, alpha: 1.0)}
        )
        let bgNormal = SKAction.run({
            self.backgroundColor = self.skyColor;
        })
        let bgFlashAndNormal = SKAction.sequence([bgFlash,SKAction.wait(forDuration: (0.05)),bgNormal,SKAction.wait(forDuration: (0.05))])
        self.run(SKAction.sequence([SKAction.repeat(bgFlashAndNormal, count: 4)]), withKey: "falsh")
        self.removeAction(forKey: "flash")
    }
 
    override func update(_ currentTime: TimeInterval) {
            let value = bird.physicsBody!.velocity.dy * (bird.physicsBody!.velocity.dy < 0 ? 0.003 : 0.001)
            bird.zRotation = min(max(-1, value),0.5)
        }

    }

