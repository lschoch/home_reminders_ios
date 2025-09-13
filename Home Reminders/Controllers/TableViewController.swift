//
//  ViewController.swift
//  Home Reminders
//
//  Created by Lawrence H. Schoch on 9/6/25.
//

import UIKit

class TableViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let docName = "home_reminders"
        let docExt = "db"
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        let destURL = documentsURL!.appendingPathComponent(docName).appendingPathExtension(docExt)
        print(destURL) // Location of home_reminders.db
//        copyFileToDocumentsFolder(nameForFile: docName, extForFile: docExt)
    }

}

