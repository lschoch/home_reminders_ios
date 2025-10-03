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
        func pickerValueDidChange(inCell cell: CustomCell, withText text: String)
        func customCellFrequencyAlert(_ cell: CustomCell)
        func datePickerValueDidChange(inCell cell: CustomCell, withDate date: Date)
    }

protocol PickerCellDelegate: AnyObject {
    func picker(cell: CustomCell, didSelectRow row: Int)
    func didTapElementInCell(_ cell: CustomCell)
}

protocol TextCalculationDelegate: AnyObject {
    func didCalculateText(_ text: String)
}

class CustomCell: UITableViewCell {
    @IBOutlet weak var customCell: UIView!

    @IBOutlet weak var noteField: UITextField!
    @IBOutlet weak var periodField: UITextField!
    @IBOutlet weak var frequencyField: UITextField!
    @IBOutlet weak var descriptionField: UITextField!
    @IBOutlet weak var dateNextField: UITextField!
    @IBOutlet weak var dateLastField: UITextField!
    
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var picker: UIPickerView!
    
    weak var customCellDelegate: CustomCellDelegate?
    weak var pickerDelegate: PickerCellDelegate?
    weak var textCalculationDelegate: TextCalculationDelegate?
    
    var pickerData: [String] = []
    var pickerDataIndex: Int = -1
    var selectedDate: Date?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Shift description field text left (so that it's not at the very edge of the container)
        let paddingView1: UIView = UIView(frame: CGRect(x: 0, y: 0, width: 2, height: 20))
        let paddingView2: UIView = UIView(frame: CGRect(x: 0, y: 0, width: 2, height: 20))
        descriptionField.leftView = paddingView1;
        descriptionField.leftViewMode = .always;
        noteField.leftView = paddingView2;
        noteField.leftViewMode = .always;
        
//        descriptionField.borderStyle = .bezell (bezel borderStyle not compatible with corner radius)
        descriptionField.layer.cornerRadius = 8.0
        descriptionField.layer.borderWidth = 1.0
        descriptionField.clipsToBounds = true
        
//        frequencyField.borderStyle = .bezel
        frequencyField.layer.cornerRadius = 8.0
        frequencyField.layer.borderWidth = 1.0
        frequencyField.clipsToBounds = true
        
//        noteField.borderStyle = .bezel
        noteField.layer.cornerRadius = 8.0
        noteField.layer.borderWidth = 1.0
        noteField.clipsToBounds = true
        
        //        frequencyField.keyboardType = .numberPad
        //
        //        // Create "Done" item in keyboard
        //        let toolbar = UIToolbar()
        //        toolbar.sizeToFit() // Adjusts the toolbar's size to fit its content
        //        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: nil, action: #selector(UITextField.resignFirstResponder))
        //        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        //        toolbar.items = [flexibleSpace, doneButton]
        //        frequencyField.inputAccessoryView = toolbar
        
        descriptionField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
//        dateNextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        frequencyField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        noteField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
//        dateNextField.addTarget(self, action: #selector(calculateAndSendText), for: .editingChanged)
        frequencyField.addTarget(self, action: #selector(calculateAndSendText), for: .editingChanged)
        
        // Create and set the custom selection background view
        let customSelectedBackgroundView = UIView()
        customSelectedBackgroundView.backgroundColor = .brandLightYellow
        selectedBackgroundView = customSelectedBackgroundView
        
        picker.delegate = self
        picker.dataSource = self
        pickerData = ["one-time", "days", "weeks", "months", "years"]
        
        descriptionField.delegate = self
        frequencyField.delegate = self
        noteField.delegate = self
        
        // Configure the date picker
        datePicker.datePickerMode = .date // Can also be .time, .dateAndTime, .countDownTimer
        datePicker.preferredDatePickerStyle = .compact // Or .wheels, .compact, .inline (iOS 14+)
        datePicker.tintColor = .black
        
        // Add a target to dismiss calendar when date is selected
        datePicker.addTarget(self, action: #selector(datePickerTapped), for: .primaryActionTriggered)
        
        // Add a target to respond to datePicker value changes
        datePicker.addTarget(self, action: #selector(datePickerValueChanged(_:)), for: .valueChanged)
        
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
            super.setSelected(selected, animated: animated)
            picker.isUserInteractionEnabled = selected
            picker.alpha = selected ? 1.0 : 0.5
        }
    
    @objc func datePickerTapped() {
            self.datePicker.preferredDatePickerStyle = .wheels
            self.datePicker.preferredDatePickerStyle = .automatic
        }
    
    @objc func datePickerValueChanged(_ sender: UIDatePicker) {
        selectedDate = sender.date
        let pickerRow = picker.selectedRow(inComponent: 0)
        // Perform actions with the selected date, e.g., update a label, send data to another component, etc.
        let calculatedDateNext = calculateDateNext(row: pickerRow)
        dateNextField.text = calculatedDateNext
        customCellDelegate?.datePickerValueDidChange(inCell: self, withDate: selectedDate ?? Date())
        textCalculationDelegate?.didCalculateText(calculatedDateNext)
    }
    
    @IBAction func descriptionTapped(_ sender: UITextField) {
        customCellDelegate?.didTapElementInCell(self)   
    }
    
    @IBAction func dateLastTapped(_ sender: UIDatePicker) {
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
    
    @objc private func calculateAndSendText() {
        let calculatedDateNext = calculateDateNext(row: pickerDataIndex)
        // Call the delegate
        textCalculationDelegate?.didCalculateText(calculatedDateNext)
    }
    
    // Calculate next date as a function of last date, frequency and period
    func calculateDateNext(row: Int) -> String {
        var nextDate: Date
        
        let period = pickerData[picker.selectedRow(inComponent: 0)]
        let lastDate = datePicker.date
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
        // The parameters named row and component represent what was selected.
        
        // Call didTapElementInCell to select the tableView row which sets tableRow (needed downstream).
        customCellDelegate?.didTapElementInCell(self)
        pickerDataIndex = row
        
        // If period is "one-time", set frequency to zero and notify RemindersViewController of the change.
        if picker.selectedRow(inComponent: 0) == 0, frequencyField.text != "0" {
            frequencyField.text = "0"
            frequencyField.resignFirstResponder()
            textFieldDidChange(frequencyField)
        }
        
        selectedDate = datePicker.date
        let calculatedDateNext = calculateDateNext(row: pickerDataIndex)
        customCellDelegate?.pickerValueDidChange(inCell: self, withText: calculatedDateNext)
        pickerDelegate?.picker(cell: self, didSelectRow: row)
        pickerDelegate?.didTapElementInCell(self)
    }
}

//MARK: - UITextFieldDelegate Implementation
extension CustomCell: UITextFieldDelegate {
    @objc func textFieldDidChange(_ textField: UITextField) {
        // If this is the frequency text field, update the date next calculation and send it to RemindersViewController.
        // (Description and note fields have no effect on date next.)
        let pickerIndex = picker.selectedRow(inComponent: 0)
        let calculatedDateNext = calculateDateNext(row: pickerIndex)
        if textField.tag == 4 {
            dateNextField.text = calculatedDateNext
        }
        
        // Send calculatedDateNext to RemindersViewController.
        textCalculationDelegate?.didCalculateText(calculatedDateNext)
        
        // If period is "one-time", set frequency to zero and trigger alert.
        if picker.selectedRow(inComponent: 0) == 0 {
            frequencyField.text = "0"
            // Trigger frequency alert if the call to this function is from the frequency field.
            if textField.tag == 4 {
                customCellDelegate?.customCellFrequencyAlert(self)
            }
        }
        // Send changed textField to RemindersViewController
        customCellDelegate?.customCell(self, didUpdateText: textField)
    }
    
    // Dismiss keyboard when "Return" key is tapped.
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
