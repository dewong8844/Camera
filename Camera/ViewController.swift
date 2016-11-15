//
//  ViewController.swift
//  Camera
//
//  Created by Dennis Wong on 11/15/16.
//  Copyright © 2016 Dennis Wong. All rights reserved.
//

import AVFoundation
import UIKit

class ViewController: UIViewController, AVCapturePhotoCaptureDelegate {
    // MARK: Properties
    @IBOutlet weak var cameraView: UIImageView!
    
    
    // MARK: Camera properties
    let captureSession = AVCaptureSession()
    let sessionOutput = AVCapturePhotoOutput()
    let sessionOutputSetting = AVCapturePhotoSettings(format: [AVVideoCodecKey:AVVideoCodecJPEG])
    var previewLayer = AVCaptureVideoPreviewLayer()
    
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
    
    // MARK: camera functions
    func initCamera() {
        captureSession.sessionPreset = AVCaptureSessionPresetHigh
        let deviceDiscoverySession = AVCaptureDeviceDiscoverySession(deviceTypes: [AVCaptureDeviceType.builtInDuoCamera, AVCaptureDeviceType.builtInTelephotoCamera, AVCaptureDeviceType.builtInWideAngleCamera], mediaType: AVMediaTypeVideo, position: AVCaptureDevicePosition.unspecified)
        for device in (deviceDiscoverySession?.devices)! {
            if device.position == AVCaptureDevicePosition.back {
                startCapture(device: device)
            }
        }
    }
    
    func startCapture(device: AVCaptureDevice) {
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

}

