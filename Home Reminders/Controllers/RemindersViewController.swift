//
//  ViewController.swift
//  Home Reminders
//
//  Created by Lawrence H. Schoch on 9/6/25.
//

import UIKit
import SQLite
import AppAuth
// import GoogleAPIClientForRESTCore
import GoogleAPIClientForREST_Calendar
import GTMSessionFetcherCore
import GoogleSignIn

class RemindersViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var reminders: [Reminder] = []
    var remindersOriginal: [Reminder] = []
    var tableRow: Int?
    let pickerData = ["one-time", "days", "weeks", "months", "years"]
    var calculatedDateNext: String = ""
    var selectedIndexPath: IndexPath?
    var activeTextField: UITextField?
    let cellSpacingHeight: CGFloat = 10.0
    var customHeaderView: UIView!
    var headerLabel: UILabel!
    
    private let service = GTLRCalendarService()
    
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
        
        navigationItem.title = "Home Reminders"
        
        // Observe for significant time changes (e.g., midnight) so that date dependent items can be updated as needed.
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleSignificantTimeChange),
                                               name: UIApplication.significantTimeChangeNotification,
                                               object: nil)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "CustomCell", bundle: nil), forCellReuseIdentifier: "CustomCell")
        tableView.rowHeight = 160
        tableView.sectionHeaderTopPadding = 0
        
        // Dismiss keyboard when tapping outside text field.
        //        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        //                view.addGestureRecognizer(tapGesture)
        
        // add long-press recognizer to tableView to deselect a selected cell
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPress.minimumPressDuration = 0.6
        tableView.addGestureRecognizer(longPress)
        
        setupHeaderView()
        
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
    
    func setupHeaderView() {
        // Create the header view and its elements
        customHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 25))
        customHeaderView.backgroundColor = .brandLightBlue
        
        headerLabel = UILabel(frame: customHeaderView.bounds.insetBy(dx: 0, dy: 0))
        headerLabel.textAlignment = .center
//        headerLabel.font = UIFont.boldSystemFont(ofSize: 16)
        headerLabel.font = UIFont.systemFont(ofSize: 15)
        headerLabel.textColor = .brandLightYellow
        updateHeaderLabelText()
        customHeaderView.addSubview(headerLabel)
        
        // Set it as the table's header view
        tableView.tableHeaderView = customHeaderView
    }
    
    func updateHeaderLabelText() {
        // Get the current date
        let currentDate = Date()
        // Format the date into a string
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd-yyyy"
        let dateString = formatter.string(from: currentDate)
        headerLabel.text = "Today is \(dateString)"
    }

    @objc func handleSignificantTimeChange() {
        print("Significant time change notification received! Updating UI/data.")
        updateHeaderLabelText()
        // Reload data to reset date-dependent cell background color changes
        loadReminders()
        tableView.reloadData()
    }
    
    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        let point = gesture.location(in: tableView)
        guard let indexPath = tableView.indexPathForRow(at: point) else { return }
        
        // If the long-pressed row is currently selected, run the existing deselect flow
        if let selected = tableView.indexPathForSelectedRow, selected == indexPath {
            // reuse your existing deselect logic (shows alerts / saves as implemented)
            deselectReminder()
            //        } else {
            //            // otherwise select the long-pressed row
            //            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
            //            tableView.delegate?.tableView?(tableView, didSelectRowAt: indexPath)
            //        }
        }
    }
    
    @objc func hideKeyboard() {
        view.endEditing(true)
    }
    @IBAction func upArrowPressed(_ sender: UIBarButtonItem) {
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
        guard tableView.indexPathForSelectedRow != nil else {
            notificationAlert(title: "Delete Reminder", message: "No reminder selected for deletion.")
            return
        }
        
        let alertController = UIAlertController(title: "Delete Reminder", message: "Are you sure you want to delete this reminder?", preferredStyle: .alert)
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
                //                // Select the row below the deleted row.
                //                self.tableView.selectRow(at: selectedIndexPath, animated: true, scrollPosition: .none)
                //                self.tableView.delegate?.tableView?(self.tableView, didSelectRowAt: selectedIndexPath) // Manually call didSelectRowAt
                
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
    
    @IBAction func calendarButtonPressed(_ sender: UIButton) {
        showCalendarConfirmationAlert()
    }
    
    func showCalendarConfirmationAlert() {
        guard tableView.indexPathForSelectedRow != nil else {
            notificationAlert(title: "Create Calendar Event", message: "No reminder selected.")
            return
        }
        
        let alertController = UIAlertController(title: "Create Calendar Event", message: "Create calendar event for this reminder?", preferredStyle: .alert)
        alertController.view.tintColor = .black
        
        let yesAction = UIAlertAction(title: "Yes", style: .default) { _ in
            // Handle "Yes" tap
            if let selectedIndexPath = self.tableView.indexPathForSelectedRow {
                self.signInToAccessCalendar(selectedIndexPath)
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            // Handle "Cancel" tap
            return
        }
        
        alertController.addAction(yesAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    func notificationAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.view.tintColor = .black
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    func deselectReminder() {
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
                    //                    self.tableView.selectRow(at: selectedIndexPath, animated: true, scrollPosition: .none)
                    //                    self.tableView.delegate?.tableView?(self.tableView, didSelectRowAt: selectedIndexPath) // Manually call didSelectRowAt
                }))
                alert.addAction(UIAlertAction(title: "Discard", style: .destructive, handler: { _ in
                    // Discard changes for selectedRowData
                    self.discardChangesForSelectedRowData(selectedIndexPath)
                    //                    self.tableView.selectRow(at: selectedIndexPath, animated: true, scrollPosition: .none)
                    //                    self.tableView.delegate?.tableView?(self.tableView, didSelectRowAt: selectedIndexPath) // Manually call didSelectRowAt
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
    
    //MARK: - Google Calendar Methods
    func signInToAccessCalendar(_ selectedIndexPath: IndexPath?) {
        // Request Calendar scopes and sign in if needed.
        let additionalScopes = "https://www.googleapis.com/auth/calendar.events" // or full calendar scope
        
        // Check whether user is already signed in.
        GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
            if error != nil || user == nil {
                // Show the app's signed-out state.
                //                self.notificationAlert(title: "Sign In", message: "Please sign in to access your calendar.")
                print("Please sign in to access your calendar.")
                GIDSignIn.sharedInstance.signIn(withPresenting: self, hint: additionalScopes) { signInResult, error in
                    if let error = error {
                        self.notificationAlert(title: "Google Sign-In Error", message: error.localizedDescription)
                        return
                    }
                    guard (signInResult?.user) != nil else {
                        self.notificationAlert(title: "Sign-In", message: "No user returned")
                        return
                    }
                    // Provide credentials to the GTLR service
                    self.service.authorizer = signInResult?.user.fetcherAuthorizer
                    DispatchQueue.main.async {
                        self.createAllDayEvent(selectedIndexPath!)
                    }
                }
            } else {
                // Show the app's signed-in state.
                //                self.notificationAlert(title: "Signed In", message: "You are already signed in.")
                print("You are already signed in.")
                self.service.authorizer = user!.fetcherAuthorizer
                DispatchQueue.main.async {
                    self.createAllDayEvent(selectedIndexPath!)
                }
            }
        }
    }
    
    // Build and send a GTLRCalendar_Event
    func createAllDayEvent(_ selectedIndexPath: IndexPath) {
        
        // Check for an existing Google Calendar event with same summary and date as the selected reminder.
        let selectedReminder = reminders[selectedIndexPath.section]
        let targetDateString = selectedReminder.dateLast
        let targetDate = DF.dateFormatter.date(from: targetDateString)
        
        let query = GTLRCalendarQuery_EventsList.query(withCalendarId: "primary")
        
        // Set timeMin and timeMax to filter events for the specific date
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds] // Adjust as needed
        
        // Assuming 'targetDate' is the Date object representing the day you're checking
        let startOfDay = Calendar.current.startOfDay(for: targetDate!)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        
        query.timeMin = GTLRDateTime(date: startOfDay)
        query.timeMax = GTLRDateTime(date: endOfDay)
        query.singleEvents = true // Important for recurring events
        
        service.executeQuery(query) { (ticket, response, error) in
            if let error = error {
                print("Error listing events: \(error.localizedDescription)")
                return
            }
            
            guard let eventList = response as? GTLRCalendar_Events else {
                print("Invalid response type.")
                return
            }
            
            // Inside the completion handler of the events.list query:
            let targetSummary = selectedReminder.description
            
            var eventFound = false
            for event in eventList.items ?? [] {
                print(event.summary ?? "Missing summary")
                if event.summary == "HR: " + targetSummary {
                    // Further check the date. For all-day events, 'start.date' is used.
                    // For timed events, 'start.dateTime' is used.
                    // You'll need to handle both cases or ensure your 'targetDate' aligns with the event's start type.
                    
                    let eventStartDate: Date?
                    if let dateTime = event.start?.dateTime?.date {
                        eventStartDate = dateTime
                    } else if let date = event.start?.date?.date {
                        eventStartDate = date
                    } else {
                        eventStartDate = nil
                    }
                    
                    if let eventStartDate = eventStartDate, Calendar.current.isDate(eventStartDate, inSameDayAs: targetDate!) {
                        print("Found an event with matching summary and date: \(event.summary ?? "")")
                        eventFound = true
                        self.notificationAlert(title: "Create Event", message: "Cancelled - found an event with matching summary and date.")
                        break // Exit loop once a match is found
                    }
                }
            }
            
            if !eventFound {
                print("No event found with matching summary and date.")
                // Proceed to create the new event.
                let allDayEvent = GTLRCalendar_Event()
                allDayEvent.summary = "HR: " + self.reminders[selectedIndexPath.section].description
                allDayEvent.descriptionProperty = self.reminders[selectedIndexPath.section].note
                
                // Use dateLast as the event date.
                let startString = self.reminders[selectedIndexPath.section].dateLast
                let startDate = DF.dateFormatter.date(from: startString)!
                // For all day event, end date is the day after the start date.
                let endDate = Calendar.current.date(byAdding: .day, value: 1, to: startDate)!
                // Convert end date to string.
                let endString   = DF.dateFormatter.string(from: endDate) // exclusive
                
                let startDT = GTLRCalendar_EventDateTime()
                // For all day event, use date property, not dateTime.
                startDT.date = GTLRDateTime(rfc3339String: startString)
                allDayEvent.start = startDT
                let endDT = GTLRCalendar_EventDateTime()
                endDT.date = GTLRDateTime(rfc3339String: endString)
                allDayEvent.end = endDT
                
                let createQuery = GTLRCalendarQuery_EventsInsert.query(withObject: allDayEvent, calendarId: "primary")
                self.service.executeQuery(createQuery) { ticket, object, error in
                    if let error = error {
                        self.notificationAlert(title: "Calendar Error", message: error.localizedDescription)
                        return
                    }
                    self.notificationAlert(title: "Success", message: "Event created")
                }
            }
        }
    }
} // end RemindersViewController class

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
        guard (indexPath != selectedIndexPath) || (selectedIndexPath == nil) else { return selectedIndexPath }
        
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


