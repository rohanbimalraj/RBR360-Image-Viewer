//
//  RBRView.swift
//  RBR360ImageViewer
//
//  Created by Rohan Bimal Raj on 04/05/2023.
//  Copyright © 2023 Rohan Bimal Raj. All rights reserved.
//
import UIKit
import SceneKit
import SceneKit.ModelIO
import CoreMotion

open class RBRView: UIView {

    @IBOutlet var containerView: UIView!
    @IBOutlet weak var scnView: SCNView!
    @IBOutlet weak var dPadView: UIView!
    @IBOutlet weak var controlPanelView: UIView!
    
    private let cameraNode = SCNNode()
    private var shouldRotateUp: Bool = false
    private var shouldRotateDown: Bool = false
    private var shouldRotateRight: Bool = false
    private var shouldRotateLeft: Bool = false
    private var lastPanLocation: SCNVector3 = SCNVector3Zero
    private var panStartZ: CGFloat = 0
    private var geometryNode: SCNNode? = nil
    private var selectedNode: SCNNode? = nil
    private let motionManager = CMMotionManager()
    private var control: cameraControl?
    private var originalRotation: SCNVector3? = nil
    private var positionIndicatorNode: PositionIndicatorNode?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initSubViews()
    }
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        initSubViews()
    }
    
    @available(iOS 13.0, *)
    public func loadImage(with url: URL, camera control: cameraControl) {
        controlPanelView.isHidden = true
        dPadView.isHidden = true
        let scene = SCNScene()
        scene.lightingEnvironment.contents = url
        scene.background.contents = url
        scnView.scene = scene
        cameraNode.camera = SCNCamera()
        scnView.scene?.rootNode.addChildNode(cameraNode)
        scnView.autoenablesDefaultLighting = true
        scnView.delegate = self
        addPinchGestureToSceneView()
        addRotationGesture()
        addPanGesture()
        addTapGestures()

        switch control {
        case .dPad:
            dPadView.isHidden = false
            scnView.isPlaying = true
            self.control = .dPad
        case .gesture:
            self.control = .gesture
        case .gyro:
            self.control = .gyro
           getDeviceMotion()
        }
        
        positionIndicatorNode = PositionIndicatorNode(cameraNode: self.cameraNode)
    }
    
    private func initSubViews() {
        let view = Bundle.module.loadNibNamed("RBRView", owner: self)!.first as! UIView
        view.frame = self.bounds
        self.insertSubview(view, at: 0)
        NSLayoutConstraint.activate([
            self.topAnchor.constraint(equalTo: view.topAnchor),
            self.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            self.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            self.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    public func addModelToScene(with url: URL, scale: Float = 0.1) {
        let modelScene = try! SCNScene(url: url)
        let modelNode = SCNNode()
        modelScene.rootNode.childNodes.forEach { node in
            modelNode.addChildNode(node)
        }
        let containerNode = SCNNode(geometry: SCNBox(width: CGFloat(modelNode.width), height: CGFloat(modelNode.height), length: CGFloat(modelNode.depth), chamferRadius: 0))
        containerNode.geometry?.firstMaterial?.transparency = 0.0
        modelNode.centerPivot()
        modelNode.name = "model"
        containerNode.name = url.lastPathComponent
        containerNode.addChildNode(modelNode)
        addModelToScene(model: containerNode, scale: scale)
    }
    
    public func addModelToScene(model: SCNNode, scale: Float = 0.1) {
        scnView.scene?.rootNode.addChildNode(model)
        let referenceNodeTransform = matrix_float4x4(cameraNode.transform)
        var translationMatrix = matrix_identity_float4x4
        translationMatrix.columns.3.x = 0
        translationMatrix.columns.3.y = 0
        translationMatrix.columns.3.z = -3

        let updatedTransform = matrix_multiply(referenceNodeTransform, translationMatrix)
        model.transform = SCNMatrix4(updatedTransform)
        model.eulerAngles = SCNVector3(x: 0, y: 0, z: 0)
        let _model = model.childNode(withName: "model", recursively: true)
        let dummyNode = cameraNode.clone()
        dummyNode.eulerAngles.x = 0
        _model?.transform = dummyNode.transform
        model.scale = SCNVector3(scale, scale, scale)
        model.stopAnimation()
    }
    
    @available(iOS 13.0, *)
    public func getDeviceMotion() {
        guard let control = control, control == .gyro else {return}
        motionManager.startDeviceMotionUpdates()
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        
        motionManager.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: OperationQueue.main, withHandler: { (motion: CMDeviceMotion?, err: Error?) in
            guard let m = motion else { return }
            let interfaceOrientation = UIApplication.shared.keyWindow?.windowScene?.interfaceOrientation ?? .landscapeLeft
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0
            self.cameraNode.orientation = m.gaze(atOrientation: interfaceOrientation)
            SCNTransaction.commit()
        })
    }
    
    public func stopCameraMotion() {
        guard let control = control, control == .gyro else {return}
        motionManager.stopDeviceMotionUpdates()
    }
    
    public func playSelectedNodeAnimation() {
        selectedNode?.startAnimation()
    }
    
    public func stopSelectedNodeAnimation() {
        selectedNode?.stopAnimation()
    }
    
    public func captureScreen() {
        let image = scnView.snapshot()
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(saveError), nil)
    }
    
    @objc func saveError(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            print("error: \(error.localizedDescription)")
            NotificationCenter.default.post(name: .imageSaveFailure, object: nil)
        } else {
            NotificationCenter.default.post(name: .imageSaveSuccess, object: nil)
        }
    }
        
    private func nodeMethod(at position: CGPoint) -> SCNNode? {
        let n = self.scnView.hitTest(position, options: nil).first(where: {
            $0.node !== cameraNode
        })?.node
        return n//?.getRoot()
    }
    
    private func addPanGesture() {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(allowCameraControl))
        scnView.addGestureRecognizer(gesture)
    }
    
    private func addPinchGestureToSceneView(){
        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(scaleObject))
        scnView.addGestureRecognizer(pinchGestureRecognizer)
    }
    
    private func addRotationGesture() {
        let rotationGesture = UIRotationGestureRecognizer(target: self, action: #selector(rotation))
            self.scnView.addGestureRecognizer(rotationGesture)
    }
    
    private func addTapGestures() {
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(onDoubleTap))
        doubleTapGesture.numberOfTapsRequired = 2
        self.scnView.addGestureRecognizer(doubleTapGesture)
        
        let singleTapGesture = UITapGestureRecognizer(target: self, action: #selector(onSingleTap))
        singleTapGesture.numberOfTapsRequired = 1
        self.scnView.addGestureRecognizer(singleTapGesture)
        
        singleTapGesture.require(toFail: doubleTapGesture)
        singleTapGesture.delaysTouchesBegan = true
        doubleTapGesture.delaysTouchesBegan = true
    }
    
    @objc func onDoubleTap(_ gesture: UITapGestureRecognizer) {
        
        let location = gesture.location(in: self.scnView)
        
        guard let node = nodeMethod(at: location), node !== selectedNode, let requiredNode =  node.childNodes.first else { return }
        selectedNode = node
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        positionIndicatorNode?.removeIndicator()
        positionIndicatorNode?.addIndicator(to: requiredNode)
        
        UIView.transition(with: self, duration: 0.5,
                          options: .transitionCrossDissolve,
                          animations: {
                         self.controlPanelView.isHidden = false
                      })

    }
    
    @objc func onSingleTap(_ gesture: UITapGestureRecognizer) {
        
        let location = gesture.location(in: self.scnView)
        
        guard let node = nodeMethod(at: location), node === selectedNode else { return }
        selectedNode = nil
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        positionIndicatorNode?.removeIndicator()
        
        UIView.transition(with: self, duration: 0.5,
                          options: .transitionCrossDissolve,
                          animations: {
                         self.controlPanelView.isHidden = true
                      })
    }
    
    @objc func rotation(_ gesture: UIRotationGestureRecognizer) {
        
        let location = gesture.location(in: self.scnView)
        
        guard let node = nodeMethod(at: location), node.isSelected else { return }
        
        switch gesture.state {
        case .began:
            originalRotation = node.eulerAngles
        case .changed:
            guard var originalRotation = originalRotation else { return }
            originalRotation.y -= Float(gesture.rotation)
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0
            node.eulerAngles = originalRotation
            SCNTransaction.commit()
        default:
            originalRotation = nil
        }
    }
    
    @objc func scaleObject(gesture: UIPinchGestureRecognizer) {

        let location = gesture.location(in: scnView)
        guard let nodeToScale = nodeMethod(at: location), nodeToScale.isSelected else {
            return
        }

        if gesture.state == .changed {

            let pinchScaleX: CGFloat = gesture.scale * CGFloat((nodeToScale.scale.x))
            let pinchScaleY: CGFloat = gesture.scale * CGFloat((nodeToScale.scale.y))
            let pinchScaleZ: CGFloat = gesture.scale * CGFloat((nodeToScale.scale.z))
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0
            nodeToScale.scale = SCNVector3Make(Float(pinchScaleX), Float(pinchScaleY), Float(pinchScaleZ))
            SCNTransaction.commit()
            gesture.scale = 1

        }
        if gesture.state == .ended { }

    }
    
    @objc func allowCameraControl(sender: UIPanGestureRecognizer) {
        
        let location = sender.location(in: self.scnView)
        switch sender.state {
        case .began:
            guard let hitNodeResult = scnView.hitTest(location).first else {return}
            lastPanLocation = hitNodeResult.worldCoordinates
            let node = nodeMethod(at: location)
            geometryNode = node
            panStartZ = CGFloat(scnView.projectPoint(geometryNode!.position).z)
        case .changed:
            guard let geometryNode = geometryNode, geometryNode.isSelected else {
                guard control == .gesture else {return}
                let translation = sender.velocity(in: sender.view)
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0
                cameraNode.eulerAngles.y -= Float(translation.x/CGFloat(100)).radians
                cameraNode.eulerAngles.x -= Float(translation.y/CGFloat(100)).radians
                SCNTransaction.commit()
                return
            }
            let worldTouchPosition = scnView.unprojectPoint(SCNVector3(location.x, location.y, panStartZ))
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.1
            geometryNode.position = worldTouchPosition
            SCNTransaction.commit()
            self.lastPanLocation = worldTouchPosition
        case .ended:
            geometryNode = nil
            panStartZ = 0
            lastPanLocation = SCNVector3Zero
        default:
            break
        }
    }
    
    
    @IBAction func removeButtonAction(_ sender: Any) {
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        positionIndicatorNode?.removeIndicator()
        selectedNode?.removeFromParentNode()
        NotificationCenter.default.post(name: .deletedModelName, object: nil, userInfo: ["name": selectedNode?.name ?? ""])
        UIView.transition(with: self, duration: 0.5,
                          options: .transitionCrossDissolve,
                          animations: {
                         self.controlPanelView.isHidden = true
                      })
        selectedNode = nil
    }
    
    @IBAction func decreaseDistanceButtonAction(_ sender: Any) {
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.5
        selectedNode?.simdPosition -= cameraNode.simdWorldFront
        SCNTransaction.commit()
    }
    
    
    @IBAction func increaseDistanceButtonAction(_ sender: Any) {
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.5
        selectedNode?.simdPosition += cameraNode.simdWorldFront
        SCNTransaction.commit()

    }
    @IBAction func upButtonAction(_ sender: UIButton) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.5
        cameraNode.eulerAngles.x += 0.1
        SCNTransaction.commit()
    }
    
    @IBAction func rightButtonAction(_ sender: UIButton) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.5
        cameraNode.eulerAngles.y -= 0.1
        SCNTransaction.commit()

    }
    
    @IBAction func downButtonAction(_ sender: UIButton) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.5
        cameraNode.eulerAngles.x -= 0.1
        SCNTransaction.commit()

    }
    
    @IBAction func leftButttonAction(_ sender: Any) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.5
        cameraNode.eulerAngles.y += 0.1
        SCNTransaction.commit()

    }
    
    @IBAction func upLongPressAction(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            shouldRotateUp = true
        }else if sender.state == .ended {
            shouldRotateUp = false
        }
    }
    
    @IBAction func downLongPressAction(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            shouldRotateDown = true
        }else if sender.state == .ended {
            shouldRotateDown = false
        }
    }
    @IBAction func rightLongPressAction(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            shouldRotateRight = true
        }else if sender.state == .ended {
            shouldRotateRight = false
        }
    }
    @IBAction func leftLongPressAction(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            shouldRotateLeft = true
        }else if sender.state == .ended {
            shouldRotateLeft = false
        }
    }
}

extension RBRView: SCNSceneRendererDelegate {
    public func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if shouldRotateUp {
            self.cameraNode.eulerAngles.x += 0.01
        }
        if shouldRotateDown {
            self.cameraNode.eulerAngles.x -= 0.01
        }
        if shouldRotateRight {
            self.cameraNode.eulerAngles.y -= 0.01
        }
        if shouldRotateLeft {
            self.cameraNode.eulerAngles.y += 0.01
        }
    }
}

public extension Notification.Name {
    static let deletedModelName = Notification.Name("deletedModelName")
    static let imageSaveSuccess = Notification.Name("imageSaveSuccess")
    static let imageSaveFailure = Notification.Name("imageSaveFailure")
}
