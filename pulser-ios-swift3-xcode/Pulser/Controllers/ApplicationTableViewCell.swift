
//
//  ApplicationTableViewCell.swift
//  Pulser
//
//  Created by Tom Gardiner on 13/03/2017.
//  Copyright © 2017 TomboFry. All rights reserved.
//

import UIKit

class ApplicationTableViewCell: UITableViewCell {

	@IBOutlet weak var imgAppImage: UIImageView!
	@IBOutlet weak var lblAppName: UILabel!
	@IBOutlet weak var lblLatestUpdate: UILabel!
	
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
