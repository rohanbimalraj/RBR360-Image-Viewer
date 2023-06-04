# RBR360-Image-Viewer

A swift package for viewing spherical panoramas(2:1 aspect ratio) and additionally for viewing 3d models with the said panorama as the background environment.



[![MIT License](https://img.shields.io/badge/License-MIT-green.svg)](https://choosealicense.com/licenses/mit/)
[![GPLv3 License](https://img.shields.io/badge/Platforms-iOS%2013%20and%20above-orange)](https://opensource.org/licenses/)
[![AGPL License](https://img.shields.io/badge/Swift%20Package%20Manager-%20Compatible-brightgreen)](http://www.gnu.org/licenses/agpl-3.0)


## Features

- Spherical panoramas(2:1) with format .jpeg, .png, .hrd, .exr are supported
- Control camera either using device motion, touch gestures or buttons
- 3D models with format .dae, .obj and .usdz are supported.
- Translate, scale and rotate(y-axis) 3d models with gestures
- Take screen shots of virtual enviorment.
- Play animation which is build into the 3D model


## Demo


![rbr360ImageViewerOne](https://github.com/rohanbimalraj/RBR360-Image-Viewer/assets/81905077/6d8593e0-e85a-42fe-a37d-abc654e5ee74)




## Installation

If you are using Xcode 11 or higher, go to File / Swift Packages / Add Package Dependency… and enter package repository URL https://github.com/rohanbimalraj/RBR360-Image-Viewer.git then follow the instructions.

    
## Usage/Examples

```swift
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
```
- Add photo library usage description in info pList to use image capture fuctionality.
- To play and stop selected model animation call playSelectedNodeAnimation and stopSelectedNodeAnimation.

## Support

For support, email rohanbimalraj@gmail.com.

