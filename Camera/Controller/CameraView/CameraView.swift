//
//  CameraView.swift
//  Camera
//
//  Created by HD Mavani on 07/04/20.
//  Copyright © 2020 HD Mavani. All rights reserved.
//

import UIKit
import Foundation
import Vision
import AVFoundation
import AudioToolbox

var lastController: UIViewController!

//------------------------------------------------------------------------------------------------------------------------------------------------
class CameraView: UIViewController {

	@IBOutlet var overlayView: UIView!
	@IBOutlet var previewView: UIView!
	@IBOutlet var imagePotoPreview: UIImageView!
	@IBOutlet var labelPhotoCount: UILabel!
	@IBOutlet var buttonDone: UIButton!
	
	private var resetTimer: Timer?
	private var boundingBox = CAShapeLayer()
	private var session: AVCaptureSession!
	private var device: AVCaptureDevice!
	private var photoOutput: AVCapturePhotoOutput!
	private var videoOutput: AVCaptureVideoDataOutput!
	private var metadataOutput: AVCaptureMetadataOutput!
	private var videoPreviewLayer: AVCaptureVideoPreviewLayer!
	private var images: [UIImage] = []
	private var counter = 0
	private var code = ""
	
	
	private lazy var detectBarcodeRequest: VNDetectBarcodesRequest = {
		return VNDetectBarcodesRequest(completionHandler: { (request, error) in
			guard error == nil else { return }
			self.processClassification(for: request)
		})
	}()
	
	private func processClassification(for request: VNRequest) {
		DispatchQueue.main.async {
			if let bestResult = request.results?.first as? VNBarcodeObservation,
			   let payload = bestResult.payloadStringValue {
				if bestResult.symbology == .QR {
					guard let data = payload.data(using: .utf8) else { return }
					print("myData: ", data)
				}
			}
		}
	}
	

	//---------------------------------------------------------------------------------------------------------------------------------------------
	convenience init(title: String, image: String) {
		self.init()
		tabBarItem.title = title
		tabBarItem.image = UIImage(systemName: image)
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	override func viewDidLoad() {

		super.viewDidLoad()

		buttonDone.layer.borderWidth = 1
		buttonDone.layer.borderColor = UIColor.white.cgColor

		images.removeAll()
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	override func viewWillAppear(_ animated: Bool) {

		super.viewWillAppear(animated)
		tabBarController?.tabBar.isHidden.toggle()
		requestCameraAccess()
		updateUI()
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	override func viewDidAppear(_ animated: Bool) {

		super.viewDidAppear(animated)
		if videoPreviewLayer != nil {
			videoPreviewLayer.frame = previewView.bounds
		}
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	override func viewWillDisappear(_ animated: Bool) {

		super.viewWillDisappear(animated)
		if (session.isRunning) {
			session.stopRunning()
		}
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func updateUI() {
		counter = 0
		code = ""
		imagePotoPreview.image = images.last
		labelPhotoCount.text = "\(images.count) Photos"
		buttonDone.isHidden = (images.count == 0)
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func requestCameraAccess() {
		switch AVCaptureDevice.authorizationStatus(for: .video) {
			case .authorized:
				print("The user has previously granted access to the camera.")
				configCameraView()
				break

			case .notDetermined:
				print("we can't determine the status of camera  permission.")
				AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
					DispatchQueue.main.async {
						if !granted {
							self.showPermissionAlert()
						}
						self.configCameraView()
					}
				})

			case .restricted:
				print("The user has previously restricted for the camera.")
				showPermissionAlert()
				break

			case .denied:
				print("The user has previously denied for the camera.")
				showPermissionAlert()
				break

			default:
				break
		}
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func showPermissionAlert() {
		let alertController = UIAlertController(title: "Camera", message: "We doesn't have permission to use the camera, please change privacy settings", preferredStyle: .alert)
		let actionOk = UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"), style: .cancel, handler: nil)
		let actionSetting = UIAlertAction(title: NSLocalizedString("Settings", comment: "Alert button to open Settings"), style: .default, handler: { _ in
			UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
		})
		alertController.addAction(actionOk)
		alertController.addAction(actionSetting)

		self.present(alertController, animated: true, completion: nil)
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func configCameraView() {
		session = AVCaptureSession()
		session.sessionPreset = AVCaptureSession.Preset.photo
		
		
		device = AVCaptureDevice.default(for: .video)
		let videoDeviceInput: AVCaptureDeviceInput
		do {
			videoDeviceInput = try AVCaptureDeviceInput(device: device)
			
			if session.canAddInput(videoDeviceInput) {
				session.addInput(videoDeviceInput)
			} else {
				return alert("Couldn't add video device input to the session.")
			}
		} catch let error as NSError {
			return alert(error.localizedDescription)
		}
		
		/*
		/// photoOutput
		photoOutput = AVCapturePhotoOutput()
		if session.canAddOutput(photoOutput) {
			session.addOutput(photoOutput)
		} else {
			return alert("Could not add photo output to the session")
		} // */
		
		/*
		/// videoOutput
		videoOutput = AVCaptureVideoDataOutput()
		if session.canAddOutput(videoOutput) {
			session.addOutput(videoOutput)
			videoOutput.alwaysDiscardsLateVideoFrames = true
			videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue.main)
			videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable as! String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)]
		} else {
			return alert("Could not add photo output to the session")
		} // */
		
		
		/// metadataOutput
		
		metadataOutput = AVCaptureMetadataOutput()
		if (session.canAddOutput(metadataOutput)) {
			session.addOutput(metadataOutput)
			// metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
			metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue(label: "com.hdmavani.scanner", qos: .default, attributes: .concurrent, autoreleaseFrequency: .inherit, target: DispatchQueue.main))
			//metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.global())
			metadataOutput.metadataObjectTypes = [.humanBody, .catBody, .dogBody, .salientObject, .face, .upce, .code39, .code39Mod43, .ean13, .ean8, .code93, .code128, .pdf417, .qr, .aztec, .interleaved2of5, .itf14, .dataMatrix]
		} else {
			return alert("Could not add photo output to the session")
		} // */
		
		/*
		var resX:Int32 = 640
		var resY:Int32 = 480
		if session.canSetSessionPreset(AVCaptureSession.Preset.hd4K3840x2160) {
			session.sessionPreset = AVCaptureSession.Preset.hd4K3840x2160;
			resX = 3840
			resY = 2160
		} else if session.canSetSessionPreset(AVCaptureSession.Preset.hd1920x1080) {
			session.sessionPreset = AVCaptureSession.Preset.hd1920x1080;
			resX = 1920
			resY = 1080
		} else if session.canSetSessionPreset(AVCaptureSession.Preset.hd1280x720) {
			session.sessionPreset = AVCaptureSession.Preset.hd1280x720;
			resX = 1280
			resY = 720
		} else if session.canSetSessionPreset(AVCaptureSession.Preset.vga640x480) {
			session.sessionPreset = AVCaptureSession.Preset.vga640x480;
		} else {
			session.sessionPreset = AVCaptureSession.Preset.photo
		}
		
		
		for vFormat in self.device.formats {
			let description = vFormat.formatDescription
			let rates = vFormat.videoSupportedFrameRateRanges[0]
			let maxrate = rates.maxFrameRate
			let minrate = rates.minFrameRate

			let dimensions: CMVideoDimensions = CMVideoFormatDescriptionGetDimensions(description);
			if maxrate > 59 && Int32(CMFormatDescriptionGetMediaSubType(description)) == Int32(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange) && dimensions.width == resX && dimensions.height == resY {
				do{
					try self.device.lockForConfiguration()
					self.device.activeFormat = vFormat
					self.device.activeVideoMinFrameDuration = CMTimeMake(value: Int64(10), timescale: Int32(minrate * 10))
					self.device.activeVideoMaxFrameDuration = CMTimeMake(value: Int64(10), timescale: Int32(600))
					self.device.unlockForConfiguration()
				}catch _{}
			}
		} // */

		videoPreviewLayer = AVCaptureVideoPreviewLayer(session: session)
		videoPreviewLayer.frame = previewView.bounds
		videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspect
		previewView.layer.sublayers?.forEach({ (layer) in
			layer.removeFromSuperlayer()
		})
		previewView.layer.addSublayer(videoPreviewLayer!)
		session.startRunning()
		setupBoundingBox()
	}
	
	//---------------------------------------------------------------------------------------------------------------------------------------------
	private func setupBoundingBox() {
		boundingBox.frame = previewView.layer.bounds
		boundingBox.strokeColor = UIColor.green.cgColor
		boundingBox.lineWidth = 4.0
		boundingBox.fillColor = UIColor.clear.cgColor
		
		previewView.layer.addSublayer(boundingBox)
	}
	
	//---------------------------------------------------------------------------------------------------------------------------------------------
	fileprivate func updateBoundingBox(_ points: [CGPoint]) {
		guard let firstPoint = points.first else {
			return
		}
		
		let path = UIBezierPath()
		path.move(to: firstPoint)
		
		var newPoints = points
		newPoints.removeFirst()
		newPoints.append(firstPoint)
		
		newPoints.forEach { path.addLine(to: $0) }
		
		boundingBox.path = path.cgPath
		boundingBox.isHidden = false
	}
	
	//---------------------------------------------------------------------------------------------------------------------------------------------
	fileprivate func hideBoundingBox(after: Double) {
		resetTimer?.invalidate()
		resetTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval() + after, repeats: false) { [unowned self] (timer) in
			self.boundingBox.isHidden = true
		}
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func alert(_ message: String) {
		print(message)
		let alertController = UIAlertController(title: "Camera", message: message, preferredStyle: .alert)
		let actionOk = UIAlertAction(title: "OK", style: .cancel, handler: nil)
		alertController.addAction(actionOk)
		self.present(alertController, animated: true, completion: nil)
	}
	
	//---------------------------------------------------------------------------------------------------------------------------------------------
	func playSystemSound() {
			DispatchQueue.global().async {
				let url = Bundle.main.url(forResource: "scanSuccess.wav", withExtension: nil)
				var soundID: SystemSoundID = 8787
				AudioServicesCreateSystemSoundID(url! as CFURL, &soundID)
				AudioServicesPlaySystemSound(soundID)
			}
		}

	// MARK: - User actions
	//---------------------------------------------------------------------------------------------------------------------------------------------
	@IBAction func actionCancel(_ sender: UIBarButtonItem) {
		images.removeAll()
		for vc in self.tabBarController!.viewControllers! {
			if vc == lastController {
				tabBarController?.tabBar.isHidden.toggle()
				self.tabBarController?.selectedViewController = lastController
			}
		}
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	@IBAction func actionTakePhoto(_ sender: UIButton) {
		if let photoOutputConnection = self.photoOutput.connection(with: .video) {
			photoOutputConnection.videoOrientation = videoPreviewLayer.connection!.videoOrientation
			photoOutputConnection.videoOrientation = .portrait
		}
		let photoSettings = AVCapturePhotoSettings()

		DispatchQueue.main.async {
			self.previewView.alpha = 0
			UIView.animate(withDuration: 0.25) {
				self.previewView.alpha = 1
				self.view.layoutSubviews()
			}
		}
		self.photoOutput.capturePhoto(with: photoSettings, delegate: self)
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	@IBAction func actionDone(_ sender: UIButton) {
		let imagesView = ImagesView()
		imagesView.images = images
		let navVC = UINavigationController(rootViewController: imagesView)
		present(navVC, animated: true)
	}
}

// MARK: - AVCapturePhotoCaptureDelegate
//-------------------------------------------------------------------------------------------------------------------------------------------------
extension CameraView: AVCapturePhotoCaptureDelegate {

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
		
		guard let imageData = photo.fileDataRepresentation(),
			  let image = UIImage(data: imageData) else { return }
		
		images.append(image)
		updateUI()
	}
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate
//-------------------------------------------------------------------------------------------------------------------------------------------------
extension CameraView: AVCaptureMetadataOutputObjectsDelegate {
	
	//---------------------------------------------------------------------------------------------------------------------------------------------
	func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
		
		if let metadataObject = metadataObjects.first {
			// for metadataObject in metadataObjects {
			
			guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
			guard let stringValue = readableObject.stringValue else { return }
			
			DispatchQueue.global().async {
				if let transformedObject = self.videoPreviewLayer.transformedMetadataObject(for: readableObject) as? AVMetadataMachineReadableCodeObject {
					DispatchQueue.main.async {
						self.updateBoundingBox(transformedObject.corners)
						self.hideBoundingBox(after: 0.25)
					}
				}
			}
			
			if self.code == stringValue { return }
			self.code = stringValue
			self.counter += 1
			print(Date(), self.counter, "\t - ", stringValue)
		}
	}
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate
//-------------------------------------------------------------------------------------------------------------------------------------------------
extension CameraView: AVCaptureVideoDataOutputSampleBufferDelegate {
	
	//---------------------------------------------------------------------------------------------------------------------------------------------
	func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
		
		guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
		
		var requestOptions: [VNImageOption : Any] = [:]
		if let camData = CMGetAttachment(sampleBuffer, key: kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, attachmentModeOut: nil) {
			requestOptions = [.cameraIntrinsics : camData]
		}
		
		let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: requestOptions)
		
		let detectQRCode = VNDetectBarcodesRequest(completionHandler: { (request, error) in
			guard error == nil else { return }
			DispatchQueue.main.async {
				if let bestResult = request.results?.first as? VNBarcodeObservation,
				   let payload = bestResult.payloadStringValue {
					if bestResult.symbology == .QR {
						guard let data = payload.data(using: .utf8) else { return }
						let stringValue = String(decoding: data, as: UTF8.self)
						if self.code == stringValue { return }
						self.code = stringValue
						self.counter += 1
						print(Date(), self.counter, "\t - ", stringValue)
					}
				}
			}
		})
		
		try? imageRequestHandler.perform([detectQRCode])
		
		return;
	}
	
}
