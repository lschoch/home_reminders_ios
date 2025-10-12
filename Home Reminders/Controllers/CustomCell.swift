//
//  CustomCell.swift
//  Home Reminders
//
//  Created by Lawrence H. Schoch on 9/13/25.
//

import UIKit

protocol CustomCellDelegate: AnyObject {
    func customCell(_ cell: CustomCell, didUpdateText textField: UITextField?)
    func pickerValueDidChange(inCell cell: CustomCell, withText text: String)
    func customCellFrequencyAlert(_ cell: CustomCell)
    func datePickerValueDidChange(inCell cell: CustomCell, withDate date: Date)
    func customCell(_ cell: CustomCell, didEndEditingWithField field: UITextField)
    func customCell(_ cell: CustomCell, didStartEditingWithField field: UITextField)
}

protocol PickerCellDelegate: AnyObject {
    func picker(cell: CustomCell, didSelectRow row: Int)
}

protocol TextCalculationDelegate: AnyObject {
    func didCalculateText(_ text: String)
}

class CustomCell: UITableViewCell {
    @IBOutlet weak var customCell: UIView!

    @IBOutlet weak var noteField: UITextField!
    @IBOutlet weak var frequencyField: UITextField!
    @IBOutlet weak var descriptionField: UITextField!
    @IBOutlet weak var dateNextField: UITextField!
    @IBOutlet weak var dateLastField: UITextField!
    
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var picker: UIPickerView!
    
    @IBOutlet weak var arrowDown: UIImageView!
    
    weak var customCellDelegate: CustomCellDelegate?
    weak var pickerDelegate: PickerCellDelegate?
    weak var textCalculationDelegate: TextCalculationDelegate?
    weak var delegate: CustomCellDelegate?
    
    var pickerData: [String] = []
    var pickerDataIndex: Int = -1
    var selectedDate: Date?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.layer.borderColor = UIColor.black.cgColor
        self.layer.borderWidth = 1.0
        self.layer.cornerRadius = 8.0
        
        
        // Shift text field text right (so that it's not at the very edge of the container)
        let paddingView1: UIView = UIView(frame: CGRect(x: 0, y: 0, width: 6, height: 20))
        let paddingView2: UIView = UIView(frame: CGRect(x: 0, y: 0, width: 6, height: 20))
        descriptionField.leftView = paddingView1;
        descriptionField.leftViewMode = .always;
        noteField.leftView = paddingView2;
        noteField.leftViewMode = .always;
        
        descriptionField.borderStyle = .bezel // (bezel borderStyle not compatible with corner radius)
        descriptionField.layer.cornerRadius = 8.0
        descriptionField.layer.borderWidth = 1.0
        descriptionField.clipsToBounds = true
        
        frequencyField.borderStyle = .bezel
        frequencyField.layer.cornerRadius = 8.0
        frequencyField.layer.borderWidth = 1.0
        frequencyField.clipsToBounds = true
        
        noteField.borderStyle = .bezel
        noteField.layer.cornerRadius = 8.0
        noteField.layer.borderWidth = 1.0
        noteField.clipsToBounds = true
        
        dateNextField.textColor = .black
        noteField.backgroundColor = .white
        
        frequencyField.keyboardType = .numberPad
        
        // Create "Done" item in keyboard
        addDoneButtonOnNumpad(textField: frequencyField)
        
        descriptionField.addTarget(self, action: #selector(textFieldDidBeginEditing(_:)), for: .editingDidBegin)
        dateLastField.addTarget(self, action: #selector(textFieldDidBeginEditing(_:)), for: .editingDidBegin)
        dateNextField.addTarget(self, action: #selector(textFieldDidBeginEditing(_:)), for: .editingDidBegin)
        frequencyField.addTarget(self, action: #selector(textFieldDidBeginEditing(_:)), for: .editingDidBegin)
        noteField.addTarget(self, action: #selector(textFieldDidBeginEditing(_:)), for: .editingDidBegin)
        
        descriptionField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingDidEnd)
        dateLastField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingDidEnd)
        dateNextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingDidEnd)
        frequencyField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingDidEnd)
        noteField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingDidEnd)
        
        // Create and set the custom selection background view
        let customSelectedBackgroundView = UIView()
        customSelectedBackgroundView.backgroundColor = .brandLightYellow
        selectedBackgroundView = customSelectedBackgroundView
        
        picker.delegate = self
        picker.dataSource = self
        pickerData = ["one-time", "days", "weeks", "months", "years"]
        
        descriptionField.delegate = self
        dateLastField.delegate = self
        dateNextField.delegate = self
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
    
    func addDoneButtonOnNumpad(textField: UITextField) {
        let keypadToolbar: UIToolbar = UIToolbar()
        keypadToolbar.items=[
            UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: self, action: nil),
            UIBarButtonItem(title: "Done", style: UIBarButtonItem.Style.done, target: textField, action: #selector(UITextField.resignFirstResponder))
        ]
        keypadToolbar.sizeToFit()
        keypadToolbar.barStyle = .default
        keypadToolbar.tintColor = .brandLightBlue
        textField.inputAccessoryView = keypadToolbar
    }//addDoneToKeyPad
    
    // To make input fields inactive unless the cell is selected
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        picker.isUserInteractionEnabled = selected
        descriptionField.isUserInteractionEnabled = selected
        frequencyField.isUserInteractionEnabled = selected
        noteField.isUserInteractionEnabled = selected
        dateNextField.isUserInteractionEnabled = selected
        // Hide datePicker and down arrow when cell is not selected
//        datePicker.isHidden = !selected
//        arrowDown.isHidden = !selected
    }
    
    // Target to dismiss calendar when date is selected
    @objc func datePickerTapped() {
            self.datePicker.preferredDatePickerStyle = .wheels
            self.datePicker.preferredDatePickerStyle = .automatic
        }
    
    // Target to respond to datePicker value changes
    @objc func datePickerValueChanged(_ sender: UIDatePicker) {
        selectedDate = sender.date
        let pickerRow = picker.selectedRow(inComponent: 0)
        // Perform actions with the selected date, e.g., update a label, send data to another component, etc.
        dateLastField.text = DF.dateFormatter.string(from: selectedDate ?? Date())
        let calculatedDateNext = calculateDateNext(row: pickerRow)
        dateNextField.text = calculatedDateNext
        customCellDelegate?.datePickerValueDidChange(inCell: self, withDate: selectedDate ?? Date())
        textCalculationDelegate?.didCalculateText(calculatedDateNext)
    }
    
    // Calculate dateNext and send to view controller
    @objc private func calculateAndSendText() {
        let calculatedDateNext = calculateDateNext(row: pickerDataIndex)
        // Call the delegate
        textCalculationDelegate?.didCalculateText(calculatedDateNext)
    }
    
    // Calculate dateNext as a function of dateLast, frequency and period
    func calculateDateNext(row: Int) -> String {
        var nextDate: Date
        
        let period = pickerData[picker.selectedRow(inComponent: 0)]
        let lastDate = datePicker.date
        let lastDateString = DF.dateFormatter.string(from: lastDate)
        
        // If frequency is nil or zero, return last date
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
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        // This method is triggered whenever the user makes a change to the picker selection.
        // The parameters named row and component represent what was selected.
        if pickerData[row] == "one-time" {
            customCellDelegate?.customCellFrequencyAlert(self)
        }
        let calculatedDateNext = calculateDateNext(row: row)
        textCalculationDelegate?.didCalculateText(calculatedDateNext)
        pickerDelegate?.picker(cell: self, didSelectRow: row)
    }
}

//MARK: - UITextFieldDelegate Implementation
extension CustomCell: UITextFieldDelegate {
    @objc func textFieldDidChange(_ textField: UITextField) {
        // If this is the frequency text field, update the dateNext calculation and send it to RemindersViewController.
        // Calculation of dateNext after period and dateLast changes is handled elsewhere.
        if textField.tag == 4 {
            let pickerIndex = picker.selectedRow(inComponent: 0)
            let calculatedDateNext = calculateDateNext(row: pickerIndex)
            dateNextField.text = calculatedDateNext
            // Send calculatedDateNext to RemindersViewController.
            textCalculationDelegate?.didCalculateText(calculatedDateNext)
        }
        
        // If period is "one-time", set frequency to zero and trigger alert.
        if picker.selectedRow(inComponent: 0) == 0 {
            frequencyField.text = "0"
            // Trigger frequency alert if the call to this function is from the frequency field.
            if textField.tag == 4 {
                customCellDelegate?.customCellFrequencyAlert(self)
            }
        }
    }
    
    // Dismiss keyboard when "Return" key is tapped.
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // Select all on tapping text field
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField.tag == 4 {
            textField.selectAll(nil)
        }
        // Set the activeTextField property in RemindersViewController
        customCellDelegate?.customCell(self, didStartEditingWithField: textField)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField.tag == 4 {
            let pickerRow = picker.selectedRow(inComponent: 0)
            dateNextField.text = calculateDateNext(row: pickerRow)
        }
        customCellDelegate?.customCell(self, didEndEditingWithField: textField)
    }
    
}
