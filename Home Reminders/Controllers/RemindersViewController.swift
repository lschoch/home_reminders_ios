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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "CustomCell", bundle: nil), forCellReuseIdentifier: "CustomCell")
        tableView.rowHeight = 160
        
        loadReminders()
        
    }
    
    @IBAction func saveButtonPressed(_ sender: UIButton) {
        print("Save button pressed")
        print("row: \(tableRow ?? -1)")
        print(reminders)
        
        if tableRow ?? -1 < 0 {
            print("Please select a reminder to save.")
            return
        } else {
            // Copy database file to documents directory (one time only), print database file path
            let docName = "home_reminders"
            let docExt = "db"
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            let dbPath = documentsURL!.appendingPathComponent(docName).appendingPathExtension(docExt)
            
            // Connect to database
            var db: Connection!
            do {
                db = try Connection("\(dbPath)")
            } catch {
                print("Error opening database: \(error)")
            }
            let remindersTable = Table("reminders")
            let id = Expression<Int64>("id")
            let description = Expression<String>("description")
            let frequency = Expression<String>("frequency")
            let period = Expression<String>("period")
            let dateLast = Expression<String>("date_last")
            let dateNext = Expression<String>("date_next")
            let note = Expression<String>("note")
            
            do {
                if let safeTableRow = tableRow {
                    let myId = reminders[safeTableRow].id
                    print(safeTableRow, myId)
                    let reminderToSave = remindersTable.filter(id == myId)
                    try db.run(reminderToSave.update(
                        description <- reminders[tableRow!].description,
                        frequency <- reminders[tableRow!].frequency,
                        period <- reminders[tableRow!].period,
                        dateLast <- reminders[tableRow!].dateLast,
                        dateNext <- reminders[tableRow!].dateNext,
                        note <- reminders[tableRow!].note
                    ))
                }
            } catch {
                print("Error saving reminder: \(error)")
            }
        }
    }
    
    //MARK: - Data Manipulation Methods
    func loadReminders() -> Void {
        // Copy database file to documents directory (one time only), print database file path
        let docName = "home_reminders"
        let docExt = "db"
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        let dbPath = documentsURL!.appendingPathComponent(docName).appendingPathExtension(docExt)
        
        // Connect to database
        var db: Connection!
        do {
            db = try Connection("\(dbPath)")
        } catch {
            print("Error opening database: \(error)")
        }
        
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
            }
        } catch {
            print("Error during query: \(error)")
        }
    }
}

//MARK: - UITableViewDataSource Extension
extension RemindersViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return reminders.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reminder = reminders[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "CustomCell", for: indexPath) as! CustomCell
        
        cell.descriptionField.text = reminder.description
        cell.dateLastField.text = reminder.dateLast
        cell.dateNextField.text = reminder.dateNext
        cell.frequencyField.text = reminder.frequency
        cell.noteField.text = reminder.note
        cell.customCellDelegate = self
        cell.pickerDelegate = self
        
        // To initialize picker with data from the database
        if let index = pickerData.firstIndex(of: reminder.period) {
            cell.picker.selectRow(index, inComponent: 0, animated: false)
        }
        
        // Modify cell background color as a function of due date in relation to today's date
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "yyyy-MM-dd"
//        let today = Date.now
//        let dateNext = dateFormatter.date(from: reminder.dateNext)
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

//MARK: - UITableViewDelegate Extension
extension RemindersViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("Selected row: \(indexPath.row)")
        let row = indexPath.row
        print("id: \(reminders[row].id)")
        tableRow = row
    }
}

//MARK: - CustomCellDelegate Extension
extension RemindersViewController: CustomCellDelegate {
    func customCell(_ cell: CustomCell, didUpdateText textField: UITextField?) {
        print("tableRow: \(tableRow ?? -1)")
        if let safeTextField = textField, let safeTableRow = tableRow {
            print("safeTextField: \(safeTextField.text ?? "empty")")
            var reminder = reminders[safeTableRow]
            switch safeTextField.tag {
            case 1:
                print("description")
                reminder.description = safeTextField.text!
            case 2:
                print("dateLast")
                reminder.dateLast = safeTextField.text!
            case 3:
                print("dateNext")
                reminder.dateNext = safeTextField.text!
            case 4:
                print("frequency")
                reminder.frequency = safeTextField.text!
            case 5:
                print("note")
                reminder.note = safeTextField.text!
            default:
                print("unknown")
            }
        }
    }
    
    func didTapElementInCell(_ cell: CustomCell) {
        if let indexPath = tableView.indexPath(for: cell) {
            print("Tapped cell at \(indexPath)")
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
            tableView.delegate?.tableView?(tableView, didSelectRowAt: indexPath) // Manually call didSelectRowAt
        }
    }
}

//MARK: - PickerCellDelegate Extension
extension RemindersViewController: PickerCellDelegate {
    func picker(cell: CustomCell, didSelectRow row: Int) {
        if let indexPath = tableView.indexPath(for: cell) {
            print("Selected row \(row) in cell at \(indexPath)")
            if let safeTableRow = tableRow {
                reminders[safeTableRow].period = pickerData[row]
            }
        }
    }
}
