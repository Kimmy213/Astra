import Foundation
import SwiftData

/// Everything needed to turn a photo from either API into a favourite, so the
/// screens don't each have to know how a FavoritePhoto is assembled.
struct FavoriteDraft {
    let identifier: String
    let title: String
    let detail: String
    /// What the row records. On APOD video days this is the video page.
    let remoteURL: String
    /// The image to download for offline use. Nil when there isn't one.
    let imageURL: URL?
    let source: PhotoSource
    let captureDate: String
}

extension APODResponse {
    var favoriteIdentifier: String { "apod-\(date)" }

    var favoriteDraft: FavoriteDraft {
        FavoriteDraft(
            identifier: favoriteIdentifier,
            title: title,
            detail: explanation,
            remoteURL: url,
            // Video days have a YouTube page where the image would be, so there
            // is nothing to download and localFileName stays nil.
            imageURL: isImage ? displayURL : nil,
            source: .apod,
            captureDate: date
        )
    }
}

extension NASAImageItem {
    var favoriteIdentifier: String { "mars-\(id)" }

    var favoriteDraft: FavoriteDraft {
        FavoriteDraft(
            identifier: favoriteIdentifier,
            title: title,
            detail: summary,
            remoteURL: originalURL?.absoluteString ?? "",
            // The grid-sized asset, not the full-resolution one: favouriting
            // should feel instant and this is what gets displayed.
            imageURL: thumbnailURL,
            source: .mars,
            captureDate: String(dateCreated.prefix(10))
        )
    }
}

@MainActor
struct FavoritesManager {
    let context: ModelContext

    func existing(identifier: String) -> FavoritePhoto? {
        var descriptor = FetchDescriptor<FavoritePhoto>(
            predicate: #Predicate<FavoritePhoto> { $0.identifier == identifier }
        )
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    func isFavorite(identifier: String) -> Bool {
        existing(identifier: identifier) != nil
    }

    func toggle(_ draft: FavoriteDraft) async {
        if let favorite = existing(identifier: draft.identifier) {
            remove(favorite)
        } else {
            await add(draft)
        }
    }

    func add(_ draft: FavoriteDraft) async {
        let favorite = FavoritePhoto(
            identifier: draft.identifier,
            title: draft.title,
            detail: draft.detail,
            remoteURL: draft.remoteURL,
            source: draft.source,
            captureDate: draft.captureDate
        )
        // Inserted first so the star fills the moment it is tapped; the image
        // file catches up a moment later.
        context.insert(favorite)
        try? context.save()

        guard let imageURL = draft.imageURL else { return }
        // A failed download leaves a favourite with no offline image rather than
        // throwing the whole thing away.
        favorite.localFileName = try? await ImageStore.shared.saveFavorite(
            from: imageURL,
            identifier: draft.identifier
        )
        try? context.save()
    }

    /// Deletes the row and its file together, so nothing is orphaned on disk.
    func remove(_ favorite: FavoritePhoto) {
        if let fileName = favorite.localFileName {
            ImageStore.shared.deleteFavorite(fileName: fileName)
        }
        context.delete(favorite)
        try? context.save()
    }
}
