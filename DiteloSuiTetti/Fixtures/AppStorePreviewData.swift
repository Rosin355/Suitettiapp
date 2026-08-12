import SwiftUI

/// Deterministic content injected when the app is launched with the --screenshots argument.
/// Use this data for App Store Connect screenshot sessions and UI automation.
///
/// Launch argument: --screenshots
/// Xcode scheme: Edit Scheme → Run → Arguments → Arguments Passed On Launch → + "--screenshots"
enum AppStorePreviewData {

    // MARK: - Articles

    static let articles: [Article] = [
        Article(
            id: UUID(uuidString: "A1000001-0000-0000-0000-000000000001")!,
            slug: "sussidiarieta-cuore-impegno-civico",
            category: "Famiglia",
            categoryColor: .brandRed,
            thumbnailColors: [
                Color(red: 253/255, green: 224/255, blue: 224/255),
                Color(red: 245/255, green: 188/255, blue: 188/255)
            ],
            title: "Sussidiarietà: il cuore del nostro impegno civico",
            date: "14 mag",
            fullDate: "14 mag 2026",
            readTime: "4 min",
            excerpt: "La sussidiarietà non è soltanto un principio giuridico: è la filosofia che orienta ogni nostra azione sul territorio, dalla scuola al quartiere.",
            body: """
La sussidiarietà è uno dei principi fondamentali su cui si regge la nostra Costituzione, eppure rimane spesso confinato nei testi accademici, lontano dalla vita quotidiana dei cittadini. Noi crediamo invece che questo principio debba diventare una bussola concreta per l'azione civica di tutti.

Il principio di sussidiarietà stabilisce che le decisioni debbano essere prese al livello più vicino possibile alle persone direttamente coinvolte. Significa che lo Stato interviene solo quando la comunità locale, la famiglia o il singolo cittadino non riescono a far fronte autonomamente a un bisogno. È il contrario della logica centralista e burocratica che spesso mortifica l'iniziativa dal basso.

Nella pratica, questo si traduce in una cosa semplice e rivoluzionaria: fiducia nei cittadini. Fiducia nelle famiglie che scelgono la scuola per i propri figli. Fiducia nelle associazioni di quartiere che presidiano il territorio. Fiducia nelle reti informali di solidarietà che suppliscono laddove lo Stato non arriva — e non per debolezza, ma per scelta deliberata di prossimità.

I Comitati Civici per Ditelo sui Tetti nascono esattamente da questa visione. Non siamo un partito, non siamo un movimento ideologico: siamo una rete di cittadini che credono nel potere delle comunità locali e che vogliono riportare il principio di sussidiarietà al centro del dibattito pubblico, un incontro alla volta, una proposta concreta alla volta.

Il nostro invito è semplice: partecipa. Porta la tua esperienza, il tuo quartiere, la tua storia. La democrazia si costruisce dal basso.
"""
        ),
        Article(
            id: UUID(uuidString: "A1000001-0000-0000-0000-000000000002")!,
            slug: "liberta-scelta-educativa",
            category: "Educazione",
            categoryColor: Color(red: 42/255, green: 122/255, blue: 75/255),
            thumbnailColors: [
                Color(red: 212/255, green: 240/255, blue: 224/255),
                Color(red: 158/255, green: 212/255, blue: 180/255)
            ],
            title: "Libertà di scelta educativa: i diritti delle famiglie",
            date: "10 mag",
            fullDate: "10 mag 2026",
            readTime: "3 min",
            excerpt: "L'articolo 30 della Costituzione è chiaro: i genitori hanno il diritto e il dovere di mantenere, istruire ed educare i figli. Difendere questo diritto è una priorità civica.",
            body: """
Ogni genitore ha il diritto di scegliere l'educazione dei propri figli secondo i propri valori e la propria visione del mondo. Questo non è un privilegio, ma un diritto costituzionale sancito dall'articolo 30 della nostra Carta fondamentale. Eppure, nel dibattito pubblico italiano, questo diritto viene spesso trattato come una concessione dello Stato piuttosto che come una libertà primaria.

La libertà di scelta educativa include il diritto di scegliere scuole paritarie, di aderire a progetti di homeschooling dove la legge lo permette, e di partecipare attivamente alla vita delle istituzioni scolastiche. Sono diritti che molte famiglie faticano a esercitare pienamente, per ragioni economiche, burocratiche o culturali.

I Comitati Civici si battono affinché questi diritti diventino realmente accessibili a tutti, non solo a chi può permetterseli. Questo significa lavorare per un sistema di voucher educativi equi, per il riconoscimento delle spese sostenute dalle famiglie che scelgono scuole non statali, e per una burocrazia scolastica meno opprimente.

Non si tratta di indebolire la scuola pubblica: si tratta di costruire un sistema educativo che rispetti davvero la pluralità delle famiglie italiane.
"""
        ),
        Article(
            id: UUID(uuidString: "A1000001-0000-0000-0000-000000000003")!,
            slug: "iniziativa-civica-reti-cittadinanza",
            category: "Bene Comune",
            categoryColor: Color(red: 91/255, green: 82/255, blue: 208/255),
            thumbnailColors: [
                Color(red: 220/255, green: 216/255, blue: 245/255),
                Color(red: 184/255, green: 177/255, blue: 232/255)
            ],
            title: "Iniziativa Civica: costruire reti di cittadinanza attiva",
            date: "5 mag",
            fullDate: "5 mag 2026",
            readTime: "5 min",
            excerpt: "Le reti civiche sono il tessuto connettivo della democrazia. Ecco come stiamo costruendo una rete nazionale di comitati attivi, capillari e autonomi.",
            body: """
La crisi della partecipazione democratica è uno dei problemi strutturali del nostro tempo. L'astensionismo cresce, la fiducia nelle istituzioni cala, e sempre più cittadini si sentono spettatori impotenti di decisioni che li riguardano ma che percepiscono come lontane e incontrollabili.

La risposta che proponiamo non è una nuova lista elettorale o un manifesto ideologico: è una rete. Una rete di comitati civici locali, autonomi nei metodi ma uniti nei valori, capaci di essere presenti sul territorio con continuità e credibilità.

I comitati civici locali di Ditelo sui Tetti operano secondo un principio semplice: ogni gruppo è autonomo nella gestione delle proprie attività, ma condivide un metodo comune e una visione comune del bene comune. Non c'è un centro che comanda: c'è una rete che si coordina, si supporta e cresce insieme.

Questo modello ha già dimostrato la sua efficacia in molte realtà locali. Laddove i comitati sono presenti e attivi, la partecipazione ai tavoli comunali aumenta, le proposte dei cittadini vengono ascoltate con più attenzione, e le decisioni locali riflettono meglio i valori delle comunità.

Il passo successivo è rendere questo modello replicabile a scala nazionale, senza perdere la sua anima locale. L'app è uno strumento per questo: per connettere chi vuole fare, non solo chi vuole parlare.
"""
        ),
        Article(
            id: UUID(uuidString: "A1000001-0000-0000-0000-000000000004")!,
            slug: "principio-sussidiarieta-costituzione",
            category: "Sussidiarietà",
            categoryColor: Color(red: 192/255, green: 112/255, blue: 32/255),
            thumbnailColors: [
                Color(red: 252/255, green: 239/255, blue: 170/255),
                Color(red: 240/255, green: 216/255, blue: 64/255)
            ],
            title: "Il principio di sussidiarietà nella Costituzione italiana",
            date: "28 apr",
            fullDate: "28 apr 2026",
            readTime: "6 min",
            excerpt: "Con la riforma del Titolo V nel 2001, la sussidiarietà verticale e orizzontale sono entrate esplicitamente nel testo costituzionale. Una conquista che aspetta ancora di essere pienamente attuata.",
            body: """
La riforma costituzionale del 2001 ha introdotto per la prima volta nel testo della Costituzione il principio di sussidiarietà, attraverso la modifica dell'articolo 118. Non è stata solo una modifica formale: è stata il riconoscimento che la democrazia italiana doveva cambiare il suo rapporto con i cittadini e con le comunità locali.

L'articolo 118, nella sua formulazione attuale, distingue tra sussidiarietà verticale — la distribuzione delle funzioni amministrative tra Stato, Regioni, Province, Comuni e Città metropolitane — e sussidiarietà orizzontale, che riconosce ai cittadini singoli e associati il diritto di svolgere attività di interesse generale.

La sussidiarietà orizzontale è la più rivoluzionaria delle due. Dice che i cittadini non sono solo destinatari di servizi pubblici: sono attori del bene comune. Quando una comunità di quartiere si organizza per gestire un giardino pubblico, quando un gruppo di genitori crea uno spazio di doposcuola, quando un'associazione di volontariato presidia un servizio che lo Stato non riesce a garantire — tutto questo è sussidiarietà orizzontale in azione.

Il problema è che questa riforma, vent'anni dopo, è ancora in larga parte inattuata. La cultura della delega verso il centro è dura a morire, e spesso le amministrazioni locali preferiscono gestire direttamente piuttosto che abilitare i cittadini. I Comitati Civici lavorano proprio per cambiare questa cultura, un territorio alla volta.
"""
        ),
    ]

    // MARK: - Events

    static let events: [Event] = [
        Event(
            id: UUID(uuidString: "E1000001-0000-0000-0000-000000000001")!,
            title: "Presidio civico — Milano",
            slug: "presidio-civico-milano",
            type: "Presidio",
            day: "15",
            monthShort: "OTT",
            fullDate: "15 ottobre 2026",
            time: "10:00",
            location: "Piazza della Scala, Milano",
            description: "Un momento di incontro e riflessione civica nel cuore di Milano. Interventi di rappresentanti dei comitati locali, musica e spazio aperto al confronto tra cittadini.",
            link: nil,
            imageURL: nil,
            rawDate: Calendar.current.date(from: DateComponents(year: 2026, month: 10, day: 15, hour: 10)),
            updatedAt: nil,
            syncVersion: 1
        ),
        Event(
            id: UUID(uuidString: "E1000001-0000-0000-0000-000000000002")!,
            title: "Assemblea nazionale — Roma",
            slug: "assemblea-nazionale-roma",
            type: "Assemblea",
            day: "08",
            monthShort: "NOV",
            fullDate: "8 novembre 2026",
            time: "15:00",
            location: "Via del Corso 42, Roma",
            description: "Assemblea plenaria dei comitati civici italiani. Aperta a tutti i soci e simpatizzanti. Programma: relazioni dei coordinatori regionali, approvazione del piano attività 2027, spazio libero.",
            link: nil,
            imageURL: nil,
            rawDate: Calendar.current.date(from: DateComponents(year: 2026, month: 11, day: 8, hour: 15)),
            updatedAt: nil,
            syncVersion: 1
        ),
        Event(
            id: UUID(uuidString: "E1000001-0000-0000-0000-000000000003")!,
            title: "Festival dell'umano tutto intero — Firenze",
            slug: "festival-umano-firenze",
            type: "Festival",
            day: "22",
            monthShort: "NOV",
            fullDate: "22 novembre 2026",
            time: "09:00",
            location: "Piazza della Repubblica, Firenze",
            description: "Tre giorni di dibattiti, musica e cultura civica nel cuore di Firenze. Ospiti da tutta Italia, tavole rotonde sui temi della famiglia, dell'educazione e del bene comune.",
            link: nil,
            imageURL: nil,
            rawDate: Calendar.current.date(from: DateComponents(year: 2026, month: 11, day: 22, hour: 9)),
            updatedAt: nil,
            syncVersion: 1,
            // Drives the Home featured-event banner in App Store screenshots, and makes
            // `--screenshots` a runnable check of the banner without a live backend.
            isFeatured: true
        ),
    ]

    // MARK: - Documents

    static let documents: [Document] = [
        Document(
            id: UUID(uuidString: "D1000001-0000-0000-0000-000000000001")!,
            title: "Statuto dell'Associazione Comitati Civici",
            slug: "statuto-comitati-civici",
            type: "Statuto",
            category: "Documenti Legali",
            description: "Testo integrale dello statuto dell'associazione, approvato dall'assemblea fondativa del 12 gennaio 2026.",
            url: nil,
            uploadedAt: "10 gen 2026",
            updatedAt: nil,
            syncVersion: 1
        ),
        Document(
            id: UUID(uuidString: "D1000001-0000-0000-0000-000000000002")!,
            title: "Relazione annuale sull'attività civica 2025",
            slug: "relazione-annuale-2025",
            type: "Relazione",
            category: "Report",
            description: "Sintesi delle iniziative promosse nel corso del 2025 sul territorio italiano. 42 comitati attivi, 180 eventi, oltre 12.000 partecipanti.",
            url: nil,
            uploadedAt: "15 feb 2026",
            updatedAt: nil,
            syncVersion: 1
        ),
        Document(
            id: UUID(uuidString: "D1000001-0000-0000-0000-000000000003")!,
            title: "Proposta di legge sull'iniziativa civica",
            slug: "proposta-legge-iniziativa-civica",
            type: "Proposta",
            category: "Legislazione",
            description: "Testo della proposta elaborata dai comitati in materia di partecipazione democratica e sussidiarietà orizzontale.",
            url: nil,
            uploadedAt: "3 mar 2026",
            updatedAt: nil,
            syncVersion: 1
        ),
    ]
}
