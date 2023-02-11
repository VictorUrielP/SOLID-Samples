import Foundation

public final class DogsAdapter {
    private let decoder: JSONDecoder
    
    private struct DogDecodingError: Error { }
    
    init(decoder: JSONDecoder) {
        self.decoder = decoder
    }
    
    public func mapToResult(with data: Data) -> Result<[Dog], Error> {
        guard let dogs = try? JSONDecoder().decode([Dog].self, from: data) else {
            return .failure(DogDecodingError())
        }
        return .success(dogs)
    }
}
