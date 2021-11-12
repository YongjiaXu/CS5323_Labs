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
let SERVER_URL = "http://10.9.165.78:8000" // change this for your server name!!!

import UIKit
import CoreMotion
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
    
    var ringBuffer = RingBuffer()
    let animation = CATransition()
    let motion = CMMotionManager()
    

    @IBOutlet weak var imageVIew: UIImageView!
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
    var expToBeTrained = "" //default is happy
    
    
    @IBOutlet weak var addImageButton: UIButton!
    @IBAction func addImage(_ sender: Any) {
        if (expToBeTrained == "") {
            // referenced: https://medium.com/design-and-tech-co/displaying-pop-ups-in-ios-applications-f550a66a5923
            let alert = UIAlertController(title: "Cannot Add Image", message: "Please select a label", preferredStyle: .alert)
            let okayAction = UIAlertAction(title: "Okay", style: .default)
            alert.addAction(okayAction)
            present(alert, animated: true, completion: nil)
        }
        else {
            print(expToBeTrained)
            // call backend to add the image
            let ciImage = self.imageVIew.image!.ciImage
            // get image array and send it to python server***
            
        }
    }
    
    @IBOutlet weak var trainButton: UIButton!
    @IBAction func trainModel(_ sender: Any) {
        // !! this if statement needs to be changed to check if each label has an image uploaded
        if (self.expToBeTrained == "") {
            // sanity check if the features are missing for each label
            // can only train model if there is at least one image for each label
            // referenced: https://medium.com/design-and-tech-co/displaying-pop-ups-in-ios-applications-f550a66a5923
            let alert = UIAlertController(title: "Cannot Train Model", message: "Missing features", preferredStyle: .alert)
            let okayAction = UIAlertAction(title: "Okay", style: .default)
            alert.addAction(okayAction)
            present(alert, animated: true, completion: nil)
        } else {
            print(self.expToBeTrained)
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
        
        imageVIew.backgroundColor = .secondarySystemBackground
        pickerView.delegate = self
        pickerView.dataSource = self
        expTextView.inputView = pickerView
        
    }

    //MARK: Get New Dataset ID
    
    
    //MARK: Comm with Server
//    func sendFeatures(_ array:[Double], withLabel label:CalibrationStage){
//        let baseURL = "\(SERVER_URL)/AddDataPoint"
//        let postUrl = URL(string: "\(baseURL)")
//
//        // create a custom HTTP POST request
//        var request = URLRequest(url: postUrl!)
//
//        // data to send in body of post request (send arguments as json)
//        let jsonUpload:NSDictionary = ["feature":array,
//                                       "label":"\(label)",
//                                       "dsid":self.dsid]
//
//
//        let requestBody:Data? = self.convertDictionaryToData(with:jsonUpload)
//
//        request.httpMethod = "POST"
//        request.httpBody = requestBody
//
//        let postTask : URLSessionDataTask = self.session.dataTask(with: request,
//            completionHandler:{(data, response, error) in
//                if(error != nil){
//                    if let res = response{
//                        print("Response:\n",res)
//                    }
//                }
//                else{
//                    let jsonDictionary = self.convertDataToDictionary(with: data)
//
//                    print(jsonDictionary["feature"]!)
//                    print(jsonDictionary["label"]!)
//                }
//
//        })
//
//        postTask.resume() // start the task
//    }
//
//    func getPrediction(_ array:[Double]){
//        let baseURL = "\(SERVER_URL)/PredictOne"
//        let postUrl = URL(string: "\(baseURL)")
//
//        // create a custom HTTP POST request
//        var request = URLRequest(url: postUrl!)
//
//        // data to send in body of post request (send arguments as json)
//        let jsonUpload:NSDictionary = ["feature":array, "dsid":self.dsid]
//
//
//        let requestBody:Data? = self.convertDictionaryToData(with:jsonUpload)
//
//        request.httpMethod = "POST"
//        request.httpBody = requestBody
//
//        let postTask : URLSessionDataTask = self.session.dataTask(with: request,
//                                                                  completionHandler:{
//                        (data, response, error) in
//                        if(error != nil){
//                            if let res = response{
//                                print("Response:\n",res)
//                            }
//                        }
//                        else{ // no error we are aware of
//                            let jsonDictionary = self.convertDataToDictionary(with: data)
//
//                            if let labelResponse = jsonDictionary["prediction"]{
//                                print(labelResponse)
//                                self.displayLabelResponse(labelResponse as! String)
//                            }
//                        }
//
//        })
//
//        postTask.resume() // start the task
//    }
//
    

    //MARK: JSON Conversion Functions
//    func convertDictionaryToData(with jsonUpload:NSDictionary) -> Data?{
//        do { // try to make JSON and deal with errors using do/catch block
//            let requestBody = try JSONSerialization.data(withJSONObject: jsonUpload, options:JSONSerialization.WritingOptions.prettyPrinted)
//            return requestBody
//        } catch {
//            print("json error: \(error.localizedDescription)")
//            return nil
//        }
//    }
//
//    func convertDataToDictionary(with data:Data?)->NSDictionary{
//        do { // try to parse JSON and deal with errors using do/catch block
//            let jsonDictionary: NSDictionary =
//                try JSONSerialization.jsonObject(with: data!,
//                                              options: JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
//
//            return jsonDictionary
//
//        } catch {
//
//            if let strData = String(data:data!, encoding:String.Encoding(rawValue: String.Encoding.utf8.rawValue)){
//                            print("printing JSON received as string: "+strData)
//            }else{
//                print("json error: \(error.localizedDescription)")
//            }
//            return NSDictionary() // just return empty
//        }
//    }

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
        imageVIew.image = image
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




