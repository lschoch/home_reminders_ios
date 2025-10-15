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
    @IBOutlet weak var dateButton: UIBarButtonItem!
    
    var reminders: [Reminder] = []
    var remindersOriginal: [Reminder] = []
    var tableRow: Int?
    let pickerData = ["one-time", "days", "weeks", "months", "years"]
    var calculatedDateNext: String = ""
    var selectedIndexPath: IndexPath?
    var activeTextField: UITextField?
    let cellSpacingHeight: CGFloat = 10.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure navbar
        if let navBar = navigationController?.navigationBar {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .brandLightBlue // nav bar color
            appearance.titleTextAttributes = [.foregroundColor: UIColor.brandLightYellow] // center title
            
            navBar.standardAppearance = appearance
            navBar.scrollEdgeAppearance = appearance
        }
        
        // Observe for significant time changes (e.g., midnight) so that date dependent items can be updated as needed.
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleSignificantTimeChange),
                                               name: UIApplication.significantTimeChangeNotification,
                                               object: nil)
        
        // Configure dateButton
        dateButton.target = nil
        dateButton.action = nil
        dateButton.style = .done
        dateButton.tintColor = .brandLightYellow
        updateDateButtonDate()
    
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "CustomCell", bundle: nil), forCellReuseIdentifier: "CustomCell")
        tableView.rowHeight = 160
        tableView.sectionHeaderTopPadding = 0
        
        // Dismiss keyboard when tapping outside text field.
//        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
//                view.addGestureRecognizer(tapGesture)
        
        loadReminders()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadReminders()
        tableView.reloadData()
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        // Currently active text field needs to resign first responder so that didEndEditing will fire.
        activeTextField?.resignFirstResponder()
        // Get the currently selected row (if any)
        if let selectedIndexPath = tableView.indexPathForSelectedRow {
            // Retrieve the data model for the currently selected row
            let selectedRowData = reminders[selectedIndexPath.section]

            // Check if the selectedRowData has "changed" based on your application's logic
            // For example, if a text field in the cell was edited and not saved
            if identifier == "NewReminderSegue" && selectedRowData.hasUnsavedChanges {
                // Present an alert or prompt the user to save/discard changes
                let alert = UIAlertController(title: "Unsaved Changes", message: "Do you want to save changes before leaving?", preferredStyle: .alert)
                alert.view.tintColor = .black
                alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { _ in
                    // Save changes for selectedRowData
                    self.saveReminder(selectedIndexPath.section)
                    // Then, proceed with selecting the new row
                    self.performSegue(withIdentifier: identifier, sender: sender) // Manually perform the segue
                }))
                alert.addAction(UIAlertAction(title: "Discard", style: .destructive, handler: { _ in
                    // Discard changes for selectedRowData
                    self.discardChangesForSelectedRowData(selectedIndexPath)
                    
                    // Then, proceed with seque
                    self.performSegue(withIdentifier: identifier, sender: sender) // Manually perform the segue
                }))
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
                    // Do not perform the seque
                    return
                }))
                self.present(alert, animated: true, completion: nil)

                return false // Prevent the segue from performing automatically
            } // end: "identifier == "NewRemincerSegue" && selectedRowData.hasUnsavedChanges"
        } // end: "if let selectedIndexPath = tableView.indexPathForSelectedRow"
        return true // Allow other segues to perform normally, or if no unsaved changes
    } // end: function
    
    deinit {
        // Remove observer when the object is deallocated
        NotificationCenter.default.removeObserver(self,
                                                  name: UIApplication.significantTimeChangeNotification,
                                                  object: nil)
    }
    
    func updateDateButtonDate() {
        // Get the current date
        let currentDate = Date()
        // Format the date into a string
        let dateString = DF.dateFormatter.string(from: currentDate)
        dateButton.title? = dateString
    }
    
    @objc func handleSignificantTimeChange() {
        print("Significant time change notification received! Updating UI/data.")
        updateDateButtonDate()
        // Reload data to reset date-dependent cell background color changes
        loadReminders()
        tableView.reloadData()
    }
    
    @objc func hideKeyboard() {
        view.endEditing(true)
    }
    
    @IBAction func saveButtonPressed(_ sender: UIButton) {
        showSaveConfirmationAlert()
    }
    
    func showSaveConfirmationAlert() {
        guard tableView.indexPathForSelectedRow != nil else {
            self.notificationAlert(title: "Save", message: "No reminder selected to save.")
            return
        }
        self.saveReminderWithOptionToDiscardChanges()
    }

    @IBAction func deleteButtonPressed(_ sender: UIButton) {
        showDeleteConfirmationAlert()
    }
    
    func showDeleteConfirmationAlert() {
        guard let selectedIndexPath = tableView.indexPathForSelectedRow else {
            notificationAlert(title: "Delete Reminder?", message: "No reminder selected for deletion.")
            return
        }
        
        let alertController = UIAlertController(title: "Delete Reminder?", message: "Are you sure you want to delete this reminder?", preferredStyle: .alert)
        alertController.view.tintColor = .black
        
        let yesAction = UIAlertAction(title: "Yes", style: .default) { _ in
            // Handle "Yes" tap
            if let db = getConnection() {
                let remindersTable = Table("reminders")
                let id = Expression<Int64>("id")
                let myId = self.reminders[self.tableRow ?? 0].id
                let reminderToDelete = remindersTable.filter(id == myId)
                try! db.run(reminderToDelete.delete())
                // Empty the reminders array to avoid duplication.
                self.reminders = []
                self.loadReminders()
                self.tableView.reloadData()
                self.tableView.selectRow(at: selectedIndexPath, animated: true, scrollPosition: .none)
                self.tableView.delegate?.tableView?(self.tableView, didSelectRowAt: selectedIndexPath) // Manually call didSelectRowAt
                
                // Alert notification that delete was successful.
                let ac = UIAlertController(title: "Delete", message: "The reminder has been deleted.", preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "OK", style: .default))
                ac.view.tintColor = .black
                self.present(ac, animated: true)
            } else {
                print("Error: Could not open database.")
            }
            self.navigationController?.popViewController(animated: true)
        }
    
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            // Handle "Cancel" tap
            return
        }
    
        alertController.addAction(yesAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func deselectButtonPressed(_ sender: UIButton) {
        // Currently active text field needs to resign first responder so that didEndEditing will fire.
        activeTextField?.resignFirstResponder()
        
        // Check for unsaved changes
        
        // Get the currently selected row (if any)
        if let selectedIndexPath = tableView.indexPathForSelectedRow {
            // Retrieve the data model for the currently selected row
            let selectedRowData = reminders[selectedIndexPath.section]

            // Check if the selectedRowData has "changed"
            if selectedRowData.hasUnsavedChanges {
                // Present an alert or prompt the user to save/discard changes
                // If the user chooses to stay on the current row, return nil
                // If the user confirms to proceed, handle saving/discarding and then return indexPath
                let alert = UIAlertController(title: "Deselect", message: "Save changes before deselecting?", preferredStyle: .alert)
                alert.view.tintColor = .black
                alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { _ in
                    self.saveReminder(selectedIndexPath.section)
                    self.tableView.deselectRow(at: selectedIndexPath, animated: true)
                }))
                alert.addAction(UIAlertAction(title: "Discard", style: .destructive, handler: { _ in
                    // Discard changes for selectedRowData
                    self.discardChangesForSelectedRowData(selectedIndexPath)
                    self.tableView.deselectRow(at: selectedIndexPath, animated: true)
                }))
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
                    return
                }))
                self.present(alert, animated: true, completion: nil)
                return
            } else {
                self.tableView.deselectRow(at: selectedIndexPath, animated: true)
            }// end: "if selectedRowData.hasUnsavedChanges"
        } else {
            notificationAlert(title: "Deselect", message: "No row is selected.") // end: "if let selectedIndexPath = tableView.indexPathForSelectedRow"
        }
    }
    
    func notificationAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.view.tintColor = .black
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
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
                remindersOriginal = []
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
                    
                    remindersOriginal.append(Reminder(
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
        } else {
            print("Could not open database")
        }
    }
    
    func saveReminder(_ row: Int?) {
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
                if let safeRow = row {
                    if !calculatedDateNext.isEmpty { self.reminders[safeRow].dateNext = self.calculatedDateNext }
                    let myId = self.reminders[safeRow].id
                    let reminderToSave = remindersTable.filter(id == myId)
                    try db.run(reminderToSave.update(
                        description <- self.reminders[safeRow].description,
                        frequency <- self.reminders[safeRow].frequency,
                        period <- self.reminders[safeRow].period,
                        dateLast <- self.reminders[safeRow].dateLast,
                        dateNext <- self.reminders[safeRow].dateNext,
                        note <- self.reminders[safeRow].note
                    ))
                }
                self.loadReminders()
                self.tableView.reloadData()
        
            } catch {
                print("Error saving reminder: \(error)")
            }
        } else {
            print("Error: Could not open database.")
        }
    }
    
    func saveReminderWithOptionToDiscardChanges() {
        // Currently active text field needs to resign first responder so that didEndEditing will fire.
        activeTextField?.resignFirstResponder()
        // Get the currently selected row (if any)
        if let selectedIndexPath = tableView.indexPathForSelectedRow {
            // Retrieve the data model for the currently selected row
            let selectedRowData = reminders[selectedIndexPath.section]

            // Check if the selectedRowData has "changed" based on your application's logic
            // For example, if a text field in the cell was edited and not saved
            if selectedRowData.hasUnsavedChanges {
                // Present an alert or prompt the user to save/discard changes
                // If the user chooses to stay on the current row, return nil
                // If the user confirms to proceed, handle saving/discarding and then return indexPath
                let alert = UIAlertController(title: "Save", message: "Are you sure you want to save this reminder?", preferredStyle: .alert)
                alert.view.tintColor = .black
                alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { _ in
                    self.saveReminder(selectedIndexPath.section)
                    self.tableView.selectRow(at: selectedIndexPath, animated: true, scrollPosition: .none)
                    self.tableView.delegate?.tableView?(self.tableView, didSelectRowAt: selectedIndexPath) // Manually call didSelectRowAt
                }))
                alert.addAction(UIAlertAction(title: "Discard", style: .destructive, handler: { _ in
                    // Discard changes for selectedRowData
                    self.discardChangesForSelectedRowData(selectedIndexPath)
                    self.tableView.selectRow(at: selectedIndexPath, animated: true, scrollPosition: .none)
                    self.tableView.delegate?.tableView?(self.tableView, didSelectRowAt: selectedIndexPath) // Manually call didSelectRowAt
                }))
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
                    self.tableView.selectRow(at: selectedIndexPath, animated: true, scrollPosition: .none)
                    self.tableView.delegate?.tableView?(self.tableView, didSelectRowAt: selectedIndexPath) // Manually call didSelectRowAt
                    return
                }))
                self.present(alert, animated: true, completion: nil)
                return
            } else {
                notificationAlert(title: "Save", message: "No changes to save.")
            }// end: "if selectedRowData.hasUnsavedChanges"
        } // end: "if let selectedIndexPath = tableView.indexPathForSelectedRow"
    }
    
    func discardChangesForSelectedRowData(_ selectedIndexPath: IndexPath) {
        // Discard changes for selectedRowData
        // Reset calculatedDateNext so it won't overwrite previous value of dateNext.
        self.calculatedDateNext = ""
        self.reminders[selectedIndexPath.section].description = self.remindersOriginal[selectedIndexPath.section].description
        self.reminders[selectedIndexPath.section].frequency = self.remindersOriginal[selectedIndexPath.section].frequency
        self.reminders[selectedIndexPath.section].period = self.remindersOriginal[selectedIndexPath.section].period
        self.reminders[selectedIndexPath.section].note = self.remindersOriginal[selectedIndexPath.section].note
        self.reminders[selectedIndexPath.section].dateLast = self.remindersOriginal[selectedIndexPath.section].dateLast
        self.reminders[selectedIndexPath.section].dateNext = self.remindersOriginal[selectedIndexPath.section].dateNext
        self.reminders[selectedIndexPath.section].hasUnsavedChanges = false
        self.saveReminder(selectedIndexPath.section)
        tableView.reloadRows(at: [selectedIndexPath], with: .automatic)
    }
    
}

//MARK: - UITableViewDataSource Implementation
extension RemindersViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.reminders.count
    }
    
    // There is just one row in every section
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    // Set the spacing between sections
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return cellSpacingHeight
    }
    
    // Make the background color show through
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = UIColor.clear
        return headerView
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reminder = reminders[indexPath.section]
        let cell = tableView.dequeueReusableCell(withIdentifier: "CustomCell", for: indexPath) as! CustomCell
        
        // add border and color
        cell.backgroundColor = UIColor.white
        cell.layer.borderColor = UIColor.black.cgColor
        cell.layer.borderWidth = 1
        cell.layer.cornerRadius = 8
        cell.clipsToBounds = true
        
        cell.descriptionField.text = reminder.description
        cell.datePicker.date = DF.dateFormatter.date(from: reminder.dateLast) ?? Date()
        cell.dateLastField.text = reminder.dateLast
        cell.dateNextField.text = reminder.dateNext
        cell.frequencyField.text = reminder.frequency
        cell.noteField.text = reminder.note
        cell.customCellDelegate = self
        cell.pickerDelegate = self
        cell.textCalculationDelegate = self // VERY IMPORTANT!
        
        // To initialize picker with data from the database
        if let index = pickerData.firstIndex(of: reminder.period) {
            cell.picker.selectRow(index, inComponent: 0, animated: false)
        }
        
        // Modify display as a function of period
        if reminder.period == "one-time" {
            cell.frequencyField.isHidden = true
            cell.dateNextStack.isHidden = true
            cell.lastLabel.text = "Due:"
            cell.repeatsEveryLabel.text = "Frequency:"
            cell.setPickerLeading(101)
        } else {
            cell.frequencyField.isHidden = false
            cell.dateNextStack.isHidden = false
            cell.lastLabel.text = "Last:"
            cell.repeatsEveryLabel.text = "Repeats every:"
            cell.setPickerLeading(185)
        }
        
        // Modify descriptionField background color as a function of due date in relation to today's date
        guard cell.dateNextField.text != "" else { return cell }
        let today = Date()
        let dateNext = DF.dateFormatter.date(from: reminder.dateNext)
        if dateNext ?? Date() < today {
            // Compare dateNext and today ignoring times (.day granularity)
            if Calendar.current.isDate(dateNext!, equalTo: today, toGranularity: .day) {
                cell.descriptionField.backgroundColor = .brandLightGreen
                
            } else {
                cell.descriptionField.backgroundColor = .brandPink
            }
        } else {
            cell.descriptionField.backgroundColor = .systemGray5
        }
        return cell
    }
}

//MARK: - UITableViewDelegate Implementation
extension RemindersViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        // Currently active text field needs to resign first responder so that didEndEditing will fire.
        activeTextField?.resignFirstResponder()
        // Get the currently selected row (if any)
        if let selectedIndexPath = tableView.indexPathForSelectedRow {
            // Retrieve the data model for the currently selected row
            let selectedRowData = reminders[selectedIndexPath.section]

            // Check if the selectedRowData has changed.
            if selectedRowData.hasUnsavedChanges {
                // Prompt the user to save/discard changes
                // If the user chooses to stay on the current row, return nil
                // If the user confirms to proceed, handle saving/discarding and then return indexPath
                let alert = UIAlertController(title: "Unsaved Changes", message: "Do you want to save changes before selecting another row?", preferredStyle: .alert)
                alert.view.tintColor = .black
                alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { _ in
                    // Save changes for selectedRowData
                    self.saveReminder(selectedIndexPath.section)
                    // Then, proceed with selecting the new row
                    tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
                    tableView.delegate?.tableView?(tableView, didSelectRowAt: indexPath) // Manually call didSelectRowAt
                }))
                alert.addAction(UIAlertAction(title: "Discard", style: .destructive, handler: { _ in
                    self.discardChangesForSelectedRowData(selectedIndexPath)
                    // Then, proceed with selecting the new row
                    tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
                    tableView.delegate?.tableView?(tableView, didSelectRowAt: indexPath) // Manually call didSelectRowAt
                }))
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
                    // Do not select the new row
                    return
                }))
                self.present(alert, animated: true, completion: nil)

                return nil // Prevent the new row from being selected immediately
            } // end: "if selectedRowData.hasUnsavedChanges"
        } // end: "if let selectedIndexPath = tableView.indexPathForSelectedRow"

        // If no row is selected or no changes were detected, allow the selection
        return indexPath
    } // end: func
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = indexPath.section
        tableRow = row
        selectedIndexPath = indexPath
    }
    
}

//MARK: - CustomCellDelegate Implementation
extension RemindersViewController: CustomCellDelegate {
    func customCell(_ cell: CustomCell, didUpdateText textField: UITextField?) {
        guard let textField, let tableRow else { return }
        switch textField.tag {
        case 1: // description
            reminders[tableRow].description = textField.text ?? ""
        case 4: // frequency
            reminders[tableRow].frequency = textField.text ?? ""
        case 5: // note
            reminders[tableRow].note = textField.text ?? ""
        default:
            print("unknown")
        }
        reminders[tableRow].dateNext = calculatedDateNext
        reminders[tableRow].hasUnsavedChanges = true
    }
    
    func customCell(_ cell: CustomCell, didEndEditingWithField textField: UITextField) {
        guard let tableRow else { return }
        switch textField.tag {
        case 1: // description
            reminders[tableRow].description = textField.text ?? ""
        case 2: // dateLast
            reminders[tableRow].dateLast = textField.text ?? ""
        case 3: // dateNext
            reminders[tableRow].dateNext = textField.text ?? ""
        case 4: // frequency
            reminders[tableRow].frequency = textField.text ?? ""
        case 5: // note
            reminders[tableRow].note = textField.text ?? ""
        default:
            print("unknown")
        }
        reminders[tableRow].hasUnsavedChanges = true
    }
    
    func customCell(_ cell: CustomCell, didStartEditingWithField textField: UITextField) {
        activeTextField = textField
    }
    
    func pickerValueDidChange(inCell cell: CustomCell, withText text: String) {
            calculatedDateNext = text
        }
    
    func customCellFrequencyAlert(_ cell: CustomCell) {
        // Alert notification re: frequency when period is "one-time."
        let ac = UIAlertController(title: "one-time", message: "Frequency is set to zero for 'one-time'.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(ac, animated: true)
        
    }
    
    func datePickerValueDidChange(inCell cell: CustomCell, withDate date: Date) {
        guard let selectedIndexPath = tableView.indexPath(for: cell) else { print("selectedIndexPath is nil"); return }
        reminders[selectedIndexPath.section].dateLast = DF.dateFormatter.string(from: date)
        reminders[selectedIndexPath.section].hasUnsavedChanges = true
        tableView.selectRow(at: selectedIndexPath, animated: true, scrollPosition: .none)
        self.tableView.delegate?.tableView?(self.tableView, didSelectRowAt: selectedIndexPath) // Manually call didSelectRowAt
    }

}

//MARK: - PickerCellDelegate Implementation
extension RemindersViewController: PickerCellDelegate {
    func picker(cell: CustomCell, didSelectRow row: Int) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let section = indexPath.section     // <- use section, not row
        tableRow = section
        reminders[section].hasUnsavedChanges = true
        reminders[section].period = pickerData[row]
        
        reminders[section].dateNext = calculatedDateNext
//        if pickerData[row] == "one-time" {
//            reminders[section].frequency = "0"
//        }
        // reload the single row in that section
        let reloadIndexPath = IndexPath(row: 0, section: section)
        tableView.reloadRows(at: [reloadIndexPath], with: .none)
        
        tableView.selectRow(at: reloadIndexPath, animated: true, scrollPosition: .none)
        tableView.delegate?.tableView?(tableView, didSelectRowAt: reloadIndexPath)
        
//                if let indexPath = tableView.indexPath(for: cell) {
//                    // Update tableRow directly
//                    tableRow = indexPath.section
//                    reminders[indexPath.section].hasUnsavedChanges = true
//                    reminders[indexPath.section].period = pickerData[row]
//                    reminders[indexPath.section].dateNext = calculatedDateNext
//        
//                    if pickerData[row] == "one-time" {
//                        reminders[indexPath.section].frequency = "0"
//                    }
//                    tableView.reloadRows(at: [indexPath], with: .none)
//        
//                    // Programmatically select the row
//                    tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
//                    tableView.delegate?.tableView?(tableView, didSelectRowAt: indexPath) // Manually call didSelectRowAt
//                }
    }
}

//MARK: - TextCalculationDelegate Implementation
extension RemindersViewController: TextCalculationDelegate {
    func didCalculateText(_ text: String) {
        calculatedDateNext = text
    }
}

