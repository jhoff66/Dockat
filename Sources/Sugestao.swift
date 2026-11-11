import SwiftUI

/// Sugestões de pelagem e de personalidade. O app abre o formulário do Tally já preenchido;
/// quem sugere só confere e clica em enviar, e a resposta chega no Tally do dono do app.
enum Sugestao: String, Identifiable {
    case pelagem, personalidade
    var id: String { rawValue }

    static let formulario = "https://tally.so/r/9N9Qjp"

    static func envia(_ campos: [String: String]) {
        if let u = url(campos) { NSWorkspace.shared.open(u) }
    }

    static func url(_ campos: [String: String]) -> URL? {
        var c = URLComponents(string: formulario)!
        let versao = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        c.queryItems = (campos.merging(["versao": versao]) { a, _ in a })
            .filter { !$0.value.trimmingCharacters(in: .whitespaces).isEmpty }
            .sorted { $0.key < $1.key }
            .map { URLQueryItem(name: $0.key, value: $0.value) }
        // "+" viraria espaço no formulário
        c.percentEncodedQuery = c.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
        return c.url
    }
}

// MARK: - Cor

private func hex(_ c: Color) -> UInt32 {
    let n = NSColor(c).usingColorSpace(.sRGB) ?? .gray
    return (UInt32((n.redComponent * 255).rounded()) << 16) | (UInt32((n.greenComponent * 255).rounded()) << 8) | UInt32((n.blueComponent * 255).rounded())
}

private func mistura(_ a: UInt32, _ b: UInt32, _ t: Double) -> UInt32 {
    func canal(_ v: UInt32, _ s: UInt32) -> Double { Double((v >> s) & 0xff) }
    var r: UInt32 = 0
    for s: UInt32 in [16, 8, 0] {
        r |= UInt32((canal(a, s) * (1 - t) + canal(b, s) * t).rounded()) << s
    }
    return r
}

private func textoHex(_ v: UInt32) -> String { String(format: "#%06X", v) }

struct SugerirPelagem: View {
    @Environment(\.dismiss) private var fechar
    @State private var nome = ""
    @State private var detalhes = ""
    @State private var pelo = Color(red: 0.62, green: 0.48, blue: 0.80)
    @State private var listras = Color(red: 0.42, green: 0.30, blue: 0.58)
    @State private var peito = Color(red: 0.95, green: 0.92, blue: 0.97)
    @State private var pontas = Color(red: 0.62, green: 0.48, blue: 0.80)
    @State private var olhos = Color(red: 0.98, green: 0.80, blue: 0.25)

    /// A pelagem montada com as cores escolhidas (sombra, brilho e contorno saem do pelo).
    private var pelagem: Pelagem {
        let g = hex(pelo)
        return Pelagem(id: "sugestao", nome: nome, cores: [
            "o": mistura(g, 0x000000, 0.78), "g": g, "d": mistura(g, 0x000000, 0.22), "h": mistura(g, 0xFFFFFF, 0.25),
            "s": hex(listras), "b": hex(peito), "x": hex(pontas), "p": 0xF29DAA,
            "e": hex(olhos), "k": 0x131318, "w": 0xFFFFFF,
        ])
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Sugerir uma pelagem").font(.title3.weight(.semibold))

            HStack(alignment: .center, spacing: 20) {
                GatoSentadoPixel(pelagem: pelagem, px: 4)
                    .frame(width: 140, height: 104)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.primary.opacity(0.04)))

                VStack(alignment: .leading, spacing: 8) {
                    ColorPicker("Pelo", selection: $pelo, supportsOpacity: false)
                    ColorPicker("Listras", selection: $listras, supportsOpacity: false)
                    ColorPicker("Peito e focinho", selection: $peito, supportsOpacity: false)
                    ColorPicker("Orelhas, patas e rabo", selection: $pontas, supportsOpacity: false)
                    ColorPicker("Olhos", selection: $olhos, supportsOpacity: false)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Nome da pelagem").font(.callout.weight(.medium))
                TextField("", text: $nome, prompt: Text("Ex.: Lilás galáctico"))
                    .textFieldStyle(.roundedBorder)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("Algum detalhe?").font(.callout.weight(.medium))
                TextField("", text: $detalhes, prompt: Text("Opcional: mancha no olho, rabo de outra cor..."), axis: .vertical)
                    .lineLimit(2...4)
                    .textFieldStyle(.roundedBorder)
            }

            rodape(podeEnviar: !nome.trimmingCharacters(in: .whitespaces).isEmpty) {
                let p = pelagem
                let cores = "pelo \(textoHex(p.cores["g"]!)), listras \(textoHex(p.cores["s"]!)), peito \(textoHex(p.cores["b"]!)), pontas \(textoHex(p.cores["x"]!)), olhos \(textoHex(p.cores["e"]!))"
                Sugestao.envia(["tipo": "Pelagem", "nome": nome, "cores": cores, "detalhes": detalhes])
                fechar()
            }
        }
        .padding(24)
        .frame(width: 440)
    }

    private func rodape(podeEnviar: Bool, enviar: @escaping () -> Void) -> some View {
        RodapeSugestao(podeEnviar: podeEnviar, cancelar: { fechar() }, enviar: enviar)
    }
}

// MARK: - Personalidade

struct SugerirPersonalidade: View {
    @Environment(\.dismiss) private var fechar
    @State private var nome = ""
    @State private var sozinho = ""
    @State private var encontro = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Sugerir uma personalidade").font(.title3.weight(.semibold))

            campo("Nome", texto: $nome, exemplo: "Ex.: Ciumento", linhas: 1)
            campo("O que ele faz sozinho", texto: $sozinho, exemplo: "Ex.: fica parado encarando a tela e mia do nada", linhas: 3)
            campo("O que ele faz quando encontra outro gato", texto: $encontro, exemplo: "Ex.: se mete na frente quando outro gato chega perto do Dock", linhas: 3)

            RodapeSugestao(podeEnviar: !nome.trimmingCharacters(in: .whitespaces).isEmpty, cancelar: { fechar() }) {
                Sugestao.envia(["tipo": "Personalidade", "nome": nome, "sozinho": sozinho, "encontro": encontro])
                fechar()
            }
        }
        .padding(24)
        .frame(width: 440)
    }

    private func campo(_ titulo: String, texto: Binding<String>, exemplo: String, linhas: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(titulo).font(.callout.weight(.medium))
            TextField("", text: texto, prompt: Text(exemplo), axis: .vertical)
                .lineLimit(linhas...max(linhas, 5))
                .textFieldStyle(.roundedBorder)
        }
    }
}

// MARK: - Peças

struct RodapeSugestao: View {
    let podeEnviar: Bool
    let cancelar: () -> Void
    let enviar: () -> Void

    var body: some View {
        HStack {
            Text("Abre um formulário no navegador para você conferir e enviar.")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Button("Cancelar", action: cancelar).keyboardShortcut(.cancelAction)
            Button("Enviar", action: enviar)
                .keyboardShortcut(.defaultAction)
                .disabled(!podeEnviar)
        }
    }
}

/// O gato sentado inteiro, para a prévia da pelagem sugerida.
struct GatoSentadoPixel: View {
    let pelagem: Pelagem
    var px: CGFloat = 4
    var body: some View {
        Canvas { ctx, tam in
            let camadas = Sprite.camadas(pose: .sentado, quadro: 0, rabo: 0, piscando: false, respira: false)
            // o sentado ocupa as colunas 9 a 26: centraliza isso
            let ox = (tam.width - 18 * px) / 2 - 9 * px
            let oy = (tam.height - 21 * px) / 2
            for c in camadas {
                for (ly, linha) in c.linhas.enumerated() {
                    for (lx, ch) in linha.enumerated() {
                        guard ch != ".", let cor = pelagem.cor(ch) else { continue }
                        let r = CGRect(x: ox + CGFloat(c.x + lx) * px, y: oy + CGFloat(c.y + ly) * px, width: px + 0.25, height: px + 0.25)
                        ctx.fill(Path(r), with: .color(Color(nsColor: cor)))
                    }
                }
            }
        }
    }
}
