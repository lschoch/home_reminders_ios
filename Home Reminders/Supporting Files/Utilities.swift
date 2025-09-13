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
