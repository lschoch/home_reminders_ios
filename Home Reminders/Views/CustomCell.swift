//
//  CustomCell.swift
//  Home Reminders
//
//  Created by Lawrence H. Schoch on 9/13/25.
//

import UIKit

protocol CustomCellDelegate: AnyObject {
        func customCell(_ cell: CustomCell, didUpdateText textField: UITextField?)
        func didTapElementInCell(_ cell: CustomCell)
    }

protocol PickerCellDelegate: AnyObject {
    func picker(cell: CustomCell, didSelectRow row: Int)
    func didTapElementInCell(_ cell: CustomCell)
}

class CustomCell: UITableViewCell {
    @IBOutlet weak var customCell: UIView!
    
    @IBOutlet weak var noteField: UITextField!
    @IBOutlet weak var periodField: UITextField!
    @IBOutlet weak var frequencyField: UITextField!
    @IBOutlet weak var descriptionField: UITextField!
    @IBOutlet weak var dateNextField: UITextField!
    @IBOutlet weak var dateLastField: UITextField!
    
    @IBOutlet weak var picker: UIPickerView!
    
    weak var customCellDelegate: CustomCellDelegate?
    weak var pickerDelegate: PickerCellDelegate?
    
    var pickerData: [String] = []
    var pickerDataIndex: Int = 0
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Shift description field text left (so that it's not at the very edge of the container)
        let paddingView1: UIView = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        let paddingView2: UIView = UIView(frame: CGRect(x: 0, y: 0, width: 25, height: 20))
        descriptionField.leftView = paddingView1;
        descriptionField.leftViewMode = .always;
        noteField.leftView = paddingView2;
        noteField.leftViewMode = .always;
        
        descriptionField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        dateLastField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        dateNextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        frequencyField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        noteField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        
        picker.delegate = self
        picker.dataSource = self
        pickerData = ["one-time", "days", "weeks", "months", "years"]
        
    }
    
    @IBAction func descriptionTapped(_ sender: UITextField) {
        customCellDelegate?.didTapElementInCell(self)   
    }
    
    @IBAction func dateLastTapped(_ sender: UITextField) {
        customCellDelegate?.didTapElementInCell(self)
    }
    
    @IBAction func dateNextTapped(_ sender: UITextField) {
        customCellDelegate?.didTapElementInCell(self)
    }
    
    @IBAction func frequencyTapped(_ sender: UITextField) {
        customCellDelegate?.didTapElementInCell(self)
    }
    
    @IBAction func noteTapped(_ sender: UITextField) {
        customCellDelegate?.didTapElementInCell(self)
    }
    
    // Calculate next date as a function of last date, frequency and period
    func calculateDateNext(row: Int) -> String {
        var nextDate: Date
        
        let period = pickerData[picker.selectedRow(inComponent: 0)]
        
        guard let lastDate = DF.dateFormatter.date(from: dateLastField.text!) else { print("Error: Could not parse lastDate."); return ""}
        let lastDateString = DF.dateFormatter.string(from: lastDate)
        
        // If frequency is nil or zero, set return last date
        guard let frequency = frequencyField.text! as String? else { return lastDateString }
        if frequency == "0" { return lastDateString }
        
        guard let frequencyInt = Int(frequency) else { return lastDateString }
        
        switch period {
        case "one-time":
            return lastDateString
        case "days":
            nextDate = Calendar.current.date(byAdding: .day, value: frequencyInt, to: lastDate)!
        case "weeks":
            nextDate = Calendar.current.date(byAdding: .day, value: frequencyInt * 7, to: lastDate)!
        case "months":
            nextDate = Calendar.current.date(byAdding: .month, value: frequencyInt, to: lastDate)!
        case "years":
            nextDate = Calendar.current.date(byAdding: .year, value: frequencyInt, to: lastDate)!
        default:
            nextDate = lastDate
        }
        return DF.dateFormatter.string(from: nextDate)
    }
    
    // To change fonts on picker menu
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var label: UILabel
        if let reusedLabel = view as? UILabel {
            label = reusedLabel
        } else {
            label = UILabel()
        }

        label.font = UIFont(name: "Helvetica Neue", size: 16) // Customize font name and size
        label.text = pickerData[row]
        label.textAlignment = .center

        return label
    }
    
}

//MARK: - UIPickerViewDataSource Implementation
extension CustomCell: UIPickerViewDataSource {
    // Number of columns of data
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // The number of rows of data
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count
    }
    
    // The data to return for the row and component (column) that's being passed in
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerData[row]
    }
}

//MARK: - UIPickerViewDelegate Implementation
extension CustomCell: UIPickerViewDelegate {
    // Capture the picker view selection
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        // This method is triggered whenever the user makes a change to the picker selection.
        // The parameter named row and component represents what was selected.
        pickerDataIndex = row
        pickerDelegate?.picker(cell: self, didSelectRow: row)
        pickerDelegate?.didTapElementInCell(self)
    }
}

//MARK: - UITextFieldDelegate Implementation
extension CustomCell: UITextFieldDelegate {
    @objc func textFieldDidChange(_ textField: UITextField) {
        // Recalculate next date when there is a change in last date or frequency
        dateNextField.text = calculateDateNext(row: pickerDataIndex)
        customCellDelegate?.customCell(self, didUpdateText: textField)
    }
}
