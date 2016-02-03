//
//  ImageDetailViewController.swift
//  GankIO
//
//  Created by 盛欣哲 on 16/1/23.
//  Copyright © 2016年 Anthony. All rights reserved.
//

import UIKit
import Kingfisher

class ImageDetailViewController: UIViewController {
    @IBOutlet weak var bigImageView: UIImageView!
    
    var imageUrl: String = ""
    override func viewDidLoad() {
        if imageUrl != "" {
            bigImageView.kf_setImageWithURL(NSURL(string: imageUrl)!)
        }
    }
}
