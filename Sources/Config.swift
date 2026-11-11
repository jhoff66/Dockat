import AppKit
import ServiceManagement

/// Ajustes de um gato só.
struct GatoConfig: Codable, Identifiable, Equatable {
    var id = UUID()
    var nome: String
    var pelagem: String
    var personalidade = "carinhoso"
    var tamanho: Double = 2        // pontos por pixel do desenho
    var velocidade: Double = 30    // pontos por segundo
    var preguica: Double = 0.5     // não usado desde as personalidades; mantido para ler ajustes antigos
    var podeSentar = true
    var podeDormir = true

    init(nome: String, pelagem: String, personalidade: String = "carinhoso") {
        self.nome = nome; self.pelagem = pelagem; self.personalidade = personalidade
    }

    // lê ajustes antigos que não tinham algum campo
    init(from d: Decoder) throws {
        let c = try d.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        nome = try c.decodeIfPresent(String.self, forKey: .nome) ?? "Gato"
        pelagem = try c.decodeIfPresent(String.self, forKey: .pelagem) ?? "cinza"
        personalidade = try c.decodeIfPresent(String.self, forKey: .personalidade) ?? "carinhoso"
        tamanho = try c.decodeIfPresent(Double.self, forKey: .tamanho) ?? 2
        velocidade = try c.decodeIfPresent(Double.self, forKey: .velocidade) ?? 30
        preguica = try c.decodeIfPresent(Double.self, forKey: .preguica) ?? 0.5
        podeSentar = try c.decodeIfPresent(Bool.self, forKey: .podeSentar) ?? true
        podeDormir = try c.decodeIfPresent(Bool.self, forKey: .podeDormir) ?? true
    }
}

/// Ajustes do Dockat, salvos no UserDefaults.
final class Config: ObservableObject {
    static let shared = Config()
    static let maximo = 5
    private let ud = UserDefaults.standard

    @Published var gatos: [GatoConfig] {
        didSet {
            if let dados = try? JSONEncoder().encode(gatos) { ud.set(dados, forKey: "gatos") }
            aoMudar?()
        }
    }
    @Published var abrirNoLogin: Bool {
        didSet {
            guard abrirNoLogin != (SMAppService.mainApp.status == .enabled) else { return }
            do { abrirNoLogin ? try SMAppService.mainApp.register() : try SMAppService.mainApp.unregister() }
            catch { NSLog("Dockat: login item falhou: \(error)") }
        }
    }

    /// Avisa o bando para criar, tirar ou redesenhar gatos.
    var aoMudar: (() -> Void)?

    private init() {
        if let dados = ud.data(forKey: "gatos"), let lista = try? JSONDecoder().decode([GatoConfig].self, from: dados), !lista.isEmpty {
            gatos = lista
        } else {
            // vindo da versão com um gato só: aproveita o que já estava escolhido
            var g = GatoConfig(nome: "Gato 1", pelagem: ud.string(forKey: "pelagem") ?? "cinza")
            if ud.object(forKey: "tamanho") != nil { g.tamanho = ud.double(forKey: "tamanho") }
            if ud.object(forKey: "velocidade") != nil { g.velocidade = ud.double(forKey: "velocidade") }
            if ud.object(forKey: "preguica") != nil { g.preguica = ud.double(forKey: "preguica") }
            if ud.object(forKey: "podeSentar") != nil { g.podeSentar = ud.bool(forKey: "podeSentar") }
            if ud.object(forKey: "podeDormir") != nil { g.podeDormir = ud.bool(forKey: "podeDormir") }
            gatos = [g]
        }
        abrirNoLogin = SMAppService.mainApp.status == .enabled
    }

    func gato(_ i: Int) -> GatoConfig { gatos.indices.contains(i) ? gatos[i] : gatos[0] }

    @discardableResult
    func adiciona() -> Int? {
        guard gatos.count < Config.maximo else { return nil }
        let usadas = Set(gatos.map(\.pelagem))
        let pelagem = Pelagem.todas.first { !usadas.contains($0.id) }?.id ?? Pelagem.todas.randomElement()!.id
        var nome = "Gato \(gatos.count + 1)"
        var n = gatos.count + 1
        while gatos.contains(where: { $0.nome == nome }) { n += 1; nome = "Gato \(n)" }
        let jeitos = Set(gatos.map(\.personalidade))
        let jeito = Personalidade.todas.filter { !jeitos.contains($0.id) }.randomElement()?.id ?? Personalidade.todas.randomElement()!.id
        gatos.append(GatoConfig(nome: nome, pelagem: pelagem, personalidade: jeito))
        return gatos.count - 1
    }

    func remove(_ i: Int) {
        guard gatos.count > 1, gatos.indices.contains(i) else { return }
        gatos.remove(at: i)
    }
}
