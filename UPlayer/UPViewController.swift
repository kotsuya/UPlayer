//
//  UPViewController.swift
//  UPlayer
//
//  Created by YooSeunghwan on 2017/09/13.
//  Copyright © 2017年 YooSeunghwan. All rights reserved.
//

import UIKit
import AVFoundation
import MobileCoreServices

let kEditMode: Int = 9999

class UPViewController: UIViewController {
    
    var myTableView: UITableView!
    
    private let list = NSArray(contentsOfFile: Bundle.main.path(forResource: "list", ofType:"plist")!)
    private let barHeight: CGFloat = UIApplication.shared.statusBarFrame.size.height
    
    var playerSizeWidth:CGFloat = 0.0
    var playerSizeHeight:CGFloat = 0.0
    
    private var seekBar : UISlider!
    private var playButton: UIButton! = nil
    private var plusButton: UIButton! = nil
    private var repeatButton: UIButton! = nil
    
    private var currentTimeLabel: UILabel!
    private var maxTimeLabel: UILabel!
    private var refreshControl:UIRefreshControl!
    
    /// An array of `Asset` objects representing the m4a files used for playback in this sample.
    var assets = [Asset]()
    
    /// The instance of `AssetPlaybackManager` to use for playing an `Asset`.
    var assetPlaybackManager: AssetPlaybackManager!
    
    var selectRow:Int = 0
    
    private var timeObserver: Any!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let displayWidth: CGFloat = self.view.frame.width
        let displayHeight: CGFloat = self.view.frame.height
        
        playerSizeWidth = self.view.bounds.size.width
        playerSizeHeight = playerSizeWidth - 40
        
        let player = assetPlaybackManager.player
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.backgroundColor = UIColor.black.cgColor
        playerLayer.name = "PlayLayer"
        playerLayer.frame = CGRect(x:0, y:barHeight, width:playerSizeWidth, height:playerSizeHeight)
        self.view.layer.addSublayer(playerLayer)
        
        seekBar = UISlider(frame: CGRect(x: 50, y: barHeight+playerSizeHeight-40, width: self.view.bounds.maxX - 100, height: 50))
        seekBar.autoresizingMask = .flexibleWidth
        seekBar.minimumValue = 0
        seekBar.maximumValue = 0
        seekBar.addTarget(self, action: #selector(onSliderValueChange(sender:)), for: .valueChanged)
        self.view.addSubview(seekBar)
        
        currentTimeLabel = UILabel(frame: CGRect(x: 0, y: barHeight+playerSizeHeight-35, width: 50, height: 40))
        currentTimeLabel.setupLabel()
        currentTimeLabel.autoresizingMask = .flexibleRightMargin
        self.view.addSubview(currentTimeLabel)
        
        maxTimeLabel = UILabel(frame: CGRect(x: self.view.bounds.width - 50, y: barHeight+playerSizeHeight-35, width: 50, height: 40))
        maxTimeLabel.setupLabel()
        maxTimeLabel.autoresizingMask = .flexibleLeftMargin
        self.view.addSubview(maxTimeLabel)
        
        playButton = UIButton(type:.custom)
        //playButton.setTitle("▶︎", for: .normal)
        playButton.setTitle("■", for: .normal)
        playButton.setupBtn()
        playButton.frame = CGRect(x: self.view.frame.size.width - 120, y: barHeight+5, width: 30, height: 30)
        playButton.addTarget(self, action: #selector(playButton(sender:)), for: UIControlEvents.touchUpInside)
        self.view.addSubview(playButton)
        
        repeatButton = UIButton(type:.custom)
        repeatButton.setImage(UIImage(named: "repeat_.png"), for: .normal)
        repeatButton.setupBtn()
        repeatButton.frame = CGRect(x: self.view.frame.size.width - 80, y: barHeight+5, width: 30, height: 30)
        repeatButton.addTarget(self, action: #selector(repeatButton(sender:)), for: UIControlEvents.touchUpInside)
        self.view.addSubview(repeatButton)
        
        plusButton = UIButton(type:.custom)
        plusButton.setTitle("＋", for: .normal)
        plusButton.setupBtn()
        plusButton.frame = CGRect(x: self.view.frame.size.width - 40, y: barHeight+5, width: 30, height: 30)
        plusButton.addTarget(self, action: #selector(addPlaylistButton(sender:)), for: UIControlEvents.touchUpInside)
        self.view.addSubview(plusButton)
   
        // TableViewの生成する(status barの高さ分ずらして表示).
        myTableView = UITableView(frame: CGRect(x: 0, y: barHeight+playerSizeHeight, width: displayWidth, height: displayHeight - (barHeight+playerSizeHeight)))
        
        // Cell名の登録をおこなう.
        myTableView.register(UITableViewCell.self, forCellReuseIdentifier: "MyCell")
        
        myTableView.dataSource = self
        myTableView.delegate = self
        self.view.addSubview(myTableView)
        
        refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "引っ張って更新")
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        myTableView.addSubview(refreshControl)
        
        self.loadPlayList()
        
        // Add the notification observers needed to respond to events from the `AssetPlaybackManager`.
        let notificationCenter = NotificationCenter.default
        
        notificationCenter.addObserver(self, selector: #selector(UPViewController.handleRemoteCommandNextTrackNotification(notification:)), name: AssetPlaybackManager.nextTrackNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(UPViewController.handleRemoteCommandPreviousTrackNotification(notification:)), name: AssetPlaybackManager.previousTrackNotification, object: nil)
        
        selectRow = 0
        self.playMusic()
        
        //回転したら
        NotificationCenter.default.addObserver(self, selector: #selector(self.rotated), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        
    }
    
    deinit {
        // Remove all notification observers.
        let notificationCenter = NotificationCenter.default
        
        notificationCenter.removeObserver(self, name: AssetPlaybackManager.nextTrackNotification, object: nil)
        notificationCenter.removeObserver(self, name: AssetPlaybackManager.previousTrackNotification, object: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func rotated(notification: NSNotification) {
        // 現在のデバイスの向きを取得.
        //let deviceOrientation: UIDeviceOrientation!  = UIDevice.current.orientation
        
        var frameRect: CGRect = self.view.bounds
        // 向きの判定.
        //if UIDeviceOrientationIsLandscape(deviceOrientation) {
        if UPUtilities.isDeviceLandscape() {
            playButton.alpha = 0.0
            plusButton.alpha = 0.0
            repeatButton.alpha = 0.0
            seekBar.alpha = 0.0
            currentTimeLabel.alpha = 0.0
            maxTimeLabel.alpha = 0.0
            myTableView.alpha = 0.0
        } else {//if UIDeviceOrientationIsPortrait(deviceOrientation){
            frameRect = CGRect(x:0,
                               y:barHeight,
                               width:playerSizeWidth,
                               height:playerSizeHeight)
            playButton.alpha = 1.0
            plusButton.alpha = 1.0
            repeatButton.alpha = 1.0
            seekBar.alpha = 1.0
            currentTimeLabel.alpha = 1.0
            maxTimeLabel.alpha = 1.0
            myTableView.alpha = 1.0
        }
        
        for layer: CALayer in self.view.layer.sublayers! {
            if layer is AVPlayerLayer {
                (layer as! AVPlayerLayer).frame = frameRect
                break
            }
        }
    }
    
    @objc func repeatButton(sender : UIButton) {
        assetPlaybackManager.oneRepeat = !assetPlaybackManager.oneRepeat
        if assetPlaybackManager.oneRepeat {
            sender.setImage(UIImage(named: "repeat.jpg"), for: .normal)
        } else {
            sender.setImage(UIImage(named: "repeat_.png"), for: .normal)
        }
    }
    
    @objc func playButton(sender : UIButton) {
        if assetPlaybackManager.state == .playing {
            sender.setTitle("▶︎", for: .normal)
            assetPlaybackManager.pause()
        } else {
            sender.setTitle("■", for: .normal)
            assetPlaybackManager.play()
        }
    }
    
    @objc func addPlaylistButton(sender : UIButton){
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let pickerView = UIImagePickerController()
            // 写真の選択元をカメラロールにする
            // 「.camera」にすればカメラを起動できる
            pickerView.sourceType = .photoLibrary
            // movie only
            pickerView.mediaTypes = [kUTTypeMovie as String]
            // デリゲート
            pickerView.delegate = self
            // ビューに表示
            self.present(pickerView, animated: true)
        }
    }
    
    @objc func onSliderValueChange(sender : UISlider){
        let player = assetPlaybackManager.player
        player.seek(to: CMTimeMakeWithSeconds(Float64(seekBar.value), Int32(NSEC_PER_SEC)))
    }
    
    @objc func refresh() {
        self.resetPlaylist()
        self.myTableView.reloadData()
        refreshControl.endRefreshing()
    }
    
    func playMusic() {
        let asset = assets[selectRow]
        assetPlaybackManager.asset = asset
        setVideo()
    }
    
    func setVideo() {
        let player = assetPlaybackManager.player
        if let tObserver = self.timeObserver {
            player.removeTimeObserver(tObserver)
        }
        
        if let avAsset = player.currentItem?.asset {
            let avAssetDuration:Float = Float(CMTimeGetSeconds(avAsset.duration))
            seekBar.maximumValue = avAssetDuration
            
            let interval : Double = Double(0.5 * seekBar.maximumValue) / Double(seekBar.bounds.maxX)
            let time : CMTime = CMTimeMakeWithSeconds(interval, Int32(NSEC_PER_SEC))
            
            // time毎に呼び出される.
            self.timeObserver = player.addPeriodicTimeObserver(forInterval: time, queue: nil) { (playTime) -> Void in
                
                let time : Float64 = CMTimeGetSeconds((player.currentTime()))
                self.seekBar.value = Float ( time )
                
                let currentTimeStr = String(format: "%02d:%02d", Int(time/60), Int(time)%60)
                self.currentTimeLabel.text = "\(currentTimeStr)"
                
                let aaa:Float = self.seekBar.maximumValue - Float(time)
                
                let min:Int = Int(aaa)/60
                let sec:Int = Int(aaa)%60
                let maxTimeStr = String(format: "-%01d:%02d", min, sec)
                self.maxTimeLabel.text = "\(maxTimeStr)"
            }
            
            myTableView.reloadData()
        }
        
    }
    
    func savePlayList() {
        // Setting
        let encoded = assets.map { $0.encode() }
        UserDefaults.standard.set(encoded, forKey: "playlist")
        UserDefaults.standard.synchronize()
        
    }
    
    func loadPlayList() {
        
        if let dataArray:[NSData] = UserDefaults.standard.object(forKey: "playlist") as? [NSData] {
            assets = dataArray.map { Asset(data: $0)! }
            print("assets : \(assets)")
        } else {
            self.resetPlaylist()
        }
    }
    
    func resetPlaylist() {
        
        guard let enumerator = FileManager.default.enumerator(at: Bundle.main.bundleURL, includingPropertiesForKeys: nil, options: [], errorHandler: nil) else { return }
        
        assets = enumerator.compactMap { element in
            guard let url = element as? URL, let list = list else { return nil }            
            if url.pathExtension != "m4v" && url.pathExtension != "mov" && url.pathExtension != "mp4" { return nil }
            
            let value = url.lastPathComponent
            let dict = (list as Array).first(where: { $0["fileName"] as? String == value })
            
            let fName = (url.lastPathComponent as NSString).deletingPathExtension
            
            if let uuu = self.copyBundleResourceToTemporaryDirectory(resourceName:fName, fileExtension:url.pathExtension) {
                //print("uuu : \(String(describing: uuu))")
                return Asset(assetName: dict?["title"] as! String, urlAsset: AVURLAsset(url: uuu as URL), albumName: dict?["artist"] as! String)
            }
            
            return nil
        }
        
        let tempDirectoryURL = NSURL.fileURL(withPath: self.documentPath(), isDirectory: true)
        guard let enumerator2 = FileManager.default.enumerator(at: tempDirectoryURL, includingPropertiesForKeys: nil, options: [], errorHandler: nil) else { return }
        
        enumerator2.forEach { element in
            guard let url = element as? URL else { return }
            
            if url.pathExtension == "MOV" {
                let name = url.lastPathComponent.split(separator:".")[0]
                let artist = url.lastPathComponent.split(separator:".")[1]
                self.assets.append(Asset(assetName: String(name), urlAsset: AVURLAsset(url: url), albumName: String(artist)))
            }
        }
    }
    
    func copyBundleResourceToTemporaryDirectory(resourceName: String, fileExtension: String) -> NSURL? {
        // Get the file path in the bundle
        if let bundleURL = Bundle.main.url(forResource: resourceName, withExtension: fileExtension) {
            
            //let tempDirectoryURL = NSURL.fileURL(withPath: NSTemporaryDirectory(), isDirectory: true)
            let tempDirectoryURL = NSURL.fileURL(withPath: self.documentPath(), isDirectory: true)
            
            // Create a destination URL.
            let targetURL = tempDirectoryURL.appendingPathComponent("\(resourceName).\(fileExtension)")
            
            if (try? targetURL.checkResourceIsReachable()) ?? false {
                return targetURL as NSURL
            }
            
            // Copy the file.
            do {
                try FileManager.default.copyItem(at: bundleURL, to: targetURL)
                return targetURL as NSURL
            } catch let error as NSError {
                NSLog("Unable to copy file: \(error)")
            }
        }
        
        return nil
    }
    
    func documentPath() -> String {
        return "\(NSHomeDirectory())/Documents"
    }
    
    @objc func accessoryButtonTapped(sender:UIButton) {
        let asset = assets[sender.tag]
        self.showEditAlert(self, url:asset.urlAsset.url, editMode: sender.tag)
    }
    
    func editOKButton(_ alert:UIAlertController, url:URL, editMode:Int) {
        var title:String = ""
        var artist:String = ""
        let textFields:Array<UITextField>? =  alert.textFields as Array<UITextField>?
        if textFields != nil {
            for textField:UITextField in textFields! {
                if let txt = textField.text {
                    if textField.tag == 0 {
                        title = txt
                    } else {
                        artist = txt
                    }
                }
            }
        }
        
        if editMode == kEditMode {
            assets.append(Asset(assetName: title, urlAsset: AVURLAsset(url: url), albumName: artist))
        } else {
            assets[editMode] = Asset(assetName: title, urlAsset: AVURLAsset(url: url), albumName: artist)
            
            if FileManager.default.fileExists(atPath: url.path) {
                // url.setTemporaryResourceValue("\(title).\(url.lastPathComponent)", forKey: .nameKey)
                do {
                    let tempDirectoryURL = NSURL.fileURL(withPath: self.documentPath(), isDirectory: true)
                    let targetURL = tempDirectoryURL.appendingPathComponent("\(title).\(artist).\(url.pathExtension)")
                    try FileManager.default.moveItem(at: url, to: targetURL)
                } catch {
                    print(error)
                }
            }
        }
        
        myTableView.reloadData()
        dismiss(animated: true, completion: nil)
    }
    
    func editCancelButton() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func showEditAlert(_ obj:AnyObject, url:URL, editMode:Int) {
        let alert:UIAlertController = UIAlertController(title:"metaData",
                                                        message: nil,
                                                        preferredStyle: .alert)
        
        let cancelAction:UIAlertAction = UIAlertAction(title: "Cancel",
                                                       style: .cancel,
                                                       handler:{
                                                        (action:UIAlertAction!) -> Void in
                                                        self.editCancelButton() })
        let defaultAction:UIAlertAction = UIAlertAction(title: "OK",
                                                        style: .default,
                                                        handler:{
                                                            (action:UIAlertAction!) -> Void in
                                                            self.editOKButton(alert, url:url, editMode: editMode) })
        alert.addAction(cancelAction)
        alert.addAction(defaultAction)
        
        //textfiledの追加
        alert.addTextField(configurationHandler: {(text:UITextField!) -> Void in
            text.placeholder = "input title"
            text.tag = 0
            let label:UILabel = UILabel(frame: CGRect(x:0, y:0, width:50, height:30))
            label.text = "title"
            text.leftView = label
            text.leftViewMode = .always
        })
        //実行した分textfiledを追加される。
        alert.addTextField(configurationHandler: {(text:UITextField!) -> Void in
            text.placeholder = "input artist"
            text.tag = 1
            let label:UILabel = UILabel(frame: CGRect(x:0, y:0, width:50, height:30))
            label.text = "artist"
            text.leftView = label
            text.leftViewMode = .always
        })
        
        obj.present(alert, animated: true, completion: {
            
        })
    }
    
    // MARK: Notification Handler Methods
    
    @objc func handleRemoteCommandNextTrackNotification(notification: Notification) {
        guard let assetName = notification.userInfo?[Asset.nameKey] as? String else { return }
        guard let assetIndex = assets.index(where: {$0.assetName == assetName}) else { return }
        
        if assetIndex < assets.count - 1 {
            //assetPlaybackManager.asset = assets[assetIndex + 1]
            selectRow = assetIndex + 1
        } else {
            //assetPlaybackManager.asset = assets[0]
            selectRow = 0
        }
        
        playMusic()
    }
    
    @objc func handleRemoteCommandPreviousTrackNotification(notification: Notification) {
        guard let assetName = notification.userInfo?[Asset.nameKey] as? String else { return }
        guard let assetIndex = assets.index(where: {$0.assetName == assetName}) else { return }
        
        if assetIndex > 0 {
            //assetPlaybackManager.asset = assets[assetIndex - 1]
            selectRow = assetIndex - 1
            playMusic()
        }
    }
}


extension UPViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if selectRow == indexPath.row, assetPlaybackManager.state == .playing {
            return
        }
        selectRow = indexPath.row
        self.playMusic()
    }
}

extension UPViewController : UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        let asset = assets[indexPath.row]
        
        let tempDirectoryURL = NSURL.fileURL(withPath: self.documentPath(), isDirectory: true)
        let targetURL = tempDirectoryURL.appendingPathComponent("\(asset.assetName)")
        
        if FileManager.default.fileExists(atPath: targetURL.path) {
            do {
                 try FileManager.default.removeItem(at: targetURL)
            } catch {
                
            }
        }
        
        self.assets.remove(at: indexPath.row)
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if selectRow > 0 {
            return "LIST (\(selectRow+1) / \(assets.count))"
        } else {
            return "↓引っぱってリストを更新"
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return assets.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "MyCell")
        
        let asset = assets[indexPath.row]
        
        let fileSize = self.localFileSize(with: asset.urlAsset.url as URL)
        
        cell.textLabel!.text = "\(asset.assetName)(\(fileSize))"
        cell.detailTextLabel?.text = asset.albumName
        
        if selectRow == indexPath.row {
            cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 17)
            cell.textLabel?.textColor = .orange
        } else {
            cell.textLabel?.font = UIFont.systemFont(ofSize: 17)
            cell.textLabel?.textColor = .black
        }
        
        //if cell.accessoryView == nil {
            let editButton = UIButton(type: .custom) as UIButton
            editButton.frame = CGRect(x: 0, y: 0, width: 60, height: cell.frame.size.height)
            editButton.setTitle("edit", for: .normal)
            editButton.setTitleColor(.darkGray, for: .normal)
            editButton.contentHorizontalAlignment = .right
            editButton.addTarget(self, action: #selector(accessoryButtonTapped(sender:)), for: UIControlEvents.touchUpInside)
            editButton.tag = indexPath.row
            cell.accessoryView = editButton as UIView
        //}
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        print("accessoryButtonTappedForRowWith")
    }
    
    
    func localFileSize(with path: URL) -> String {
        if let imageData = NSData(contentsOf: path) {
            var convertedValue: Double = Double(imageData.length)
            var multiplyFactor = 0
            let tokens = ["bytes", "KB", "MB", "GB", "TB", "PB",  "EB",  "ZB", "YB"]
            while convertedValue > 1024 {
                convertedValue /= 1024
                multiplyFactor += 1
            }
            return String(format: "%4.2f %@", convertedValue, tokens[multiplyFactor])
        }
        return "0 MB"
    }
}

extension UPViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // 写真を選んだ後に呼ばれる処理
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        let mediaType: String = info[UIImagePickerControllerMediaType] as! String
        if mediaType == kUTTypeMovie as String, let url = info[UIImagePickerControllerMediaURL] as? URL {
            print("url : \(String(describing: url))")

           let tmpUrl = URL(fileURLWithPath: "\(self.documentPath())/\(url.lastPathComponent)")
            
            // Copy the file.
            do {
                try FileManager.default.copyItem(at: url, to: tmpUrl)
                self.showEditAlert(picker, url:tmpUrl, editMode: kEditMode)
            } catch let error as NSError {
                NSLog("Unable to copy file: \(error)")
            }
        }
    }
}

