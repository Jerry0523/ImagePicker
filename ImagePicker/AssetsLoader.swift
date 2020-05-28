//
//  AssetsLoader.swift
//  ImagePickerMacOSDemo
//
//  Created by Jerry Wong on 2020/5/1.
//  Copyright © 2020 com.jerry. All rights reserved.
//

import Photos
import Combine

protocol ProgressOptions {
    
    var progressHandler: PHAssetImageProgressHandler? { get set }
}

struct RequestParam<T> where T: ProgressOptions {
    
    let targetSize: CGSize
    
    let contentMode: PHImageContentMode
    
    var options: T
    
}

protocol SupportedAsset where Options: ProgressOptions {
    
    associatedtype Options
    
    associatedtype Content
    
    static var preferredReqOpts: Options { get }
    
    static func request(_ asset: PHAsset, with manager: PHImageManager, and: RequestParam<Options>, resultHandler: @escaping (Content?, [AnyHashable : Any]?) -> Void) -> PHImageRequestID
}

class AssetsLoader {
    
    func livePhotoTask(for asset: PHAsset) -> Task<PHLivePhoto> {
        Task<PHLivePhoto>(asset, onLoad: { [unowned self] asset, targetSize, isThumbnail, promise in
            self.request(asset, param: .init(targetSize: targetSize, contentMode: .aspectFill, options: PHLivePhoto.preferredReqOpts), promise: promise)
            }, onUnload: { [unowned self] reqID in
                self.manager.cancelImageRequest(reqID)
            }
        )
    }
    
    func videoTask(for asset: PHAsset) -> Task<AVPlayerItem> {
        Task<AVPlayerItem>(asset, onLoad: { [unowned self] asset, targetSize, isThumbnail, promise in
            self.request(asset, param: .init(targetSize: .zero, contentMode: .aspectFill, options: AVPlayerItem.preferredReqOpts), promise: promise)
            }, onUnload: { [unowned self] reqID in
                self.manager.cancelImageRequest(reqID)
            }
        )
    }
    
    func imageTask(for asset: PHAsset) -> Task<ImageType> {
        if let stored = imageTasks[asset] {
            return stored
        }
        let task = Task<ImageType>(asset, onLoad: { [unowned self] asset, targetSize, isThumbnail, promise in
                self.request(asset, param: .init(targetSize: targetSize, contentMode: .aspectFill, options: ImageType.preferredReqOpts), promise: promise)
            }, onUnload: { [unowned self] reqID in
                self.manager.cancelImageRequest(reqID)
            }
        )
        imageTasks[asset] = task
        return task
    }
    
    func prefetch(_ assets: [PHAsset]?, targetSize: CGSize) {
        manager.stopCachingImagesForAllAssets()
        guard let assets = assets, targetSize != .zero else {
            return
        }
        manager.startCachingImages(for: assets, targetSize: targetSize, contentMode: .aspectFill, options: ImageType.preferredReqOpts)
    }
    
    private func request<T>(_ asset: PHAsset, param: RequestParam<T.Options>, promise: @escaping (Task<T>.Result) -> ()) -> PHImageRequestID? {
        var mParam = param
        mParam.options.progressHandler = { progress, error, _, _ in
            DispatchQueue.main.async {
                if let error = error {
                    promise(.onError(error))
                } else {
                    promise(.inProgress(progress))
                }
            }
        }
        
        return T.request(asset, with: manager, and: mParam) { content, info in
            if let content = content {
                promise(.onCompletion(content))
            } else {
                if let error = info?[PHImageErrorKey] as? Error {
                    promise(.onError(error))
                } else {
                    promise(.onError(NSError(domain: "com.jerry", code: 0, userInfo: [NSLocalizedDescriptionKey: "An error occured when loading image"])))
               }
            }
        }
    }
    
    class Task<T> : ObservableObject where T: SupportedAsset {
        
        enum Result {
            
            case idle
            
            case inProgress(_ p: Double)
            
            case onCompletion(_ content: T.Content)
            
            case onError(_ e: Error)
            
            var isCompleted: Bool {
                switch self {
                case .onCompletion(_):
                    return true
                default:
                    return false
                }
            }
            
        }
        
        typealias OnLoad = (PHAsset, CGSize, Bool, (@escaping (Result) -> ())) -> PHImageRequestID?
        
        typealias OnUnload = (PHImageRequestID) -> ()
        
        @Published private(set) var resultSet = [CGSize: Result]()
        
        init(_ asset: PHAsset, onLoad: @escaping OnLoad, onUnload: @escaping OnUnload) {
            self.asset = asset
            self.onLoad = onLoad
            self.onUnload = onUnload
        }
        
        func result(for targetSize: CGSize?) -> Result {
            if let targetSize = targetSize {
                return resultSet[targetSize] ?? .idle
            } else {
                var maxWidth = CGFloat(0)
                var mTargetSize: CGSize?
                for key in resultSet.keys {
                    if key.width > maxWidth {
                        maxWidth = key.width
                        mTargetSize = key
                    }
                }
                if let targetSize = mTargetSize {
                    return resultSet[targetSize] ?? .idle
                } else {
                    return .idle
                }
            }
        }
        
        deinit {
            unload()
        }
        
        func load(size: CGSize, isThumbnail: Bool = true, isCache: Bool = true) {
            if result(for: size).isCompleted || requestID != nil {
                return
            }
            requestID = onLoad(asset, size, isThumbnail) { result in
                self.requestID = nil
                if !self.hasCompletedResult() || result.isCompleted {
                    if isCache {
                        self.cacheSize.insert(size)
                    }
                    self.resultSet[size] = result
                }
            }
        }
        
        func unload(clearUnCached: Bool = false) {
            if let reqID = requestID {
                onUnload(reqID)
            }
            if clearUnCached {
                resultSet
                    .keys
                    .filter { !self.cacheSize.contains($0) }
                    .forEach {
                        resultSet.removeValue(forKey: $0)
                    }
            }
        }
        
        private func hasCompletedResult() -> Bool {
            self.resultSet.reduce(into: false) { (ret, pair) in
                ret = ret || pair.value.isCompleted
            }
        }
        
        private var cacheSize = Set<CGSize>()
        
        private let asset: PHAsset
        
        private let onLoad: OnLoad
        
        private let onUnload: OnUnload
        
        private var requestID: PHImageRequestID?
        
    }
    
    private let manager = PHCachingImageManager()
    
    private var imageTasks = [PHAsset: Task<ImageType>]()
    
}

extension CGSize : Hashable {
    
    public func hash(into hasher: inout Hasher) {
        width.hash(into: &hasher)
        height.hash(into: &hasher)
    }
    
}

extension PHImageRequestOptions : ProgressOptions {}

extension PHVideoRequestOptions : ProgressOptions {}

extension PHLivePhotoRequestOptions : ProgressOptions {}

extension ImageType : SupportedAsset {
    
    static var preferredReqOpts: PHImageRequestOptions {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .exact
        options.isNetworkAccessAllowed = true
        return options
    }
    
    static func request(_ asset: PHAsset, with manager: PHImageManager, and param: RequestParam<PHImageRequestOptions>, resultHandler: @escaping (ImageType?, [AnyHashable : Any]?) -> Void) -> PHImageRequestID {
        manager.requestImage(for: asset, targetSize: param.targetSize, contentMode: param.contentMode, options: param.options, resultHandler: resultHandler)
    }
}

extension AVPlayerItem : SupportedAsset {
    
    static var preferredReqOpts: PHVideoRequestOptions {
        let options = PHVideoRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        return options
    }
    
    static func request(_ asset: PHAsset, with manager: PHImageManager, and param: RequestParam<PHVideoRequestOptions>, resultHandler: @escaping (AVPlayerItem?, [AnyHashable : Any]?) -> Void) -> PHImageRequestID {
        manager.requestPlayerItem(forVideo: asset, options: param.options, resultHandler: resultHandler)
    }
    
}

extension PHLivePhoto : SupportedAsset {
    
    static var preferredReqOpts: PHLivePhotoRequestOptions {
        let options = PHLivePhotoRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        return options
    }
    
    static func request(_ asset: PHAsset, with manager: PHImageManager, and param: RequestParam<PHLivePhotoRequestOptions>, resultHandler: @escaping (PHLivePhoto?, [AnyHashable : Any]?) -> Void) -> PHImageRequestID {
        manager.requestLivePhoto(for: asset, targetSize: param.targetSize, contentMode: param.contentMode, options: param.options, resultHandler: resultHandler)
    }
    
}
