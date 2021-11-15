//
//  ViewController.swift
//  HTTPSwiftExample
//
//  Created by Eric Larson on 3/30/15.
//  Copyright (c) 2015 Eric Larson. All rights reserved.
//

// This exampe is meant to be run with the python example:
//              tornado_example.py 
//              from the course GitHub repository: tornado_bare, branch sklearn_example


// if you do not know your local sharing server name try:
//    ifconfig |grep inet   
// to see what your public facing IP address is, the ip address can be used here
//let SERVER_URL = "http://erics-macbook-pro.local:8000" // change this for your server name!!!
//let SERVER_URL = "http://10.9.165.78:8000" // change this for your server name!!!

import UIKit
import AVFoundation
import CoreMotion
import VideoToolbox
// pop up button : https://www.youtube.com/watch?v=VzT15es8bjM

class ViewController: UIViewController, URLSessionDelegate {
    
    // MARK: Class Properties
    lazy var session: URLSession = {
        let sessionConfig = URLSessionConfiguration.ephemeral
        
        sessionConfig.timeoutIntervalForRequest = 5.0
        sessionConfig.timeoutIntervalForResource = 8.0
        sessionConfig.httpMaximumConnectionsPerHost = 1
        
        return URLSession(configuration: sessionConfig,
            delegate: self,
            delegateQueue:self.operationQueue)
    }()
    
    let operationQueue = OperationQueue()
    let motionOperationQueue = OperationQueue()
    let calibrationOperationQueue = OperationQueue()
    let bridge = OpenCVBridge()
    
    
    private let serverHandler = ServerHalder()
//    var ringBuffer = RingBuffer()
    let animation = CATransition()
//    let motion = CMMotionManager()
    
    @IBOutlet weak var imageView: UIImageView!
    
    // -------- Take a picture --------
    @IBOutlet weak var takePictureButton: UIButton!
    @IBAction func takePictureOnClick(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self
        picker.allowsEditing = true
        present(picker, animated: true)
    }
    
    @IBOutlet weak var expTextView: UITextField!
    let expressions = ["happy", "sad", "neutral", "disgust", "surprise", "angry", "fear"]
    var pickerView = UIPickerView()
    var expToBeTrained = ""
    var modelSelected = ""

    // -------- Add an image to database --------
    @IBOutlet weak var addImageButton: UIButton!
    @IBAction func addImage(_ sender: Any) {
        let image : UIImage? = self.imageView.image
        // sanity checks before addImage
        if (expToBeTrained == "") {
            // referenced: https://medium.com/design-and-tech-co/displaying-pop-ups-in-ios-applications-f550a66a5923
            let alert = UIAlertController(title: "Cannot Add Image", message: "Please select a label", preferredStyle: .alert)
            let okayAction = UIAlertAction(title: "Okay", style: .default)
            alert.addAction(okayAction)
            present(alert, animated: true, completion: nil)
        }
        else if (image == nil) {
            let alert = UIAlertController(title: "Cannot Add Image", message: "Please take a picture", preferredStyle: .alert)
            let okayAction = UIAlertAction(title: "Okay", style: .default)
            alert.addAction(okayAction)
            present(alert, animated: true, completion: nil)
        }
        else {
            print(expToBeTrained)
            let image = self.imageView.image!
            let data = image.pixelData()
            let dataArr = self.reshapeArray(arr: data!)
            print(dataArr.count)
            self.serverHandler.addImage(dataArr, label: expToBeTrained)
            let alert = UIAlertController(title: "Add Image Successful!", message: "", preferredStyle: .alert)
            let okayAction = UIAlertAction(title: "Okay", style: .default)
            alert.addAction(okayAction)
            present(alert, animated: true, completion: nil)
        }
    }
    
    // -------- Function for training the model --------
    @IBOutlet weak var trainButton: UIButton!
    @IBAction func trainModel(_ sender: Any) {
        // !! this if statement needs to be changed to check if each label has an image uploaded
        self.serverHandler.checkEnoughLabel()
        let enoughData = self.serverHandler.enoughData
        print(enoughData)
        if (enoughData == false) {
            // sanity check if the features are missing for each label
            // can only train model if there is at least one image for each label
            // referenced: https://medium.com/design-and-tech-co/displaying-pop-ups-in-ios-applications-f550a66a5923
            let alert = UIAlertController(title: "Cannot Train Model", message: "Missing labels, please upload at least one image for each label", preferredStyle: .alert)
            let okayAction = UIAlertAction(title: "Okay", style: .default)
            alert.addAction(okayAction)
            present(alert, animated: true, completion: nil)
        } else {
            self.serverHandler.trainModel()
            let alert = UIAlertController(title: "Model Trained Successful!", message: "You can now take pictures and predict!", preferredStyle: .alert)
            let okayAction = UIAlertAction(title: "Okay", style: .default)
            alert.addAction(okayAction)
            present(alert, animated: true, completion: nil)
        }
    }
    
    // -------- Function for training and comparing the models --------
    
    @IBOutlet weak var bdtAccLabel: UILabel!
    @IBOutlet weak var lrAccLabel: UILabel!
    @IBOutlet weak var trainAndCompareButton: UIButton!
    @IBAction func trainAndCompareModels(_ sender: Any) {
        self.serverHandler.checkEnoughLabelForCompare()
        let enoughDataToCompare = self.serverHandler.enoughDataToCompare
        print(enoughDataToCompare)
        if (enoughDataToCompare == false) {
            let alert = UIAlertController(title: "Cannot Train and Compare Model", message: "Comparing models need more images!", preferredStyle: .alert)
            let okayAction = UIAlertAction(title: "Okay", style: .default)
            alert.addAction(okayAction)
            present(alert, animated: true, completion: nil)
        } else {
            self.serverHandler.trainAndCompareModel()
            self.lrAccLabel.text = "Logistic Regression: \(self.serverHandler.lrAcc)"
            self.bdtAccLabel.text = "Boosted Decision Tree: \(self.serverHandler.bdtAcc)"
            let alert = UIAlertController(title: "Model Trained Successful!", message: "You can now take pictures and predict!", preferredStyle: .alert)
            let okayAction = UIAlertAction(title: "Okay", style: .default)
            alert.addAction(okayAction)
            present(alert, animated: true, completion: nil)
        }
        
    }
    
    // -------- Function for selecting model --------
    @IBOutlet weak var modelSelector: UISegmentedControl!

    @IBAction func selectModel(_ sender: Any) {
        self.modelSelected = self.modelSelector.titleForSegment(at: self.modelSelector.selectedSegmentIndex)!
    }
    
    // -------- Function for predicting --------
    @IBOutlet weak var predictionLabel: UILabel!
    @IBOutlet weak var predictButton: UIButton!
    @IBAction func predictClicked(_ sender: Any) {
        // check if image is available
        let image : UIImage? = self.imageView.image
        if (image == nil) {
            let alert = UIAlertController(title: "Cannot Predict", message: "Please take a picture", preferredStyle: .alert)
            let okayAction = UIAlertAction(title: "Okay", style: .default)
            alert.addAction(okayAction)
            present(alert, animated: true, completion: nil)
        }
        // check if the model is available
        else {
            let image = self.imageView.image!
            let data = image.pixelData()
            let dataArr = self.reshapeArray(arr: data!)
            self.serverHandler.predict(image: dataArr, model: self.modelSelected)
            let pred = self.serverHandler.resultLabel
            if (pred == "None") {
                // if the model does not exist, will return None form server, alert showing
                let alert = UIAlertController(title: "Cannot Predict", message: "Please train the model first", preferredStyle: .alert)
                let okayAction = UIAlertAction(title: "Okay", style: .default)
                alert.addAction(okayAction)
                present(alert, animated: true, completion: nil)
            } else {
                self.predictionLabel.text = "Prection: \(pred)"
            }
        }
    }
    
    
    // MARK: View Controller Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // create reusable animation
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        animation.type = CATransitionType.fade
        animation.duration = 0.5
        
        imageView.backgroundColor = .secondarySystemBackground
        pickerView.delegate = self
        pickerView.dataSource = self
        expTextView.inputView = pickerView
        self.modelSelected = "LR" // default to logistic regression
        
        // style for buttons and labels
        takePictureButton.layer.masksToBounds = true
        takePictureButton.layer.cornerRadius = 4
    }
    
    private func reshapeArray(arr: [UInt8]) -> [Float]{
        var tmpArr:[Float] = []
        var grayscaled:Float = 0
        
        // calculate the gray from RGB channels and append to a temporary array
        for i in stride(from: 0, to: arr.count, by: 4){
            grayscaled = 0.299*Float(arr[i]) + 0.587*Float(arr[i+1]) + 0.114*Float(arr[i+2])
            tmpArr.append(grayscaled)
            // skipping the alpha channel
        }
        
        // dimension reduction for the image, skipping some of the pixels
        var retArr:[Float] = []
        for i in stride(from: 0, to: 1242, by: 1) {
            for j in stride(from: 0, to: 1242, by: 1){
                if (i % 6 == 0 && j % 6 == 0) {
                    retArr.append(tmpArr[j+i*1242])
                }
                else {continue}
            }
        }
        return retArr
    }

}

// https://www.youtube.com/watch?v=hg-6sOOxeHA
extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage else {
            return
        }
        imageView.image = image
    }
}

// https://www.youtube.com/watch?v=FKuNwHZzJlA
extension ViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return expressions.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return expressions[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        expTextView.text = expressions[row]
        expTextView.resignFirstResponder()
        expToBeTrained = expressions[row]
    }
}

//https://stackoverflow.com/questions/33768066/get-pixel-data-as-array-from-uiimage-cgimage-in-swift
extension UIImage {
    func pixelData() -> [UInt8]? {
        let size = self.size
        let dataSize = size.width * size.height * 4
        var pixelData = [UInt8](repeating: 0, count: Int(dataSize))
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: &pixelData,
                                width: Int(size.width),
                                height: Int(size.height),
                                bitsPerComponent: 8,
                                bytesPerRow: 4 * Int(size.width),
                                space: colorSpace,
                                bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
        guard let cgImage = self.cgImage else { return nil }
        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))

        return pixelData
    }
 }

