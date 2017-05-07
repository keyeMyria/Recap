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
    
    var sendPhoto: SendPhoto { get }
}

class CameraViewController: UIViewController {
    
    var viewModel: CameraViewModelProtocol?
    let overlay = CameraOverlayView.loadFromNib()
    var photoTakenView: PhotoTakenView?

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
        let vm = CameraOverlayViewModel(takePhoto: takePhoto,
                                        showSettings: viewModel.showSettings,
                                        sentPostcardsTapHandler: viewModel.sentPostcardsTapHandler,
                                        rotateCamera: rotateCamera,
                                        sendPhoto: { image in
                                            viewModel.sendPhoto(image)
                                        })
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
    
    func deletePhoto() {
        photoTakenView?.removeFromSuperview()
    }
    
    var alert: SimpleImageLabelAlert?
    
    func presentAlert(vm: SimpleImageLabelAlertViewModelProtocol) {
        let alert = SimpleImageLabelAlert(frame: .zero, viewModel: vm)
        alert.alpha = 0
        view.addSubview(alert)
        alert.translatesAutoresizingMaskIntoConstraints = false
        alert.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        view.addConstraint(NSLayoutConstraint(item: alert, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 0.46, constant: 0.0))
        self.alert = alert
        
        UIView.animate(withDuration: 0.2) { 
            alert.alpha = 1.0
        }
    }
    
    func returnToCamera(withAlertVM vm: SimpleImageLabelAlertViewModelProtocol) {
        dismissPresentedAlert {
            self.photoTakenView?.removeFromSuperview()
            self.presentAlert(vm: vm)
            self.dismissPresentedAlert(delay: 2.0)
        }
    }
    
    func dismissPresentedAlert(delay: TimeInterval = 0, completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.2, delay: delay, animations: {
            self.alert?.alpha = 0.0
        }) { _ in
            self.alert?.removeFromSuperview()
            completion?()
        }
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
        
        if let cgImage = image.cgImage, cameraPosition == .front {
            image = UIImage(cgImage: cgImage, scale: image.scale, orientation:.leftMirrored)
        }
        
        let photoTakenView = PhotoTakenView(frame: .zero, image: image)
        view.addSubview(photoTakenView)
        photoTakenView.constrainToSuperview()
        photoTakenView.viewModel = PhotoTakenViewModel(sendPhoto: { [weak self] image in
                                                            self?.viewModel?.sendPhoto(image)
                                                        },
                                                       deletePhotoAction: { [weak self] in self?.deletePhoto() },
                                                       savePhotoAction: {})
        self.photoTakenView = photoTakenView
    }
}
