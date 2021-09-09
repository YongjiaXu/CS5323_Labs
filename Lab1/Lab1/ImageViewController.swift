//
//  ImageViewController.swift
//  Lab1
//
//  Created by Yongjia Xu on 9/8/21.
//

import UIKit

class ImageViewController: UIViewController, UIScrollViewDelegate {
    lazy var foodModel:FoodModel = {
        return FoodModel.sharedInstance()
    }()
    
    var displayFoodName = "Spicy-Fish"
    
    lazy private var imageView: UIImageView? = {
        return UIImageView.init(image: foodModel.getImageWithName(displayFoodName))
    }()
    
    @IBOutlet var scrollView: UIScrollView!
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        // Do any additional setup after loading the view.
        if let size = self.imageView?.image?.size{
            self.scrollView.addSubview(self.imageView!)
            self.scrollView.contentSize = size
            self.scrollView.minimumZoomScale = 0.1
            self.scrollView.delegate = self
        }
        
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }
    
}
