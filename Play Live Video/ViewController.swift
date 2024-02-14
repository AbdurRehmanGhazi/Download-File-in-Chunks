//
//  ViewController.swift
//  Play Live Video
//
//  Created by Abdur Rehman on 24/11/2023.
//
import AVFoundation
import UIKit
import FlipBook
import AVKit

class ViewController: UIViewController {
    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?
    var timeObserver: Any?
    var isSeeking = false

    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var totalTimeLabel: UILabel!
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var progressBarSlider: UISlider!

    let flipBook = FlipBook()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Create the video URL from the server
        guard let videoURL = URL(string: "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4") else {
            return
        }

        // Create an AVPlayer with the video URL
        player = AVPlayer(url: videoURL)

        // Create an AVPlayerLayer and add it to your view's layer
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.frame = videoView.bounds
        playerLayer?.videoGravity = .resizeAspect // Adjust the video gravity as per your requirement

        if let playerLayer = playerLayer {
            videoView.layer.addSublayer(playerLayer)
        }

        // Add time observer to update the time label and progress bar
        addTimeObserver()

        // Play the video
        player?.play()
        
        // Usage:
        // Replace "YOUR_VIDEO_URL_HERE" with the actual URL of your video
        getTotalVideoLength(from: videoURL) { totalLength in
            if let length = totalLength {
                print("Total video length: \(length) seconds")
                self.updateTotalTimeLabel(length)
                // Use the obtained length as needed in your application
            } else {
                print("Failed to get video length.")
            }
            
        }
        
        // Configure the progress bar
        progressBarSlider.addTarget(self, action: #selector(progressChanged(_:)), for: .valueChanged)
    }

//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//        
//        DispatchQueue.main.asyncAfter(deadline: .now()+5, execute: {
//            
//                                          
//            self.flipBook.startRecording(self.view) { [weak self] result in
//                   
//                   // Switch on result
//                   switch result {
//                   case .success(let asset):
//                       // Switch on the asset that's returned
//                       switch asset {
//                       case .video(let url):
//                           // Do something with the video
//                           self?.playRecordedVideo(url: url)
//                       // We expect a video so do nothing for .livePhoto and .gif
//                       case .livePhoto, .gif:
//                           break
//                       }
//                   case .failure(let error):
//                       // Handle error in recording
//                       print(error)
//                   }
//               }
//               
//        })
//        
//        DispatchQueue.main.asyncAfter(deadline: .now()+15, execute: {
//            print("stop recording")
//            self.flipBook.stop()
//        })
//    }
    
    func playRecordedVideo(url: URL?) {
            if let videoURL = url {
                let player = AVPlayer(url: videoURL)
                let playerViewController = AVPlayerViewController()
                playerViewController.player = player
                present(playerViewController, animated: true) {
                    player.play()
                }
            }
        }

    func addTimeObserver() {
        // Update the time label and progress bar every 0.1 second
        let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main) { [weak self] time in
            guard let player = self?.player, !self!.isSeeking  else { return }

            let currentTime = CMTimeGetSeconds(time)
            let duration = CMTimeGetSeconds(player.currentItem?.duration ?? CMTime.zero)
            
            self?.updateTimeLabel(currentTime)
            self?.updateProgressBar(currentTime, duration)
        }
    }

    func updateTimeLabel(_ currentTime: Double) {
        let timeFormatter = DateComponentsFormatter()
        timeFormatter.allowedUnits = [.minute, .second]
        timeFormatter.unitsStyle = .positional
        timeFormatter.zeroFormattingBehavior = .pad

        if let formattedString = timeFormatter.string(from: TimeInterval(currentTime)) {
            timeLabel.text = formattedString
        }
    }
    
    func updateTotalTimeLabel(_ currentTime: Double) {
        let timeFormatter = DateComponentsFormatter()
        timeFormatter.allowedUnits = [.minute, .second]
        timeFormatter.unitsStyle = .positional
        timeFormatter.zeroFormattingBehavior = .pad

        if let formattedString = timeFormatter.string(from: TimeInterval(currentTime)) {
            totalTimeLabel.text = formattedString
        }
    }

    func updateProgressBar(_ currentTime: Double, _ duration: Double) {
        guard duration > 0 else { return }

        let progress = Float(currentTime / duration)
        progressBar.progress = progress
        progressBarSlider.value = progress
    }
    
    func getTotalVideoLength(from url: URL, completion: @escaping (Double?) -> Void) {
        let asset = AVURLAsset(url: url)
        let duration = asset.duration
        let durationInSeconds = CMTimeGetSeconds(duration)
        
        if !durationInSeconds.isNaN && durationInSeconds > 0 {
            completion(durationInSeconds)
        } else {
            completion(nil)
        }
    }

    @objc func progressChanged(_ sender: UISlider) {
        if let player = player {
            let duration = CMTimeGetSeconds(player.currentItem?.duration ?? CMTime.zero)
            let seekTime = Double(sender.value) * duration
            let timeToSeek = CMTime(seconds: seekTime, preferredTimescale: 1)
            
            isSeeking = true
            
            player.seek(to: timeToSeek) { [weak self] _ in
                DispatchQueue.main.async {
                    self?.isSeeking = false
                }
            }
        }
    }

    deinit {
        // Remove time observer when the view controller is deallocated
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }
    }
}


/*
class ViewController: UIViewController {
    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?
    var timeObserver: Any?
    var isSeeking = false
    
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var progressBar: UISlider!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Create the video URL from the server
        guard let videoURL = URL(string: "YOUR_VIDEO_URL_HERE") else {
            return
        }

        // Create an AVPlayer with the video URL
        player = AVPlayer(url: videoURL)

        // Create an AVPlayerLayer and add it to your view's layer
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.frame = videoView.bounds
        playerLayer?.videoGravity = .resizeAspectFill // Adjust the video gravity as per your requirement

        if let playerLayer = playerLayer {
            videoView.layer.addSublayer(playerLayer)
        }

        // Add time observer to update the time label and progress bar
        addTimeObserver()

        // Play the video
        player?.play()
        
        // Configure the progress bar
        progressBar.addTarget(self, action: #selector(progressChanged(_:)), for: .valueChanged)
    }

    func addTimeObserver() {
        // Update the time label and progress bar every 0.1 second
        let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main) { [weak self] time in
            guard let player = self?.player, !self!.isSeeking else { return }

            let currentTime = CMTimeGetSeconds(time)
            let duration = CMTimeGetSeconds(player.currentItem?.duration ?? CMTime.zero)
            
            self?.updateTimeLabel(currentTime, duration)
            self?.updateProgressBar(currentTime, duration)
        }
    }

    func updateTimeLabel(_ currentTime: Double, _ duration: Double) {
        let timeFormatter = DateComponentsFormatter()
        timeFormatter.allowedUnits = [.hour, .minute, .second]
        timeFormatter.unitsStyle = .positional

        if let formattedString = timeFormatter.string(from: TimeInterval(currentTime)) {
            timeLabel.text = formattedString + "/" + timeFormatter.string(from: TimeInterval(duration))!
        }
    }

    func updateProgressBar(_ currentTime: Double, _ duration: Double) {
        guard duration > 0 else { return }

        let progress = Float(currentTime / duration)
        progressBar.value = progress
    }

    @objc func progressChanged(_ sender: UISlider) {
        if let player = player {
            let duration = CMTimeGetSeconds(player.currentItem?.duration ?? CMTime.zero)
            let seekTime = Double(sender.value) * duration
            let timeToSeek = CMTime(seconds: seekTime, preferredTimescale: 1)
            
            isSeeking = true
            
            player.seek(to: timeToSeek) { [weak self] _ in
                self?.isSeeking = false
            }
        }
    }

    deinit {
        // Remove time observer when the view controller is deallocated
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }
    }
}
*/
