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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "CustomCell", bundle: nil), forCellReuseIdentifier: "CustomCell")
        
        tableView.rowHeight = 160 // UITableView.automaticDimension
        
        loadReminders()
        
    }
    
    //MARK: - Data Manipulation Methods
    func loadReminders() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = Date.now
        
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
        
        // Select all reminders and append each to the reminders array
        do {
            let remindersTable = Table("reminders")
            let description = Expression<String>("description")
            let frequency = Expression<String>("frequency")
            let period = Expression<String>("period")
            let date_last = Expression<String>("date_last")
            let date_next = Expression<String>("date_next")
            let note = Expression<String>("note")
            
            for reminder in try db.prepare(remindersTable.order(date_next.asc)) {
                reminders.append(Reminder(
                    description: try reminder.get(description),
                    frequency: try reminder.get(frequency),
                    period: try reminder.get(period),
                    dateLast: try reminder.get(date_last),
                    dateNext: try reminder.get(date_next),
                    note: try reminder.get(note)
                )
                )
                
                do {
                    let dateNext = try dateFormatter.date(from: reminder.get(date_next))!
                    if dateNext < today {
                        print("expired")
                    }
                } catch {
                    print("Error converting string to date: \(error)")
                }
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
        let reminder = reminders[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "CustomCell", for: indexPath) as! CustomCell
        
        cell.descriptionField.text = reminder.description
        cell.dateLastField.text = reminder.dateLast
        cell.dateNextField.text = reminder.dateNext
        cell.frequencyField.text = reminder.frequency
        cell.periodField.text = reminder.period
        cell.noteField.text = reminder.note

        return cell
    }
}

extension RemindersViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("Selected row: \(indexPath.row)")
    }
}
