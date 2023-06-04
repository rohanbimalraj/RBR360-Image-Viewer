//
//  ViewController.swift
//  360ViewerExample
//
//  Created by Rohan Bimal Raj on 03/06/23.
//

import UIKit
import RBR360ImageViewer

class ViewController: UIViewController {

    /*
     1.Add a view to your storyboard.
     2.Change class from UIView to RBRView in the storyboard inspector.
     3.Create Outlet of the new view.
     */
    @IBOutlet weak var rbrView: RBRView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let url = Bundle.main.url(forResource: "classRoom", withExtension: "jpeg")
        rbrView.loadImage(with: url!, camera: .gesture)
        
        NotificationCenter.default.addObserver(self, selector: #selector(itemRemoved), name: .deletedModelName, object: nil)
    }

    @IBAction func addButtonACtion(_ sender: Any) {
        let url = Bundle.main.url(forResource: "toy_drummer", withExtension: "usdz")
        rbrView.addModelToScene(with: url!)
    }
    @objc func itemRemoved(_ notification: Notification) {
        if let name = notification.userInfo?["name"] as? String {
            print("Removed item:", name)
        }
    }

}

