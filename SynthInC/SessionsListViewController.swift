// SessionsListViewController.swift
// SynthInC
//
// Created by Brad Howes
// Copyright (c) 2016 Brad Howes. All rights reserved.

import UIKit

/**
 Main view controller for the application.
 */
final class SessionsListViewController: UITableViewController {

    enum BarButtonItems: Int {
        case add = 0, edit, done
    }

    @IBOutlet weak var addButton: UIBarButtonItem!
    @IBOutlet weak var editButton: UIBarButtonItem!

    /**
     Initialize and configure view after loading.
     */
    override func viewDidLoad() {
        setNeedsStatusBarAppearanceUpdate()
        addButton.isEnabled = true
        editButton.isEnabled = true
        super.viewDidLoad()
    }

    /**
     Tell the OS that we have a dark background
     
     - returns: UIStatusBarStyle.LigthContent
     */
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }

    /**
     Memory pressure in effect. Resources should be purged. But what?
     */
    override func didReceiveMemoryWarning() {
        print("*** memory pressure ***")
        super.didReceiveMemoryWarning()
    }

    /**
     Support deselection of a row. If a row is already selected, deselect the row.
     
     - parameter tableView: the instruments view
     - parameter indexPath: the index of the row that will be selected
     
     - returns: indexPath if row should be selected, nil otherwise
     */
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard let currentRow = (tableView.indexPathForSelectedRow as NSIndexPath?)?.row else { return indexPath }
        let newRow = (indexPath as NSIndexPath).row
        if currentRow == newRow {
            tableView.deselectRow(at: indexPath, animated: true)
            return nil
        }
        return indexPath
    }

    /**
     Obtain the number of rows to display in the instruments view
     - parameter tableView: the UITableView to work with
     - parameter numberOfRowsInSection: which section to report on (only one in our view)
     - returns: number of instruments active in music playback
     */
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1;
    }

    /**
     Obtain a UITableViewCell to use for an instrument, and fill it in with the instrument's values.
     - parameter tableView: the UITableView to work with
     - parameter indexPath: the row of the table to update
     - returns: UITableViewCell
     */
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "SessionCell" // !!! This must match prototype in Main.storyboard !!!
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as! SessionsTableViewCell
        cell.showsReorderControl = true
       
        let button = UIButton(type:.infoLight)
        cell.accessoryView = button
        
        return cell
    }    
}
