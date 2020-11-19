//
// Copyright © 2020 mycujoo. All rights reserved.
//

import Foundation

extension DataLayer {
    struct Stream: Decodable {
        let id: String
        let fullUrl: URL?
        let fairplay: FairplayStream?
        let dvrWindowSize: Int?
        let errorCode: String?
    }

    struct FairplayStream: Decodable {
        let fullUrl: URL
        let licenseUrl: URL
        let certificateUrl: URL
    }
}

extension DataLayer.FairplayStream {
    enum CodingKeys: String, CodingKey {
        case fullUrl = "full_url"
        case licenseUrl = "license_url"
        case certificateUrl = "certificate_url"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let fullUrl: URL = try container.decode(URL.self, forKey: .fullUrl)
        let licenseUrl: URL = try container.decode(URL.self, forKey: .licenseUrl)
        let certificateUrl: URL = try container.decode(URL.self, forKey: .certificateUrl)

        self.init(fullUrl: fullUrl, licenseUrl: licenseUrl, certificateUrl: certificateUrl)
    }
}

extension DataLayer.Stream {
    enum CodingKeys: String, CodingKey {
        case id
        case fullUrl = "full_url"
        case fairplay
        case dvrWindowSize = "dvr_window_size"
        case errorCode = "error"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id: String = try container.decode(String.self, forKey: .id)
        let fullUrl: URL? = try? container.decode(URL.self, forKey: .fullUrl)
//        let fairplay: DataLayer.FairplayStream? = try? container.decode(DataLayer.FairplayStream.self, forKey: .fairplay)
        let fairplay: DataLayer.FairplayStream? = nil // Temporarily fixed to nil until we are ready to release DRM.
        let dvrWindowSize: Int? = try? container.decode(Int.self, forKey: .dvrWindowSize)
        let errorCode: String? = try? container.decode(String.self, forKey: .errorCode)

        self.init(id: id, fullUrl: fullUrl, fairplay: fairplay, dvrWindowSize: dvrWindowSize, errorCode: errorCode)
    }
}

// - MARK: Mappers

extension DataLayer.Stream {
    var toDomain: MLSSDK.Stream {
        return MLSSDK.Stream(id: self.id, fullUrl: self.fullUrl, fairplay: self.fairplay?.toDomain, dvrWindowSize: self.dvrWindowSize, errorCode: self.errorCode)
    }
}

extension DataLayer.FairplayStream {
    var toDomain: MLSSDK.FairplayStream {
        return MLSSDK.FairplayStream(fullUrl: fullUrl, licenseUrl: licenseUrl, certificateUrl: certificateUrl)
    }
}
