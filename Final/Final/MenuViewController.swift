//
//  MenuViewController.swift
//  Final
//
//  Created by iOS Training on 3/14/20.
//  Copyright © 2020 JETS. All rights reserved.
//

class MenuViewController: UITableViewController {
    
    override func viewDidLoad() {
    }
    
    @IBOutlet weak var rated: UIButton!
    @IBOutlet weak var popular: UIButton!
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        _ = MoviesViewController.which = (sender?.isEqual(popular))!
    }
}
