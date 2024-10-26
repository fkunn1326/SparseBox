import Foundation

// MARK: - Response Model
struct ItunesLookupResponse: Codable {
    let resultCount: Int
    let results: [AppResult]
}

struct AppResult: Codable {
    let bundleId: String?
    let trackId: Int?
    let version: String?
    // Add other fields as needed
}

// MARK: - Error
enum ITunesClientError: Error {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case invalidResponse
    case appVersionNotFound
}



// MARK: - Store Table
struct ITunesClient {
    static let storeTable: [String: String] = ["AE":"143481-2,32","AG":"143540-2,32","AI":"143538-2,32","AL":"143575-2,32","AM":"143524-2,32","AO":"143564-2,32","AR":"143505-28,32","AT":"143445-4,32","AU":"143460-27,32","AZ":"143568-2,32","BB":"143541-2,32","BE":"143446-2,32","BF":"143578-2,32","BG":"143526-2,32","BH":"143559-2,32","BJ":"143576-2,32","BM":"143542-2,32","BN":"143560-2,32","BO":"143556-28,32","BR":"143503-15,32","BS":"143539-2,32","BT":"143577-2,32","BW":"143525-2,32","BY":"143565-2,32","BZ":"143555-2,32","CA":"143455-6,32","CG":"143582-2,32","CH":"143459-57,32","CL":"143483-28,32","CN":"143465-19,32","CO":"143501-28,32","CR":"143495-28,32","CV":"143580-2,32","CY":"143557-2,32","CZ":"143489-2,32","DE":"143443-4,32","DK":"143458-2,32","DM":"143545-2,32","DO":"143508-28,32","DZ":"143563-2,32","EC":"143509-28,32","EE":"143518-2,32","EG":"143516-2,32","ES":"143454-8,32","FI":"143447-2,32","FJ":"143583-2,32","FM":"143591-2,32","FR":"143442-3,32","GB":"143444-2,32","GD":"143546-2,32","GH":"143573-2,32","GM":"143584-2,32","GR":"143448-2,32","GT":"143504-28,32","GW":"143585-2,32","GY":"143553-2,32","HK":"143463-45,32","HN":"143510-28,32","HR":"143494-2,32","HU":"143482-2,32","ID":"143476-2,32","IE":"143449-2,32","IL":"143491-2,32","IN":"143467-2,32","IS":"143558-2,32","IT":"143450-7,32","JM":"143511-2,32","JO":"143528-2,32","JP":"143462-9,32","KE":"143529-2,32","KG":"143586-2,32","KH":"143579-2,32","KN":"143548-2,32","KR":"143466-13,32","KW":"143493-2,32","KY":"143544-2,32","KZ":"143517-2,32","LA":"143587-2,32","LB":"143497-2,32","LC":"143549-2,32","LK":"143486-2,32","LR":"143588-2,32","LT":"143520-2,32","LU":"143451-2,32","LV":"143519-2,32","MD":"143523-2,32","MG":"143531-2,32","MK":"143530-2,32","ML":"143532-2,32","MN":"143592-2,32","MO":"143515-45,32","MR":"143590-2,32","MS":"143547-2,32","MT":"143521-2,32","MU":"143533-2,32","MW":"143589-2,32","MX":"143468-28,32","MY":"143473-2,32","MZ":"143593-2,32","NA":"143594-2,32","NE":"143534-2,32","NG":"143561-2,32","NI":"143512-28,32","NL":"143452-10,32","NO":"143457-2,32","NP":"143484-2,32","NZ":"143461-27,32","OM":"143562-2,32","PA":"143485-28,32","PE":"143507-28,32","PG":"143597-2,32","PH":"143474-2,32","PK":"143477-2,32","PL":"143478-2,32","PT":"143453-24,32","PW":"143595-2,32","PY":"143513-28,32","QA":"143498-2,32","RO":"143487-2,32","RU":"143469-16,32","SA":"143479-2,32","SB":"143601-2,32","SC":"143599-2,32","SE":"143456-17,32","SG":"143464-19,32","SI":"143499-2,32","SK":"143496-2,32","SL":"143600-2,32","SN":"143535-2,32","SR":"143554-2,32","ST":"143598-2,32","SV":"143506-28,32","SZ":"143602-2,32","TC":"143552-2,32","TD":"143581-2,32","TH":"143475-2,32","TJ":"143603-2,32","TM":"143604-2,32","TN":"143536-2,32","TR":"143480-2,32","TT":"143551-2,32","TW":"143470-18,32","TZ":"143572-2,32","UA":"143492-2,32","UG":"143537-2,32","US":"143441-1,32","UY":"143514-2,32","UZ":"143566-2,32","VC":"143550-2,32","VE":"143502-28,32","VG":"143543-2,32","VN":"143471-2,32","YE":"143571-2,32","ZA":"143472-2,32","ZW":"143605-2,32"]
    
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    // MARK: - Lookup Method
    func lookup(bundleId: String? = nil,
               appId: String? = nil,
               term: String? = nil,
               country: String = "US",
               limit: Int = 1,
               media: String = "software") async throws -> ItunesLookupResponse {
        
        var components = URLComponents(string: "https://itunes.apple.com/lookup")
        var queryItems: [URLQueryItem] = []
        
        if let bundleId = bundleId {
            queryItems.append(URLQueryItem(name: "bundleId", value: bundleId))
        }
        if let appId = appId {
            queryItems.append(URLQueryItem(name: "id", value: appId))
        }
        if let term = term {
            queryItems.append(URLQueryItem(name: "term", value: term))
        }
        
        queryItems.append(contentsOf: [
            URLQueryItem(name: "country", value: country),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "media", value: media)
        ])
        
        components?.queryItems = queryItems
        
        guard let url = components?.url else {
            throw ITunesClientError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        do {
            let (data, _) = try await session.data(for: request)
            let response = try JSONDecoder().decode(ItunesLookupResponse.self, from: data)
            return response
        } catch let error as DecodingError {
            throw ITunesClientError.decodingError(error)
        } catch {
            throw ITunesClientError.networkError(error)
        }
    }
    
    // MARK: - Get App Version ID
    func getAppVerId(appId: String, country: String) async throws -> String {
        let storeFront: String
        if !country.contains(",") {
            guard let store = Self.storeTable[country.uppercased()] else {
                throw ITunesClientError.invalidResponse
            }
            storeFront = store
        } else {
            storeFront = country
        }
        
        let url = URL(string: "https://apps.apple.com/app/id\(appId)")!
        var request = URLRequest(url: url)
        request.setValue(storeFront, forHTTPHeaderField: "X-Apple-Store-Front")
        
        do {
            let (data, _) = try await session.data(for: request)
            guard let htmlString = String(data: data, encoding: .utf8) else {
                throw ITunesClientError.invalidResponse
            }
            
            // Try both regex patterns
            if let appParam = try? extractBuyParams(from: htmlString, pattern: #""buyParams":"(.*?)""#) {
                return try parseAppVersion(from: appParam)
            } else if let appParam = try? extractBuyParams(from: htmlString, pattern: #"buy-params="(.*?)""#) {
                let decodedParam = appParam.replacingOccurrences(of: "&amp;", with: "&")
                return try parseAppVersion(from: decodedParam)
            }
            
            throw ITunesClientError.appVersionNotFound
        } catch {
            throw ITunesClientError.networkError(error)
        }
    }
    
    // MARK: - Helper Methods
    private func extractBuyParams(from html: String, pattern: String) throws -> String {
        let regex = try NSRegularExpression(pattern: pattern)
        let range = NSRange(html.startIndex..., in: html)
        
        guard let match = regex.firstMatch(in: html, range: range),
              let paramRange = Range(match.range(at: 1), in: html) else {
            throw ITunesClientError.appVersionNotFound
        }
        
        return String(html[paramRange])
    }
    
    private func parseAppVersion(from param: String) throws -> String {
        let paramPairs = param
            .removingPercentEncoding?
            .components(separatedBy: "&")
            .compactMap { pair -> (String, String)? in
                let components = pair.components(separatedBy: "=")
                guard components.count == 2 else { return nil }
                return (components[0], components[1])
            }
        
        guard let appVer = Dictionary(paramPairs!, uniquingKeysWith: { first, _ in first })["appExtVrsId"] else {
            throw ITunesClientError.appVersionNotFound
        }
        
        return appVer
    }
}