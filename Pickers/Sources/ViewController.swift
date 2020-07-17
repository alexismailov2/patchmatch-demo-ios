//
//  ViewController.swift
//  Pickers
//
//  Created by Tibor Bödecs on 2019. 08. 28..
//  Copyright © 2019. Tibor Bödecs. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    var imagePicker: ImagePicker!
    var original: UIImage!
    var mask: UIImage!
    
    var drawColor = UIColor.white
    var lineWidth: CGFloat = 20
    
    private var lastPoint: CGPoint!
    private var bezierPath: UIBezierPath!
    private var pointCounter: Int = 0
    private let pointLimit: Int = 128

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var imagePickerButton: UIButton!
    
    @IBOutlet weak var videoPickerButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initBezierPath()
    }

    func initBezierPath() {
        bezierPath = UIBezierPath()
        bezierPath.lineCapStyle = CGLineCap.round
        bezierPath.lineJoinStyle = CGLineJoin.round
    }

    @IBAction func imagePickerButtonTouched(_ sender: UIButton) {
        self.imagePicker = ImagePicker(presentationController: self, delegate: { (image: UIImage?) -> Void in
            guard let image = image else {
                return
            }
            self.imageView.image = image
            self.original = image
            let bounds = self.calculateClientRectOfImageInUIImageView(imgView:self.imageView)
            self.mask = self.getImageWithColor(color:.black, size:bounds.size)
        })
        self.imagePicker.present(from: sender)
    }
    
    func textToImage(drawText text: String, inImage image: UIImage, atPoint point: CGPoint) -> UIImage {
        let textColor = UIColor.black
        let textFont = UIFont(name: "Helvetica Bold", size: 12)!

        let scale = UIScreen.main.scale
        UIGraphicsBeginImageContextWithOptions(image.size, false, scale)

        let textFontAttributes = [
            NSAttributedString.Key.font: textFont,
            NSAttributedString.Key.foregroundColor: textColor,
            ] as [NSAttributedString.Key : Any]
        image.draw(in: CGRect(origin: CGPoint.zero, size: image.size))

        let rect = CGRect(origin: point, size: image.size)
        text.draw(in: rect, withAttributes: textFontAttributes)

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage!
    }

    @IBAction func videoPickerButtonTouched(_ sender: UIButton) {
        DispatchQueue.global(qos: .background).async { [weak self] in
          guard let self = self else {
            return
          }
          let result = PatchMatch.imageComplete(withOriginal:self.original!, mask:self.mask!, imageCompletionSteps:10, patchMatchingSteps:10, callback: { (original: UIImage?, percent:NSInteger) -> Void in
              self.imageView.image = original
              print("Percent: ", percent, "%")
              DispatchQueue.main.async { [weak self] in
                self?.imageView.image = self?.textToImage(drawText: "Percent: " + String(percent) + "%", inImage: (self?.original)!, atPoint: CGPoint(x:100, y:100))
              }
          }, isNeededImageOnProgress: false)

          DispatchQueue.main.async { [weak self] in
            self?.imageView.image = result
          }
        }
    }
    
    func getImageWithColor(color: UIColor, size: CGSize) -> UIImage {
        let rect = CGRect(x:0, y:0, width:size.width, height:size.height)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        color.setFill()
        UIRectFill(rect)
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
    
    // MARK: - Touch handling
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            lastPoint = touch.location(in: imageView)
            let bounds = calculateClientRectOfImageInUIImageView(imgView:imageView)
            if lastPoint.y > bounds.minY && lastPoint.y < bounds.maxY
            {
               pointCounter = 0
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch: AnyObject? = touches.first
        var newPoint = touch!.location(in: imageView)
        
        let bounds = calculateClientRectOfImageInUIImageView(imgView:imageView)
        if newPoint.y > bounds.minY && lastPoint.y < bounds.maxY {
            bezierPath.move(to: lastPoint)
            newPoint.y -= bounds.minY
            bezierPath.addLine(to: newPoint)
            lastPoint = newPoint
            
            pointCounter += 1
            
            if pointCounter == pointLimit {
                pointCounter = 0
                renderToImage()
                bezierPath.removeAllPoints()
            }
            else {
                renderToImage()
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        pointCounter = 0
        renderToImage()
        bezierPath.removeAllPoints()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>?, with event: UIEvent?) {
        touchesEnded(touches!, with: event)
    }
    
    func calculateClientRectOfImageInUIImageView(imgView : UIImageView) -> CGRect
    {
        let imgViewSize = imgView.frame.size; // Size of UIImageView
        var imgSize = imgView.image!.size;     // Size of the image, currently displayed

        // Calculate the aspect, assuming imgView.contentMode==UIViewContentModeScaleAspectFit

        let scaleW = imgViewSize.width / imgSize.width;
        let scaleH = imgViewSize.height / imgSize.height;
        let aspect = fmin(scaleW, scaleH);

        imgSize.width *= aspect
        imgSize.height *= aspect
        var imageRect:CGRect = CGRect(x:0, y:0, width:imgSize.width, height:imgSize.height);

        // Note: the above is the same as :
        // CGRect imageRect=CGRectMake(0,0,imgSize.width*=aspect,imgSize.height*=aspect) I just like this notation better

        // Center image

        imageRect.origin.x = (imgViewSize.width - imageRect.size.width) / 2;
        imageRect.origin.y = (imgViewSize.height - imageRect.size.height) / 2;

        // Add imageView offset

        imageRect.origin.x+=imgView.frame.origin.x;
        imageRect.origin.y+=imgView.frame.origin.y;

        return CGRect(x:Int(imageRect.minX), y:Int(imageRect.minY), width:Int(imageRect.width), height:Int(imageRect.height))
    }

    // MARK: - Pre render
    
    func renderToImage() {
        self.imageView.image = original
        let bounds = calculateClientRectOfImageInUIImageView(imgView:imageView);
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0.0)
        if mask != nil {
            mask.draw(in: CGRect(x:0, y:0, width:bounds.width, height:bounds.height))
        }
        
        bezierPath.lineWidth = lineWidth
        drawColor.setFill()
        drawColor.setStroke()
        bezierPath.stroke()
        
        mask = UIGraphicsGetImageFromCurrentImageContext()
        self.imageView.image!.draw(in: CGRect(x:0, y:0, width:bounds.width, height:bounds.height), blendMode: CGBlendMode.normal, alpha: 0.8)
        self.imageView.image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
    }
}
