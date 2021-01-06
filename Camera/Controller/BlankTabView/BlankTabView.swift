//
//  BlankTabView.swift
//  Camera
//
//  Created by HD Mavani on 07/04/20.
//  Copyright © 2020 HD Mavani. All rights reserved.
//

import UIKit

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
}
