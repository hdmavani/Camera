//
//  ImagesView.swift
//  Camera
//
//  Created by HD Mavani on 07/04/20.
//  Copyright © 2020 HD Mavani. All rights reserved.
//

import UIKit

//------------------------------------------------------------------------------------------------------------------------------------------------
class ImagesView: UIViewController {

	@IBOutlet var collectionView: UICollectionView!

	var images: [UIImage] = []

	//---------------------------------------------------------------------------------------------------------------------------------------------
	override func viewDidLoad() {
		
		super.viewDidLoad()
		title = "images"
		navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(actionDone(_:)))
		collectionView.register(UINib(nibName: "ImagesCell", bundle: Bundle.main), forCellWithReuseIdentifier: "ImagesCell")
	}

	// MARK: - User actions
	//---------------------------------------------------------------------------------------------------------------------------------------------
	@objc func actionDone(_ sender: UIBarButtonItem) {
		dismiss(animated: true)
	}
}

// MARK: - UICollectionViewDataSource
//-------------------------------------------------------------------------------------------------------------------------------------------------
extension ImagesView: UICollectionViewDataSource {

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func numberOfSections(in collectionView: UICollectionView) -> Int {

		return 1
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {

		return images.count
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImagesCell", for: indexPath) as! ImagesCell
		cell.imageView.image = images[indexPath.row]
		return cell
	}
}

// MARK: - UICollectionViewDelegate
//-------------------------------------------------------------------------------------------------------------------------------------------------
extension ImagesView: UICollectionViewDelegate {

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

		print(#function)
	}
}

// MARK: - UICollectionViewDelegateFlowLayout
//-------------------------------------------------------------------------------------------------------------------------------------------------
extension ImagesView: UICollectionViewDelegateFlowLayout {

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

		let width = (collectionView.frame.size.width-4)/4
		return CGSize(width: width, height: width)
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {

		return 1
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {

		return 1
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {

		return UIEdgeInsets.zero
	}
}
