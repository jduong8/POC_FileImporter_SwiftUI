//
//  ContentView.swift
//  POC_FileImporter
//
//  Created by Jonathan Duong on 14/04/2024.
//

import SwiftUI
import PDFKit

struct ContentView: View {
    @State private var pdfDocuments = [PDFDocumentInfo]()
    @State private var showFileImporter = false
    @State private var showRenameAlert = false
    @State private var pendingPDFDocument: PDFDocument?
    @State private var pendingPDFName: String = ""
    @State private var originalPDFName: String = ""

    init() {
        loadSavedPDFs()
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(pdfDocuments, id: \.url) { pdfInfo in
                    NavigationLink(destination: PDFViewerView(document: PDFDocument(url: pdfInfo.url))) {
                        Text(pdfInfo.name)
                    }
                }
                .onDelete(perform: deletePDF)
            }
            .navigationTitle("PDF Files")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showFileImporter = true
                    }) {
                        Label("Add PDF", systemImage: "plus")
                    }
                }
            }
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: [.pdf],
                allowsMultipleSelection: false
            ) { result in
                handleFileImportResult(result)
            }
            .alert("Add PDF File", isPresented: $showRenameAlert) {
                TextField("Enter PDF name", text: $pendingPDFName)
                Button("Use Default Name") {
                    addPDFToDocumentsList(using: originalPDFName)
                }
                Button("Confirm Custom Name") {
                    addPDFToDocumentsList(using: pendingPDFName)
                }
            } message: {
                Text("Choose the PDF file name:")
            }
        }
    }

    func handleFileImportResult(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first, url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }
            
            if let pdfDocument = PDFDocument(url: url) {
                pendingPDFDocument = pdfDocument
                pendingPDFName = url.deletingPathExtension().lastPathComponent
                originalPDFName = url.deletingPathExtension().lastPathComponent
                showRenameAlert = true
            }
        case .failure(let error):
            print("Cannot load PDF: \(error)")
        }
    }
    /// Mise à jour de la méthode de sauvegarde des références de fichiers
    func updateUserDefaults(with pdfInfo: PDFDocumentInfo) {
        var savedPDFs = UserDefaults.standard.array(forKey: "savedPDFs") as? [String] ?? []
        savedPDFs.append(pdfInfo.url.path)
        UserDefaults.standard.set(savedPDFs, forKey: "savedPDFs")
        print("Updated UserDefaults with: \(savedPDFs)")
    }


    func addPDFToDocumentsList(using name: String) {
        if let pdfDocument = pendingPDFDocument {
            let pdfInfo = PDFDocumentInfo(name: name, url: storePDFFileLocally(pdfDocument: pdfDocument))
            pdfDocuments.append(pdfInfo)
            updateUserDefaults(with: pdfInfo) // Mettre à jour UserDefaults après l'ajout d'un nouveau PDF
            resetPendingData()
        }
    }

    func storePDFFileLocally(pdfDocument: PDFDocument) -> URL {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileName = "\(UUID().uuidString).pdf"
        let destinationPath = documentsDirectory.appendingPathComponent(fileName)
        
        if pdfDocument.write(to: destinationPath) {
            print("PDF saved successfully at \(destinationPath)")
        } else {
            print("Failed to save PDF")
        }
        return destinationPath
    }

    func loadSavedPDFs() {
        let fileManager = FileManager.default
        let savedPDFs = UserDefaults.standard.array(forKey: "savedPDFs") as? [String] ?? []
        print("Loading saved PDF paths: \(savedPDFs)")

        pdfDocuments = savedPDFs.compactMap { path in
            let url = URL(fileURLWithPath: path)
            guard fileManager.fileExists(atPath: url.path) else {
                print("File does not exist: \(url.path)")
                return nil
            }
            return PDFDocumentInfo(name: url.deletingPathExtension().lastPathComponent, url: url)
        }
    }


    func deletePDF(at offsets: IndexSet) {
        offsets.forEach { index in
            let pdfInfo = pdfDocuments[index]
            try? FileManager.default.removeItem(at: pdfInfo.url)
        }
        pdfDocuments.remove(atOffsets: offsets)
    }

    func resetPendingData() {
        pendingPDFDocument = nil
        pendingPDFName = ""
        originalPDFName = ""
    }
}

struct PDFDocumentInfo {
    var name: String
    var url: URL
}

struct PDFViewerView: View {
    var document: PDFDocument?
    
    var body: some View {
        PDFKitView(document: document)
    }
}

struct PDFKitView: View {
    var document: PDFDocument?
    
    var body: some View {
        PDFViewRepresentable(document: document)
    }
}

struct PDFViewRepresentable: UIViewRepresentable {
    let document: PDFDocument?
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = document
        pdfView.autoScales = true
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {}
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
