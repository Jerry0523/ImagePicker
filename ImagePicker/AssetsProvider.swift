//
//  AssetsProvider.swift
//  ImagePickerMacOSDemo
//
//  Created by Jerry Wong on 2020/5/1.
//  Copyright © 2020 com.jerry. All rights reserved.
//

import Photos
import Combine

class AssetsProvider : ObservableObject  {
    
    @Published var status = Status.idle
    
    @Published var assets: [PHAsset]?
    
    @Published var collectionName: String?
    
    @Published var selectedAssets = Array<PHAsset>()
    
    @Published var focusedAssets: [PHAsset]?
    
    @Published var focusedIndex: Int?
    
    let fetchDiscriptors: [FetchDiscriptor]
    
    var selectionType = SelectionType.multi {
        didSet {
            if oldValue != selectionType {
                selectedAssets.removeAll()
            }
        }
    }
    
    func select(_ indexOfCollection: Int) {
        guard let assetsInArray = assetsInArray,
            indexOfCollection >= 0,
            indexOfCollection < assetsInArray.count,
            indexOfCollection != self.indexOfCollection
        else {
            return
        }
        
        self.status = .isLoading
        selectedAssets.removeAll()
        self.indexOfCollection = indexOfCollection
        
        assets = assetsInArray[indexOfCollection]
        collectionName = fetchDiscriptors[indexOfCollection].name
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.status = .idle
        }
    }
    
    func isSelected(for asset: PHAsset?) -> Bool {
        guard let asset = asset else {
            return false
        }
        return selectedAssets.contains(asset)
    }
    
    func toggleSelection(for asset: PHAsset?) {
        guard let asset = asset, selectionType != .none else {
            return
        }
        if selectedAssets.contains(asset) {
            selectedAssets  = selectedAssets.filter { $0 != asset }
        } else {
            if case .single = selectionType {
                selectedAssets.removeAll()
            }
            selectedAssets.append(asset)
        }
    }
    
    func rowCountIdentifier(for column: Int) -> [RowIdentifier] {
        guard let indexOfCollection = indexOfCollection,
            indexOfCollection >= 0,
            indexOfCollection < fetchDiscriptors.count
        else {
            return []
        }
        return (0..<rowCount(for: column)).map { .init(index: $0, id: fetchDiscriptors[indexOfCollection].id) }
    }
    
    func rowCount(for column: Int) -> Int {
        precondition(column > 0)
        guard let assets = assets else {
            return 0
        }
        return Int(ceilf((Float(assets.count) / Float(column))))
    }
    
    func asset(at row: Int, column: Int, columnCount: Int) -> PHAsset? {
        precondition(row >= 0 && column >= 0 && columnCount > 0)
        let idx = row * columnCount + column
        guard let assets = assets else {
            return nil
        }
        return idx < assets.count ? assets[idx] : nil
    }
    
    private init(_ fetchDiscriptors: [FetchDiscriptor] ) {
        self.fetchDiscriptors = fetchDiscriptors.map {
            let opt = $0.options
            if opt.sortDescriptors == nil {
                opt.sortDescriptors = AssetsProvider.sortDescriptors
            }
            return .init($0.name) { opt }
        }
        assetsInArray = fetchDiscriptors
            .map { PHAsset.fetchAssets(with: $0.options) }
            .map { fetchResult in (0..<fetchResult.count).map { fetchResult[$0] } }
        select(0)
    }
    
    static func publisherForNewInstance(with fetchDiscriptors: [FetchDiscriptor]) -> AnyPublisher<AssetsProvider, Never> {
        Future { promise in
            PHPhotoLibrary.requestAuthorization { status in
                switch status {
                case .authorized:
                    promise(.success(AssetsProvider(fetchDiscriptors)))
                default:
                    print(status)
                }
            }
        }.eraseToAnyPublisher()
    }
    
    struct RowIdentifier : Hashable {
        
        let index: Int
        
        let id: UUID
        
    }
    
    struct FetchDiscriptor {
        
        let name: String
        
        let options: PHFetchOptions
        
        let id = UUID()
        
        init(_ name: String, options: () -> PHFetchOptions) {
            self.name = name
            self.options = options()
        }
        
    }
    
    enum SelectionType {
        
        case none
        
        case single
        
        case multi
        
    }
    
    enum Status : Equatable {
        
        case isLoading
        
        case idle
        
        case error(_ msg: String)
        
    }
    
    private var assetsInArray: [[PHAsset]]?
    
    private var indexOfCollection: Int?
    
    private var pendingThresholdCount = 0
    
    private var pendingSubscription: AnyCancellable?
    
    private static let sortDescriptors: [NSSortDescriptor] = [NSSortDescriptor(key: "creationDate", ascending: true)]
    
}

