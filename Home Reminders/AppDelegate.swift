//
//  AppDelegate.swift
//  Home Reminders
//
//  Created by Lawrence H. Schoch on 9/6/25.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor.brandLightYellow]
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.brandLightBlue
        appearance.titleTextAttributes = [.foregroundColor: UIColor.brandLightYellow] // center title
    
        // Create button appearance, with color
        let buttonAppearance = UIBarButtonItemAppearance(style: .plain)
                                          buttonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.brandLightYellow]

        // Apply button appearance
        appearance.buttonAppearance = buttonAppearance

        // Apply tint to the back arrow "chevron"
                                          UINavigationBar.appearance().tintColor = UIColor.brandLightYellow // back arrow
        
                                          appearance.backButtonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.brandLightYellow] // ToDoey
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

