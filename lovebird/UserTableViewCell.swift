//
//  UserTableViewCell.swift
//  lovebird
//
//  Created by Junyu Wang on 4/7/17.
//  Copyright © 2017 Junyu Wang. All rights reserved.
//

import UIKit
import TextFieldEffects

class UserTableViewCell: UITableViewCell {

    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var userDisplayNameLabel: UILabel!
    @IBOutlet weak var functionButton: UIButton!
    @IBOutlet weak var userStatusTextField: YoshikoTextField!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        functionButton.titleLabel?.numberOfLines = 0
        functionButton.titleLabel?.lineBreakMode = .byWordWrapping
        profileImageView.layer.cornerRadius = 30
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setUpCell(_ user: User) {
        userDisplayNameLabel.text = user.name
        if let status =  user.status {
            userStatusTextField.text = status
        }
    }
}
