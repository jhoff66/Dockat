import AppKit

// Pixel art virada para a direita. Cada letra é uma cor da pelagem:
// o contorno · g pelo · d sombra · h brilho · s listra · b branco (peito, focinho)
// x pontas (orelha, ponta do rabo, patinhas) · p rosa · e íris · k pupila · w brilho do olho

enum Pose: CaseIterable { case andando, sentado, sentadoFeliz, dormindo, arrepiado, tapa, lambendo, espreguicando, bocejando, cheirando, cochilando }

struct Pelagem: Identifiable, Equatable {
    let id: String
    let nome: String
    let cores: [Character: UInt32]

    func cor(_ c: Character) -> NSColor? {
        guard let hex = cores[c] else { return nil }
        return NSColor(srgbRed: CGFloat((hex >> 16) & 0xff) / 255, green: CGFloat((hex >> 8) & 0xff) / 255,
                       blue: CGFloat(hex & 0xff) / 255, alpha: 1)
    }

    private static func monta(_ id: String, _ nome: String, o: UInt32, g: UInt32, d: UInt32, h: UInt32, s: UInt32,
                              b: UInt32, x: UInt32? = nil, p: UInt32 = 0xF29DAA, e: UInt32) -> Pelagem {
        Pelagem(id: id, nome: nome, cores: ["o": o, "g": g, "d": d, "h": h, "s": s, "b": b, "x": x ?? g,
                                            "p": p, "e": e, "k": 0x131318, "w": 0xFFFFFF])
    }

    static let todas: [Pelagem] = [
        monta("cinza", "Cinza tigrado", o: 0x26262E, g: 0x8E929C, d: 0x6C707A, h: 0xB4B8C1, s: 0x5E626C, b: 0xE6E7EB, e: 0x8CC63F),
        monta("azul", "Azul russo", o: 0x23272F, g: 0x7D8796, d: 0x5F6876, h: 0x9FA9B7, s: 0x7D8796, b: 0x9FA9B7, e: 0x7ED957),
        monta("laranja", "Laranja", o: 0x3A1F10, g: 0xF0A04B, d: 0xC97A2E, h: 0xFAC67F, s: 0xCF7428, b: 0xFCEBD2, e: 0x7FBF3F),
        monta("preto", "Pretinho", o: 0x08080B, g: 0x2D2D36, d: 0x1C1C22, h: 0x484855, s: 0x2D2D36, b: 0x2D2D36, p: 0xC97A88, e: 0xF2C94C),
        monta("frajola", "Frajola", o: 0x08080B, g: 0x2B2B33, d: 0x1B1B21, h: 0x42424E, s: 0x2B2B33, b: 0xF3F3F5, x: 0xF3F3F5, e: 0x9BD35A),
        monta("siames", "Siamês", o: 0x3A281D, g: 0xF0E4D0, d: 0xD8C6A8, h: 0xFBF5EA, s: 0xF0E4D0, b: 0xF8F0E3, x: 0x4F3828, e: 0x5FA8E8),
        monta("branco", "Branquinho", o: 0x5A5A66, g: 0xF5F5F7, d: 0xD5D6DD, h: 0xFFFFFF, s: 0xF5F5F7, b: 0xFFFFFF, e: 0x6AB0F0),
        monta("rajado", "Rajado marrom", o: 0x2E2016, g: 0xA67C55, d: 0x7F5C3D, h: 0xC49A70, s: 0x5E412A, b: 0xEFE0CC, e: 0xD9B13B),
    ]

    static func por(_ id: String) -> Pelagem { todas.first { $0.id == id } ?? todas[0] }
}

/// Uma camada do desenho: linhas de texto posicionadas no quadro.
struct Camada {
    let linhas: [String]
    let x: Int
    let y: Int
}

enum Sprite {
    static let largura = 31
    static let altura = 21
    static let margemTopo = 12     // espaço acima do gato para pulos e balõezinhos

    // Cabeça de frente (12 × 12)
    static let cabeca = [
        ".o........o.",
        "oxo......oxo",
        "oxpo....opxo",
        "oxppooooppxo",
        "oghhhhhhhhgo",
        "oggsgsgsgggo",
        "ogwkggggwkgo",
        "ogekggggekgo",
        "oggbbppbbggo",
        "ogbbobbobbgo",
        ".oggbbbbggo.",
        "..oooooooo..",
    ]
    static let cabecaPiscando: [String] = {
        var c = cabeca
        c[6] = "oggggggggggo"
        c[7] = "ogooggggoogo"
        return c
    }()

    static let cabecaBrava: [String] = {
        var c = cabeca
        c[5] = "ogooggggoogo"   // sobrancelha franzida
        c[9] = "ogbowwwwobgo"   // dentinhos
        return c
    }()
    static let cabecaLingua: [String] = {
        var c = cabecaPiscando
        c[10] = ".oggbppbggo."
        c[11] = "..oooppooo.."
        return c
    }()
    static let cabecaBocejo: [String] = {
        var c = cabecaPiscando
        c[9] = "ogboppppobgo"
        c[10] = ".oggboobggo."
        return c
    }()

    // Corpo de lado (18 × 8)
    static let corpo = [
        "...oooooooooooo...",
        ".oohhhhhhhhhhhhoo.",
        "oggsgggsgggsgggggo",
        "oggsgggsgggsgggggo",
        "oggggggggggggggggo",
        "odgggbbbbbbbbgggdo",
        ".oddddbbbbbbddddo.",
        "..oooooooooooooo..",
    ]

    static let pata = ["oggo", "oggo", "oggo", "oxxo", "oooo"]
    static let pataErguida = ["oggo", "oggo", "oxxo", "oooo"]
    static let pataLonge = ["oddo", "oddo", "oddo", "oxxo", "oooo"]
    static let pataLongeErguida = ["oddo", "oddo", "oxxo", "oooo"]

    // Rabo em pé, três posições
    static let rabos: [[String]] = [
        ["...oo.", "..oxxo", "..oxxo", ".ogso.", ".oggo.", "ogso..", "oggo..", "ogso..", "oggoo.", ".oggoo"],
        ["..oo..", ".oxxo.", ".oxxo.", ".ogso.", ".oggo.", ".ogso.", ".oggo.", ".ogso.", ".oggoo", "..oggo"],
        [".oo...", "oxxo..", "oxxo..", "ogso..", ".ogo..", ".ogso.", ".oggo.", ".ogso.", ".oggoo", "..oggo"],
    ]

    // Sentado (14 × 9)
    static let corpoSentado = [
        ".oggggggggggo.",
        ".oggbbbbbbggo.",
        "ogggbbbbbbgggo",
        "osggbbbbbbggso",
        "ogsgbbbbbbgsgo",
        "ogggobbbboggdo",
        "ogggobbbboggdo",
        "oggoxxooxxoggo",
        ".oooooooooooo.",
    ]
    static let raboSentado: [[String]] = [
        ["....oo", "...oxo", "..ogo.", ".oggo.", "oggo..", "ooo..."],
        ["......", "......", "...ooo", ".oogxo", "oggoo.", "ooo..."],
    ]

    // Deitado, em formato de pão
    static let pao = [
        ".....oooooooo.....",
        "...oohhhhhhhhoo...",
        "..ohgsggsggsgggo..",
        ".oggsggsggsgggggo.",
        "oggggggggggggggggo",
        "oggggggggggggggggo",
        "odggggggggggggdddo",
        "oddddddddddddddddo",
        ".oooooooooooooooo.",
    ]

    // Dormindo: rabo enrolado na frente
    static let raboDormindo = [
        ".oooooooooooo.",
        "oggsggsgggxxxo",
        ".oooooooooooo.",
    ]

    static let z = ["oooo", "..o.", ".o..", "oooo"]

    // Arrepiado: costas em arco e rabo eriçado
    static let corpoArqueado = [
        ".......oooo.......",
        ".....oohhhhoo.....",
        "....ohsggsggsho...",
        "...oggsggsggsggo..",
        "..oggggggggggggo..",
        ".oggggggggggggggo.",
        ".oddggggggggggddo.",
        ".oddo........oddo.",
        ".oddo........oddo.",
    ]
    static let raboArrepiado = [
        "..oo..", ".oxxo.", "oxggxo", "ogsggo", "oggsgo", "ogsggo", "oggsgo",
        "ogsggo", ".oggo.", ".oggo.", ".oggo.", ".oggo.", "..oo..",
    ]
    static let pataTapaAlta = ["oxxo", "oggo", "oggo", "oggo", "oooo"]
    static let pataTapaFrente = ["oooooo", "oggxxo", "oooooo"]
    static let pataEsticada = ["oooooooo", "oggggxxo", "oooooooo"]

    /// Corpo inclinado (traseiro pra cima), gerado coluna a coluna.
    static func corpoInclinado(largura w: Int, topoEsq: Int, topoDir: Int, base: Int) -> (linhas: [String], y0: Int) {
        let y0 = min(topoEsq, topoDir)
        var grade = Array(repeating: Array(repeating: Character("."), count: w), count: base - y0 + 1)
        for x in 0..<w {
            var t = topoEsq + Int((Double(topoDir - topoEsq) * Double(x) / Double(w - 1)).rounded())
            if x == 0 || x == w - 1 { t += 1 }
            for y in t...base {
                var ch: Character = "g"
                if y == t || y == base || x == 0 || x == w - 1 { ch = "o" }
                else if y == t + 1 { ch = "h" }
                else if y == base - 1 { ch = "d" }
                else if x % 4 == 2 && y <= t + 3 { ch = "s" }
                grade[y - y0][x] = ch
            }
        }
        return (grade.map { String($0) }, y0)
    }

    /// Onde fica a cabeça em cada pose (canto de cima, à esquerda), para os balõezinhos.
    static func posCabeca(_ pose: Pose) -> (x: Int, y: Int) {
        switch pose {
        case .sentado, .sentadoFeliz, .bocejando, .cochilando: return (10, 1)
        case .dormindo: return (17, 9)
        case .arrepiado: return (18, 4)
        case .espreguicando: return (19, 8)
        case .cheirando: return (18, 4)
        default: return (18, 1)
        }
    }

    /// Gato andando parado no quadro `q`, com cabeça e patas da frente trocáveis.
    private static func emPe(q: Int, rabo: Int, cab: [String], cabX: Int = 18, cabY: Int = 1, pataFrente: Bool = true) -> [Camada] {
        let passos = [(1, -1, -1, 1), (0, 0, 0, 0), (-1, 1, 1, -1), (0, 0, 0, 0)]
        let (pf, pt, lf, lt) = passos[q % 4]
        let sobe = (q % 4 == 1 || q % 4 == 3) ? 1 : 0
        let pertoErgue = q % 4 == 1, longeErgue = q % 4 == 3
        var c = [
            Camada(linhas: rabos[rabo % 3], x: 1, y: 1 + sobe),
            Camada(linhas: longeErgue ? pataLongeErguida : pataLonge, x: 9 + lt, y: 16),
            Camada(linhas: longeErgue ? pataLongeErguida : pataLonge, x: 19 + lf, y: 16),
            Camada(linhas: corpo, x: 4, y: 9 + sobe),
            Camada(linhas: pertoErgue ? pataErguida : pata, x: 6 + pt, y: 16),
        ]
        if pataFrente { c.append(Camada(linhas: pertoErgue ? pataErguida : pata, x: 16 + pf, y: 16)) }
        c.append(Camada(linhas: cab, x: cabX, y: cabY + sobe))
        return c
    }

    /// Camadas do quadro, de trás para a frente.
    static func camadas(pose: Pose, quadro: Int, rabo: Int, piscando: Bool, respira: Bool) -> [Camada] {
        let cab = piscando ? cabecaPiscando : cabeca
        let sentadoBase = { (c: [String], y: Int) -> [Camada] in [
            Camada(linhas: raboSentado[rabo % 2], x: 21, y: 15),
            Camada(linhas: corpoSentado, x: 9, y: 12),
            Camada(linhas: c, x: 10, y: y),
        ] }
        switch pose {
        case .andando:
            return emPe(q: quadro, rabo: rabo, cab: cab)
        case .sentado:
            return sentadoBase(cab, 1)
        case .sentadoFeliz:
            return sentadoBase(cabecaPiscando, 1)
        case .bocejando:
            return sentadoBase(cabecaBocejo, 1)
        case .cochilando:
            return sentadoBase(cabecaPiscando, 1 + quadro % 2)
        case .dormindo:
            return [
                Camada(linhas: pao, x: 4, y: respira ? 11 : 12),
                Camada(linhas: raboDormindo, x: 4, y: 18),
                Camada(linhas: cabecaPiscando, x: 17, y: 9),
            ]
        case .arrepiado:
            return [
                Camada(linhas: raboArrepiado, x: 2, y: 0),
                Camada(linhas: pataLonge, x: 7, y: 16),
                Camada(linhas: pataLonge, x: 15, y: 16),
                Camada(linhas: corpoArqueado, x: 4, y: 7),
                Camada(linhas: pata, x: 5, y: 16),
                Camada(linhas: pata, x: 17, y: 16),
                Camada(linhas: cabecaBrava, x: 18, y: 4),
            ]
        case .tapa:
            var c = emPe(q: 1, rabo: rabo, cab: cabecaBrava, pataFrente: false)
            c.append(quadro % 2 == 0 ? Camada(linhas: pataTapaAlta, x: 27, y: 7) : Camada(linhas: pataTapaFrente, x: 25, y: 12))
            return c
        case .lambendo:
            return emPe(q: 1, rabo: rabo, cab: cabecaLingua, cabX: 18 + quadro % 2, cabY: 2)
        case .cheirando:
            return emPe(q: 1, rabo: rabo, cab: cab, cabY: 4 + quadro % 2)
        case .espreguicando:
            let (corpoI, y0) = corpoInclinado(largura: 17, topoEsq: 8, topoDir: 13, base: 16)
            return [
                Camada(linhas: rabos[rabo % 3], x: 0, y: 0),
                Camada(linhas: pataLonge, x: 8, y: 16),
                Camada(linhas: corpoI, x: 3, y: y0),
                Camada(linhas: pata, x: 5, y: 16),
                Camada(linhas: cabecaPiscando, x: 19, y: 8),
                Camada(linhas: pataEsticada, x: 21, y: 18),
            ]
        }
    }

    /// Pinta o gato num contexto com y para baixo.
    static func pinta(_ ctx: CGContext, pelagem: Pelagem, camadas: [Camada], px: CGFloat, origem: CGPoint, espelhar: Bool) {
        ctx.setShouldAntialias(false)
        for c in camadas {
            for (ly, linha) in c.linhas.enumerated() {
                for (lx, ch) in linha.enumerated() {
                    guard ch != ".", let cor = pelagem.cor(ch) else { continue }
                    var gx = c.x + lx
                    if espelhar { gx = largura - 1 - gx }
                    ctx.setFillColor(cor.cgColor)
                    ctx.fill(CGRect(x: origem.x + CGFloat(gx) * px, y: origem.y + CGFloat(c.y + ly) * px, width: px, height: px))
                }
            }
        }
    }

    /// Carinha de gatinho branco pixelado para a barra de menus (contorno escuro, aparece em barra clara e escura).
    static func iconeBarraDeMenu() -> NSImage {
        var cores = Pelagem.por("branco").cores
        cores["o"] = 0x26262E
        cores["g"] = 0xFFFFFF
        cores["d"] = 0xFFFFFF
        cores["s"] = 0xFFFFFF
        let branco = Pelagem(id: "menubar", nome: "Barra de menus", cores: cores)
        let px: CGFloat = 1.5   // 12 × 12 células = 18 pt, 3 pixels por célula na tela retina
        let img = NSImage(size: NSSize(width: 18, height: 18), flipped: true) { _ in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
            pinta(ctx, pelagem: branco, camadas: [Camada(linhas: cabeca, x: 0, y: 0)], px: px, origem: .zero, espelhar: false)
            return true
        }
        img.isTemplate = false
        return img
    }

    /// Miniatura para a tela de Ajustes.
    static func miniatura(_ pelagem: Pelagem, px: CGFloat = 3) -> NSImage {
        let tam = NSSize(width: CGFloat(largura) * px, height: CGFloat(altura) * px)
        return NSImage(size: tam, flipped: true) { _ in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
            pinta(ctx, pelagem: pelagem, camadas: camadas(pose: .sentado, quadro: 0, rabo: 0, piscando: false, respira: false),
                  px: px, origem: .zero, espelhar: false)
            return true
        }
    }
}

// MARK: - Balõezinhos

enum Emote {
    case coracao, raiva, exclamacao, interrogacao

    var linhas: [String] {
        switch self {
        case .coracao: return [".r.r.", "rrrrr", "rrrrr", ".rrr.", "..r.."]
        case .raiva: return [".r...r.", "rr...rr", ".......", ".......", "rr...rr", ".r...r."]
        case .exclamacao: return [".rr.", ".rr.", ".rr.", "....", ".rr."]
        case .interrogacao: return [".rrr.", "r...r", "...r.", "..r..", ".....", "..r.."]
        }
    }
    var cor: NSColor {
        switch self {
        case .coracao: return NSColor(srgbRed: 0.94, green: 0.35, blue: 0.47, alpha: 1)
        case .raiva: return NSColor(srgbRed: 0.90, green: 0.28, blue: 0.30, alpha: 1)
        case .exclamacao, .interrogacao: return NSColor(srgbRed: 0.96, green: 0.77, blue: 0.26, alpha: 1)
        }
    }

    /// Desenha com contorno escuro em volta, para aparecer em fundo claro e escuro.
    func pinta(_ ctx: CGContext, x: CGFloat, y: CGFloat, px: CGFloat) {
        ctx.setShouldAntialias(false)
        let cheios = linhas.enumerated().flatMap { (ly, l) in l.enumerated().compactMap { $0.element == "." ? nil : (lx: $0.offset, ly: ly) } }
        ctx.setFillColor(NSColor(srgbRed: 0.12, green: 0.12, blue: 0.14, alpha: 1).cgColor)
        for p in cheios {
            ctx.fill(CGRect(x: x + CGFloat(p.lx - 1) * px, y: y + CGFloat(p.ly - 1) * px, width: px * 3, height: px * 3))
        }
        ctx.setFillColor(cor.cgColor)
        for p in cheios {
            ctx.fill(CGRect(x: x + CGFloat(p.lx) * px, y: y + CGFloat(p.ly) * px, width: px, height: px))
        }
    }
}
