




import UIKit
import CoreImage
import ImageIO
import AssetsLibrary
import AVFoundation

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupAVCapture()
        view.addSubview(previewView)
    }
    
    var isUsingFrontFacingCamera = false
    var observationContext = UInt8()
    var videoDataOutput = AVCaptureVideoDataOutput()
    var videoDataOutputQueue: dispatch_queue_t = dispatch_queue_create(UnsafePointer(bitPattern: 0), DISPATCH_QUEUE_SERIAL)
    var stillImageOutput = AVCaptureStillImageOutput()
    var effectiveScale: CGFloat = 1.0
    var previewLayer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer()
    var previewView = UIView()
    
    func setupAVCapture() {
        let session = AVCaptureSession()
        session.sessionPreset = AVCaptureSessionPreset640x480
        
        // Select a video device, make an input
        let device = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        do {
            let deviceInput = try AVCaptureDeviceInput(device: device)
            isUsingFrontFacingCamera = true
            if (session.canAddInput(deviceInput)) {
                session.addInput(deviceInput)
            }
            
            // Make a still image output
            stillImageOutput = AVCaptureStillImageOutput()
            let options = NSKeyValueObservingOptions([.New])
            stillImageOutput.addObserver(self, forKeyPath: "capturingStillImage", options: options, context: &observationContext)
            if (session.canAddOutput(stillImageOutput)) {
                session.addOutput(stillImageOutput)
            }
            
            // Make a video data output
            videoDataOutput = AVCaptureVideoDataOutput()
            
            // we want BGRA, both CoreGraphics and OpenGL work well with 'BGRA'
            let rgbOutputSettings: [String: AnyObject] = [String(kCVPixelBufferPixelFormatTypeKey): NSNumber(unsignedInt: kCMPixelFormat_32BGRA)]
            videoDataOutput.videoSettings = rgbOutputSettings
            videoDataOutput.alwaysDiscardsLateVideoFrames = true // discard if the data output queue is blocked (as we process the still image)
            
            videoDataOutputQueue = dispatch_queue_create(UnsafePointer(bitPattern: 0), DISPATCH_QUEUE_SERIAL)
            videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
            
            if (session.canAddOutput(videoDataOutput)) {
                session.addOutput(videoDataOutput)
            }
            
            videoDataOutput.connectionWithMediaType(AVMediaTypeVideo).enabled = false
            effectiveScale = 1.0
            
            previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer.backgroundColor = UIColor.blueColor().CGColor
            previewLayer.videoGravity = AVLayerVideoGravityResizeAspect
            
            previewView.frame = view.bounds
            let rootLayer = previewView.layer
            rootLayer.masksToBounds = true
            previewLayer.frame = rootLayer.bounds
            rootLayer.addSublayer(previewLayer)
            session.startRunning()
        } catch {
            teardownAVCapture()
        }
    }
    
    func teardownAVCapture() {
        stillImageOutput.removeObserver(self, forKeyPath: "isCapturingStillImage")
        previewLayer.removeFromSuperlayer()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewView.frame = view.bounds
    }

}

func ReleaseCVPixelBuffer(pixelBuffer: CVPixelBufferRef) {
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0)
}

//static void ReleaseCVPixelBuffer(void *pixel, const void *data, size_t size);
//static void ReleaseCVPixelBuffer(void *pixel, const void *data, size_t size)
//{
//    CVPixelBufferRef pixelBuffer = (CVPixelBufferRef)pixel;
//    CVPixelBufferUnlockBaseAddress( pixelBuffer, 0 );
//    CVPixelBufferRelease( pixelBuffer );
//}

