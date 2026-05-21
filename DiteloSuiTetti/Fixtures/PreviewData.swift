import SwiftUI

extension Article {
    static let all: [Article] = [
        Article(
            category: "Famiglia",
            categoryColor: .brandRed,
            thumbnailColors: [Color(red: 253/255, green: 224/255, blue: 224/255),
                              Color(red: 245/255, green: 188/255, blue: 188/255)],
            title: "Sussidiarietà: il cuore del nostro impegno civico",
            date: "14 mag", fullDate: "14 mag 2026", readTime: "4 min"
        ),
        Article(
            category: "Educazione",
            categoryColor: Color(red: 42/255, green: 122/255, blue: 75/255),
            thumbnailColors: [Color(red: 212/255, green: 240/255, blue: 224/255),
                              Color(red: 158/255, green: 212/255, blue: 180/255)],
            title: "Libertà di scelta educativa: i diritti delle famiglie",
            date: "10 mag", fullDate: "10 mag 2026", readTime: "3 min"
        ),
        Article(
            category: "Bene Comune",
            categoryColor: Color(red: 91/255, green: 82/255, blue: 208/255),
            thumbnailColors: [Color(red: 220/255, green: 216/255, blue: 245/255),
                              Color(red: 184/255, green: 177/255, blue: 232/255)],
            title: "Iniziativa Civica: costruire reti di cittadinanza attiva",
            date: "5 mag", fullDate: "5 mag 2026", readTime: "5 min"
        ),
        Article(
            category: "Sussidiarietà",
            categoryColor: Color(red: 192/255, green: 112/255, blue: 32/255),
            thumbnailColors: [Color(red: 252/255, green: 239/255, blue: 170/255),
                              Color(red: 240/255, green: 216/255, blue: 64/255)],
            title: "Il principio di sussidiarietà nella Costituzione italiana",
            date: "28 apr", fullDate: "28 apr 2026", readTime: "6 min"
        ),
        Article(
            category: "Famiglia",
            categoryColor: .brandRed,
            thumbnailColors: [Color(red: 253/255, green: 224/255, blue: 224/255),
                              Color(red: 245/255, green: 188/255, blue: 188/255)],
            title: "Famiglie e politiche sociali: proposte per il futuro",
            date: "21 apr", fullDate: "21 apr 2026", readTime: "4 min"
        ),
        Article(
            category: "Bene Comune",
            categoryColor: Color(red: 91/255, green: 82/255, blue: 208/255),
            thumbnailColors: [Color(red: 220/255, green: 216/255, blue: 245/255),
                              Color(red: 184/255, green: 177/255, blue: 232/255)],
            title: "Reti civiche e democrazia partecipativa",
            date: "14 apr", fullDate: "14 apr 2026", readTime: "5 min"
        ),
    ]

    static let categories = ["Tutto", "Famiglia", "Educazione", "Sussidiarietà", "Bene Comune"]
}
