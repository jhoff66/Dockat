import Foundation

/// O jeito de cada gato: quanto anda, o que faz quando está sozinho e como trata os outros.
struct Personalidade: Identifiable, Equatable {
    let id: String
    let nome: String
    let descricao: String
    let icone: String          // SF Symbol
    let velocidade: Double     // multiplica a velocidade escolhida
    let iniciativa: Int        // quem puxa a interação quando dois se encontram
    /// Peso de cada coisa que ele faz sozinho.
    let pesos: [Solo: Double]

    static func == (a: Personalidade, b: Personalidade) -> Bool { a.id == b.id }

    static let todas: [Personalidade] = [
        Personalidade(id: "brigao", nome: "Brigão", descricao: "Arrepia, dá tapa no ar e bate em quem chegar perto.",
                      icone: "flame.fill", velocidade: 1.15, iniciativa: 6,
                      pesos: [.andar: 5, .sentar: 2, .dormir: 1, .tapaNoAr: 2.5, .arrepiar: 1]),
        Personalidade(id: "dorminhoco", nome: "Dorminhoco", descricao: "Boceja, cochila sentado e chama os outros pra dormir junto.",
                      icone: "moon.zzz.fill", velocidade: 0.7, iniciativa: 2,
                      pesos: [.andar: 2, .sentar: 1, .dormir: 5, .bocejo: 2, .cochilo: 3]),
        Personalidade(id: "preguicoso", nome: "Preguiçoso", descricao: "Anda devagarinho, se espreguiça e deita em qualquer canto.",
                      icone: "tortoise.fill", velocidade: 0.5, iniciativa: 1,
                      pesos: [.andar: 2, .sentar: 2, .dormir: 3, .espreguicar: 3, .bocejo: 1.5]),
        Personalidade(id: "brincalhao", nome: "Brincalhão", descricao: "Corre, dá saltinhos, corre atrás do rabo e pula por cima dos outros.",
                      icone: "sparkles", velocidade: 1.45, iniciativa: 5,
                      pesos: [.andar: 3, .correr: 3, .pular: 2.5, .girar: 2, .sentar: 0.6]),
        Personalidade(id: "carinhoso", nome: "Carinhoso", descricao: "Se lambe, solta coraçõezinhos e lambe quem encontra.",
                      icone: "heart.fill", velocidade: 1.0, iniciativa: 4,
                      pesos: [.andar: 4, .sentar: 2.5, .dormir: 1, .seLamber: 2.5]),
        Personalidade(id: "curioso", nome: "Curioso", descricao: "Cheira tudo, olha pros lados e vai fuçar os outros gatos.",
                      icone: "magnifyingglass", velocidade: 0.95, iniciativa: 3,
                      pesos: [.andar: 4, .sentar: 1, .cheirar: 3, .olharEmVolta: 2.5]),
        Personalidade(id: "medroso", nome: "Medroso", descricao: "Leva susto do nada e foge quando alguém chega perto.",
                      icone: "exclamationmark.bubble.fill", velocidade: 0.9, iniciativa: 3,
                      pesos: [.andar: 4, .sentar: 2.5, .dormir: 1, .susto: 1.2]),
    ]

    static func por(_ id: String) -> Personalidade { todas.first { $0.id == id } ?? todas[4] }
}

/// Coisas que o gato faz quando está sozinho.
enum Solo: CaseIterable {
    case andar, correr, sentar, dormir
    case tapaNoAr, arrepiar, bocejo, cochilo, espreguicar, pular, girar, seLamber, cheirar, olharEmVolta, susto
}
