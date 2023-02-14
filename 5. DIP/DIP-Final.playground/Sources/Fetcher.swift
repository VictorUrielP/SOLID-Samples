import Foundation

public protocol Fetcher {
    func fetchData<T: Decodable>(completion: @escaping (Result<T, Error>) -> Void)
}
