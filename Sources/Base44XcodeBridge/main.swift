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
    @Published var tokenText = ""
    @Published var projects: [Base44Project] = []
    @Published var statusMessage = "Ready"
    @Published var isLoading = false
    @Published var schemeText = ""

    private let projectManager: XcodeProjectManager
    private let keychain = KeychainHelper()

    // last opened project (.xcodeproj or .xcworkspace)
    private(set) var lastOpenedProjectURL: URL?

    init() {
        self.projectManager = XcodeProjectManager()
        // try load token from keychain
        if let saved = keychain.readToken() {
            self.tokenText = saved
        }
    }

    func saveTokenToKeychain() {
        keychain.saveToken(tokenText)
    }

    func loadProjects() {
        let baseURL = URL(string: baseURLText.trimmingCharacters(in: .whitespacesAndNewlines)) ?? URL(string: "https://api.base44.example")!
        let token = tokenText.trimmingCharacters(in: .whitespacesAndNewlines)

        isLoading = true
        statusMessage = "Loading projects..."

        let client = Base44Client(baseURL: baseURL, token: token)
        client.fetchProjects { [weak self] result in
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
                        self.lastOpenedProjectURL = openedProjectURL
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

    func buildLastOpenedProject() {
        guard let projectURL = lastOpenedProjectURL else {
            statusMessage = "No opened project to build"
            return
        }
        let scheme = schemeText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !scheme.isEmpty else {
            statusMessage = "Please enter the scheme name to build"
            return
        }

        isLoading = true
        statusMessage = "Building scheme \(scheme) on simulator..."

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let output = try self.projectManager.buildForSimulator(projectURL: projectURL, scheme: scheme)
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.statusMessage = "Build succeeded for \(scheme). Output:\n\(output.prefix(200))..."
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.statusMessage = "Build failed: \(error.localizedDescription)"
                }
            }
        }
    }
}

struct ContentView: View {
    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Base44 Xcode Bridge")
                .font(.system(size: 32, weight: .bold))

            Group {
                TextField("Base44 URL", text: $viewModel.baseURLText)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 600)

                HStack {
                    SecureField("Base44 token", text: $viewModel.tokenText)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 400)
                    Button("Save token") {
                        viewModel.saveTokenToKeychain()
                    }
                    .buttonStyle(.bordered)
                }
            }

            HStack(spacing: 12) {
                Button(action: viewModel.loadProjects) {
                    Label(viewModel.isLoading ? "Loading..." : "Load projects", systemImage: "arrow.down.circle")
                }
                .disabled(viewModel.isLoading)
                .buttonStyle(.borderedProminent)

                Spacer()

                Text(viewModel.statusMessage)
                    .foregroundStyle(.secondary)
                    .font(.system(size: 13))
            }

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
            .frame(maxHeight: 280)

            Divider()

            HStack(spacing: 12) {
                TextField("Scheme name to build", text: $viewModel.schemeText)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 300)

                Button("Build on Simulator") {
                    viewModel.buildLastOpenedProject()
                }
                .buttonStyle(.borderedProminent)

                Spacer()

                VStack(alignment: .leading) {
                    Text("Tip: vul eerst de scheme-naam in (zoals \"App\") nadat je het project hebt geopend in Xcode.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(20)
    }
}
