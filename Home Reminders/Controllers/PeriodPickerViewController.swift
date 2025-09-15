//
//  PeriodPickerViewController.swift
//  Home Reminders
//
//  Created by Lawrence H. Schoch on 9/15/25.
//

import UIKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var dropdownButton: UIButton!
    var dropdownTableView: UITableView?
    let menuItems = ["one-time", "days", "weeks", "months", "years"]

    override func viewDidLoad() {
        super.viewDidLoad()
        setupDropdownTableView()
    }

    func setupDropdownTableView() {
        dropdownTableView = UITableView(frame: .zero, style: .plain)
        dropdownTableView?.dataSource = self
        dropdownTableView?.delegate = self
        dropdownTableView?.isHidden = true
        dropdownTableView?.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dropdownTableView!)

        // Add constraints to position the table view relative to the button
        NSLayoutConstraint.activate([
            dropdownTableView!.topAnchor.constraint(equalTo: dropdownButton.bottomAnchor),
            dropdownTableView!.leadingAnchor.constraint(equalTo: dropdownButton.leadingAnchor),
            dropdownTableView!.widthAnchor.constraint(equalTo: dropdownButton.widthAnchor),
            dropdownTableView!.heightAnchor.constraint(equalToConstant: 150) // Adjust height as needed
        ])
    }

    @IBAction func dropdownButtonTapped(_ sender: UIButton) {
        dropdownTableView?.isHidden.toggle()
    }

    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") ?? UITableViewCell(style: .default, reuseIdentifier: "cell")
        cell.textLabel?.text = menuItems[indexPath.row]
        return cell
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        dropdownButton.setTitle(menuItems[indexPath.row], for: .normal)
        dropdownTableView?.isHidden = true
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
