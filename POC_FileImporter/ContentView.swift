//
//  ContentView.swift
//  POC_FileImporter
//
//  Created by Jonathan Duong on 14/04/2024.
//

import SwiftUI
import PDFKit

/// ContentView qui gère l'ajout, l'affichage et la suppression de documents PDF.
struct ContentView: View {
    @State private var showFileImporter = false
    @State private var showRenameAlert = false
    @State private var pdfDocuments = [(pdf: PDFDocument, name: String)]()
    @State private var pendingPDFDocument: PDFDocument?
    @State private var pendingPDFName: String = ""
    @State private var originalPDFName: String = ""

    var body: some View {
        NavigationView {
            List {
                ForEach(pdfDocuments, id: \.name) { pdfInfo in
                    NavigationLink(destination: PDFViewerView(document: pdfInfo.pdf)) {
                        Text(pdfInfo.name)
                    }
                }
                .onDelete(perform: deletePDF)
            }
            .navigationTitle("PDF Files")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()  // Bouton pour activer le mode d'édition de la liste.
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

    /// Ajoute le PDF à la liste de documents avec le nom spécifié.
    func addPDFToDocumentsList(using name: String) {
        if let pdfDocument = pendingPDFDocument {
            pdfDocuments.append((pdf: pdfDocument, name: name))
        }
        resetPendingData()
    }

    /// Gère le résultat de l'importation de fichiers.
    func handleFileImportResult(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            processSelectedFiles(urls)
        case .failure(let error):
            print("Cannot load PDF: \(error)")
        }
    }

    /// Traite les fichiers sélectionnés pour préparation à l'ajout.
    func processSelectedFiles(_ urls: [URL]) {
        urls.forEach { url in
            guard url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }
            
            if let pdfDocument = PDFDocument(url: url) {
                pendingPDFDocument = pdfDocument
                pendingPDFName = url.deletingPathExtension().lastPathComponent
                originalPDFName = url.deletingPathExtension().lastPathComponent
                showRenameAlert = true
            }
        }
    }

    /// Supprime les éléments sélectionnés de la liste de documents.
    func deletePDF(at offsets: IndexSet) {
        pdfDocuments.remove(atOffsets: offsets)
    }

    /// Réinitialise les données temporaires.
    func resetPendingData() {
        pendingPDFDocument = nil
        pendingPDFName = ""
        originalPDFName = ""
    }
}

/// Vue pour visualiser un document PDF spécifique.
struct PDFViewerView: View {
    var document: PDFDocument
    
    var body: some View {
        PDFKitView(document: document)
    }
}

/// Vue pour encapsuler PDFView de PDFKit, utilisé pour afficher le contenu d'un PDF.
struct PDFKitView: View {
    var document: PDFDocument
    
    var body: some View {
        PDFViewRepresentable(document: document)
    }
}

/// UIViewRepresentable pour intégrer PDFView de PDFKit dans SwiftUI.
struct PDFViewRepresentable: UIViewRepresentable {
    let document: PDFDocument
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = document
        pdfView.autoScales = true
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {}
}

/// Previews pour ContentView.
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
