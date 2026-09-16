import CoreGraphics
import CryptoKit
import Foundation
import ImageIO
import UIKit

/// Where image files live.
///
/// Three tiers, checked in this order:
///
/// | Tier      | Location                       | Survives app close          |
/// |-----------|--------------------------------|-----------------------------|
/// | memory    | `NSCache`                      | no                          |
/// | disk cache| `.cachesDirectory`             | yes, but iOS may purge it   |
/// | favourites| `Documents/Favorites`          | yes, guaranteed             |
///
/// `UIImage` appears here because `NSCache` needs a class type and because
/// decoding once beats decoding on every scroll. No UIKit views are involved.
///
/// `@unchecked Sendable` is accurate rather than a shortcut: `NSCache` and
/// `FileManager` are both documented as thread-safe, and nothing else here is
/// mutable state.
final class ImageStore: @unchecked Sendable {
    static let shared = ImageStore()

    private let memory = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default

    private let favoritesDirectory: URL
    private let cacheDirectory: URL

    private init() {
        favoritesDirectory = URL.documentsDirectory.appending(path: "Favorites")
        cacheDirectory = URL.cachesDirectory.appending(path: "ImageCache")
        for directory in [favoritesDirectory, cacheDirectory] {
            try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        memory.countLimit = 150
    }

    // MARK: - Favourites (Documents — guaranteed to survive)

    /// Downloads the image and writes it into Documents, returning the file name
    /// to store alongside the SwiftData row.
    func saveFavorite(from url: URL, identifier: String) async throws -> String {
        let fileName = identifier + ".jpg"
        let (data, response) = try await URLSession.shared.data(from: url)

        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw NetworkError.badStatus(code: http.statusCode)
        }
        guard let image = UIImage(data: data) else {
            throw NetworkError.decodingFailed(underlying: URLError(.cannotDecodeContentData))
        }

        // Written as the original bytes rather than re-encoded, so nothing is
        // lost to a second round of JPEG compression.
        try data.write(to: favoritesDirectory.appending(path: fileName), options: .atomic)
        memory.setObject(image, forKey: fileName as NSString)
        return fileName
    }

    func loadFavorite(fileName: String) async -> UIImage? {
        if let cached = memory.object(forKey: fileName as NSString) { return cached }

        let url = favoritesDirectory.appending(path: fileName)
        // Off the main actor so a screen full of favourites does not read the
        // disk while the list is scrolling.
        let image = await Task.detached(priority: .userInitiated) {
            guard let data = try? Data(contentsOf: url) else { return UIImage?.none }
            return UIImage(data: data)
        }.value

        if let image { memory.setObject(image, forKey: fileName as NSString) }
        return image
    }

    /// Called when a photo is unfavourited, so the file does not outlive its row.
    func deleteFavorite(fileName: String) {
        memory.removeObject(forKey: fileName as NSString)
        try? fileManager.removeItem(at: favoritesDirectory.appending(path: fileName))
    }

    // MARK: - General image loading (memory → disk cache → network)

    /// `maxPixelSize` downsamples while decoding.
    ///
    /// A month of APOD pictures is 31 full-resolution images, and NASA publishes
    /// no thumbnails. Decoded at full size that is roughly 100MB of bitmaps in
    /// memory at once; at 400px it is closer to 15MB. It does not reduce what is
    /// downloaded — only what is decoded and held.
    func image(for url: URL, maxPixelSize: CGFloat? = nil) async throws -> UIImage {
        let key = cacheKey(for: url, maxPixelSize: maxPixelSize)

        if let cached = memory.object(forKey: key as NSString) { return cached }

        let fileURL = cacheDirectory.appending(path: key)
        if let image = await Task.detached(priority: .userInitiated, operation: {
            guard let data = try? Data(contentsOf: fileURL) else { return UIImage?.none }
            return Self.decode(data, maxPixelSize: maxPixelSize)
        }).value {
            memory.setObject(image, forKey: key as NSString)
            return image
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw NetworkError.badStatus(code: http.statusCode)
        }
        guard let image = Self.decode(data, maxPixelSize: maxPixelSize) else {
            throw NetworkError.decodingFailed(underlying: URLError(.cannotDecodeContentData))
        }

        // For a sized request keep the shrunken copy, not the original. The file
        // is keyed by size, so storing the original meant a warm launch re-read
        // the whole picture to draw a 400px cell — and one APOD this month is a
        // 16MB GIF. The full-size path still caches the bytes untouched.
        let bytesToCache = maxPixelSize == nil
            ? data
            : (image.jpegData(compressionQuality: 0.8) ?? data)
        try? bytesToCache.write(to: fileURL, options: .atomic)
        memory.setObject(image, forKey: key as NSString)
        return image
    }

    /// Decodes image data, optionally shrinking it in the process. ImageIO does
    /// the downsampling during decode, so the full-size bitmap is never created.
    private static func decode(_ data: Data, maxPixelSize: CGFloat?) -> UIImage? {
        guard let maxPixelSize else { return UIImage(data: data) }
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ]
        guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
        else { return UIImage(data: data) }
        return UIImage(cgImage: thumbnail)
    }

    /// A synchronous peek at the memory tier only, so a view can render an
    /// already-decoded image in the same frame instead of flashing a placeholder.
    func memoryImage(for url: URL, maxPixelSize: CGFloat? = nil) -> UIImage? {
        memory.object(forKey: cacheKey(for: url, maxPixelSize: maxPixelSize) as NSString)
    }

    /// A URL is not a legal file name, and `hashValue` changes between launches,
    /// so the cache is keyed on a stable hash of the address.
    /// The size is part of the key, so a 400px grid copy is never handed to the
    /// detail screen, which asks for the full-size one.
    private func cacheKey(for url: URL, maxPixelSize: CGFloat?) -> String {
        let digest = SHA256.hash(data: Data(url.absoluteString.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
        guard let maxPixelSize else { return digest }
        return "\(digest)-\(Int(maxPixelSize))"
    }

    // MARK: - Diagnostics

    /// Used by the Favorites screen's footer to make the offline story visible.
    func favoritesOnDiskCount() -> Int {
        (try? fileManager.contentsOfDirectory(atPath: favoritesDirectory.path()).count) ?? 0
    }
}
