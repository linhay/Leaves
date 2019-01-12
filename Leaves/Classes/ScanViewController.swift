
import UIKit
import AVFoundation

open class ScanViewController: UIViewController {
  
  lazy var captureSession: AVCaptureSession = {
    return  AVCaptureSession()
  }()
  
  lazy var videoPreviewLayer:AVCaptureVideoPreviewLayer = {
    let item = AVCaptureVideoPreviewLayer(session: captureSession)
    item.videoGravity = AVLayerVideoGravity.resizeAspectFill
    return item
  }()
  
  lazy var qrCodeFrameView: UIView = {
    // 初始化二维码选框并高亮边框
    let item = UIView()
    item.layer.borderColor = UIColor.green.cgColor
    item.layer.borderWidth = 2
    self.view.addSubview(item)
    self.view.bringSubviewToFront(item)
    return item
  }()
  
  lazy var messageLabel = UILabel()
  
  lazy var torchBtn: UIButton = {
    let item = UIButton()
    let image = UIImage(named: "leaves-torch", in: Bundle(for: Leaves.self), compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
    
    item.setImage(, for: .normal)
    item.setTitle(<#T##title: String?##String?#>, for: <#T##UIControl.State#>)
  }()
  
  override open func viewDidLoad() {
    super.viewDidLoad()
    
    
    
    if let device = AVCaptureDevice.default(for: AVMediaType.video),
      let input = try? AVCaptureDeviceInput(device: device),
      captureSession.canAddInput(input) {
      captureSession.addInput(input)
    }
    
    do {
      let output = AVCaptureVideoDataOutput()
      if captureSession.canAddOutput(output) {
        captureSession.addOutput(output)
      }
      output.setSampleBufferDelegate(self, queue: DispatchQueue.main)
    }
    
    do {
      let output = AVCaptureMetadataOutput()
      if captureSession.canAddOutput(output) {
        captureSession.addOutput(output)
      }
      output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
      output.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
    }
    
    
    
    videoPreviewLayer.frame = view.layer.bounds
    self.view.layer.addSublayer(videoPreviewLayer)
    
    // 开始视频捕获
    captureSession.startRunning()
    
    view.addSubview(messageLabel)
    messageLabel.frame = CGRect(x: 0, y: 60, width: 200, height: 60)
    
    
  }
  
  func authorization() {
    let status = AVCaptureDevice.authorizationStatus(for: .video)
    switch status {
    case .notDetermined:
      AVCaptureDevice.requestAccess(for: .video, completionHandler: { (granted) in
        granted ? self.configureCamera() : self.showErrorAlertView()
      })
    case .authorized:
      self.configureCamera()
    default:
      self.showErrorAlertView()
    }
  }
  
  func configureCamera() {
    
  }
  
  func showErrorAlertView() {
    
  }
  
  func turnTorch(on: Bool) {
    
  }
  
}

extension ScanViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
  
  public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    guard
      let dict = CMCopyDictionaryOfAttachments(allocator: nil, target: sampleBuffer, attachmentMode: kCMAttachmentMode_ShouldPropagate)
        as? [String: Any],
      let exifMetadata = dict[kCGImagePropertyExifDictionary as String] as? [String: Any],
      let brightnessValue = exifMetadata[kCGImagePropertyExifBrightnessValue as String] as? Double
      else { return }
    print("当前亮度值 : \(brightnessValue)")
    let brightnessThresholdValue = -0.2
    if brightnessValue < brightnessThresholdValue { DispatchQueue.main.async { self.turnTorch(on: true) } }
  }
  
}

extension ScanViewController: AVCaptureMetadataOutputObjectsDelegate {
  
  public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
    // 检查：metadataObjects 对象不为空，并且至少包含一个元素
    if metadataObjects.isEmpty {
      qrCodeFrameView.frame = CGRect.zero
      messageLabel.text = "No QR code is detected"
      return
    }
    
    // 获得元数据对象
    let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
    
    if metadataObj.type == AVMetadataObject.ObjectType.qr {
      // 如果元数据是二维码，则更新二维码选框大小与 label 的文本
      let barCodeObject = videoPreviewLayer.transformedMetadataObject(for: metadataObj)
      qrCodeFrameView.frame = barCodeObject!.bounds
      
      if metadataObj.stringValue != nil {
        messageLabel.text = metadataObj.stringValue
      }
    }
  }
  
}
