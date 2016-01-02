//
//  UIImageView+ImageLoader.swift
//  ImageLoader
//
//  Created by Hirohisa Kawasaki on 10/17/14.
//  Copyright © 2014 Hirohisa Kawasaki. All rights reserved.
//

import Foundation
import UIKit

private var ImageLoaderURLKey = 0
private var ImageLoaderBlockKey = 0

/**
 Extension using ImageLoader sends a request, receives image and displays.
 */
extension UIImageView {

    public static var imageLoader = Manager()

    // MARK: - properties

    private var URL: NSURL? {
        get {
            var URL: NSURL?
            dispatch_sync(UIImageView._ioQueue) {
                URL = objc_getAssociatedObject(self, &ImageLoaderURLKey) as? NSURL
            }

            return URL
        }
        set(newValue) {
            dispatch_barrier_async(UIImageView._ioQueue) {
                objc_setAssociatedObject(self, &ImageLoaderURLKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
    }

    // MARK: - public
    public func load(URL: URLLiteralConvertible, placeholder: UIImage? = nil, completionHandler:CompletionHandler? = nil) {
        dispatch_async(UIImageView._Queue) { [weak self] in
            guard let wSelf = self else { return }

            wSelf.cancelLoading()
        }

        if let placeholder = placeholder {
            image = placeholder
        }

        imageLoader_load(URL.imageLoaderURL, completionHandler: completionHandler)
    }

    public func cancelLoading() {
        if let URL = URL {
            UIImageView.imageLoader.cancel(URL, identifier: hash)
        }
    }

    // MARK: - private
    private static let _ioQueue = dispatch_queue_create("swift.imageloader.queues.io", DISPATCH_QUEUE_CONCURRENT)
    private static let _Queue = dispatch_queue_create("swift.imageloader.queues.request", DISPATCH_QUEUE_SERIAL)

    private func imageLoader_load(URL: NSURL, completionHandler: CompletionHandler?) {
        let handler: CompletionHandler = { [weak self] URL, image, error, cacheType in
            if let wSelf = self, thisURL = wSelf.URL, image = image where thisURL.isEqual(URL) {
                wSelf.imageLoader_setImage(image)
            }
            completionHandler?(URL, image, error, cacheType)
        }

        // caching
        if let data = UIImageView.imageLoader.cache[URL] {
            self.URL = URL
            handler(URL, UIImage.decode(data), nil, .Cache)
            return
        }

        let identifier = hash
        dispatch_async(UIImageView._Queue) { [weak self] in
            guard let wSelf = self else { return }

            let block = Block(identifier: identifier, completionHandler: handler)
            UIImageView.imageLoader.load(URL).appendBlock(block)

            wSelf.URL = URL
        }
    }

    private func imageLoader_setImage(image: UIImage) {
        dispatch_async(dispatch_get_main_queue()) { [weak self] in
            guard let wSelf = self else { return }

            if UIImageView.imageLoader.automaticallyAdjustsSize {
                wSelf.image = image.adjusts(wSelf.frame.size, scale: UIScreen.mainScreen().scale, contentMode: wSelf.contentMode)
            } else {
                wSelf.image = image
            }
        }
    }
    
}