//
//  BlankTabView.swift
//  Camera
//
//  Created by HD Mavani on 07/04/20.
//  Copyright © 2020 HD Mavani. All rights reserved.
//

import UIKit
import Vision
import VisionKit

//------------------------------------------------------------------------------------------------------------------------------------------------
class BlankTabView: UIViewController {

	//---------------------------------------------------------------------------------------------------------------------------------------------
	convenience init(title: String, image: String) {
		self.init()
		tabBarItem.title = title
		tabBarItem.image = UIImage(systemName: image)
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	override func viewDidLoad() {

		super.viewDidLoad()
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	override func viewWillAppear(_ animated: Bool) {

		super.viewWillAppear(true)
		lastController = self
	}
	
	@IBAction func scan(_ sender: UIControl) {
		let documentCameraVC = VNDocumentCameraViewController()
		documentCameraVC.delegate = self
		present(documentCameraVC, animated: true)
	}
}

extension BlankTabView: VNDocumentCameraViewControllerDelegate {
	
	func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {

		controller.dismiss(animated: true)
		DispatchQueue.main.async {
		//DispatchQueue.global(qos: .userInitiated).async {
			
			var images: [UIImage] = []
			for pageNumber in 0 ..< scan.pageCount {
				let image = scan.imageOfPage(at: pageNumber)
				images.append(image)
			}
			
			let imagesView = ImagesView()
			imagesView.images = images
			let navVC = UINavigationController(rootViewController: imagesView)
			self.present(navVC, animated: true)
		}
	}
}
