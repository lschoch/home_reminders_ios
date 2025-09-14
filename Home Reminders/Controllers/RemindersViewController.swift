//
//  ViewController.swift
//  Home Reminders
//
//  Created by Lawrence H. Schoch on 9/6/25.
//

import UIKit

class RemindersViewController: UIViewController {
    
    
    @IBOutlet weak var tableView: UITableView!
    
    var reminders: [Reminder] = [
        Reminder(description: "Check water softener level", frequency: "2", period: "weeks", dateLast: "2025-09-06", dateNext: "2025-09-20", note: "no note for this reminder"),
        Reminder(description: "Change furnace filters", frequency: "6", period: "months", dateLast: "2025-06-06", dateNext: "2025-12-06", note: "no note for this reminder but what happens if the note is very long?"),
        Reminder(description: "Change furnace filters", frequency: "6", period: "months", dateLast: "2025-06-06", dateNext: "2025-12-06", note: "no note for this reminder but what happens if the note is very long?")
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "CustomCell", bundle: nil), forCellReuseIdentifier: "CustomCell")
        
        tableView.rowHeight = 160 // UITableView.automaticDimension
//        tableView.estimatedRowHeight = 130 // Adjust as needed
        
        
        //MARK: - Date Logic
//        let currentDate = Date()
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "yyyy-MM-dd"
//        let formattedDate = dateFormatter.string(from: currentDate)
//        print("Formatted date: \(formattedDate)")
        
        //MARK: - Database File
        // Copy database file to documents directory (one time only), print database file path
        let docName = "home_reminders"
        let docExt = "db"
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        let destURL = documentsURL!.appendingPathComponent(docName).appendingPathExtension(docExt)
        print(destURL) // Location of home_reminders.db
        //        copyFileToDocumentsFolder(nameForFile: docName, extForFile: docExt) // Function in Utilities folder, run one time
        
        //        loadReminders()
        
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
