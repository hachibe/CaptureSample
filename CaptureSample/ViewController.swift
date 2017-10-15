//
//  ViewController.swift
//  CaptureSample
//
//  Created by Hachibe on 2017/10/14.
//  Copyright © 2017年 Masanori. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var updateSwitch: UISwitch!
    @IBOutlet weak var capturedImageView: UIImageView!
    @IBOutlet weak var timeLabel: UILabel!
    
    var timer: Timer!
    let launchDate = Date()

    override func viewDidLoad() {
        super.viewDidLoad()
        timer = Timer.scheduledTimer(timeInterval: 0.01,
                                     target: self,
                                     selector: #selector(updateTime),
                                     userInfo: nil,
                                     repeats: true)
        timer.fire()
    }
    
    @objc func updateTime() {
        let time = Date().timeIntervalSince(launchDate)
        timeLabel.text = String("\(time)".prefix(5))
    }
    
    @IBAction func captureScreen(_ sender: UIButton) {
        let startDate = Date()
        
        let screen = UIScreen.main
        UIGraphicsBeginImageContextWithOptions(screen.bounds.size, false, 0);
        let snapshotView = UIScreen.main.snapshotView(afterScreenUpdates: false)
        snapshotView.drawHierarchy(in: screen.bounds, afterScreenUpdates: updateSwitch.isOn)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        capturedImageView.image = image
        UIGraphicsEndImageContext();
        
        let time = Date().timeIntervalSince(startDate)
        print("captureScreenTime: \(time)")
    }
    
    @IBAction func captureWindow(_ sender: Any) {
        let startDate = Date()
        
        guard let window = UIApplication.shared.keyWindow  else {
            return
        }
        let ratio = CGFloat(2)
        let resizedSize = CGSize(width: window.bounds.size.width/ratio, height: window.bounds.size.height/ratio)
        let resizedRect = CGRect(x: 0, y: 0, width: resizedSize.width, height: resizedSize.height)
        UIGraphicsBeginImageContextWithOptions(resizedSize, false, 0);
        window.drawHierarchy(in: resizedRect, afterScreenUpdates: updateSwitch.isOn)
        guard let image = UIGraphicsGetImageFromCurrentImageContext() else {
            fatalError("UIGraphicsGetImageFromCurrentImageContext failed")
        }
        
//        UIGraphicsEndImageContext();
        
        // imageの縮小
//        UIGraphicsBeginImageContextWithOptions(resizedSize, false, 0);
//        guard let context = UIGraphicsGetCurrentContext() else {
//            fatalError("UIGraphicsGetCurrentContext failed")
//        }
//        context.draw(image.cgImage!, in: window.bounds)
//        context.scaleBy(x: 0.5, y: 0.5)
//        let rect = CGRect(x: 0, y: 0, width: resizedSize.width, height: resizedSize.height)
//        image.draw(in: rect)
//        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        
        capturedImageView.image = image
        UIGraphicsEndImageContext();

        // pixelBufferの生成
        let width = Int(image.size.width * ratio) / 16 * 16 // 16の倍数に
        let height = Int(image.size.height * ratio) / 16 * 16
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
                     kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var buffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                         width,
                                         height,
                                         kCVPixelFormatType_32ARGB,
                                         attrs,
                                         &buffer)
        guard (status == kCVReturnSuccess) else {
            fatalError("CVPixelBufferCreate status not success")
        }
        guard let pixelBuffer = buffer else {
            fatalError("CVPixelBufferCreate failed to create pixelBuffer")
        }

        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer)
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(data: pixelData,
                                      width: width,
                                      height: height,
                                      bitsPerComponent: 8,
                                      bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
                                      space: rgbColorSpace,
                                      bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) else {
                                        fatalError("CGContext from pixelBuffer failed")
        }
        context.translateBy(x: 0, y: image.size.height * ratio)
        context.scaleBy(x: 1.0, y: -1.0)
        
        UIGraphicsPushContext(context)
        image.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        
        // pixelBufferからimageを取得(imageからpixelBufferが生成されているかの確認用)
//        let ciImage = CIImage(cvImageBuffer: pixelBuffer)
//        let temporaryContext = CIContext(options: nil)
//        let imageRect = CGRect(x: 0,
//                               y: 0,
//                               width: CGFloat(CVPixelBufferGetWidth(pixelBuffer)),
//                               height: CGFloat(CVPixelBufferGetHeight(pixelBuffer)))
//        guard let videoImage = temporaryContext.createCGImage(ciImage, from: imageRect) else {
//            fatalError("createCGImage failed")
//        }
//        let uiImage = UIImage(cgImage: videoImage)
        
        let time = Date().timeIntervalSince(startDate)
        print("captureWindowTime: \(time)")
    }
}

