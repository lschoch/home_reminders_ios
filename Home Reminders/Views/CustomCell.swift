//
//  CustomCell.swift
//  Home Reminders
//
//  Created by Lawrence H. Schoch on 9/13/25.
//

import UIKit

class CustomCell: UITableViewCell {
    @IBOutlet weak var customCell: UIView!
    
    @IBOutlet weak var noteField: UITextField!
    @IBOutlet weak var periodField: UITextField!
    @IBOutlet weak var frequencyField: UITextField!
    @IBOutlet weak var descriptionField: UITextField!
    @IBOutlet weak var dateNextField: UITextField!
    @IBOutlet weak var dateLastField: UITextField!
    
    @IBOutlet weak var dropDownButton: UIButton!
    
    let periodPicker = ViewController()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Shift description field text left (so that it's not at the very edge of the container)
        let paddingView1: UIView = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        let paddingView2: UIView = UIView(frame: CGRect(x: 0, y: 0, width: 25, height: 20))
        descriptionField.leftView = paddingView1;
        descriptionField.leftViewMode = .always;
        noteField.leftView = paddingView2;
        noteField.leftViewMode = .always;
    }

    @IBAction func dropDownButtonTapped(_ sender: UIButton) {
        periodPicker.dropdownTableView?.isHidden.toggle()
    }
    
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
