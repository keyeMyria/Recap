//
//  ViewController.swift
//  MeMailer5000
//
//  Created by Alex Brashear on 1/28/17.
//  Copyright © 2017 memailer. All rights reserved.
//

import UIKit
import AVFoundation

protocol CameraViewModelProtocol {    
    var sentPostcardsTapHandler: SentPostcardsTapHandler { get }
    
    var showSettings: () -> Void { get }
}

class CameraViewController: UIViewController {
    
    var viewModel: CameraViewModelProtocol?
    let overlay = CameraOverlayView.loadFromNib()

    // MARK: - IBOutlets

    @IBOutlet fileprivate var captureView: UIView!
    
    fileprivate var cameraPosition: AVCaptureDevicePosition = .back
    
    var imageView = UIImageView()
    
    var session = AVCaptureSession()
    var stillImageOutput: AVCapturePhotoOutput?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadCamera(atPosition: .back)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        configureCameraView()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let viewModel = viewModel else { fatalError() }
        let rotateCamera: RotateCamera = { [weak self] in self?.switchCamera() }
        let takePhoto: TakePhoto = { [weak self] flashMode in self?.takePhoto(withFlashMode: flashMode) }
        let vm = CameraOverlayViewModel(takePhoto: takePhoto, showSettings: viewModel.showSettings, sentPostcardsTapHandler: viewModel.sentPostcardsTapHandler, rotateCamera: rotateCamera)
        view.addSubview(overlay)
        overlay.viewModel = vm
    }
    
    fileprivate func capturePhotoSettings(flashMode: AVCaptureFlashMode) -> AVCapturePhotoSettings {
        let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecJPEG])
        settings.flashMode = stillImageOutput?.supportedFlashModes.contains(NSNumber(value: flashMode.rawValue)) ?? false ? flashMode : .off
        return settings
    }
    
    fileprivate func configureCameraView() {
        videoPreviewLayer?.frame = captureView.frame
    }
    
    fileprivate func loadCamera(atPosition position: AVCaptureDevicePosition) {
        let camera = AVCaptureDevice.defaultDevice(withDeviceType: .builtInWideAngleCamera, mediaType: AVMediaTypeVideo, position: position)
        
        if camera == nil {
            print("turds")
        }
        
        if session.isRunning {
            session.stopRunning()
            videoPreviewLayer?.removeFromSuperlayer()
            session = AVCaptureSession()
        }
        
        var input: AVCaptureDeviceInput!
        do {
            input = try AVCaptureDeviceInput(device: camera)
        } catch let error as NSError {
            assertionFailure(error.localizedDescription)
        }
        
        if session.canAddInput(input) {
            session.addInput(input)
            // ...
            stillImageOutput = AVCapturePhotoOutput()
        }
        
        if session.canAddOutput(stillImageOutput) {
            session.addOutput(stillImageOutput)
            // ...
            // Configure the Live Preview here...
            cameraPosition = position
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: session)
            videoPreviewLayer!.videoGravity = AVLayerVideoGravityResizeAspectFill
            captureView.layer.addSublayer(videoPreviewLayer!)
            session.startRunning()
        }
    }
    
    func takePhoto(withFlashMode flashMode: AVCaptureFlashMode) {
        stillImageOutput?.capturePhoto(with: capturePhotoSettings(flashMode: flashMode), delegate: self)
    }

    func switchCamera() {
        if cameraPosition == .back { loadCamera(atPosition: .front) }
        else { loadCamera(atPosition: .back) }
        configureCameraView()
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func capture(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhotoSampleBuffer photoSampleBuffer: CMSampleBuffer?, previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        guard let buffer = photoSampleBuffer else {
            return assertionFailure("unable to unwrap photo buffer")
        }
        guard let imageData = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: buffer, previewPhotoSampleBuffer: previewPhotoSampleBuffer),
            var image = UIImage(data: imageData) else { return }
        
        imageView.frame = captureView.frame
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        if let cgImage = image.cgImage, cameraPosition == .front {
            image = UIImage(cgImage: cgImage, scale: image.scale, orientation:.leftMirrored)
        }
        imageView.image = image
    }
}
