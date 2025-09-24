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
    
    weak var newPickerDelegate: PickerCellDelegate?
    
    var newPickerData: [String] = []
    var newPickerDataIndex: Int = 0
    
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
            
            newPicker.delegate = self
            newPicker.dataSource = self
            newPickerData = ["one-time", "days", "weeks", "months", "years"]
            
            // Configure the date picker
            datePicker.datePickerMode = .date // Can also be .time, .dateAndTime, .countDownTimer
            datePicker.preferredDatePickerStyle = .compact // Or .wheels, .compact, .inline (iOS 14+)
            
            // Add a target to respond to value changes
            datePicker.addTarget(self, action: #selector(datePickerValueChanged(_:)), for: .valueChanged)
        }
    }
    
    @IBAction func backButtonPressed(_ sender: UIBarButtonItem) {
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
                    description <- descriptionField.text,
                    frequency <- frequencyField.text,
                    period <- newPickerData[newPickerDataIndex],
                    note <- noteField.text,
                    dateLast <- DF.dateFormatter.string(from: selectedDate ?? Date()),
                    dateNext <- calculateDateNext()))
            } catch {
                print("Error saving reminder: \(error)")
            }
        }
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc func datePickerValueChanged(_ sender: UIDatePicker) {
            selectedDate = sender.date
        }
    
    func calculateDateNext() -> String {
        let period = newPickerData[newPickerDataIndex]
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
    }

}

