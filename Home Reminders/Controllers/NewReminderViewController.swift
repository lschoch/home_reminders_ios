//
//  NewItemViewController.swift
//  Home Reminders
//
//  Created by Lawrence H. Schoch on 9/6/25.
//

import UIKit
import SQLite

class NewReminderViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {

    @IBOutlet weak var newPicker: UIPickerView!
    @IBOutlet weak var datePicker: UIDatePicker!
    
    @IBOutlet weak var descriptionField: UITextField!
    @IBOutlet weak var frequencyField: UITextField!
    @IBOutlet weak var noteField: UITextField!
    @IBOutlet weak var saveButton: UIButton!
    
    weak var newPickerDelegate: PickerCellDelegate?
    
    var newPickerData: [String] = []
    var newPickerDataIndex: Int = -1
    
    var selectedDate: Date?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let navBar = navigationController?.navigationBar {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .brandLightBlue // nav bar color
            appearance.titleTextAttributes = [.foregroundColor: UIColor.brandLightYellow] // center title
            
            // Change the back button background (the "circle")
            //            appearance.backButtonAppearance.normal.backgroundImage = UIImage(color: .brandLightYellow, size: CGSize(width: 30, height: 30)).withRoundedCorners(radius: 15)
            navigationItem.hidesBackButton = true
            
            navBar.standardAppearance = appearance
            navBar.scrollEdgeAppearance = appearance
            
            UITextField.appearance().tintColor = .black
            
            newPicker.delegate = self
            newPicker.dataSource = self
            newPickerData = ["one-time", "days", "weeks", "months", "years"]
            
            // Configure the date picker
            datePicker.datePickerMode = .date // Can also be .time, .dateAndTime, .countDownTimer
            datePicker.preferredDatePickerStyle = .compact // Or .wheels, .compact, .inline (iOS 14+)
            datePicker.tintColor = .black
            datePicker.addTarget(self, action: #selector(datePickerTapped), for: .primaryActionTriggered)
            
            // Add a target to respond to datePicker value changes
            datePicker.addTarget(self, action: #selector(datePickerValueChanged(_:)), for: .valueChanged)
            
            // Set initial frequency to zero (because intial period is "one-time"
            frequencyField.text = "0"
            
            // Add target to frequency field to set frequancy = zero if period is "one-time"
            frequencyField.addTarget(self, action: #selector(frequencyFieldChanged(_:)), for: .editingChanged)
            
            saveButton.isHidden = true
            
            // Dismiss keyboard when tapping outside text field.
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
                    view.addGestureRecognizer(tapGesture)
        }
    }
    
    @objc func hideKeyboard() {
            view.endEditing(true)
        }
    
    @objc func frequencyFieldChanged(_ textField: UITextField) {
        if newPicker.selectedRow(inComponent: 0) == 0 {
            frequencyField.text = "0"
        }
    }
    
    @objc func datePickerTapped() {
            self.datePicker.preferredDatePickerStyle = .wheels
            self.datePicker.preferredDatePickerStyle = .automatic
        }
    
    @IBAction func backButtonPressed(_ sender: UIBarButtonItem) {
        showConfirmationAlert()
    }
    
    func showConfirmationAlert() {
        let alertController = UIAlertController(title: "Save Reminder?", message: "Do you want to save this reminder?", preferredStyle: .alert)
        
        let yesAction = UIAlertAction(title: "Yes", style: .default) { _ in
            // Handle "Yes" tap
            if let db = getConnection() {
                let remindersTable = Table("reminders")
                let description = Expression<String?>("description")
                let dateLast = Expression<String?>("date_last")
                let dateNext = Expression<String?>("date_next")
                let frequency = Expression<String?>("frequency")
                let period = Expression<String?>("period")
                let note = Expression<String?>("note")
                
                do {
                    try db.run(remindersTable.insert(
                        description <- self.descriptionField.text,
                        frequency <- self.frequencyField.text,
                        period <- self.newPickerData[self.newPicker.selectedRow(inComponent: 0)],   //self.newPickerData[self.newPickerDataIndex],
                        note <- self.noteField.text,
                        dateLast <- DF.dateFormatter.string(from: self.selectedDate ?? Date()),
                        dateNext <- self.calculateDateNext()))
                } catch {
                    print("Error saving reminder: \(error)")
                }
            }
            self.navigationController?.popViewController(animated: true)

        }
    
        let noAction = UIAlertAction(title: "No", style: .cancel) { _ in
            // Handle "No" tap
            self.navigationController?.popViewController(animated: true)
        }
    
        alertController.addAction(yesAction)
        alertController.addAction(noAction)
        
        present(alertController, animated: true, completion: nil)
    }
        
    
    @objc func datePickerValueChanged(_ sender: UIDatePicker) {
        selectedDate = sender.date
    }
    
    func calculateDateNext() -> String {
        let period = newPickerData[newPicker.selectedRow(inComponent: 0)]
        let frequency = frequencyField.text
        let dateLast = selectedDate ?? Date()
        
        if let frequencyInt = Int(frequency!) {
            var dateNext: Date
            switch period {
            case "days":
                dateNext = Calendar.current.date(byAdding: .day, value: frequencyInt, to: dateLast)!
                return DF.dateFormatter.string(from: dateNext)
            case "weeks":
                dateNext = Calendar.current.date(byAdding: .day, value: frequencyInt * 7, to: dateLast)!
                return DF.dateFormatter.string(from: dateNext)
            case "months":
                dateNext = Calendar.current.date(byAdding: .month, value: frequencyInt, to: dateLast)!
                return DF.dateFormatter.string(from: dateNext)
            case "years":
                dateNext = Calendar.current.date(byAdding: .year, value: frequencyInt, to: dateLast)!
                return DF.dateFormatter.string(from: dateNext)
            default:
                dateNext = dateLast
                return DF.dateFormatter.string(from: dateLast)
            }
        }
        // FrequencyInt is nil (i.e., frequency is nil)
        return DF.dateFormatter.string(from: dateLast)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    //MARK: - UIPickerViewDataSource Implementation
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return newPickerData.count
    }
    
    //MARK: - UIPickerViewDelegate Implementation
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return newPickerData[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        newPickerDataIndex = row
        
        if newPicker.selectedRow(inComponent: 0) == 0 {
            frequencyField.text = "0"
        }
    }

}

