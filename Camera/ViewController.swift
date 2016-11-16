//
//  ViewController.swift
//  Camera
//
//  Created by Dennis Wong on 11/15/16.
//  Copyright © 2016 Dennis Wong. All rights reserved.
//

import AVFoundation
import UIKit
import Photos

class ViewController: UIViewController, AVCapturePhotoCaptureDelegate {
    // MARK: Properties
    @IBOutlet weak var cameraView: UIImageView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    
    // MARK: Camera properties
    let captureSession = AVCaptureSession()
    let sessionOutput = AVCapturePhotoOutput()
    let sessionOutputSetting = AVCapturePhotoSettings(format: [AVVideoCodecKey:AVVideoCodecJPEG])
    var previewLayer = AVCaptureVideoPreviewLayer()
    var desiredCameraPosition = AVCaptureDevicePosition.back
    var photoData: Data? = nil

    // If we find a device we'll store it here for later use
    var captureDevice : AVCaptureDevice?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initCamera()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer.frame = cameraView.bounds
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: camera delegate functions
    func capture(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhotoSampleBuffer photoSampleBuffer: CMSampleBuffer?, previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        if let photoSampleBuffer = photoSampleBuffer {
            photoData = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: photoSampleBuffer, previewPhotoSampleBuffer: previewPhotoSampleBuffer)
        }
        else {
            print("Error capturing photo: \(error)")
            return
        }
    }
    
    func capture(_ captureOutput: AVCapturePhotoOutput, didFinishCaptureForResolvedSettings resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        if let error = error {
            print("Error capturing photo: \(error)")
            return
        }
        
        guard let photoData = photoData else {
            print("No photo data resource")
            return
        }
        
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                PHPhotoLibrary.shared().performChanges({ [] in
                    let creationRequest = PHAssetCreationRequest.forAsset()
                    creationRequest.addResource(with: .photo, data: photoData, options: nil)
                    
                    }, completionHandler: { success, error in
                        if let error = error {
                            print("Error occurered while saving photo to photo library: \(error)")
                        }
                        
                    }
                )
            }
        }
    }


    // MARK: camera functions
    func initCamera() {
        let deviceDiscoverySession = AVCaptureDeviceDiscoverySession(deviceTypes: [AVCaptureDeviceType.builtInDuoCamera, AVCaptureDeviceType.builtInTelephotoCamera, AVCaptureDeviceType.builtInWideAngleCamera], mediaType: AVMediaTypeVideo, position: AVCaptureDevicePosition.unspecified)
        for device in (deviceDiscoverySession?.devices)! {
            if device.position == desiredCameraPosition {
                captureDevice = device
                startCapture(device: device)
            }
        }
    }
    
    func startCapture(device: AVCaptureDevice) {
        captureSession.sessionPreset = AVCaptureSessionPresetHigh
        do {
            let input = try AVCaptureDeviceInput(device: device)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
                if captureSession.canAddOutput(sessionOutput) {
                    captureSession.addOutput(sessionOutput)
                    previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                    previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
                    previewLayer.connection.videoOrientation = AVCaptureVideoOrientation.portrait
                    cameraView.layer.addSublayer(previewLayer)
                    
                    captureSession.startRunning()
                }
            }
        }
        catch {
            print("Exception")
        }
    }

    private func focus(with focusMode: AVCaptureFocusMode, exposureMode: AVCaptureExposureMode, at devicePoint: CGPoint, monitorSubjectAreaChange: Bool) {
        if let device = captureDevice {
            do {
                try device.lockForConfiguration()
                
                /*
                 Setting (focus/exposure)PointOfInterest alone does not initiate a (focus/exposure) operation.
                 Call set(Focus/Exposure)Mode() to apply the new point of interest.
                 */
                if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(focusMode) {
                    device.focusPointOfInterest = devicePoint
                    device.focusMode = focusMode
                }
                
                if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(exposureMode) {
                    device.exposurePointOfInterest = devicePoint
                    device.exposureMode = exposureMode
                }
                
                device.isSubjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange
                device.unlockForConfiguration()
            }
            catch {
                print("Could not lock device for configuration: \(error)")
            }
        }
    }

    
    // MARK: Actions
    @IBAction func clickButton(_ sender: UIButton) {
        print("Clicked snap button")
        sessionOutput.capturePhoto(with: sessionOutputSetting, delegate: self)
    }
    
    @IBAction func focusAndExposeTap(_ gestureRecognizer: UITapGestureRecognizer) {
        let devicePoint = previewLayer.captureDevicePointOfInterest(for: gestureRecognizer.location(in: gestureRecognizer.view))
        focus(with: .autoFocus, exposureMode: .autoExpose, at: devicePoint, monitorSubjectAreaChange: true)
        print("tapped focus location x= \(devicePoint.x) y= \(devicePoint.y)")
    }
    
    @IBAction func frontBackSelect(_ sender: UISegmentedControl) {
        switch (segmentedControl.selectedSegmentIndex) {
        case 0:
            desiredCameraPosition =
                    AVCaptureDevicePosition.front;
        case 1:
            desiredCameraPosition =
                    AVCaptureDevicePosition.back;
        default:
            break;

        }
    }
    

}

