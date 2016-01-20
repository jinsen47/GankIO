//
//  ViewController.swift
//  GankIO
//
//  Created by ZhuDuan on 16/1/19.
//  Copyright © 2016年 Anthony. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    
    @IBOutlet weak var myTableView: UITableView!
    
    let API = "http://gank.avosapps.com/api/data/%E7%A6%8F%E5%88%A9/10/1"
    
    var titleNames = [String]()
    var beautyImages = [String]()
    var mockImage = "pic1"
    
    var screenWidth: CGFloat = 0.0

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        loadData(API)
        self.screenWidth = UIScreen.mainScreen().bounds.width
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return titleNames.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cellIdentifier = "cell"
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! CustomTableViewCell
        
        cell.titleLabel.text = titleNames[indexPath.row]
        cell.dateLabel.text = titleNames[indexPath.row]
        
        let imageHeight = cell.beautyImageView.bounds.height
        let imageWidth = cell.beautyImageView.bounds.width
        
        let originImage = UIImage(data: NSData(contentsOfURL: NSURL(string: beautyImages[indexPath.row])!)!)
//        print("第\(indexPath.row)张图片的宽是 \(originImage?.size.width), 高是 \(originImage?.size.height)")
        
        let resizedImage : UIImage
        if originImage?.size.height > originImage?.size.width {
            let resize = CGSizeMake(imageWidth, (originImage?.size.height)! * imageWidth /  (originImage?.size.width)!)
//            print("缩放大小 \(resize.width) * \(resize.height)")
            resizedImage = resizeImage(originImage!, size: resize)
        } else {
            let resize = CGSizeMake((originImage?.size.width)! * imageHeight / (originImage?.size.height)!, imageHeight)
//            print("缩放大小 \(resize.width) * \(resize.height)")
            resizedImage = resizeImage(originImage!, size: resize)
            
        }
        
        let cropImage = cropRectImage(resizedImage, targetSize: CGSizeMake(screenWidth, imageHeight))
        
        cell.beautyImageView.image = cropImage
        return cell
    }
    
    // hide status bar
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    func loadData(url : String) ->Void {
        let nsUrl  = NSURL(string: url)
        let request = NSURLRequest(URL: nsUrl!)
        
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue(), completionHandler: {
            (response, data, error) -> Void in
            if ((error) != nil) {
                print("网络故障")
            } else {
                if let jsonData: NSDictionary = try! NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers) as? NSDictionary {
                    let resultArray = jsonData["results"] as! Array<NSDictionary>
                    for item in resultArray {
                        var publishString = item["publishedAt"] as! String
                        publishString = publishString.substringToIndex(publishString.startIndex.advancedBy(10))
                        let imageUrl = item["url"] as! String
                        
                        self.beautyImages.append(imageUrl)
                        self.titleNames.append(publishString)
                    }
                    dispatch_async(dispatch_get_main_queue(), {
                        self.self.myTableView.reloadData()
                    })
                }
            }
            })
    }
    
    func resizeImage(image: UIImage, size: CGSize) -> UIImage {
        let sourceSize = image.size
        
        let widthRatio = size.width / sourceSize.width
        let heightRatio = size.height / sourceSize.height
        
        var newSize: CGSize
        if widthRatio > heightRatio {
            newSize = CGSizeMake(sourceSize.width * heightRatio, sourceSize.height * heightRatio)
        } else {
            newSize = CGSizeMake(sourceSize.width * widthRatio, sourceSize.height * widthRatio)
        }
        
        let rect = CGRectMake(0, 0, newSize.width, newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.drawInRect(rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
    
    func cropRectImage(image: UIImage, targetSize :CGSize) -> UIImage {
        let sourceSize = image.size
        
        var cropRect: CGRect
        if sourceSize.width > sourceSize.height {
            cropRect = CGRectMake((sourceSize.width - targetSize.width) / 2, 0, targetSize.width, targetSize.height)
        } else {
            cropRect = CGRectMake(0, (sourceSize.height - targetSize.height) / 2, targetSize.width, targetSize.height)
        }
        
        let imageRef = CGImageCreateWithImageInRect(image.CGImage, cropRect)
        if let imageTar = imageRef {
//            print("image crop suceess!")
            return UIImage(CGImage: imageTar, scale: UIScreen.mainScreen().scale, orientation: image.imageOrientation)

        } else {
            print("image crop FAILED!")
            return image
        }
    }
}

