//
//  HTAHistoryView.swift
//  Employ210
//
//  Lists past HTAs via Lambda phase=list_htas.
//  Segmented: "My HTAs" (folder-scoped) vs "All HTAs".
//  Auto-refreshes every 30s. Pull-to-refresh supported.
//

import SwiftUI

private struct HTAListItem: Decodable, Identifiable {
    let session_id: String?
    let job_title: String?
    let folder: String?
    let generated_date: String?
    var id: String { session_id ?? "\(job_title ?? "")-\(generated_date ?? "")" }
}

private struct HTAListResponse: Decodable {
    let htas: [HTAListItem]?
}

struct HTAHistoryView: View {
    @AppStorage("selectedFolder") private var selectedFolder = ""
    @Environment(\.dismiss) private var dismiss

    @State private var scope = 0
    @State private var items: [HTAListItem] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let autoRefresh = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.05, green: 0.10, blue: 0.15)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    Picker("Scope", selection: $scope) {
                        Text("My HTAs").tag(0)
                        Text("All HTAs").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)

                    if isLoading && items.isEmpty {
                        Spacer()
                        ProgressView().tint(.white).scaleEffect(1.2)
                        Spacer()
                    } else if let err = errorMessage, items.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 40))
                                .foregroundStyle(.orange.opacity(0.7))
                            Text(err)
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.6))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        Spacer()
                    } else if items.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "doc.text.magnifyingglass")
                                .font(.system(size: 44))
                                .foregroundStyle(.white.opacity(0.25))
                            Text("No HTAs found")
                                .foregroundStyle(.white.opacity(0.5))
                        }
                        Spacer()
                    } else {
                        List {
                            ForEach(items) { item in
                                HTAHistoryRow(item: item)
                                    .listRowBackground(Color.white.opacity(0.05))
                                    .listRowSeparatorTint(Color.white.opacity(0.1))
                                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            }
                        }
                        .listStyle(.plain)
                        .refreshable { await fetch() }
                    }
                }
            }
            .navigationTitle("HTA History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.55))
                    }
                }
            }
        }
        .task { await fetch() }
        .onChange(of: scope) { _ in Task { await fetch() } }
        .onReceive(autoRefresh) { _ in Task { await fetch() } }
    }

    private func fetch() async {
        isLoading = true
        errorMessage = nil
        let folder = scope == 0 ? (selectedFolder.isEmpty ? "all" : selectedFolder) : "all"
        do { items = try await fetchHTAs(folder: folder) }
        catch { errorMessage = error.localizedDescription }
        isLoading = false
    }

    private func fetchHTAs(folder: String) async throws -> [HTAListItem] {
        guard let url = URL(string: AWSConfig.lambdaURL) else { throw URLError(.badURL) }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 15
        req.httpBody = try JSONEncoder().encode(["phase": "list_htas", "folder": folder])
        let (data, _) = try await URLSession.shared.data(for: req)
        return (try JSONDecoder().decode(HTAListResponse.self, from: data)).htas ?? []
    }
}

private struct HTAHistoryRow: View {
    let item: HTAListItem

    var formattedDate: String {
        guard let raw = item.generated_date else { return "Unknown date" }
        if let date = ISO8601DateFormatter().date(from: raw) {
            let df = DateFormatter()
            df.dateStyle = .medium
            df.timeStyle = .short
            return df.string(from: date)
        }
        return raw
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.teal.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.teal)
            }
            VStack(alignment: .leading, spacing: 5) {
                Text(item.job_title ?? "Untitled HTA")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                HStack(spacing: 8) {
                    if let folder = item.folder, !folder.isEmpty {
                        Label(folder, systemImage: "folder.fill")
                            .font(.caption)
                            .foregroundStyle(.teal.opacity(0.8))
                    }
                    Text(formattedDate)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.45))
                }
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    HTAHistoryView()
}
