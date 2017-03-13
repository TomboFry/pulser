//
//  ModuleTableCell.swift
//  Pulser
//
//  Created by Tom Gardiner on 09/03/2017.
//  Copyright © 2017 TomboFry. All rights reserved.
//

import UIKit

class ModuleTableCell: UITableViewCell {

	@IBOutlet weak var imgState: UIImageView!
	@IBOutlet weak var prgValue: UIProgressView!
	@IBOutlet weak var lblUpdateText: UITextView!
	
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
