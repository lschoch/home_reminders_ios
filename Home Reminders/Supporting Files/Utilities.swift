//
//  Utilities.swift
//  Home Reminders
//
//  Created by Lawrence H. Schoch on 9/13/25.
//

import Foundation

func copyFileToDocumentsFolder(nameForFile: String, extForFile: String) {

    let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    let destURL = documentsURL!.appendingPathComponent(nameForFile).appendingPathExtension(extForFile)
    guard let sourceURL = Bundle.main.url(forResource: nameForFile, withExtension: extForFile)
        else {
            print("Source File not found.")
            return
    }
        let fileManager = FileManager.default
        do {
            try fileManager.copyItem(at: sourceURL, to: destURL)
        } catch {
            print("Unable to copy file")
        }
}

//{
//    
//    @IBOutlet weak var tableView: UITableView!
//    
//    var reminders: [Reminder] = [
//        Reminder(description: "Check water softener level", frequency: "2", period: "weeks", dateLast: "2025-09-06", dateNext: "2025-09-20", note: "no note for this reminder"),
//        Reminder(description: "Change furnace filters", frequency: "6", period: "months", dateLast: "2025-06-06", dateNext: "2025-12-06", note: "no note for this reminder")
//    
//    
//    ]
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        
//        // Date logic
//        let currentDate = Date()
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "yyyy-MM-dd"
//        let formattedDate = dateFormatter.string(from: currentDate)
//        print("Formatted date: \(formattedDate)")
//        
//        // Copy database file to documents directory (one time only), print database file path
//        let docName = "home_reminders"
//        let docExt = "db"
//        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
//        let destURL = documentsURL!.appendingPathComponent(docName).appendingPathExtension(docExt)
//        print(destURL) // Location of home_reminders.db
////        copyFileToDocumentsFolder(nameForFile: docName, extForFile: docExt) // Function in Utilities folder, run one time
//        
////        loadReminders()
//        
//    }
//    
//    
//    //MARK: - TableView Datasource Methods
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
////        print(reminders.count)
//        return reminders.count
//        
//    }
//    
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        
//        let reminder = reminders[indexPath.row]
//        let cell = tableView.dequeueReusableCell(withIdentifier: "ReminderCell", for: indexPath)
//        
//        cell.textLabel?.text = reminder.description
//
//        return cell
//    }
//
//}
//

