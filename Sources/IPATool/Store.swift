import Foundation
import CryptoKit

// MARK: - Constants
let CONFIGURATOR_UA = "Configurator/2.0 (Macintosh; OS X 10.12.6; 16G29) AppleWebKit/2603.3.8 iOS/14.2 hwp/t8020"

// MARK: - Errors
enum StoreError: Error {
    case invalidAuthSession
    case purchaseError(request: String, message: String, type: String?)
    case networkError(Error)
    case decodingError(Error)
    case invalidResponse
}

// MARK: - Models
struct StoreAuthenticateRequest: Codable {
    let appleId: String
    let password: String
    let attempt: String
    let createSession: String
    let guid: String
    let rmp: String
    let why: String
}

struct StoreAuthenticateResponse: Codable {
    let mAllowed: Bool
    let customerMessage: String?
    let failureType: String?
    let downloadQueueInfo: DownloadQueueInfo
    let accountInfo: AccountInfo
    let passwordToken: String
    
    struct DownloadQueueInfo: Codable {
        let dsid: Int
    }
    
    struct AccountInfo: Codable {
        let address: Address
    }
    
    struct Address: Codable {
        let firstName: String
        let lastName: String
    }
}

// MARK: - Auth Client
class StoreClientAuth {
    private var appleId: String?
    private var password: String?
    var guid: String?
    var accountName: String?
    var authHeaders: [String: String]?
    var authCookies: String?
    
    init(appleId: String? = nil, password: String? = nil) {
        self.appleId = appleId
        self.password = password
    }
    
    private func generateGuid(for appleId: String) -> String {
        let defaultGuid = "000C2941396B"
        let guidDefaultPrefix = 2
        let guidSeed = "CAFEBABE"
        let guidPos = 10
        
        let seedString = "\(guidSeed)\(appleId)\(guidSeed)"
        let hash = Insecure.SHA1.hash(data: seedString.data(using: .utf8)!)
        let hashString = hash.map { String(format: "%02x", $0) }.joined()
        
        let defaultPart = String(defaultGuid.prefix(guidDefaultPrefix))
        let hashPart = String(hashString[hashString.index(hashString.startIndex, offsetBy: guidPos)..<hashString.index(hashString.startIndex, offsetBy: guidPos + (defaultGuid.count - guidDefaultPrefix))])
        
        return (defaultPart + hashPart).uppercased()
    }
    
    func login(using session: URLSession) async throws {
        guard let appleId = appleId else { throw StoreError.invalidAuthSession }
        
        if guid == nil {
            guid = generateGuid(for: appleId)
        }
        
        let request = StoreAuthenticateRequest(
            appleId: appleId,
            password: password ?? "",
            attempt: "4",
            createSession: "true",
            guid: guid ?? "",
            rmp: "0",
            why: "signIn"
        )
        
        var urlComponents = URLComponents(string: "https://p46-buy.itunes.apple.com/WebObjects/MZFinance.woa/wa/authenticate")
        urlComponents?.queryItems = [URLQueryItem(name: "guid", value: guid)]
        
        guard let url = urlComponents?.url else {
            throw StoreError.invalidAuthSession
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("*/*", forHTTPHeaderField: "Accept")
        urlRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(CONFIGURATOR_UA, forHTTPHeaderField: "User-Agent")
        
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml
        urlRequest.httpBody = try encoder.encode(request)
        
        let (data, response) = try await session.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw StoreError.invalidResponse
        }
        
        if httpResponse.statusCode == 302,
           let location = httpResponse.value(forHTTPHeaderField: "Location") {
            // Handle redirect
            var redirectRequest = URLRequest(url: URL(string: location)!)
            redirectRequest.httpMethod = "POST"
            redirectRequest.httpBody = urlRequest.httpBody
            redirectRequest.allHTTPHeaderFields = urlRequest.allHTTPHeaderFields
            
            let (redirectData, _) = try await session.data(for: redirectRequest)
            try processAuthResponse(redirectData, httpResponse: httpResponse)
        } else {
            try processAuthResponse(data, httpResponse: httpResponse)
        }
    }
    
    private func processAuthResponse(_ data: Data, httpResponse: HTTPURLResponse) throws {
        let decoder = PropertyListDecoder()
        let response = try decoder.decode(StoreAuthenticateResponse.self, from: data)
        
        guard response.mAllowed else {
            throw StoreError.purchaseError(
                request: "authenticate",
                message: response.customerMessage ?? "Authentication failed",
                type: response.failureType
            )
        }
        
        authHeaders = [
            "X-Dsid": String(response.downloadQueueInfo.dsid),
            "iCloud-Dsid": String(response.downloadQueueInfo.dsid),
            "X-Apple-Store-Front": httpResponse.value(forHTTPHeaderField: "x-set-apple-store-front") ?? "",
            "X-Token": response.passwordToken
        ]
        
        accountName = "\(response.accountInfo.address.firstName) \(response.accountInfo.address.lastName)"
    }
    
    func save() throws -> String {
        let encoder = JSONEncoder()
    
        struct AccountData: Codable {
            let appleId: String
            let guid: String
            let accountName: String
            let authHeaders: [String: String]
            let authCookies: String
        }

        let data = try encoder.encode(AccountData(
            appleId: appleId!,
            guid: guid!,
            accountName: accountName!,
            authHeaders: authHeaders!,
            authCookies: authCookies!
        ))
        return String(data: data, encoding: .utf8) ?? ""
    }
    
    static func load(_ jsonString: String) throws -> StoreClientAuth {
        let decoder = JSONDecoder()
        let data = jsonString.data(using: .utf8)!
        let dict = try decoder.decode([String: String?].self, from: data)
        
        let auth = StoreClientAuth()
        auth.appleId = dict["appleId"] ?? nil
        auth.guid = dict["guid"] ?? nil
        auth.accountName = dict["accountName"] ?? nil
        if let headersString = dict["authHeaders"]!,
           let headersData = headersString.data(using: .utf8) {
            auth.authHeaders = try JSONDecoder().decode([String: String].self, from: headersData)
        }
        auth.authCookies = dict["authCookies"] ?? nil
        
        return auth
    }
}

// MARK: - Store Client
class StoreClient {
    private let session: URLSession
    private var iTunesProvider: ((String) -> [String: Any])?
    private var authInfo: StoreClientAuth?
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func authenticateLoadSession(_ sessionContent: String) throws {
        authInfo = try StoreClientAuth.load(sessionContent)
        guard let authInfo = authInfo,
              let _headers = authInfo.authHeaders,
              let _cookies = authInfo.authCookies else {
            throw StoreError.invalidAuthSession
        }
        
        // Set headers and cookies for session
        // Note: URLSession cookie handling would need to be implemented
    }
    
    func authenticateSaveSession() throws -> String {
        guard let authInfo = authInfo else {
            throw StoreError.invalidAuthSession
        }
        return try authInfo.save()
    }
    
    func authenticate(appleId: String, password: String) async throws {
        if authInfo == nil {
            authInfo = StoreClientAuth(appleId: appleId, password: password)
        }
        try await authInfo?.login(using: session)
    }
    
    // volumeStoreDownloadProduct implementation
    func volumeStoreDownloadProduct(appId: String, appVerId: String = "") async throws -> StoreDownloadResponse {
        guard let authInfo = authInfo else {
            throw StoreError.invalidAuthSession
        }
        
        let request = StoreDownloadRequest(
            creditDisplay: "",
            guid: authInfo.guid ?? "",
            salableAdamId: appId,
            externalVersionId: appVerId
        )
        
        var urlComponents = URLComponents(string: "https://p25-buy.itunes.apple.com/WebObjects/MZFinance.woa/wa/volumeStoreDownloadProduct")
        urlComponents?.queryItems = [URLQueryItem(name: "guid", value: authInfo.guid)]
        
        guard let url = urlComponents?.url else {
            throw StoreError.invalidResponse
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(CONFIGURATOR_UA, forHTTPHeaderField: "User-Agent")
        
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml
        urlRequest.httpBody = try encoder.encode(request)
        
        let (data, _) = try await session.data(for: urlRequest)
        let decoder = PropertyListDecoder()
        let response = try decoder.decode(StoreDownloadResponse.self, from: data)
        
        if response.cancelPurchaseBatch! {
            throw StoreError.purchaseError(
                request: "volumeStoreDownloadProduct",
                message: response.customerMessage ?? "Download failed",
                type: "\(response.failureType ?? "")-\(response.metrics)"
            )
        }
        
        return response
    }
}

// Add other necessary request/response models and implementations...