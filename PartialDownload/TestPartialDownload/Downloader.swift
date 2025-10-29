import Foundation

class DownloadManager: NSObject, URLSessionDownloadDelegate {
    private var session: URLSession!
    private var downloadTask: URLSessionDownloadTask?
    private var resumeData: Data?
    private var url: URL
    private var destinationURL: URL
    private var isDownloading = false
    private var progress: Double = 0
    
    init(downloadURL: URL, destinationURL: URL) {
        url = downloadURL
        self.destinationURL = destinationURL
        super.init()
        session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    }
    
    func start() {
        guard !isDownloading else { return }
        if let resumeData {
            downloadTask = session.downloadTask(withResumeData: resumeData)
        } else {
            downloadTask = session.downloadTask(with: url)
        }
        downloadTask?.resume()
        isDownloading = true
        print("Download started.")
    }
    
    func pause() {
        guard isDownloading else { return }
        downloadTask?.cancel(byProducingResumeData: { data in
            self.resumeData = data
        })
        isDownloading = false
        // Reset progress so it handles both partial and restart.
        progress = .zero
        print("\nDownload paused.")
    }
    
    func resume() {
        guard !isDownloading else { return }
        start()
    }
    
    func urlSession(
        _ session: URLSession, downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        let newProgress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        if newProgress - progress >= 0.01 {
            progress = newProgress
            let percentage = Int(progress * 100)
            print("Download progress: \(percentage)%", terminator: "\r")
            fflush(stdout)
        }
    }
    
    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        do {
            try FileManager.default.moveItem(at: location, to: destinationURL)
            print("\nDownload finished. File saved to \(destinationURL.path)")
        } catch {
            print("\nFailed to move downloaded file: \(error)")
            exit(1)
        }
        isDownloading = false
        exit(0)
    }
    
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        if let error = error as NSError?,
           error.domain != NSURLErrorDomain || error.code != NSURLErrorCancelled {
            print("\nDownload failed: \(error.localizedDescription)")
            exit(1)
        }
    }
}
