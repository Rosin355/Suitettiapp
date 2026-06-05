import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                headerBlock
                Divider().padding(.vertical, 8).opacity(0.4)
                section1
                section2
                section3
                section4
                section5
                section6
                section7
                section8
                section9
                Color.clear.frame(height: 60)
            }
            .padding(.horizontal, 20)
        }
        .background(.brandCream)
        .scrollIndicators(.hidden)
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
    }

    // MARK: - Header

    private var headerBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Informativa sulla Privacy dell'Applicazione \"SUITETTI\"")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.brandBlack)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)
            Text("Ultimo aggiornamento: 3 Giugno 2026")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.brandGray)
            pBody("La presente Informativa sulla Privacy descrive le modalità con cui l'applicazione mobile \"SUITETTI\" (di seguito, l'\"Applicazione\") raccoglie, utilizza e protegge i dati degli utenti, in conformità al Regolamento (UE) 2016/679 (di seguito \"GDPR\").")
            pBody("L'Applicazione è progettata per raggruppare e mostrare i contenuti informativi e gli articoli presenti sul sito web ufficiale https://www.suitetti.org/. L'Applicazione adotta un approccio improntato alla massima minimizzazione dei dati, applicando i principi di Privacy by Design e by Default ai sensi del GDPR.")
        }
    }

    // MARK: - Section 1

    private var section1: some View {
        PolicySection(number: "1", title: "Titolare del Trattamento e Referente per la Protezione dei Dati") {
            pBody("Il Titolare del Trattamento dei dati raccolti tramite questa Applicazione è l'entità legale che ne determina le finalità e i mezzi.")
            PolicyContactCard(entries: [
                ("Ragione Sociale", "COMITATO PER LA PUBBLICA AGENDA SUSSIDIARIA E CONDIVISA \"DITELO SUI TETTI (MT 10,27)\" - PASC"),
                ("Sede Legale",           "Via Cavour n. 285, 00184 Roma (RM)"),
                ("Codice Fiscale / P.IVA","17703591002"),
                ("Email Privacy",         "privacy@suitetti.org"),
            ])
            pBody("Come punto di contatto per l'esercizio dei diritti e per qualsiasi questione relativa al trattamento dei dati personali, è stato designato il seguente referente:")
            PolicyContactCard(entries: [
                ("Referente",  "Avv. Domenico Menorello"),
                ("C.F.",       "MNRDNC67L28G224D"),
                ("P.IVA",      "00449020288"),
                ("Indirizzo",  "Piazza De Gasperi, 22 – Padova"),
                ("PEC",        "domenico.menorello@ordineavvocatipadova.it"),
            ])
        }
    }

    // MARK: - Section 2

    private var section2: some View {
        PolicySection(number: "2", title: "Tipologie di Dati Raccolti e Finalità") {
            pBody("L'Applicazione tratta i dati personali nel rispetto dei principi di liceità, correttezza e trasparenza. Le tipologie di dati trattati sono strettamente limitate a quanto necessario per il suo funzionamento e la sua sicurezza.")

            pSubsection("A) Assenza di Registrazione e Autenticazione (Login)")
            pBody("L'Applicazione non richiede la creazione di un account, non prevede funzioni di login e non raccoglie dati identificativi diretti dell'utente (quali nome, cognome, indirizzo email o numero di telefono) per la fruizione dei contenuti ordinari.")

            pSubsection("B) Dati Tecnici di Navigazione e Funzionamento (Infrastruttura Backend)")
            pBody("Per mostrare gli articoli e i contenuti archiviati, l'Applicazione si collega alla piattaforma cloud Supabase. Durante questo collegamento tecnico, vengono inevitabilmente trasmessi alcuni dati necessari al protocollo internet:")
            PolicyBulletList(items: [
                "Indirizzo IP del dispositivo dell'utente (un indirizzo IP può costituire un dato personale se, associato ad altri elementi, consente di identificare l'interessato).",
                "Log di connessione (es. orario della richiesta, tipo di dispositivo).",
            ])
            pBody("Finalità: Questi dati vengono trattati esclusivamente per garantire la sicurezza informatica dell'infrastruttura, prevenire abusi e assicurare il corretto funzionamento tecnico dell'Applicazione.")
            pBody("Base giuridica: Il trattamento è fondato sul legittimo interesse del Titolare (Art. 6, par. 1, lett. f del GDPR). Per maggiori informazioni consultare la Privacy Policy di Supabase: https://supabase.com/privacy")

            pSubsection("C) Dati relativi alle Donazioni e Pagamenti (Stripe)")
            pBody("L'Applicazione permette di effettuare donazioni a sostegno del progetto tramite la piattaforma di pagamento Stripe.")
            pBody("L'Applicazione non raccoglie, non memorizza e non tratta in alcun modo i dati finanziari dell'utente. Tali dati, inseriti tramite un'interfaccia sicura integrata nell'Applicazione, vengono crittografati e trasmessi direttamente ed esclusivamente a Stripe, che agisce in qualità di autonomo Titolare del Trattamento per l'elaborazione della transazione.")
            pBody("Per maggiori informazioni consultare la Privacy Policy di Stripe: https://stripe.com/it/privacy")
        }
    }

    // MARK: - Section 3

    private var section3: some View {
        PolicySection(number: "3", title: "Notifiche Push e Permessi del Dispositivo") {
            pSubsection("A) Notifiche Push")
            pBody("L'Applicazione offre un servizio di Notifiche Push per avvisare tempestivamente l'utente della presenza di nuovi eventi o aggiornamenti.")
            pBody("Dati trattati: Previo consenso dell'utente, l'Applicazione genera e utilizza un identificativo univoco e anonimo associato al dispositivo (Push Token). Questo token viene trasmesso in modo sicuro e memorizzato temporaneamente sui nostri server cloud (Supabase) e viene utilizzato per interfacciarsi con i servizi di notifica dei sistemi operativi (Apple Push Notification service per iOS).")
            pBody("Natura dei dati: Il Push Token è un dato pseudonimizzato: non contiene informazioni personali, non traccia la posizione e non consente al Titolare di risalire all'identità o ai dati di contatto dell'utente.")
            pBody("Base giuridica: Il trattamento si basa sul consenso esplicito dell'utente (Art. 6, par. 1, lett. a del GDPR). L'utente può revocare il consenso in qualsiasi momento tramite le impostazioni di sistema del proprio dispositivo.")

            pSubsection("B) Permessi Richiesti")
            pBody("L'Applicazione richiede all'utente esclusivamente il permesso di inviare le suddette notifiche. Non viene richiesto l'accesso ad altre funzionalità o dati personali sensibili residenti sul dispositivo (come geolocalizzazione, microfono, fotocamera, contatti o galleria fotografica).")
        }
    }

    // MARK: - Section 4

    private var section4: some View {
        PolicySection(number: "4", title: "Archiviazione Locale (Local Storage / Cookie)") {
            pBody("L'Applicazione non utilizza strumenti di tracciamento, cookie di profilazione o sistemi di archiviazione locale per salvare preferenze, cronologie o identificativi dell'utente sul dispositivo, ad eccezione delle preferenze strettamente tecniche di base legate al sistema operativo.")
        }
    }

    // MARK: - Section 5

    private var section5: some View {
        PolicySection(number: "5", title: "Luogo del Trattamento e Trasferimento dei Dati") {
            pBody("I dati tecnici di connessione (es. indirizzi IP) vengono elaborati attraverso l'infrastruttura cloud di Supabase Inc. I server dedicati al progetto sono situati all'interno dell'Unione Europea (Regione Europe). I dati sono pertanto trattati in conformità alle tutele previste dal GDPR, senza trasferimenti al di fuori dello Spazio Economico Europeo.")
            pBody("Per l'erogazione materiale delle notifiche, i Push Token potrebbero transitare temporaneamente sui server di Apple Inc. e Google LLC, i quali operano in conformità ai framework internazionali di trasferimento dati.")
        }
    }

    // MARK: - Section 6

    private var section6: some View {
        PolicySection(number: "6", title: "Strumenti di Analisi (Analytics)") {
            pBody("All'interno dell'Applicazione non sono implementati strumenti di analisi statistica, tracciamento del comportamento dell'utente o software di analytics di terze parti (es. Google Analytics, Flurry, etc.).")
        }
    }

    // MARK: - Section 7

    private var section7: some View {
        PolicySection(number: "7", title: "Periodo di Conservazione dei Dati") {
            pBody("In applicazione del principio di limitazione della conservazione (Art. 5, par. 1, lett. e) GDPR), i dati personali sono conservati per un arco di tempo non superiore al conseguimento delle finalità per le quali sono trattati:")
            PolicyBulletList(items: [
                "I dati tecnici di connessione gestiti tramite l'infrastruttura di backend vengono conservati esclusivamente per il tempo strettamente necessario a garantire la sicurezza del servizio (generalmente non superiore a 30 giorni nei log del server), salvo necessità di accertamento di reati da parte dell'Autorità giudiziaria.",
                "I Push Token per le notifiche vengono conservati solo finché l'utente mantiene l'App installata e il consenso attivo. In caso di revoca o disinstallazione, il token diventa inutilizzabile e viene sovrascritto/cancellato dai nostri sistemi.",
            ])
        }
    }

    // MARK: - Section 8

    private var section8: some View {
        PolicySection(number: "8", title: "Diritti degli Interessati") {
            pBody("In conformità agli articoli da 15 a 22 del GDPR, gli utenti hanno il diritto di esercitare i seguenti diritti:")
            PolicyRightItem(title: "Diritto di accesso (Art. 15)", description: "Ottenere la conferma che sia o meno in corso un trattamento di dati personali che li riguardano e, in tal caso, ottenere l'accesso ai dati personali.")
            PolicyRightItem(title: "Diritto di rettifica (Art. 16)", description: "Ottenere la rettifica dei dati personali inesatti senza ingiustificato ritardo.")
            PolicyRightItem(title: "Diritto alla cancellazione (Art. 17)", description: "Ottenere la cancellazione dei dati personali (\"diritto all'oblio\"), se sussiste uno dei motivi previsti dalla norma.")
            PolicyRightItem(title: "Diritto di limitazione (Art. 18)", description: "Ottenere la limitazione del trattamento quando ricorre una delle ipotesi previste dalla norma.")
            PolicyRightItem(title: "Diritto di opposizione (Art. 21)", description: "Opporsi in qualsiasi momento, per motivi connessi alla propria situazione particolare, al trattamento dei dati personali fondato sul legittimo interesse.")
            PolicyRightItem(title: "Diritto di reclamo (Art. 77)", description: "Proporre reclamo a un'autorità di controllo, segnatamente il Garante per la Protezione dei Dati Personali (per l'Italia).")
            pBody("Le richieste per l'esercizio dei diritti possono essere inviate all'indirizzo email del Titolare: privacy@suitetti.org — o ai contatti del Referente per la Protezione dei Dati sopra indicati.")
            PolicyInfoBox(text: "Nota ai sensi dell'Art. 11 GDPR: Poiché l'Applicazione non raccoglie dati identificativi diretti e non associa gli indirizzi IP a identità specifiche degli utenti, potrebbe non essere tecnicamente possibile per il Titolare identificare i dati relativi a un singolo utente senza una sua collaborazione attiva.")
        }
    }

    // MARK: - Section 9

    private var section9: some View {
        PolicySection(number: "9", title: "Modifiche all'Informativa") {
            pBody("Il Titolare del Trattamento si riserva il diritto di apportare modifiche alla presente informativa in qualunque momento, dandone pubblicità agli utenti su questa pagina. Si prega dunque di consultare regolarmente questa sezione, facendo riferimento alla data di ultimo aggiornamento indicata in testa al documento.")
        }
    }

    // MARK: - Inline helpers (avoids repeated modifier chains on Text)

    @ViewBuilder
    private func pBody(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 14))
            .foregroundStyle(.brandBlack.opacity(0.8))
            .lineSpacing(4)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.bottom, 10)
    }

    @ViewBuilder
    private func pSubsection(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.brandBlack)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, 8)
            .padding(.bottom, 4)
    }
}

// MARK: - PolicySection

private struct PolicySection<Content: View>: View {
    let number: String
    let title: String
    let content: Content

    init(number: String, title: String, @ViewBuilder content: () -> Content) {
        self.number = number
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 8) {
                Text(number)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.brandRed)
                    .frame(minWidth: 16, alignment: .center)
                    .padding(.vertical, 3)
                    .padding(.horizontal, 6)
                    .background(.brandRed.opacity(0.10))
                    .clipShape(Capsule())
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.brandBlack)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 24)
            .padding(.bottom, 12)
            content
        }
    }
}

// MARK: - PolicyContactCard

private struct PolicyContactCard: View {
    let entries: [(String, String)]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(entries.enumerated()), id: \.offset) { idx, entry in
                if idx > 0 {
                    Divider().padding(.leading, 14)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.0.uppercased())
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.brandGrayLight)
                        .kerning(0.5)
                    Text(entry.1)
                        .font(.system(size: 13))
                        .foregroundStyle(.brandBlack)
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.enabled)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(.white.opacity(0.8))
        .clipShape(.rect(cornerRadius: DT.smallCorner))
        .overlay {
            RoundedRectangle(cornerRadius: DT.smallCorner)
                .strokeBorder(.white.opacity(0.7), lineWidth: 0.5)
        }
        .cardShadow()
        .padding(.bottom, 12)
    }
}

// MARK: - PolicyBulletList

private struct PolicyBulletList: View {
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 10) {
                    Circle()
                        .fill(.brandRed)
                        .frame(width: 5, height: 5)
                        .padding(.top, 5)
                    Text(item)
                        .font(.system(size: 14))
                        .foregroundStyle(.brandBlack.opacity(0.8))
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.bottom, 10)
    }
}

// MARK: - PolicyRightItem

private struct PolicyRightItem: View {
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14))
                .foregroundStyle(.brandRed.opacity(0.7))
                .padding(.top, 1)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.brandBlack)
                Text(description)
                    .font(.system(size: 13))
                    .foregroundStyle(.brandBlack.opacity(0.72))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.bottom, 8)
    }
}

// MARK: - PolicyInfoBox

private struct PolicyInfoBox: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.brandGray)
                .padding(.top, 1)
            Text(text)
                .font(.system(size: 12))
                .foregroundStyle(.brandGray)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(.brandGray.opacity(0.06))
        .clipShape(.rect(cornerRadius: 10))
        .padding(.bottom, 10)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PrivacyPolicyView()
    }
}
