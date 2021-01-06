//
//  CameraView.swift
//  Camera
//
//  Created by HD Mavani on 07/04/20.
//  Copyright © 2020 HD Mavani. All rights reserved.
//

import UIKit
import AVFoundation

var lastController: UIViewController!

//------------------------------------------------------------------------------------------------------------------------------------------------
class CameraView: UIViewController {

	@IBOutlet var previewView: UIView!
	@IBOutlet var imagePotoPreview: UIImageView!
	@IBOutlet var labelPhotoCount: UILabel!
	@IBOutlet var buttonDone: UIButton!

	private var session: AVCaptureSession!
	private var photoOutput: AVCapturePhotoOutput!
	private var videoPreviewLayer: AVCaptureVideoPreviewLayer!
	private var images: [UIImage] = []

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

		guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
		let videoDeviceInput: AVCaptureDeviceInput
		do {
			videoDeviceInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
		} catch let error as NSError {
			alert(error.localizedDescription)
			print(error.localizedDescription)
			return
		}

		if session.canAddInput(videoDeviceInput) {
			session.addInput(videoDeviceInput)
		} else {
			alert("Couldn't add video device input to the session.")
			print("Couldn't add video device input to the session.")
			return
		}

		photoOutput = AVCapturePhotoOutput()
		if session.canAddOutput(photoOutput) {
			session.addOutput(photoOutput)
		} else {
			alert("Could not add photo output to the session")
			print("Could not add photo output to the session")
			return
		}

		videoPreviewLayer = AVCaptureVideoPreviewLayer(session: session)
		videoPreviewLayer.frame = previewView.bounds
		videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
		previewView.layer.sublayers?.forEach({ (layer) in
			layer.removeFromSuperlayer()
		})
		previewView.layer.addSublayer(videoPreviewLayer!)
		session.startRunning()
	}

	func alert(_ message: String) {
		let alertController = UIAlertController(title: "Camera", message: message, preferredStyle: .alert)
		let actionOk = UIAlertAction(title: "OK", style: .cancel, handler: nil)
		alertController.addAction(actionOk)
		self.present(alertController, animated: true, completion: nil)
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
