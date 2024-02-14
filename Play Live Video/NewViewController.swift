//
//  NewViewController.swift
//  Play Live Video
//
//  Created by Abdur Rehman on 13/02/2024.
//

//let videoURLString = "https://storage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
import UIKit
import AVFoundation

class NewViewController: UIViewController, URLSessionDownloadDelegate {
    
    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?
    var session: URLSession?
    var destinationURL: URL?
    var fileHandle: FileHandle?
    let chunkSize: Int = 1024 * 1024 // 1 MB chunk size
    var currentOffset: Int = 0
    var downloadFileSize: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // URL of the video stream
        let videoURLString = "https://storage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        guard let videoURL = URL(string: videoURLString) else { return }
        
        // Create a URLSession to download the video file
        session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        
        // Create a temporary file URL to save the downloaded data
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        destinationURL = documentsDirectory.appendingPathComponent("liveStream.mp4")
        
        // Create the file if it doesn't exist
        if !FileManager.default.fileExists(atPath: destinationURL!.path) {
            let success = FileManager.default.createFile(atPath: destinationURL!.path, contents: nil, attributes: nil)
            if !success {
                print("Error: Failed to create file at \(destinationURL!.path)")
                return
            }
        } else {
            currentOffset = try! Data(contentsOf: destinationURL!).count
        }
        
        // Open the file handle for writing
        do {
            fileHandle = try FileHandle(forWritingTo: destinationURL!)
        } catch {
            print("Error: Unable to open file handle for writing - \(error)")
            return
        }
        
        let url = URL(string: "https://s3.amazonaws.com/x265.org/video/Tears_400_x265.mp4")!

        videoURL.fetchContentLength(completionHandler: { (fileSize) in
            print("Video file size \(fileSize ?? 0)")
            self.downloadFileSize = Int(fileSize ?? .min)
            if self.downloadFileSize > self.currentOffset {
                // Start downloading the video
                self.downloadNextChunk(from: videoURL)
            } else {
                DispatchQueue.main.async {
                    self.setupPlayer()
                }
            }
        })
    }
    
    func downloadNextChunk(from videoURL: URL) {
        // Calculate the end offset for the current chunk
        let endOffset = min(currentOffset + chunkSize, Int.max)
        
        // Create a URLRequest for the video file with the appropriate Range header
        var request = URLRequest(url: videoURL)
        request.addValue("bytes=\(currentOffset)-\(endOffset)", forHTTPHeaderField: "Range")
        
        // Create a download task to download the next chunk
        let downloadTask = session?.downloadTask(with: request)
        downloadTask?.resume()
        print("bytes=\(currentOffset)-\(endOffset)")
        print("FileSize: ",try? Data(contentsOf: destinationURL!).count)
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        do {
            // Move the downloaded data to the destination file
            let data = try Data(contentsOf: location)
            if var fileHandle = fileHandle {
                // Append the downloaded data to the file
                fileHandle = try FileHandle(forWritingTo: destinationURL!)
                // Seek to the end of the file before writing
                fileHandle.seekToEndOfFile()
                
                fileHandle.write(data)
                fileHandle.closeFile()
                // Update the current offset for the next chunk
                currentOffset += data.count
            } else {
                print("Error: File handle is nil")
            }
        } catch {
            print("Error: Failed to write downloaded data to file - \(error)")
            return
        }
        
        if downloadFileSize > self.currentOffset {
            // Continue downloading the next chunk
            downloadNextChunk(from: downloadTask.originalRequest!.url!)
        } else {
            print("Downloading complete")
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            print("Download task completed with error: \(error)")
        } else {
            print("Download task completed successfully")
        }

        // Initialize the AVPlayer and start playback
        DispatchQueue.main.async {
            self.setupPlayer()
        }
    }
    
    func setupPlayer() {
        // Create AVPlayer with AVPlayerItem

        if let destinationURL = destinationURL, player == nil {
            let playerItem = AVPlayerItem(url: destinationURL)
            player = AVPlayer(playerItem: playerItem)
            
            // Create AVPlayerLayer and add it to view
            playerLayer = AVPlayerLayer(player: player)
            playerLayer?.frame = view.bounds
            view.layer.addSublayer(playerLayer!)
            
            // Start playing the video
            player?.play()
        }
    }
}





extension URL {
    
    func fetchContentLength(completionHandler: @escaping (_ contentLength: UInt64?) -> ()) {
        
      var request = URLRequest(url: self)
      request.httpMethod = "HEAD"
        
      let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
        guard error == nil,
          let response = response as? HTTPURLResponse,
          let contentLength = response.allHeaderFields["Content-Length"] as? String else {
            completionHandler(nil)
            return
        }
        completionHandler(UInt64(contentLength))
      }
        
      task.resume()
    }
}









/*

 class NewViewController: UIViewController, URLSessionDownloadDelegate {
     
     var player: AVPlayer?
     var playerLayer: AVPlayerLayer?
     var session: URLSession?
     var destinationURL: URL?
     var fileHandle: FileHandle?
     let chunkSize: Int = 1024 * 1024 // 1 MB chunk size
     var currentOffset: Int = 0
     
     override func viewDidLoad() {
         super.viewDidLoad()
         
         // URL of the video stream
         let videoURLString = "https://storage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
         guard let videoURL = URL(string: videoURLString) else { return }
         
         // Create a URLSession to download the video file
         session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
         
         // Create a temporary file URL to save the downloaded data
         let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
         destinationURL = documentsDirectory.appendingPathComponent("liveStream.mp4")
         
         // Create the file if it doesn't exist
         if !FileManager.default.fileExists(atPath: destinationURL!.path) {
             let success = FileManager.default.createFile(atPath: destinationURL!.path, contents: nil, attributes: nil)
             if !success {
                 print("Error: Failed to create file at \(destinationURL!.path)")
                 return
             }
         }
         
         // Open the file handle for writing
         do {
             fileHandle = try FileHandle(forWritingTo: destinationURL!)
         } catch {
             print("Error: Unable to open file handle for writing - \(error)")
             return
         }
         
         // Start downloading the video
         downloadNextChunk(from: videoURL)
     }
     
     func downloadNextChunk(from videoURL: URL) {
         // Calculate the end offset for the current chunk
         let endOffset = min(currentOffset + chunkSize, Int.max)
         
         // Create a URLRequest for the video file with the appropriate Range header
         var request = URLRequest(url: videoURL)
         request.addValue("bytes=\(currentOffset)-\(endOffset)", forHTTPHeaderField: "Range")
         
         // Create a download task to download the next chunk
         let downloadTask = session?.downloadTask(with: request)
         downloadTask?.resume()
     }
     
     func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
         do {
             // Move the downloaded data to the destination file
             let data = try Data(contentsOf: location)
             if let fileHandle = fileHandle {
                 // Seek to the end of the file before writing
                 fileHandle.seekToEndOfFile()
                 
                 // Write the downloaded data to the file
                 fileHandle.write(data)
             } else {
                 print("Error: File handle is nil")
             }
             
             // Update the current offset for the next chunk
             currentOffset += data.count
         } catch {
             print("Error: Failed to write downloaded data to file - \(error)")
             return
         }
         
         // Continue downloading the next chunk
         downloadNextChunk(from: downloadTask.originalRequest!.url!)
     }
     
     func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
         if let error = error {
             print("Download task completed with error: \(error)")
         } else {
             print("Download task completed successfully")
         }
         
         // Close the file handle after download completion
         fileHandle?.closeFile()
         
         // Initialize the AVPlayer and start playback
         DispatchQueue.main.async {
             self.setupPlayer()
         }
     }
     
     func setupPlayer() {
         // Create AVPlayer with AVPlayerItem
         if let destinationURL = destinationURL {
             let playerItem = AVPlayerItem(url: destinationURL)
             player = AVPlayer(playerItem: playerItem)
             
             // Create AVPlayerLayer and add it to view
             playerLayer = AVPlayerLayer(player: player)
             playerLayer?.frame = view.bounds
             view.layer.addSublayer(playerLayer!)
             
             // Start playing the video
             player?.play()
         } else {
             print("Error: Destination URL is nil")
         }
     }
 }
 
*/
