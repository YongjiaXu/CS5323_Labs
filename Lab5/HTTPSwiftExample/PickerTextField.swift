//
//  PickerTextField.swift
//  HTTPSwiftExample
//
//  Created by Yongjia Xu on 11/10/21.
//  Copyright © 2021 Eric Larson. All rights reserved.
//

// referenced: https://www.youtube.com/watch?v=b2WDVqNLTqE
import Foundation
import UIKit

typealias PickerTextFieldDisplayNameHandler = ((Any) -> String)
typealias PickerTextFieldItemSelectionHandler = ((Int, Any) -> Void)

final class PickerTextField: UITextField {
    private let pickerView = UIPickerView(frame: .zero)
    private var lastSelectedRow: Int?
    
    public var pickerData: [Any] = []
    public var displayNameHandler: PickerTextFieldDisplayNameHandler?
    public var itemSelectionHandler: PickerTextFieldItemSelectionHandler?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.configureView()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.configureView()
    }
    
    private func configureView() {
        self.pickerView.delegate = self
        self.pickerView.dataSource = self
        self.inputView = self.pickerView
    }
    
    private func updateText() {
        if self.lastSelectedRow == nil {
            self.lastSelectedRow = 0
        }
        if self.lastSelectedRow! > self.pickerData.count {
            return
        }
        let data = self.pickerData[self.lastSelectedRow!]
        self.text = self.displayNameHandler?(data)
        
    }
}

extension PickerTextField: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let data = self.pickerData[row]
        return self.displayNameHandler?(data)
    }
}

extension PickerTextField: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.pickerData.count
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.lastSelectedRow = row
        self.updateText()
        let data = self.pickerData[row]
        self.itemSelectionHandler?(row,data)
    }
}
