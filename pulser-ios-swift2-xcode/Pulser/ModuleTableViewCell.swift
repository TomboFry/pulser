//
//  ModuleTableViewCell.swift
//  Pulser
//
//  Created by Tom Gardiner on 06/11/2016.
//  Copyright © 2016 TomboFry. All rights reserved.
//

import UIKit

class ModuleTableViewCell: UITableViewCell {
	
	// MARK: Properties
	@IBOutlet weak var nameLabel: UILabel!
	@IBOutlet weak var txtLabel: UILabel!
	@IBOutlet weak var valueProgress: UIProgressView!
	@IBOutlet weak var stateImage: UIImageView!
	@IBOutlet weak var urgencyLabel: UILabel!

	override func awakeFromNib() {
		super.awakeFromNib()
		// Initialization code
	}

	override func setSelected(selected: Bool, animated: Bool) {
		super.setSelected(selected, animated: animated)

		// Configure the view for the selected state
	}

}
