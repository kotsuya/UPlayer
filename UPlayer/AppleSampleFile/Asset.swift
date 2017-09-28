//
//  Asset.swift
//  UPlayer
//
//  Created by YooSeunghwan on 2017/09/28.
//  Copyright © 2017年 YooSeunghwan. All rights reserved.
//

import Foundation
import AVFoundation

struct Asset {
    
    // MARK: Types
    static let nameKey = "AssetName"
    
    // MARK: Properties
    
    /// The name of the asset to present in the application.
    let assetName: String
    
    /// The `AVURLAsset` corresponding to an asset in either the application bundle or on the Internet.
    let urlAsset: AVURLAsset
    
    let albumName: String
}


extension Asset {
    init?(data: NSData) {
        if let coding = NSKeyedUnarchiver.unarchiveObject(with: data as Data) as? Encoding {
            assetName = coding.assetName as String
            urlAsset = (coding.urlAsset as AVURLAsset?)!
            albumName = coding.albumName as String
        } else {
            return nil
        }
    }
    
    func encode() -> NSData {
        return NSKeyedArchiver.archivedData(withRootObject: Encoding(self)) as NSData
    }
    
    @objc(_TtCV7UPlayer5AssetP33_7CF8201979A08DFF4508EC85CEB9C71E8Encoding)private class Encoding: NSObject, NSCoding {
        func encode(with aCoder: NSCoder) {
            aCoder.encode(assetName, forKey: "assetName")
            aCoder.encode(urlAsset.url.lastPathComponent, forKey: "urlAsset")
            aCoder.encode(albumName, forKey: "albumName")
        }
        
        var assetName: String
        var urlAsset: AVURLAsset
        var albumName: String
        
        init(_ asset: Asset) {
            assetName = asset.assetName
            urlAsset = asset.urlAsset
            albumName = asset.albumName
        }
        
        @objc required init?(coder aDecoder: NSCoder) {
            if let a = aDecoder.decodeObject(forKey: "assetName") as? NSString {
                self.assetName = a as String
            } else {
                return nil
            }
            
            if let a = aDecoder.decodeObject(forKey: "urlAsset") as? NSString {
                let tempDirectoryURL = NSURL.fileURL(withPath: NSTemporaryDirectory(), isDirectory: true)
                let targetURL = tempDirectoryURL.appendingPathComponent("\(a)")
                self.urlAsset =  AVURLAsset(url: targetURL)//a as AVURLAsset
            } else {
                return nil
            }
            
            if let a = aDecoder.decodeObject(forKey: "albumName") as? NSString {
                self.albumName = a as String
            } else {
                return nil
            }
        }
    }
}


/*
 let fooArray = [ Foo(a: "a", b: "b"), Foo(a: "c", b: nil) ]
 let encoded = fooArray.map { $0.encode() }
 NSUserDefaults.standardUserDefaults().setObject(encoded, forKey: "my-key")
 */


/*
 let dataArray = NSUserDefaults.standardUserDefaults().objectForKey("my-key") as! [NSData]
 let savedFoo = dataArray.map { Foo(data: $0)! }
 */

//https://stackoverflow.com/questions/38406457/how-to-save-an-array-of-custom-struct-to-nsuserdefault-with-swift

