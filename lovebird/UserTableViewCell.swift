//
//  UserTableViewCell.swift
//  lovebird
//
//  Created by Junyu Wang on 4/7/17.
//  Copyright © 2017 Junyu Wang. All rights reserved.
//

import UIKit

class UserTableViewCell: UITableViewCell {

    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var userDisplayNameLabel: UILabel!
    @IBOutlet weak var userStatusLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setUpCell(_ user: User) {
        userDisplayNameLabel.text = user.name
        if let status =  user.status {
            userStatusLabel.text = status
        }
    }

    @IBAction func updateStatusButtonWasPressed(_ sender: UIButton) {
    }
}
