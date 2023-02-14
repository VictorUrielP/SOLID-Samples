import Foundation

public protocol DecodableResultAdapter {
    func mapModel<T: Decodable>(data: Data) -> Result<T, Error>
}
