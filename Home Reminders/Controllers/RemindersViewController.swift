//
//  ViewController.swift
//  Home Reminders
//
//  Created by Lawrence H. Schoch on 9/6/25.
//

import UIKit
import SQLite

class RemindersViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var reminders: [Reminder] = []
    var tableRow: Int?
    let pickerData = ["one-time", "days", "weeks", "months", "years"]
    var calculatedDateNext: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "CustomCell", bundle: nil), forCellReuseIdentifier: "CustomCell")
        tableView.rowHeight = 160
        
        loadReminders()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)

            loadReminders()
            tableView.reloadData()
        }
    
    @IBAction func saveButtonPressed(_ sender: UIButton) {
        showSaveConfirmationAlert()
    }
    
    func showSaveConfirmationAlert() {
        let alertController = UIAlertController(title: "Update Reminder?", message: "Are you sure you want to save this reminder?", preferredStyle: .alert)
        
        let yesAction = UIAlertAction(title: "Yes", style: .default) { _ in
            // Handle "Yes" tap
//            print("User chose Yes. Proceeding with the action.")
            if self.tableRow ?? -1 < 0 {
                print("Please select a reminder to save.")
                return
            } else {
                if let db = getConnection() {
                    let remindersTable = Table("reminders")
                    let id = Expression<Int64>("id")
                    let description = Expression<String>("description")
                    let frequency = Expression<String>("frequency")
                    let period = Expression<String>("period")
                    let dateLast = Expression<String>("date_last")
                    let dateNext = Expression<String>("date_next")
                    let note = Expression<String>("note")
                    
                    do {
                        if let safeTableRow = self.tableRow  {
                            self.reminders[safeTableRow].dateNext = self.calculatedDateNext
                            let myId = self.reminders[safeTableRow].id
    //                        print(safeTableRow, myId)
                            let reminderToSave = remindersTable.filter(id == myId)
                            try db.run(reminderToSave.update(
                                description <- self.reminders[safeTableRow].description,
                                frequency <- self.reminders[safeTableRow].frequency,
                                period <- self.reminders[safeTableRow].period,
                                dateLast <- self.reminders[safeTableRow].dateLast,
                                dateNext <- self.reminders[safeTableRow].dateNext,
                                note <- self.reminders[safeTableRow].note
                            ))
                        }
                        self.loadReminders()
                        self.tableView.reloadData()
                        let ac = UIAlertController(title: "Updated!", message: "Your reminder has been updated.", preferredStyle: .alert)
                        ac.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(ac, animated: true)
                    } catch {
                        print("Error saving reminder: \(error)")
                    }
                } else {
                    print("Error: Could not open database.")
                }
            }
            
        }
    
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            // Handle "Cancel" tap
//            print("User chose Cancel. Canceling the action.")
        }
    
        alertController.addAction(yesAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
        
        
    
    @IBAction func deleteButtonPressed(_ sender: UIButton) {
        showDeleteConfirmationAlert()
    }
    
    func showDeleteConfirmationAlert() {
        let alertController = UIAlertController(title: "Delete Reminder?", message: "Are you sue you want to delete this reminder?", preferredStyle: .alert)
        
        let yesAction = UIAlertAction(title: "Yes", style: .default) { _ in
            // Handle "Yes" tap
//            print("User chose Yes. Proceeding with the action.")
            if let db = getConnection() {
                let remindersTable = Table("reminders")
                let id = Expression<Int64>("id")
                if let safeTableRow = self.tableRow  {
                    let myId = self.reminders[self.tableRow ?? 0].id
                    let reminderToDelete = remindersTable.filter(id == myId)
                    try! db.run(reminderToDelete.delete())
                    // Empty the reminders array to avoid duplication.
                    self.reminders = []
                    self.loadReminders()
                    self.tableView.reloadData()
                    self.tableView.selectRow(at: [0, safeTableRow], animated: true, scrollPosition: .none)
                } else {
                    print("No row to delete.")
                }
            } else {
                print("Error: Could not open database.")
            }
            self.navigationController?.popViewController(animated: true)
        }
    
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            // Handle "Cancel" tap
//            print("User chose Cancel. Canceling the action.")
        }
    
        alertController.addAction(yesAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    //MARK: - Data Manipulation Methods
    func loadReminders() -> Void {
        // Copy database file from app bundle to documents directory (one time only)
//        copyFileToDocumentsFolder(nameForFile: "home_reminders", extForFile: "db")
        
        if let db = getConnection() {
            // Select all reminders, append each reminder to the reminders array
            do {
                let remindersTable = Table("reminders")
                let id = Expression<Int64>("id")
                let description = Expression<String>("description")
                let frequency = Expression<String>("frequency")
                let period = Expression<String>("period")
                let date_last = Expression<String>("date_last")
                let date_next = Expression<String>("date_next")
                let note = Expression<String>("note")
                
                reminders = []
                for reminder in try db.prepare(remindersTable.order(date_next.asc)) {
                    reminders.append(Reminder(
                        id: Int64(try reminder.get(id)),
                        description: try reminder.get(description),
                        frequency: try reminder.get(frequency),
                        period: try reminder.get(period),
                        dateLast: try reminder.get(date_last),
                        dateNext: try reminder.get(date_next),
                        note: try reminder.get(note)
                    )
                    )
                    if reminders.last!.period == "one-time" {
                        reminders[reminders.count - 1].frequency = ""
                    }
                }
            } catch {
                print("Error during query: \(error)")
            }
        } else {
            print("Could not open database")
        }
    }
}

//MARK: - UITableViewDataSource Implementation
extension RemindersViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return reminders.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reminder = reminders[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "CustomCell", for: indexPath) as! CustomCell
        
        cell.descriptionField.text = reminder.description
//        cell.dateLastField.text = reminder.dateLast
        cell.datePicker.date = DF.dateFormatter.date(from: reminder.dateLast) ?? Date()
        cell.dateNextField.text = reminder.dateNext
        cell.frequencyField.text = reminder.frequency
        cell.noteField.text = reminder.note
        cell.customCellDelegate = self
        cell.pickerDelegate = self
        cell.textCalculationDelegate = self // VERY IMPORTANT!
//        cell.dateLastField.delegate = cell // Ensure the text field delegate is set to the cell
        
        // To initialize picker with data from the database
        if let index = pickerData.firstIndex(of: reminder.period) {
            cell.picker.selectRow(index, inComponent: 0, animated: false)
        }
        
        // Modify cell background color as a function of due date in relation to today's date
//        let DF.dateFormatter = DateFormatter()
//        DF.dateFormatter.dateFormat = "yyyy-MM-dd"
//        let today = Date.now
//        let dateNext = DF.dateFormatter.date(from: reminder.dateNext)
//        if dateNext! < today {
//            cell.contentView.backgroundColor = .yellow
//        } else if dateNext! == today {
//            cell.contentView.backgroundColor = .green
//        } else {
//            cell.contentView.backgroundColor = .white
//        }
        
        // Create and set the custom selection background view
        let customSelectedBackgroundView = UIView()
        customSelectedBackgroundView.backgroundColor = .brandLightYellow
        cell.selectedBackgroundView = customSelectedBackgroundView

        return cell
    }
}

//MARK: - UITableViewDelegate Implementation
extension RemindersViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = indexPath.row
        tableRow = row
    }
}

//MARK: - CustomCellDelegate Implementation
extension RemindersViewController: CustomCellDelegate {
    func customCell(_ cell: CustomCell, didUpdateText textField: UITextField?) {
        switch textField!.tag {
        case 1: // description
            reminders[tableRow ?? -1].description = textField?.text ?? "no text"
//        case 2: // dateLast
//            reminders[tableRow ?? -1].dateLast = textField?.text ?? "no text"
        case 4: // frequency
            reminders[tableRow ?? -1].frequency = textField?.text ?? "no text"
        case 5: // note
            reminders[tableRow ?? -1].note = textField?.text ?? "no text"
        default:
            print("unknown")
        }
        reminders[tableRow ?? -1].dateNext = calculatedDateNext
    }
    
    func didTapElementInCell(_ cell: CustomCell) {
        if let indexPath = tableView.indexPath(for: cell) {
//            print("Tapped cell at \(indexPath)")
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
            tableView.delegate?.tableView?(tableView, didSelectRowAt: indexPath) // Manually call didSelectRowAt
        }
    }
    
    func pickerValueDidChange(inCell cell: CustomCell, withText text: String) {
            // Handle the received text from the custom cell
//            print("Received text from picker in cell: \(text)")
            // Update UI or perform other actions in the view controller
            calculatedDateNext = text
        }

}

//MARK: - PickerCellDelegate Implementation
extension RemindersViewController: PickerCellDelegate {
    func picker(cell: CustomCell, didSelectRow row: Int) {
        if let indexPath = tableView.indexPath(for: cell) {
            // Update tableRow directly
            tableRow = indexPath.row
            
            reminders[indexPath.row].period = pickerData[row]
            reminders[indexPath.row].dateNext = calculatedDateNext
            tableView.reloadRows(at: [indexPath], with: .none)
            
            // Programmatically select the row
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
        }
    }
}

//MARK: - TextCalculationDelegate Implementation
extension RemindersViewController: TextCalculationDelegate {
    func didCalculateText(_ text: String) {
        calculatedDateNext = text
    }
}
