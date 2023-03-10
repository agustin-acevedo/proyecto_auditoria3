import AutomatticTracks
import Aztec
import Gridicons

final class AuthenticatedImageDownload: AsyncOperation {
    let url: URL
    let blog: Blog
    private let onSuccess: (UIImage) -> ()
    private let onFailure: (Error) -> ()

    init(url: URL, blog: Blog, onSuccess: @escaping (UIImage) -> (), onFailure: @escaping (Error) -> ()) {
        self.url = url
        self.blog = blog
        self.onSuccess = onSuccess
        self.onFailure = onFailure
    }

    override func main() {
        let mediaRequestAuthenticator = MediaRequestAuthenticator()
        let host = MediaHost(with: blog) { error in
            // We'll log the error, so we know it's there, but we won't halt execution.
            WordPressAppDelegate.crashLogging?.logError(error)
        }

        mediaRequestAuthenticator.authenticatedRequest(
            for: url,
            from: host,
            onComplete: { request in
                ImageDownloader.shared.downloadImage(for: request) { (image, error) in
                    self.state = .isFinished

                    DispatchQueue.main.async {
                        guard let image = image else {
                            DDLogError("Unable to download image for attachment with url = \(String(describing: request.url)). Details: \(String(describing: error?.localizedDescription))")
                            if let error = error {
                                self.onFailure(error)
                            } else {
                                self.onFailure(NSError(domain: NSURLErrorDomain, code: NSURLErrorUnknown, userInfo: nil))
                            }

                            return
                        }

                        self.onSuccess(image)
                    }
                }
        },
            onFailure: { error in
                self.state = .isFinished
                self.onFailure(error)
        })
    }
}

struct VideoMetadata: Encodable {
    public let videopressGUID: String?

    public func asDictionary() -> [String: Any] {
        guard
            let data = try? JSONEncoder().encode(self),
            let dictionary = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
        else {
            assertionFailure("Encoding of VideoMetadata failed")
            return [String: Any]()
        }
        return dictionary
    }
}

class EditorMediaUtility {

    private struct Constants {
        static let placeholderDocumentLink = URL(string: "documentUploading://")!
    }

    func placeholderImage(for attachment: NSTextAttachment, size: CGSize, tintColor: UIColor?) -> UIImage {
        var icon: UIImage
        switch attachment {
        case let imageAttachment as ImageAttachment:
            if imageAttachment.url == Constants.placeholderDocumentLink {
                icon = .gridicon(.pages, size: size)
            } else {
                icon = .gridicon(.image, size: size)
            }
        case _ as VideoAttachment:
            icon = .gridicon(.video, size: size)
        default:
            icon = .gridicon(.attachment, size: size)
        }
        if let color = tintColor {
            icon = icon.withTintColor(color)
        }
        icon.addAccessibilityForAttachment(attachment)
        return icon
    }

    func fetchPosterImage(for sourceURL: URL, onSuccess: @escaping (UIImage) -> (), onFailure: @escaping () -> ()) {
        let thumbnailGenerator = MediaVideoExporter(url: sourceURL)
        thumbnailGenerator.exportPreviewImageForVideo(atURL: sourceURL, imageOptions: nil, onCompletion: { (exportResult) in
            guard let image = UIImage(contentsOfFile: exportResult.url.path) else {
                onFailure()
                return
            }
            DispatchQueue.main.async {
                onSuccess(image)
            }
        }, onError: { (error) in
            DDLogError("Unable to grab frame from video = \(sourceURL). Details: \(error.localizedDescription)")
            onFailure()
        })
    }


    func downloadImage(
        from url: URL,
        post: AbstractPost,
        success: @escaping (UIImage) -> Void,
        onFailure failure: @escaping (Error) -> Void) -> ImageDownloaderTask {

        let imageMaxDimension = max(UIScreen.main.bounds.size.width, UIScreen.main.bounds.size.height)
        //use height zero to maintain the aspect ratio when fetching
        let size = CGSize(width: imageMaxDimension, height: 0)
        let scale = UIScreen.main.scale

        return downloadImage(from: url, size: size, scale: scale, post: post, success: success, onFailure: failure)
    }

    func downloadImage(
        from url: URL,
        size requestSize: CGSize,
        scale: CGFloat, post: AbstractPost,
        success: @escaping (UIImage) -> Void,
        onFailure failure: @escaping (Error) -> Void) -> ImageDownloaderTask {

        let imageMaxDimension = max(requestSize.width, requestSize.height)
        //use height zero to maintain the aspect ratio when fetching
        var size = CGSize(width: imageMaxDimension, height: 0)
        let requestURL: URL

        if url.isFileURL {
            requestURL = url
        } else if post.isPrivateAtWPCom() && url.isHostedAtWPCom {
            // private wpcom image needs special handling.
            // the size that WPImageHelper expects is pixel size
            size.width = size.width * scale
            requestURL = WPImageURLHelper.imageURLWithSize(size, forImageURL: url)
        } else if !post.blog.isHostedAtWPcom && post.blog.isBasicAuthCredentialStored() {
            size.width = size.width * scale
            requestURL = WPImageURLHelper.imageURLWithSize(size, forImageURL: url)
        } else {
            // the size that PhotonImageURLHelper expects is points size
            requestURL = PhotonImageURLHelper.photonURL(with: size, forImageURL: url)
        }

        let imageDownload = AuthenticatedImageDownload(
            url: requestURL,
            blog: post.blog,
            onSuccess: success,
            onFailure: failure)

        imageDownload.start()
        return imageDownload
    }

    static func fetchRemoteVideoURL(for media: Media, in post: AbstractPost, withToken: Bool = false, completion: @escaping ( Result<(URL), Error> ) -> Void) {
        // Return the attachment url it it's not a VideoPress video
        if media.videopressGUID == nil {
            guard let videoURLString = media.remoteURL, let videoURL = URL(string: videoURLString) else {
                DDLogError("Unable to find remote video URL for video with upload ID = \(media.uploadID).")
                completion(Result.failure(NSError()))
                return
            }
            completion(Result.success(videoURL))
        }
        else {
            fetchVideoPressMetadata(for: media, in: post) { result in
                switch result {
                case .success((let metadata)):
                    if withToken {
                        guard let videoURL = metadata.getURLWithToken(url: metadata.originalURL) else {
                            DDLogWarn("Failed getting video play URL for media with upload ID: \(media.uploadID)")
                            return
                        }
                        completion(Result.success(videoURL))
                    }
                    else {
                        guard let videoURL = metadata.originalURL else {
                            DDLogWarn("Failed getting original URL for media with upload ID: \(media.uploadID)")
                            return
                        }
                        completion(Result.success(videoURL))
                    }
                case .failure(let error):
                    completion(Result.failure(error))
                }
            }
        }
    }

    static func fetchVideoPressMetadata(for media: Media, in post: AbstractPost, completion: @escaping ( Result<(RemoteVideoPressVideo), Error> ) -> Void) {
        guard let videoPressID = media.videopressGUID else {
            DDLogError("Unable to find metadata for video with upload ID = \(media.uploadID).")
            completion(Result.failure(NSError()))
            return
        }

        let mediaService = MediaService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        mediaService.getMetadataFromVideoPressID(videoPressID, in: post.blog, success: { (metadata) in
            completion(Result.success(metadata))
        }, failure: { (error) in
            DDLogError("Unable to find metadata for VideoPress video with ID = \(videoPressID). Details: \(error.localizedDescription)")
            completion(Result.failure(error))
        })
    }

    static func getVideoMetadata(media: Media) -> VideoMetadata {
        return VideoMetadata(videopressGUID: media.videopressGUID)
    }
}
