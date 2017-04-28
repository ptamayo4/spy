//
//  LoginViewController.swift
//  SPY
//
//  Created by Patrick Tamayo on 4/27/17.
//  Copyright © 2017 Patrick Tamayo. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {
    
    @IBOutlet weak var aliasTextField: UITextField!
    
    @IBAction func enterButtonPressed(_ sender: UIButton) {
        performSegue(withIdentifier: "loginSegue", sender: UIButton())
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        var vc = segue.destination as! MainViewController
        vc.delegate? = self as! LoginDelegate
        vc.aliasString = aliasTextField.text!
    }
    
}
