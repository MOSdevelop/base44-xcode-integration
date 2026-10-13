import AppKit
import SwiftUI

@main
struct Base44XcodeBridgeApp: App {
    @StateObject private var viewModel = AppViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
                .frame(minWidth: 900, minHeight: 620)
        }
    }
}

final class AppViewModel: ObservableObject {
    @Published var baseURLText = "https://api.base44.example"
    @Published var tokenText = "YOUR_BASE44_TOKEN"
    @Published var projects: [Base44Project] = []
    @Published var statusMessage = "Ready"
    @Published var isLoading = false

    private let client: Base44Client
    private let projectManager: XcodeProjectManager

    init() {
        let defaultURL = URL(string: "https://api.base44.example")!
        self.client = Base44Client(baseURL: defaultURL, token: "YOUR_BASE44_TOKEN")
        self.projectManager = XcodeProjectManager()
    }

    func loadProjects() {
        let baseURL = URL(string: baseURLText.trimmingCharacters(in: .whitespacesAndNewlines)) ?? URL(string: "https://api.base44.example")!
        let token = tokenText.trimmingCharacters(in: .whitespacesAndNewlines)

        isLoading = true
        statusMessage = "Loading projects..."

        let updatedClient = Base44Client(baseURL: baseURL, token: token)
        updatedClient.fetchProjects { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isLoading = false

                switch result {
                case .success(let projects):
                    self.projects = projects
                    self.statusMessage = projects.isEmpty ? "No projects found" : "Loaded \(projects.count) project(s)"
                case .failure(let error):
                    self.projects = []
                    self.statusMessage = "Error: \(error.localizedDescription)"
                }
            }
        }
    }

    func openProject(_ project: Base44Project) {
        isLoading = true
        statusMessage = "Downloading project..."

        let baseURL = URL(string: baseURLText.trimmingCharacters(in: .whitespacesAndNewlines)) ?? URL(string: "https://api.base44.example")!
        let token = tokenText.trimmingCharacters(in: .whitespacesAndNewlines)
        let client = Base44Client(baseURL: baseURL, token: token)

        client.downloadProject(project: project) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isLoading = false

                switch result {
                case .success(let archiveURL):
                    do {
                        let openedProjectURL = try self.projectManager.extractProjectArchive(at: archiveURL)
                        let opened = self.projectManager.openInXcode(projectURL: openedProjectURL)
                        self.statusMessage = opened
                            ? "Opened \(project.name) in Xcode"
                            : "Downloaded, but Xcode could not open project automatically"
                    } catch {
                        self.statusMessage = "Extraction error: \(error.localizedDescription)"
                    }
                case .failure(let error):
                    self.statusMessage = "Download error: \(error.localizedDescription)"
                }
            }
        }
    }
}

struct ContentView: View {
    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Base44 Xcode Bridge")
                .font(.system(size: 34, weight: .bold))

            Group {
                TextField("Base44 URL", text: $viewModel.baseURLText)
                    .textFieldStyle(.roundedBorder)
                SecureField("Base44 token", text: $viewModel.tokenText)
                    .textFieldStyle(.roundedBorder)
            }

            HStack {
                Button(action: viewModel.loadProjects) {
                    Label(viewModel.isLoading ? "Loading..." : "Load projects", systemImage: "arrow.down.circle")
                }
                .disabled(viewModel.isLoading)
                .buttonStyle(.borderedProminent)
            }

            Text(viewModel.statusMessage)
                .foregroundStyle(.secondary)
                .font(.system(size: 14))

            List(viewModel.projects) { project in
                HStack {
                    VStack(alignment: .leading) {
                        Text(project.name)
                            .font(.headline)
                        Text(project.id)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Open in Xcode") {
                        viewModel.openProject(project)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .frame(maxHeight: .infinity)
        }
        .padding(24)
    }
}
