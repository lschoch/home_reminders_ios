//
//  ViewController.swift
//  Home Reminders
//
//  Created by Lawrence H. Schoch on 9/6/25.
//

import UIKit
import SQLite

class RemindersViewController: UIViewController, CustomCellDelegate, PickerCellDelegate {
    
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
    
    func customCell(_ cell: CustomCell, didUpdateText textField: UITextField?) {
        print("textField: \(textField as Any)")
        print("tableRow: \(tableRow ?? -1)")
        if let safeTextField = textField, let safeTableRow = tableRow {
            if safeTextField.tag == 1 {
                print("dateLastField")
                reminders[safeTableRow].dateLast = safeTextField.text!
            } else if safeTextField.tag == 2 {
                print("frequencyField")
                reminders[safeTableRow].frequency = safeTextField.text!
            } else {
                print("no tag")
            }
        }
    }
    
    func picker(cell: CustomCell, didSelectRow row: Int) {
            // You now have access to the cell and the selected row.
            // Get the index path of the cell to update your data model.
            if let indexPath = tableView.indexPath(for: cell) {
                print("Selected row \(row) in cell at \(indexPath)")
                if let safeTableRow = tableRow {
                    reminders[safeTableRow].period = pickerData[row]
                    print("period: \(reminders[safeTableRow].period)")
                    print("pickerdata: \(pickerData[row])")
                }
                
            }
        }
    
    @IBAction func saveButtonPressed(_ sender: UIButton) {
        print("Save button pressed")
        print("row: \(tableRow ?? -1)")
        
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
    func loadReminders() {
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
   
extension RemindersViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return reminders.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
//        let today = Date.now
        
        let reminder = reminders[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "CustomCell", for: indexPath) as! CustomCell
        
        cell.descriptionField.text = reminder.description
        cell.dateLastField.text = reminder.dateLast
        cell.dateNextField.text = reminder.dateNext
        cell.frequencyField.text = reminder.frequency
        cell.noteField.text = reminder.note
        cell.delegate = self
        cell.delegate2 = self
        
        // To initialize picker with data from the database
        if let index = pickerData.firstIndex(of: reminder.period) {
            cell.picker.selectRow(index, inComponent: 0, animated: false)
        }
        
        // Modify cell background color as a function of due date in relation to today's date
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

extension RemindersViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("Selected row: \(indexPath.row)")
        let row = indexPath.row
        print("id: \(reminders[row].id)")
        tableRow = row
    }
}
