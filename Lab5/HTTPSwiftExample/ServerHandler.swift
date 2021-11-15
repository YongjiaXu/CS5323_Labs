//
//  ServerHandler.swift
//  HTTPSwiftExample
//
//  Created by Yongjia Xu on 11/13/21.
//  Copyright © 2021 Eric Larson. All rights reserved.
//

import Foundation
import UIKit

let SERVER_URL = "http://10.9.165.78:8000"

class ServerHalder: NSObject, URLSessionDelegate {
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
    var enoughData:Bool = false
    var resultLabel = ""
    var enoughDataToCompare:Bool = false
    var lrAcc = ""
    var bdtAcc = ""
    
    func convertDictionaryToData(with jsonUpload:NSDictionary) -> Data?{
        do { // try to make JSON and deal with errors using do/catch block
            let requestBody = try JSONSerialization.data(withJSONObject: jsonUpload, options:JSONSerialization.WritingOptions.prettyPrinted)
            return requestBody
        } catch {
            print("json error: \(error.localizedDescription)")
            return nil
        }
    }
    
    func convertDataToDictionary(with data:Data?)->NSDictionary{
        do { // try to parse JSON and deal with errors using do/catch block
            let jsonDictionary: NSDictionary =
                try JSONSerialization.jsonObject(with: data!,
                                              options: JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
            
            return jsonDictionary
            
        } catch {
            
            if let strData = String(data:data!, encoding:String.Encoding(rawValue: String.Encoding.utf8.rawValue)){
                            print("printing JSON received as string: "+strData)
            }else{
                print("json error: \(error.localizedDescription)")
            }
            return NSDictionary() // just return empty
        }
    }
    
    func addImage(_ image: [Float], label: String) {
        let baseURL = "\(SERVER_URL)/AddImage"
        let postURL = URL(string: "\(baseURL)")
        
        var request = URLRequest(url: postURL!)
        
        let jsonUpload:NSDictionary = ["feature": image, "label": "\(label)"]
        
        let requestBody:Data? = self.convertDictionaryToData(with:jsonUpload)
        
        request.httpMethod = "POST"
        request.httpBody = requestBody
        
        let postTask : URLSessionDataTask = self.session.dataTask(with: request,
            completionHandler:{(data, response, error) in
                if(error != nil){
                    if let res = response{
                        print("Response:\n",res)
                    }
                }
                else{
                    print("Upload successful!")
//                    let jsonDictionary = self.convertDataToDictionary(with: data)
                    
//                    print(jsonDictionary["feature"]!)
//                    print(jsonDictionary["label"]!)
                }
        })
        
        postTask.resume() // start the task
    }
    
    func checkEnoughLabel(){
        let baseURL = "\(SERVER_URL)/CheckEnoughData"
        let getUrl = URL(string: baseURL)
        let request: URLRequest = URLRequest(url: getUrl!)
        // https://stackoverflow.com/questions/42254114/how-can-we-wait-for-http-requests-to-finish
        // wait for the http request to check if there is enough Data
        let sem = DispatchSemaphore(value: 0)

        let dataTask : URLSessionDataTask = self.session.dataTask(with: request,
            completionHandler:{(data, response, error) in
                if(error != nil){
                    print("Response:\n%@",response!)
                }
                else{
                    let jsonDictionary = self.convertDataToDictionary(with: data)
                    if let enoughData = jsonDictionary["enough"]{
                        if (enoughData as! Bool == true) {
                            self.enoughData = true
                        }
                    }
                }
            sem.signal()
        })
        dataTask.resume() // start the task
        sem.wait()
    }
   
    func trainModel() {
        let baseURL = "\(SERVER_URL)/TrainModel"
        let postURL = URL(string: "\(baseURL)")
        var request = URLRequest(url: postURL!)
        
        request.httpMethod = "POST"
        let sem = DispatchSemaphore(value: 0) // waiting for the model to be trained
        let postTask : URLSessionDataTask = self.session.dataTask(with: request,
            completionHandler:{(data, response, error) in
                if(error != nil){
                    if let res = response{
                        print("Response:\n",res)
                    }
                }
                else{
                    print("Trained successful!")
                }
            sem.signal()
        })
        
        postTask.resume() // start the task
        sem.wait()
    }
    
    func checkEnoughLabelForCompare(){
        let baseURL = "\(SERVER_URL)/ValidCompare"
        let getUrl = URL(string: baseURL)
        let request: URLRequest = URLRequest(url: getUrl!)
        // https://stackoverflow.com/questions/42254114/how-can-we-wait-for-http-requests-to-finish
        // wait for the http request to check if there is enough Data
        let sem = DispatchSemaphore(value: 0)

        let dataTask : URLSessionDataTask = self.session.dataTask(with: request,
            completionHandler:{(data, response, error) in
                if(error != nil){
                    print("Response:\n%@",response!)
                }
                else{
                    let jsonDictionary = self.convertDataToDictionary(with: data)
                    if let enoughDataToCompare = jsonDictionary["valid"]{
                        if (enoughDataToCompare as! Bool == true) {
                            self.enoughDataToCompare = true
                        }
                    }
                }
            sem.signal()
        })
        dataTask.resume() // start the task
        sem.wait()
    }
   
    func trainAndCompareModel() {
        let baseURL = "\(SERVER_URL)/TrainAndCompareModel"
        let postURL = URL(string: "\(baseURL)")
        var request = URLRequest(url: postURL!)
        
        request.httpMethod = "POST"
        let sem = DispatchSemaphore(value: 0) // waiting for the model to be trained
        let postTask : URLSessionDataTask = self.session.dataTask(with: request,
            completionHandler:{(data, response, error) in
                if(error != nil){
                    if let res = response{
                        print("Response:\n",res)
                    }
                }
                else{
                    print("Trained successful!")
                    let jsonDictionary = self.convertDataToDictionary(with: data)
                    
                    if let acc = jsonDictionary["acc"]{
                        let accArr = acc as! Array<Any>
                        self.lrAcc = accArr[0] as! String
                        self.bdtAcc = accArr[1] as! String
                    }
                }
            sem.signal()
        })
        
        postTask.resume() // start the task
        sem.wait()
    }
    
    func predict(image: [Float], model: String) {
        let baseURL = "\(SERVER_URL)/Predict"
        let postURL = URL(string: "\(baseURL)")
        
        var request = URLRequest(url: postURL!)
        
        let jsonUpload:NSDictionary = ["feature": image, "model": "\(model)"]
        
        let requestBody:Data? = self.convertDictionaryToData(with:jsonUpload)
        
        request.httpMethod = "POST"
        request.httpBody = requestBody
        let sem = DispatchSemaphore(value: 0)
        let postTask : URLSessionDataTask = self.session.dataTask(with: request,
            completionHandler:{(data, response, error) in
                if(error != nil){
                    if let res = response{
                        print("Response:\n",res)
                    }
                }
                else{
                    let jsonDictionary = self.convertDataToDictionary(with: data)
                    if let result = jsonDictionary["result"]{
                        self.resultLabel = result as! String
                    }
                }
            sem.signal()
        })
        
        postTask.resume() // start the task
        sem.wait()
    }

}

