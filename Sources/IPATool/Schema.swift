import Foundation

struct StoreDownloadRequest: Codable {
    let creditDisplay: String
    let guid: String
    let salableAdamId: String
    let externalVersionId: String?

    enum CodingKeys: String, CodingKey {
        case creditDisplay
        case guid
        case salableAdamId
        case externalVersionId
    }
}

struct StoreDownloadResponse: Codable {
    let pings: [AnyCodable]
    let cancelPurchaseBatch: Bool?
    let customerMessage: String?
    let failureType: String?
    let jingleDocType: String
    let jingleAction: String
    let status: Int
    let dsPersonId: String
    let creditDisplay: String
    let creditBalance: String
    let freeSongBalance: String
    let authorized: Bool
    let downloadQueueItemCount: Int
    let songList: [Song]
    let metrics: Metrics
    let subscriptionStatus: SubscriptionStatus
    
    enum CodingKeys: String, CodingKey {
        case pings
        case cancelPurchaseBatch = "cancel-purchase-batch"
        case customerMessage
        case failureType
        case jingleDocType
        case jingleAction
        case status
        case dsPersonId
        case creditDisplay
        case creditBalance
        case freeSongBalance
        case authorized
        case downloadQueueItemCount = "download-queue-item-count"
        case songList
        case metrics
        case subscriptionStatus
    }
}

// その他の構造体定義

struct Song: Codable {
    let songId: Int
    let URL: String
    let downloadKey: String
    let artworkURL: String
    let artworkUrls: ArtworkUrls
    let md5: String
    let chunks: Chunks
    let isStreamable: Bool
    let uncompressedSize: String
    let sinfs: [Sinf]
    let purchaseDate: String
    let downloadId: String
    let isInQueue: Bool
    let assetInfo: AssetInfo
    let metadata: Metadata
    
    enum CodingKeys: String, CodingKey {
        case songId
        case URL
        case downloadKey
        case artworkURL
        case artworkUrls = "artwork-urls"
        case md5
        case chunks
        case isStreamable
        case uncompressedSize
        case sinfs
        case purchaseDate
        case downloadId = "download-id"
        case isInQueue = "is-in-queue"
        case assetInfo = "asset-info"
        case metadata
    }
}

struct ArtworkUrls: Codable {
    let imageType: String
    let defaultImage: DefaultImage
    
    enum CodingKeys: String, CodingKey {
        case imageType = "image-type"
        case defaultImage = "default"
    }
}

struct DefaultImage: Codable {
    let url: String
}

struct Chunks: Codable {
    let chunkSize: Int
    let hashes: [String]
}

struct Sinf: Codable {
    let id: Int
    let sinf: String
}

struct AssetInfo: Codable {
    let fileSize: Int
    let flavor: String
    
    enum CodingKeys: String, CodingKey {
        case fileSize = "file-size"
        case flavor
    }
}

struct Metadata: Codable {
    let macUIRequiredDeviceCapabilities: DeviceCapabilities
    let uiRequiredDeviceCapabilities: DeviceCapabilities
    let artistId: Int
    let artistName: String
    let bundleDisplayName: String
    let bundleShortVersionString: String
    let bundleVersion: String
    let copyright: String
    let fileExtension: String
    let gameCenterEnabled: Bool
    let gameCenterEverEnabled: Bool
    let genre: String
    let genreId: Int
    let itemId: Int
    let itemName: String
    let kind: String
    let playlistName: String
    let productType: String
    let rating: Rating
    let releaseDate: String
    let requiresRosetta: Bool
    let runsOnAppleSilicon: Bool
    let runsOnIntel: Bool
    let s: Int
    let softwarePlatform: String
    let softwareIcon57x57URL: String
    let softwareIconNeedsShine: Bool
    let softwareSupportedDeviceIds: [Int]
    let softwareVersionBundleId: String
    let softwareVersionExternalIdentifier: Int
    let softwareVersionExternalIdentifiers: [Int]
    let subgenres: [Subgenre]
    let vendorId: Int
    let drmVersionNumber: Int
    let versionRestrictions: Int
}

struct DeviceCapabilities: Codable {
    let arm64: Bool
    let gamekit: Bool
    let metal: Bool
}

struct Rating: Codable {
    let content: String
    let label: String
    let rank: Int
    let system: String
}

struct Subgenre: Codable {
    let genre: String
    let genreId: Int
}

struct Metrics: Codable {
    let itemIds: [Int]
    let currency: String
    let exchangeRateToUSD: Double
}

struct SubscriptionStatus: Codable {
    let terms: [SubscriptionTerms]
    let account: AccountStatus
    let family: FamilyStatus
}

struct SubscriptionTerms: Codable {
    let type: String
    let latestTerms: Int
    let agreedToTerms: Int
    let source: String
}

struct AccountStatus: Codable {
    let isMinor: Bool
    let suspectUnderage: Bool
}

struct FamilyStatus: Codable {
    let hasFamily: Bool
}