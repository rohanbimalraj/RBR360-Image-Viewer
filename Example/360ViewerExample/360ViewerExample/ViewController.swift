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
        
        //Please add photo library usage description in info pList to use image capture fuctionality.
        NotificationCenter.default.addObserver(self, selector: #selector(imageSavedSuccessfully), name: .imageSaveSuccess, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(imageSavedWithError), name: .imageSaveFailure, object: nil)
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
    
    @objc func imageSavedSuccessfully() {
        let alert = UIAlertController(title: "Success", message: "Captured image is saved successfully in Photos", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        self.present(alert, animated: true)
    }
    
    @objc func imageSavedWithError() {
        let alert = UIAlertController(title: "Failure", message: "Unfortunately captured image couldn't be saved", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        self.present(alert, animated: true)
    }
    
    @IBAction func captureButtonActiob(_ sender: Any) {
        rbrView.captureScreen()
    }
}

