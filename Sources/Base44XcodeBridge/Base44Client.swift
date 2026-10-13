import Foundation

struct Base44Project: Identifiable, Decodable {
    let id: String
    let name: String
    let downloadURL: String

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case downloadURL = "download_url"
    }
}

enum Base44ClientError: LocalizedError {
    case invalidURL
    case invalidResponse
    case emptyData
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The Base44 API URL is invalid."
        case .invalidResponse:
            return "The server response was invalid."
        case .emptyData:
            return "The server returned no data."
        case .decodingFailed:
            return "The response could not be decoded."
        }
    }
}

final class Base44Client {
    private let baseURL: URL
    private let token: String

    init(baseURL: URL, token: String) {
        self.baseURL = baseURL
        self.token = token
    }

    func fetchProjects(completion: @escaping (Result<[Base44Project], Error>) -> Void) {
        let endpoint = baseURL.appendingPathComponent("/api/apps")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error {
                completion(.failure(error))
                return
            }

            guard let data else {
                completion(.failure(Base44ClientError.emptyData))
                return
            }

            do {
                let projects = try JSONDecoder().decode([Base44Project].self, from: data)
                completion(.success(projects))
            } catch {
                completion(.failure(Base44ClientError.decodingFailed))
            }
        }.resume()
    }

    func downloadProject(project: Base44Project, completion: @escaping (Result<URL, Error>) -> Void) {
        guard let url = URL(string: project.downloadURL) else {
            completion(.failure(Base44ClientError.invalidURL))
            return
        }

        let task = URLSession.shared.downloadTask(with: url) { tempURL, response, error in
            if let error {
                completion(.failure(error))
                return
            }

            guard let tempURL else {
                completion(.failure(Base44ClientError.emptyData))
                return
            }

            completion(.success(tempURL))
        }

        task.resume()
    }
}
