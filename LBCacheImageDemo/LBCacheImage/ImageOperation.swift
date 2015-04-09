//
//  ImageOperation.swift
//  SwiftProject
//
//  Created by Lucian Boboc on 18/10/14.
//  Copyright (c) 2014 Lucian Boboc. All rights reserved.
//

import UIKit
import ImageIO




//MARK: ImageOperation class
class ImageOperation: NSOperation {
    
    //MARK: properties
    private var urlString:NSString!
    private var session:NSURLSession!
    private var imageBlock:LBCacheImageBlock!
    private var fileManager:NSFileManager!
    private var queue:NSOperationQueue!
    
    private var locationURL:NSURL?
    private var progressBlock:LBCacheProgressBlock?
    
    private var _executing = false
    override var executing:Bool {
        get {
            return _executing
        }
        set {
            self.willChangeValueForKey("executing")
            _executing = newValue
            self.didChangeValueForKey("executing")
        }
    }
    
    private var _finished = false
    override var finished:Bool {
        get {
            return _finished
        }
        set {
            self.willChangeValueForKey("finished")
            _finished = newValue
            self.didChangeValueForKey("finished")
        }
    }
    
    
    // MARK: methods
    deinit {
        self.session?.invalidateAndCancel()
    }
    
    
    init(urlString:NSString, progressBlock: LBCacheProgressBlock?, completionBlock: LBCacheImageBlock) {
        
        self.queue = NSOperationQueue()
        self._executing = false
        self._finished = false
        self.urlString = urlString
        self.progressBlock = progressBlock
        self.imageBlock = completionBlock
        self.fileManager = NSFileManager()
    }
    
    private func done() {
        self.finished = true
        self.executing = false
    }
    
    override func start() {
        
        if self.cancelled {
            self.done()
            return
        }
        
        var request = self.getTheMutableRequest()
        if request == nil {
            self.done()
            var error = NSError(domain: kLBCacheErrorDomain, code: LBCacheImageError.UrlStringNotValid.rawValue, userInfo: [NSLocalizedDescriptionKey:"Can't create URL from \(self.urlString)"])
            self.imageBlock(nil, error)
        }else {
            
            self.finished = true
            dispatch_async(dispatch_get_main_queue()) {
                let notification = NSNotification(name: LBCacheImageDownloadDidStartNotification, object: self)
                NSNotificationCenter.defaultCenter().postNotification(notification)
            }
            
            self.session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration(), delegate: self, delegateQueue: nil)
            var task:NSURLSessionDownloadTask = self.session.downloadTaskWithRequest(request!)
            task.resume()
            CFRunLoopRun()
        }
        
    }
    
    private func getTheMutableRequest() -> NSMutableURLRequest? {
        var url = NSURL(string: self.urlString as String)
        if url != nil {
            var request = NSMutableURLRequest(URL: url!, cachePolicy: .ReloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 30)
            request.allHTTPHeaderFields = ["Accept":"image/*"]
            request.HTTPMethod = "GET"
            return request
        }
        return nil
    }
}























//MARK: ImageOperation extension
extension ImageOperation: NSURLSessionDelegate {
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        if totalBytesWritten > 0 {
            
            var percent:Double = 0
            if totalBytesWritten == totalBytesExpectedToWrite {
                percent = 100
            }else {
                percent = Double(totalBytesWritten * 100) / Double(totalBytesExpectedToWrite)
            }
            if self.progressBlock != nil {
                self.progressBlock!(percent)
            }
            
        }else {
            if self.progressBlock != nil {
                self.progressBlock!(0)
            }
        }
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        
        if let str = downloadTask.response?.URL?.absoluteString {
            if let hash = (str as NSString).hashMD5() {
                if let tmpURL = NSURL(fileURLWithPath: NSTemporaryDirectory()) {
                    var imageURL = tmpURL.URLByAppendingPathComponent(hash as String)
                    
                    var error:NSError? = nil
                    if self.fileManager.fileExistsAtPath(imageURL.path!) {
                        var resultingURL:NSURL? = imageURL
                        var success = self.fileManager.replaceItemAtURL(imageURL, withItemAtURL: location, backupItemName: nil, options: NSFileManagerItemReplacementOptions.WithoutDeletingBackupItem, resultingItemURL: &resultingURL, error: &error)
                        if success == true {
                            self.locationURL = imageURL
                        }
                    }else {
                        var success = self.fileManager.copyItemAtURL(location, toURL: imageURL, error: &error)
                        if success == true {
                            self.locationURL = imageURL
                        }
                    }
                }
            }
        }
    }
    
    
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        if error != nil {
            self.imageBlock(nil,error);
        }else {
            var error:NSError? = nil
            var imageURL:NSURL? = nil
            if self.locationURL != nil {
                imageURL = self.saveImageAndReturnURLLocation(self.locationURL!, urlString: self.urlString, error: &error)
            }
            
            if imageURL != nil {
                var image:UIImage? = self.createImage(url: imageURL!)
                if image != nil {
                    self.imageBlock(image, nil)
                }else {
                    var error = NSError(domain: kLBCacheErrorDomain, code: LBCacheImageError.CantCreateImage.rawValue, userInfo: [NSLocalizedDescriptionKey: kCantCreateImageDescription])
                    self.removeTheItem(url:imageURL!)
                    self.imageBlock(nil,error)
                }
            }else {
                self.imageBlock(nil, error)
            }
        }
        
        dispatch_async(dispatch_get_main_queue()) {
            let notification = NSNotification(name: LBCacheImageDownloadDidStopNotification, object: self)
            NSNotificationCenter.defaultCenter().postNotification(notification)
        }
        
        self.done()
    }
    
    
    
    
    func createImage(#url:NSURL) -> UIImage? {
        
        var imageSource = CGImageSourceCreateWithURL(url, nil)
        if imageSource == nil {
            return nil
        }
        
        var orientation:UIImageOrientation! = .Up
        
        var properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil)
        if properties != nil {
            var ptr = unsafeAddressOf(kCGImagePropertyOrientation)
            if ptr != nil {
                var val = CFDictionaryGetValue(properties, ptr)
                if val != nil {
                    var number = CFNumberCreate(kCFAllocatorDefault, CFNumberType.IntType, val)
                    CFNumberGetValue(number, CFNumberType.IntType, &orientation)
                }
            }
        }
        
        var imageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, nil)
        if imageRef == nil {
            return nil
        }else {
            var image = UIImage(CGImage: imageRef, scale: UIScreen.mainScreen().scale, orientation: orientation!)
            return image
        }
    }
    
    
    private func saveImageAndReturnURLLocation(tempLocation:NSURL, urlString:NSString, inout error: NSError?) -> NSURL?{
        
        var imagesURLDirectory = LBCacheImage.sharedInstance().getLBCacheDirectory()
        if imagesURLDirectory != nil {
            var imageName:NSString? = urlString.hashWithType(.MD5)
            if imageName != nil {
                var imageURL = imagesURLDirectory!.URLByAppendingPathComponent(imageName! as String)
                
                if self.fileManager.fileExistsAtPath(imageURL.path!) {
                    var resultingURL:NSURL? = imageURL
                    var success = self.fileManager.replaceItemAtURL(imageURL, withItemAtURL: tempLocation, backupItemName: nil, options: NSFileManagerItemReplacementOptions.WithoutDeletingBackupItem, resultingItemURL: &resultingURL, error: &error)
                    if success == true {
                        return imageURL
                    }else {
                        return nil
                    }
                }else {
                    var success = self.fileManager.copyItemAtURL(tempLocation, toURL: imageURL, error: &error)
                    if success == true {
                        return imageURL
                    }else {
                        return nil
                    }
                }
            }else {
                error = NSError(domain: kLBCacheErrorDomain, code: LBCacheImageError.NilHashFromURLString.rawValue, userInfo: [NSLocalizedDescriptionKey:kNilURLStringToHash])
                return nil
            }
        }else {
            error = NSError(domain: kLBCacheErrorDomain, code: LBCacheImageError.NilCacheDirectory.rawValue, userInfo: [NSLocalizedDescriptionKey:kNilLBCacheDicrectory])
            return nil
        }
    }
    
    
    
    private func removeTheItem(#url: NSURL) {
        NSFileManager.defaultManager().removeItemAtURL(url, error: nil)
    }
}
