import SwiftUI

struct SyncDiagnosticsView: View {
    @Environment(\.dismiss) private var dismiss
    private let logger = SyncLogger.shared

    var body: some View {
        NavigationStack {
            List {
                Section("Endpoint") {
                    Text(AppEnvironment.syncEditorialEndpoint.absoluteString)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }

                Section("Ultima sincronizzazione") {
                    LabeledContent("Articoli", value: "\(logger.lastArticleCount)")
                    LabeledContent("Eventi",   value: "\(logger.lastEventCount)")
                    LabeledContent("Documenti", value: "\(logger.lastDocumentCount)")
                }

                Section("Log (\(logger.entries.count) voci)") {
                    if logger.entries.isEmpty {
                        Text("Nessuna voce ancora.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(logger.entries.reversed(), id: \.self) { entry in
                            Text(entry)
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundStyle(.primary)
                                .textSelection(.enabled)
                        }
                    }
                }
            }
            .navigationTitle("Diagnostica Sync")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Chiudi") { dismiss() }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancella", role: .destructive) { logger.clear() }
                }
            }
        }
    }
}
