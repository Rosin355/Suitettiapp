import UIKit

/// Two-tier persistent image cache: NSCache (memory) + FileManager (disk).
///
/// Load order: memory → disk → URLSession network.
/// All access is @MainActor so callers on the main actor never cross an isolation boundary.
@MainActor
final class ImageCache {
    static let shared = ImageCache()
    private init() {
        memoryCache.countLimit = 100
        memoryCache.totalCostLimit = 50 * 1024 * 1024
        if let dir = Self.diskDir {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
    }

    private let memoryCache = NSCache<NSString, UIImage>()

    // MARK: - Public

    func image(for url: URL) async -> UIImage? {
        let key = url.absoluteString as NSString

        // 1. Memory
        if let img = memoryCache.object(forKey: key) {
            NSLog("[ImageCache] memory: %@", url.lastPathComponent)
            return img
        }

        // 2. Disk
        if let fileURL = Self.fileURL(for: url),
           let data = try? Data(contentsOf: fileURL),
           let img = UIImage(data: data) {
            NSLog("[ImageCache] disk: %@", url.lastPathComponent)
            memoryCache.setObject(img, forKey: key)
            return img
        }

        // 3. Network
        NSLog("[ImageCache] fetch: %@", url.absoluteString)
        guard let (data, response) = try? await URLSession.shared.data(from: url),
              (response as? HTTPURLResponse)?.statusCode == 200,
              let img = UIImage(data: data) else {
            NSLog("[ImageCache] ✗ failed: %@", url.absoluteString)
            return nil
        }
        memoryCache.setObject(img, forKey: key)
        if let fileURL = Self.fileURL(for: url) {
            try? data.write(to: fileURL, options: .atomic)
        }
        NSLog("[ImageCache] ✓ saved: %@", url.lastPathComponent)
        return img
    }

    // MARK: - Disk helpers

    private static var diskDir: URL? {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?
            .appendingPathComponent("DST_ImageCache")
    }

    private static func fileURL(for url: URL) -> URL? {
        guard let dir = diskDir else { return nil }
        let hash = abs(url.absoluteString.hashValue)
        return dir.appendingPathComponent("\(hash).imgcache")
    }
}
