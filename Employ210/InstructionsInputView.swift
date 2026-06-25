//
//  InstructionsInputView.swift
//  Employ210
//
//  Sheet for adding typed instructions or importing a PDF (on-device text extraction via PDFKit).
//  The combined text is written back to the HTAViewModel's customInstructions binding.
//

import SwiftUI
import PDFKit
import UniformTypeIdentifiers

struct InstructionsInputView: View {
    @Binding var customInstructions: String
    @Environment(\.dismiss) private var dismiss

    @State private var typedText: String
    @State private var pdfExtractedText = ""
    @State private var pdfFileName = ""
    @State private var showFileImporter = false
    @State private var pdfError: String? = nil
    @State private var isExtracting = false

    init(customInstructions: Binding<String>) {
        _customInstructions = customInstructions
        // Pre-populate with whatever is already set so the user can edit
        _typedText = State(initialValue: customInstructions.wrappedValue)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.05, green: 0.10, blue: 0.15)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {

                        Text("Ground the HTA with your SOPs, policies, or safety notes. The more context you provide, the more accurate and compliant the output.")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.6))
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 24)
                            .padding(.top, 8)

                        // MARK: Typed instructions
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Typed Instructions")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.white.opacity(0.6))

                            ZStack(alignment: .topLeading) {
                                TextEditor(text: $typedText)
                                    .foregroundColor(.white)
                                    .scrollContentBackground(.hidden)
                                    .padding(12)
                                    .frame(minHeight: 160)

                                if typedText.isEmpty {
                                    Text("Paste SOP steps, safety rules, compliance notes…")
                                        .foregroundStyle(.white.opacity(0.35))
                                        .padding(.top, 20)
                                        .padding(.leading, 16)
                                        .allowsHitTesting(false)
                                }
                            }
                            .background(Color.white.opacity(0.07))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, 24)

                        // MARK: PDF import
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Or Import a PDF")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.white.opacity(0.6))

                            Button {
                                showFileImporter = true
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: pdfExtractedText.isEmpty ? "doc.badge.plus" : "doc.fill")
                                        .font(.system(size: 22))
                                        .foregroundStyle(pdfExtractedText.isEmpty ? .white.opacity(0.5) : .teal)
                                        .frame(width: 32)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(pdfFileName.isEmpty ? "Choose PDF…" : pdfFileName)
                                            .font(.subheadline)
                                            .foregroundColor(pdfExtractedText.isEmpty ? .white.opacity(0.6) : .white)
                                            .lineLimit(1)

                                        if !pdfExtractedText.isEmpty {
                                            Text("\(pdfExtractedText.count) characters extracted")
                                                .font(.caption)
                                                .foregroundStyle(.teal.opacity(0.8))
                                        }
                                    }

                                    Spacer()

                                    if isExtracting {
                                        ProgressView().tint(.white)
                                    }
                                }
                                .padding(16)
                                .background(Color.white.opacity(0.07))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            pdfExtractedText.isEmpty ? Color.white.opacity(0.1) : Color.teal.opacity(0.4),
                                            lineWidth: 1
                                        )
                                )
                            }

                            // Error banner (scanned / unreadable PDF)
                            if let error = pdfError {
                                HStack(alignment: .top, spacing: 10) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundStyle(.orange)
                                    Text(error)
                                        .font(.caption)
                                        .foregroundStyle(.orange.opacity(0.9))
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(12)
                                .background(Color.orange.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }

                            // Extracted text preview
                            if !pdfExtractedText.isEmpty {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text("Extracted Preview")
                                            .font(.caption)
                                            .foregroundStyle(.white.opacity(0.5))
                                        Spacer()
                                        Button {
                                            pdfExtractedText = ""
                                            pdfFileName = ""
                                            pdfError = nil
                                        } label: {
                                            Text("Clear PDF")
                                                .font(.caption)
                                                .foregroundStyle(.red.opacity(0.7))
                                        }
                                    }

                                    Text(String(pdfExtractedText.prefix(500)) + (pdfExtractedText.count > 500 ? "…" : ""))
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundStyle(.white.opacity(0.5))
                                        .padding(10)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color.white.opacity(0.05))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                        .padding(.horizontal, 24)

                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle("Add Instructions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white.opacity(0.7))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") { applyInstructions() }
                        .foregroundColor(.teal)
                        .fontWeight(.semibold)
                }
            }
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: [.pdf]
            ) { result in
                handleFileImport(result: result)
            }
        }
    }

    // MARK: - Actions

    private func applyInstructions() {
        var combined = typedText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !pdfExtractedText.isEmpty {
            if !combined.isEmpty { combined += "\n\n" }
            combined += "--- From \(pdfFileName) ---\n" + pdfExtractedText
        }
        customInstructions = combined
        dismiss()
    }

    private func handleFileImport(result: Result<URL, Error>) {
        pdfError = nil
        switch result {
        case .failure:
            pdfError = "Could not open the file. Please try again."
        case .success(let url):
            isExtracting = true
            pdfFileName = url.lastPathComponent

            guard url.startAccessingSecurityScopedResource() else {
                pdfError = "Permission denied to read this file."
                isExtracting = false
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }

            let extracted = extractText(from: url)
            isExtracting = false

            if extracted.isEmpty {
                pdfError = "No selectable text found in this PDF. It may be a scanned image. Please use a PDF with selectable/copyable text, or type the instructions manually."
            } else {
                pdfExtractedText = extracted
            }
        }
    }

    private func extractText(from url: URL) -> String {
        guard let document = PDFDocument(url: url) else { return "" }
        var text = ""
        for i in 0..<document.pageCount {
            if let page = document.page(at: i), let pageText = page.string {
                text += pageText + "\n"
            }
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Preview

#Preview("Empty") {
    InstructionsInputView(customInstructions: .constant(""))
}

#Preview("Pre-filled") {
    InstructionsInputView(customInstructions: .constant("Always use PPE. Check equipment before starting."))
}
