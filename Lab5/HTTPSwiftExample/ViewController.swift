//
//  ViewController.swift
//  HTTPSwiftExample
//
//  Created by Eric Larson on 3/30/15.
//  Copyright (c) 2015 Eric Larson. All rights reserved.
//

import UIKit
import AVFoundation
import CoreMotion
import VideoToolbox
import CoreML

class ViewController: UIViewController, URLSessionDelegate {
    
    private let serverHandler = ServerHalder()
    let animation = CATransition()
    
    @IBOutlet weak var imageView: UIImageView!
    
    // -------- Take a picture --------
    @IBOutlet weak var takePictureButton: UIButton!
    @IBAction func takePictureOnClick(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self
        picker.allowsEditing = true // allows editting so that users can crop and zoom in on faces
        present(picker, animated: true)
    }
    
    @IBOutlet weak var expTextView: UITextField!
    let expressions = ["", "happy", "sad", "neutral", "disgust", "surprise", "angry", "fear"]
    var pickerView = UIPickerView()
    var expToBeTrained = ""
    var modelSelected = ""

    // -------- Add an image to database --------
    @IBOutlet weak var addImageButton: UIButton!
    @IBAction func addImage(_ sender: Any) {
        let image : UIImage? = self.imageView.image
        // sanity checks before addImage
        if (expToBeTrained == "") {
            // if no expression is selected, ask user to select one
            // referenced: https://medium.com/design-and-tech-co/displaying-pop-ups-in-ios-applications-f550a66a5923
            let alert = UIAlertController(title: "Cannot Add Image", message: "Please select a label", preferredStyle: .alert)
            let okayAction = UIAlertAction(title: "Okay", style: .default)
            alert.addAction(okayAction)
            present(alert, animated: true, completion: nil)
        }
        else if (image == nil) {
            // if no image has been taken, ask user to take a picture
            let alert = UIAlertController(title: "Cannot Add Image", message: "Please take a picture", preferredStyle: .alert)
            let okayAction = UIAlertAction(title: "Okay", style: .default)
            alert.addAction(okayAction)
            present(alert, animated: true, completion: nil)
        }
        else {
            // add image to backend
            print(expToBeTrained)
            let image = self.imageView.image!
            // get the pixel data from the image
            let data = image.pixelData()
            // reshape the array into 1-d
            let dataArr = self.reshapeArray(arr: data!)
            print(dataArr.count)
            // send the array and label to backend
            self.serverHandler.addImage(dataArr, label: expToBeTrained)
            // a success alert of adding image
            let alert = UIAlertController(title: "Add Image Successful!", message: "", preferredStyle: .alert)
            let okayAction = UIAlertAction(title: "Okay", style: .default)
            alert.addAction(okayAction)
            present(alert, animated: true, completion: nil)
        }
    }
    
    // -------- Function for training the model --------
    @IBOutlet weak var trainButton: UIButton!
    @IBAction func trainModel(_ sender: Any) {
        // check if there is enough data for training. ie: each label should at least has one image
        self.serverHandler.checkEnoughLabel()
        let enoughData = self.serverHandler.enoughData
        print(enoughData)
        if (enoughData == false) {
            // fail alert, also works in the server is down
            let alert = UIAlertController(title: "Cannot Train Model", message: "Missing labels, please upload at least one image for each label", preferredStyle: .alert)
            let okayAction = UIAlertAction(title: "Okay", style: .default)
            alert.addAction(okayAction)
            present(alert, animated: true, completion: nil)
        } else {
            // calling backend to train the model
            self.serverHandler.trainModel()
            // prompt success alert
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
        // a different criteria for training and comparing
        // in this case, we need more data since we are doing train_test_split to compare the accuracy
        self.serverHandler.checkEnoughLabelForCompare()
        let enoughDataToCompare = self.serverHandler.enoughDataToCompare
        print(enoughDataToCompare)
        if (enoughDataToCompare == false) {
            // fail alert, also works in the server is down
            let alert = UIAlertController(title: "Cannot Train and Compare Model", message: "Comparing models need more images!", preferredStyle: .alert)
            let okayAction = UIAlertAction(title: "Okay", style: .default)
            alert.addAction(okayAction)
            present(alert, animated: true, completion: nil)
        } else {
            // call backend to train and compare model
            self.serverHandler.trainAndCompareModel()
            // update the statistics labels
            self.lrAccLabel.text = "Logistic Regression: \(self.serverHandler.lrAcc)"
            self.bdtAccLabel.text = "Boosted Decision Tree: \(self.serverHandler.bdtAcc)"
            // prompt success alert
            let alert = UIAlertController(title: "Model Trained Successful!", message: "You can now take pictures and predict!", preferredStyle: .alert)
            let okayAction = UIAlertAction(title: "Okay", style: .default)
            alert.addAction(okayAction)
            present(alert, animated: true, completion: nil)
        }
        
    }
    
    // -------- Function for selecting model --------
    @IBOutlet weak var modelSelector: UISegmentedControl!
    @IBAction func selectModel(_ sender: Any) {
        // update model selected according to selector
        self.modelSelected = self.modelSelector.titleForSegment(at: self.modelSelector.selectedSegmentIndex)!
    }
    
    // -------- Function for predicting --------
    @IBOutlet weak var predictionLabel: UILabel!
    @IBOutlet weak var predictButton: UIButton!
    @IBAction func predictClicked(_ sender: Any) {
        // check if image is available
        let image : UIImage? = self.imageView.image
        if (image == nil) {
            // if there is no image, ask user to take a pictire
            let alert = UIAlertController(title: "Cannot Predict", message: "Please take a picture", preferredStyle: .alert)
            let okayAction = UIAlertAction(title: "Okay", style: .default)
            alert.addAction(okayAction)
            present(alert, animated: true, completion: nil)
        }
        else {
            // get the image and image data
            let image = self.imageView.image!
            let data = image.pixelData()
            let dataArr = self.reshapeArray(arr: data!)
            var pred = "None"
            if (self.preTrainSelected == false) {
                // if not using the pretrained model, call the http server and pass the selected model
                self.serverHandler.predict(image: dataArr, model: self.modelSelected)
                // get result from the serverHandler and update prediction 
                pred = self.serverHandler.resultLabel
            }
            else {
                // if using the pre-trained model
                let seq = self.toMLMultiArray(dataArr)
                if (self.modelSelected == "LR") {
                    // using logistic regression
                    guard let outputTuri = try? lrModel.prediction(sequence: seq) else {
                        fatalError("Unexpected runtime error.")
                    }
                    pred = outputTuri.target
                } else if (self.modelSelected == "BDT" ) {
                    // using boosted decision tree
                    guard let outputTuri = try? bdtModel.prediction(sequence: seq) else {
                        fatalError("Unexpected runtime error.")
                    }
                    // update prediction
                    pred = outputTuri.target
                }
            }
            if (pred == "None") {
                // if the model does not exist, will return None from server, alert showing
                // also works if the server is not connected
                let alert = UIAlertController(title: "Cannot Predict", message: "Please train the model first", preferredStyle: .alert)
                let okayAction = UIAlertAction(title: "Okay", style: .default)
                alert.addAction(okayAction)
                present(alert, animated: true, completion: nil)
                self.predictionLabel.text = "Prection: None"
            } else {
                self.predictionLabel.text = "Prection: \(pred)"
            }
        }
    }
    
    // -------- Use Pre-Trained Model ------
    @IBOutlet weak var preTrainSwitch: UISwitch!
    var preTrainSelected = false
    @IBAction func toggleSwitch(_ sender: UISwitch) {
        // toggle switch to select if the model is pretrained
        if sender.isOn {
            self.preTrainSelected = true
        } else {
            self.preTrainSelected = false
        }
        print(self.preTrainSelected)
    }
    
    // initialize pre-trained boosted decision tree model
    lazy var bdtModel:bdt_model = {
        do{
            let config = MLModelConfiguration()
            return try bdt_model(configuration: config)
        }catch{
            print(error)
            fatalError("Could not load bdt")
        }
    }()
    
    // initialize pre-trained logistic regression model
    lazy var lrModel:lr_model = {
        do{
            let config = MLModelConfiguration()
            return try lr_model(configuration: config)
        }catch{
            print(error)
            fatalError("Could not load lr")
        }
    }()
    
    // to MLMultiArray is for pre-trained coreml models
    private func toMLMultiArray(_ arr: [Float]) -> MLMultiArray {
        // initialize sequence with required space
        guard let sequence = try? MLMultiArray(shape:[42849], dataType:MLMultiArrayDataType.double) else {
            fatalError("Unexpected runtime error. MLMultiArray could not be created")
        }
        let size = Int(truncating: sequence.shape[0])
        for i in 0..<size {
            // assign original array data to the new sequence
            sequence[i] = NSNumber(value: arr[i])
        }
        return sequence
    }
    
    @IBOutlet weak var staticsBgLabel: UILabel!
    
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
        
        trainButton.layer.cornerRadius = 3
        trainButton.layer.borderWidth = 1
        trainButton.layer.borderColor = UIColor.systemBlue.cgColor
        
        trainAndCompareButton.layer.cornerRadius = 3
        trainAndCompareButton.layer.borderWidth = 1
        trainAndCompareButton.layer.borderColor = UIColor.systemBlue.cgColor
        
        staticsBgLabel.layer.masksToBounds = true
        staticsBgLabel.layer.cornerRadius = 3
        
    }
    
    // this function is for reshape image array
    private func reshapeArray(arr: [UInt8]) -> [Float]{
        var tmpArr:[Float] = []
        var grayscaled:Float = 0
        
        // calculate the gray from RGB channels and append to a temporary array
        // since the expressions are normally irrelvant with the image color
        for i in stride(from: 0, to: arr.count, by: 4){
            // The Weighted Method of RGB to grayscale
            grayscaled = 0.299*Float(arr[i]) + 0.587*Float(arr[i+1]) + 0.114*Float(arr[i+2])
            tmpArr.append(grayscaled)
            // skipping the alpha channel
        }
        
        // dimension reduction for the image, skipping some of the pixels
        // since we don't want to overload the data passed to backend and excede database limit
        var retArr:[Float] = []
        // from 1242*1242 to 207*207
        for i in stride(from: 0, to: 1242, by: 1) {
            for j in stride(from: 0, to: 1242, by: 1){
                if (i % 6 == 0 && j % 6 == 0) {
                    retArr.append(tmpArr[j+i*1242])
                }
                else { continue }
            }
        }
        return retArr
    }

}

// https://www.youtube.com/watch?v=hg-6sOOxeHA
// image view extension
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
// extension for selecting the label
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
        expTextView.resignFirstResponder() // resign after selecting
        expToBeTrained = expressions[row] // update expression label selected to be uploaded
    }
}

//https://stackoverflow.com/questions/33768066/get-pixel-data-as-array-from-uiimage-cgimage-in-swift
// extension for UIImage to get the pixel data from the image
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

