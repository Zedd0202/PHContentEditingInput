//
//  ViewController.swift
//  PHContentEditingInputTest
//
//  Created by Zedd on 2020/04/27.
//  Copyright © 2020 Zedd. All rights reserved.
//

import UIKit
import Photos
import PhotosUI

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var myImageView: UIImageView!
    
    var picker = UIImagePickerController()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let status = PHPhotoLibrary.authorizationStatus()
        
        if status == .notDetermined  {
            PHPhotoLibrary.requestAuthorization({status in
                
            })
        }
    }
    
    @IBAction func buttonDidTap(_ sender: Any) {
        picker.sourceType = .photoLibrary
        picker.delegate = self
        self.present(picker, animated: true, completion: nil)
        
    }
    
    func sepiaFilter(_ input: CIImage, intensity: Double) -> CIImage? {
        let sepiaFilter = CIFilter(name:"CISepiaTone")
        
        sepiaFilter?.setValue(input, forKey: kCIInputImageKey)
        sepiaFilter?.setValue(intensity, forKey: kCIInputIntensityKey)
        
        return sepiaFilter?.outputImage
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let asset = info[.phAsset] as? PHAsset
    
        asset?.requestContentEditingInput(with: nil, completionHandler: { (contentEditingInput, info) in
            guard let contentEditingInput = contentEditingInput else { return }
            guard let url = contentEditingInput.fullSizeImageURL, let ciImage = CIImage(contentsOf: url, options: nil) else { return }
            guard let outputImage = self.sepiaFilter(ciImage, intensity: 1.0) else { return }
            
            let uiImage = UIImage(ciImage: outputImage)
            guard let renderedData = uiImage.jpegData(compressionQuality: 0.9) else { return }
            let adjData = PHAdjustmentData(formatIdentifier: "com.PHContentEditingInputTest", formatVersion: "1.0", data: renderedData)

            let contentOutput = PHContentEditingOutput(contentEditingInput: contentEditingInput)
            contentOutput.adjustmentData = adjData
            
            do {
                try renderedData.write(to: contentOutput.renderedContentURL, options: .atomic)
                
                PHPhotoLibrary.shared().performChanges({
                    let request = PHAssetChangeRequest(for: asset!)
                    request.contentEditingOutput = contentOutput
                }, completionHandler: { [weak self] (isSuccess, error) in
                    if isSuccess {
                        DispatchQueue.main.async(execute: {
                            self?.picker.dismiss(animated: true, completion: {
                                self?.myImageView.image = uiImage
                            })
                        })
                    }
                })
            } catch let error {
                print(error.localizedDescription)
            }
        })
    }
}

