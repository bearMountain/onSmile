




import UIKit
import CoreImage
import ImageIO
import AssetsLibrary
import AVFoundation

class CaptureController: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    //MARK: - Public
    var previewLayer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer()
    
    //MARK: - Init
    override init() {
        super.init()
        setupAVCapture()
        setupFaceDetector()
    }
    
    //MARK: - Internal
    var isUsingFrontFacingCamera = false
    var observationContext = UInt8()
    var videoDataOutput = AVCaptureVideoDataOutput()
    var videoDataOutputQueue: dispatch_queue_t = dispatch_queue_create(UnsafePointer(bitPattern: 0), DISPATCH_QUEUE_SERIAL)
    var stillImageOutput = AVCaptureStillImageOutput()
    var effectiveScale: CGFloat = 1.0
    var faceDetector = CIDetector()
    var ioSession = AVCaptureSession()
    
    func setupAVCapture() {
        ioSession = AVCaptureSession()
        ioSession.sessionPreset = AVCaptureSessionPreset640x480
        
        if let cameraInput = getCameraInput() {
            isUsingFrontFacingCamera = true
            effectiveScale = 1.0
            
            addInput(cameraInput)
            addStillImageOutput()
            addVideoDataOutput()
            setupPreviewLayer()
            
            ioSession.startRunning()
        }
    }
    
    func setupFaceDetector() {
        let detectorOptions = [CIDetectorAccuracy: CIDetectorAccuracyLow]
        faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: detectorOptions)
    }
    
    func getCameraInput() -> AVCaptureInput? {
        // Select a video device, make an input
        let cameraDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        var cameraInput: AVCaptureInput?
        do {
            cameraInput = try AVCaptureDeviceInput(device: cameraDevice)
        } catch {
            teardownAVCapture()
        }
        
        return cameraInput
    }
    
    func addInput(input: AVCaptureInput) {
        if (ioSession.canAddInput(input)) {
            ioSession.addInput(input)
        }
    }
    
    func addOutput(output: AVCaptureOutput) {
        if (ioSession.canAddOutput(output)) {
            ioSession.addOutput(output)
        }
    }
    
    func addStillImageOutput() {
        stillImageOutput = AVCaptureStillImageOutput()
        let options = NSKeyValueObservingOptions([.New])
        stillImageOutput.addObserver(self, forKeyPath: "capturingStillImage", options: options, context: &observationContext)
        addOutput(stillImageOutput)
    }
    
    func addVideoDataOutput() {
        // Make a video data output
        videoDataOutput = AVCaptureVideoDataOutput()
        
        // we want BGRA, both CoreGraphics and OpenGL work well with 'BGRA'
        let rgbOutputSettings: [String: AnyObject] = [String(kCVPixelBufferPixelFormatTypeKey): NSNumber(unsignedInt: kCMPixelFormat_32BGRA)]
        videoDataOutput.videoSettings = rgbOutputSettings
        videoDataOutput.alwaysDiscardsLateVideoFrames = true // discard if the data output queue is blocked (as we process the still image)
        
        videoDataOutputQueue = dispatch_queue_create(UnsafePointer(bitPattern: 0), DISPATCH_QUEUE_SERIAL)
        videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        addOutput(videoDataOutput)
        
        videoDataOutput.connectionWithMediaType(AVMediaTypeVideo).enabled = false
    }

    func setupPreviewLayer() {
        previewLayer = AVCaptureVideoPreviewLayer(session: ioSession)
        previewLayer.backgroundColor = UIColor.blueColor().CGColor
        previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
    }
    
    func teardownAVCapture() {
        stillImageOutput.removeObserver(self, forKeyPath: "isCapturingStillImage")
        previewLayer.removeFromSuperlayer()
    }

    func ReleaseCVPixelBuffer(pixelBuffer: CVPixelBufferRef) {
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0)
    }
}


let FlipCameraButtonWidth: CGFloat = 100.0
let FlipCameraButtonSideInset: CGFloat = 40.0
let FlipCameraButtonTopInset: CGFloat = 60.0

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    let captureController = CaptureController()
    let flipCameraButton = UIButton(type: .Custom)

    //MARK: - ViewLifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.layer.addSublayer(captureController.previewLayer)
        
        setupFlipCameraButton()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        captureController.previewLayer.frame = view.bounds
        
        flipCameraButton.frame = CGRect(
            x: view.frame.size.width - FlipCameraButtonWidth - FlipCameraButtonSideInset,
            y: FlipCameraButtonTopInset,
            width: FlipCameraButtonWidth,
            height: FlipCameraButtonWidth
        )
    }
    
    //MARK: - Internal
    func setupFlipCameraButton() {
        view.addSubview(flipCameraButton)
        
        flipCameraButton.setTitle("test", forState: .Normal)
    }
}


