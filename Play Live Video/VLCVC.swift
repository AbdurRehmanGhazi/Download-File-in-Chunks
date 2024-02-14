//
//  VLCVC.swift
//  Play Live Video
//
//  Created by Abdur Rehman on 27/11/2023.
//

import UIKit
import MobileVLCKit

class VLCVC: UIViewController {

    @IBOutlet weak var vlcView: UIView!
    let videoPlayer = VLCMediaPlayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        startStream()
        // Do any additional setup after loading the view.
    }
    
    func startStream() {
        videoPlayer.delegate = self
        guard let videoURL = URL(string: "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4") else {
            return
        }
        videoPlayer.drawable = view
        videoPlayer.media = VLCMedia(url: videoURL)
        
        videoPlayer.media?.addOption("-vv")
        videoPlayer.media?.addOption("--network-caching=10000")
        
        videoPlayer.play()
        
    }
}

extension VLCVC: VLCMediaPlayerDelegate {
    func mediaPlayerStateChanged(_ aNotification: Notification) {
        guard let videoPlayer = aNotification.object as? VLCMediaPlayer else { return }
        switch videoPlayer.state {
        case .stopped:
            print("VLCMediaPlayerDeletate : \("stopped".uppercased())")
        case .opening:
            print("VLCMediaPlayerDeletate : \("opening".uppercased())")
        case .buffering:
            print("VLCMediaPlayerDeletate : \("buffering".uppercased())")
        case .ended:
            print("VLCMediaPlayerDeletate : \("ended".uppercased())")
        case .error:
            print("VLCMediaPlayerDeletate : \("error".uppercased())")
        case .playing:
            print("VLCMediaPlayerDeletate : \("playing".uppercased())")
        case .paused:
            print("VLCMediaPlayerDeletate : \("paused".uppercased())")
        case .esAdded:
            print("VLCMediaPlayerDeletate : \("esAdded".uppercased())")
        @unknown default:
            print("Default")
        }
    }
}
