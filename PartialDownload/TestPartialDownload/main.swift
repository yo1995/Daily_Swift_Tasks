import Foundation

guard CommandLine.arguments.count >= 2,
      let url = URL(string: CommandLine.arguments[1]) else {
    print("Usage: downloader <URL>")
    exit(1)
}

let filename = url.lastPathComponent
let destinationURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(filename)

let downloadManager = DownloadManager(
    downloadURL: url,
    destinationURL: destinationURL
)
downloadManager.start()

// Handle user input.
while let input = readLine(strippingNewline: true) {
    switch input.lowercased() {
    case "p":
        downloadManager.pause()
    case "r":
        downloadManager.resume()
    case "q":
        print("\nQuitting.")
        exit(0)
    default:
        print("Unknown command. Use 'p' to pause, 'r' to resume, 'q' to quit.")
    }
}
