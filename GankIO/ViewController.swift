//
//  ViewController.swift
//  GankIO
//
//  Created by ZhuDuan on 16/1/19.
//  Copyright © 2016年 Anthony. All rights reserved.
//

import UIKit
import Kingfisher
import PullToRefreshSwift

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    
    @IBOutlet weak var myTableView: UITableView!
    
    let API = "http://gank.avosapps.com/api/data/%E7%A6%8F%E5%88%A9/10/"
    var page = 1
    
    var titleNames = [String]()
    var beautyImages = [String]()
    var mockImage = "pic1"
    
    var screenWidth: CGFloat = 0.0
    var screenHeight: CGFloat = 0.0
    
    var cellHeight: CGFloat = 0.0
    
    var isLoading: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        myTableView.delegate = self
        myTableView.dataSource = self
        
        // Do any additional setup after loading the view, typically from a nib.
        loadData(API + "\(page)")
        if screenHeight == 0.0 || screenWidth == 0.0 {
            self.screenWidth = UIScreen.mainScreen().bounds.width
            self.screenHeight = UIScreen.mainScreen().bounds.height
        }
        
        self.myTableView.addPullToRefresh(refreshCompletion: { [weak self] in
            if let isLoading = self?.isLoading {
                if isLoading {
                    return
                }
            }
            self?.titleNames = []
            self?.beautyImages = []
            self?.page = 1
            self?.loadData(((self?.API)! + "\(self?.page)"))
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
//        print("\(scrollView.contentOffset.y + myTableView.bounds.height)")
        if scrollView.contentOffset.y + screenHeight > CGFloat(titleNames.count) * cellHeight {
            if isLoading {
                return
            } else {
                isLoading = true
                loadData(self.API + "\(++page)")
            }
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return titleNames.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cellIdentifier = "cell"
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! CustomTableViewCell
        
        if cellHeight == 0.0 {
            cellHeight = cell.bounds.height
        }
        cell.titleButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
        cell.titleButton.backgroundColor = UIColor(red: 255.0, green: 255.0, blue: 255.0, alpha: 0.5)
        cell.titleButton.setTitle(titleNames[indexPath.row], forState: UIControlState.Normal)
        cell.dateLabel.text = self.titleNames[indexPath.row]
        
//        cell.beautyImageView.image = cropImage
        cell.beautyImageButton.imageView?.kf_setImageWithURL(NSURL(string: beautyImages[indexPath.row])!,
            placeholderImage: nil,
            optionsInfo: nil,
            progressBlock: {(receive, total) -> () in
            },
            completionHandler: { (image, error, cacheType, imageUrl) -> () in
                let imageHeight = cell.beautyImageButton.bounds.height
                let imageWidth = cell.beautyImageButton.bounds.width
                
                let originImage = image
                
                let resizedImage : UIImage
                if originImage?.size.height > originImage?.size.width {
                    let resize = CGSizeMake(imageWidth, (originImage?.size.height)! * imageWidth /  (originImage?.size.width)!)
                    resizedImage = self.resizeImage(originImage!, size: resize)
                } else {
                    let resize = CGSizeMake((originImage?.size.width)! * imageHeight / (originImage?.size.height)!, imageHeight)
                    resizedImage = self.resizeImage(originImage!, size: resize)
                    
                }
                
                let cropImage = self.cropRectImage(resizedImage, targetSize: CGSizeMake(self.self.screenWidth, imageHeight))
                cell.beautyImageButton.setBackgroundImage(cropImage, forState: UIControlState.Normal)
                cell.beautyImageButton.setTitle("", forState: UIControlState.Normal)
            }
        )
        
        cell.beautyImageButton.tag = indexPath.row
        cell.titleButton.tag = indexPath.row
        return cell
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let row = (sender as! UIButton).tag
        if segue.identifier == "imageDetailSegue" {
            let destController = segue.destinationViewController as! ImageDetailViewController
            destController.imageUrl = self.beautyImages[row]
            print("prepareSegue imageUrl = \(self.beautyImages[row])")
        }
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
                        self.self.myTableView.stopPullToRefresh()
                        self.self.isLoading = false
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
    
    func generateApiUrl(baseUrl: String, count: Int, page: Int) ->NSURL {
        return NSURL(string: baseUrl + "\(count)" + "/" + "\(page)")!
    }
}

