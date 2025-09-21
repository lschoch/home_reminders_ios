//
//  NewItemViewController.swift
//  Home Reminders
//
//  Created by Lawrence H. Schoch on 9/6/25.
//

import UIKit

class NewItemViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        if let navBar = navigationController?.navigationBar {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .brandLightBlue // nav bar color
            appearance.titleTextAttributes = [.foregroundColor: UIColor.brandLightYellow] // center title
            
            // Change the back button background (the "circle")
            appearance.backButtonAppearance.normal.backgroundImage = UIImage(color: .brandLightYellow, size: CGSize(width: 30, height: 30)).withRoundedCorners(radius: 15)

            navBar.standardAppearance = appearance
            navBar.scrollEdgeAppearance = appearance
        }

    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension UIImage {
    convenience init(color: UIColor, size: CGSize) {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        color.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        self.init(cgImage: image!.cgImage!)
    }

    func withRoundedCorners(radius: CGFloat) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        let rect = CGRect(origin: .zero, size: size)
        UIBezierPath(roundedRect: rect, cornerRadius: radius).addClip()
        draw(in: rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image ?? self
    }
}
