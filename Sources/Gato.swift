import AppKit

// MARK: - Desenho

final class GatoView: NSView {
    var pelagem = Pelagem.todas[0]
    var px: CGFloat = 2
    var pose: Pose = .andando
    var fase: CGFloat = 0          // passada (andando)
    var tempoPose: CGFloat = 0     // há quanto tempo está na pose (anima tapa, lambida etc.)
    var olhandoEsquerda = false
    var piscando = false
    var tempo: CGFloat = 0
    var dy: CGFloat = 0            // altura do pulo, em pontos
    var emote: Emote?

    override var isFlipped: Bool { true }

    private var quadro: Int {
        switch pose {
        case .andando: return Int(fase)
        case .tapa: return Int(tempoPose / 0.16)
        case .lambendo: return Int(tempoPose / 0.22)
        case .cheirando: return Int(tempoPose / 0.35)
        case .cochilando: return Int(tempoPose / 1.3)
        default: return 0
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        ctx.clear(bounds)
        let rabo: Int
        switch pose {
        case .andando, .lambendo, .cheirando, .tapa, .espreguicando: rabo = [0, 1, 2, 1][Int(tempo * 2.5) % 4]
        default: rabo = Int(tempo * 1.2) % 2
        }
        let respira = Int(tempo * 1.1) % 2 == 1
        let camadas = Sprite.camadas(pose: pose, quadro: quadro, rabo: rabo, piscando: piscando, respira: respira)
        let origem = CGPoint(x: 0, y: bounds.height - CGFloat(Sprite.altura) * px - dy)
        Sprite.pinta(ctx, pelagem: pelagem, camadas: camadas, px: px, origem: origem, espelhar: olhandoEsquerda)

        let (cx, cy) = Sprite.posCabeca(pose)
        if pose == .dormindo || pose == .cochilando { desenhaZzz(ctx, origem: origem, cx: cx, cy: cy) }

        if let emote {
            let larg = emote.linhas[0].count
            var gx = cx + 6 - larg / 2
            if olhandoEsquerda { gx = Sprite.largura - gx - larg }
            let flutua = Int((sin(tempo * 5) * 0.6).rounded())
            let y = origem.y + CGFloat(cy - emote.linhas.count - 2 + flutua) * px
            emote.pinta(ctx, x: CGFloat(gx) * px, y: y, px: px)
        }
    }

    private func desenhaZzz(_ ctx: CGContext, origem: CGPoint, cx: Int, cy: Int) {
        let n = Int(tempo * 0.9) % 3
        let zpx = max(1, (px * 0.75).rounded())
        ctx.setFillColor(pelagem.cor("o")!.withAlphaComponent(0.7).cgColor)
        for i in 0...n {
            var gx = cx + 10 + i * 2
            if olhandoEsquerda { gx = Sprite.largura - 1 - gx - 3 }
            let zx = CGFloat(gx) * px
            let zy = origem.y + CGFloat(cy - 2 - i * 4) * px
            for (yy, l) in Sprite.z.enumerated() {
                for (xx, c) in l.enumerated() where c == "o" {
                    ctx.fill(CGRect(x: zx + CGFloat(xx) * zpx, y: zy + CGFloat(yy) * zpx, width: zpx, height: zpx))
                }
            }
        }
    }
}

// MARK: - Passos

/// Uma coisinha que o gato faz. A fila de passos é o "roteiro" dele.
enum Passo {
    case ir(alvo: () -> CGFloat, vel: CGFloat)             // anda até o x (canto esquerdo da janela)
    case pose(Pose, dur: Double)
    case pulo(alvo: () -> CGFloat, altura: CGFloat, dur: Double)
    case emote(Emote, dur: Double)                          // instantâneo: mostra o balão por um tempo
    case olhar(Gato)                                        // instantâneo: vira pro outro gato
    case virar                                              // instantâneo: vira pro outro lado
    case chamar(() -> Void)                                 // instantâneo
}

// MARK: - Gato

final class Gato {
    let janela: NSPanel
    let view: GatoView
    let idConfig: UUID
    var cfg: GatoConfig { Config.shared.gatos.first { $0.id == idConfig } ?? Config.shared.gatos[0] }
    var jeito: Personalidade { Personalidade.por(cfg.personalidade) }

    var x: CGFloat
    var chaoAtual: CGFloat
    var info: InfoDock

    var fila: [Passo] = []
    var atual: Passo?
    var inicioPasso: TimeInterval = 0
    var xInicioPasso: CGFloat = 0
    var emoteAte: TimeInterval = 0
    var proxPiscada: TimeInterval = .random(in: 1...4)
    var interagindo = false
    var variacao: CGFloat = .random(in: 0.85...1.15)   // cada gato com o seu passo
    var historico: [String] = []                       // últimos passos, para o raio-x

    func estado() -> String {
        let f = janela.frame
        return """
        \(cfg.nome) (\(jeito.nome), \(cfg.pelagem)) x=\(Int(x)) chão=\(Int(chaoAtual)) dy=\(Int(view.dy)) pose=\(view.pose) \
        esquerda=\(view.olhandoEsquerda) interagindo=\(interagindo) atual=\(descreve(atual)) fila=\(fila.map { descreve($0, calcula: false) }) \
        janela=(\(Int(f.minX)),\(Int(f.minY)),\(Int(f.width))x\(Int(f.height))) visível=\(janela.isVisible) faixa=\(Int(faixaX.lowerBound))...\(Int(faixaX.upperBound))
          histórico: \(historico.suffix(15).joined(separator: " > "))
        """
    }

    func descreve(_ p: Passo?, calcula: Bool = true) -> String {
        switch p {
        case .none: return "nada"
        case .ir(let a, let v): return calcula ? "ir(\(Int(a())),v\(v))" : "ir(v\(v))"
        case .pose(let p, let d): return "\(p)(\(String(format: "%.1f", d))s)"
        case .pulo(let a, _, _): return calcula ? "pulo(\(Int(a())))" : "pulo"
        case .emote(let e, _): return "emote(\(e))"
        case .olhar: return "olhar"
        case .virar: return "virar"
        case .chamar: return "chamar"
        }
    }

    var largura: CGFloat { CGFloat(Sprite.largura) * view.px }
    var centro: CGFloat { x + largura / 2 }
    var pulando: Bool { if case .pulo = atual { return true }; return false }
    var dormindo: Bool { view.pose == .dormindo || view.pose == .cochilando }
    var tamanho: NSSize { NSSize(width: largura, height: CGFloat(Sprite.altura + Sprite.margemTopo) * view.px) }

    init(config: GatoConfig, info: InfoDock) {
        idConfig = config.id
        self.info = info
        view = GatoView(frame: .zero)
        view.pelagem = Pelagem.por(config.pelagem)
        view.px = CGFloat(config.tamanho)
        janela = NSPanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        janela.isOpaque = false
        janela.backgroundColor = .clear
        janela.hasShadow = false
        janela.ignoresMouseEvents = true
        janela.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.dockWindow)) + 1)
        janela.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        janela.contentView = view
        let lo = info.faixa.lowerBound, hi = max(lo + 1, info.faixa.upperBound - CGFloat(Sprite.largura) * view.px)
        x = .random(in: lo...hi)
        chaoAtual = info.chao
        ajustaTamanho()
        janela.orderFrontRegardless()
    }

    func ajustaTamanho() {
        view.px = CGFloat(cfg.tamanho)
        janela.setContentSize(tamanho)
        view.frame = NSRect(origin: .zero, size: tamanho)
        view.needsDisplay = true
    }

    func fecha() { janela.orderOut(nil) }

    // MARK: Lugares

    var faixaX: ClosedRange<CGFloat> {
        let lo = info.faixa.lowerBound
        return lo...max(lo + 1, info.faixa.upperBound - largura)
    }

    func xQualquer() -> CGFloat {
        let f = faixaX
        var novo = CGFloat.random(in: f)
        if abs(novo - x) < 60 { novo = x < (f.lowerBound + f.upperBound) / 2 ? min(f.upperBound, x + 160) : max(f.lowerBound, x - 160) }
        return novo
    }

    /// Um ponto bem longe do outro gato (para fugir).
    func xLongeDe(_ outro: Gato) -> CGFloat {
        let f = faixaX
        let paraEsquerda = outro.centro > centro
        let alvo = paraEsquerda ? max(f.lowerBound, outro.x - largura * 2.5) : min(f.upperBound, outro.x + largura * 2.5)
        if abs(alvo - x) < 20 { return paraEsquerda ? f.lowerBound : f.upperBound }
        return alvo
    }

    // MARK: Roteiro sozinho

    func decideSozinho() -> [Passo] {
        let c = cfg
        var pesos = jeito.pesos
        if !c.podeSentar { for k in [Solo.sentar, .cochilo, .bocejo, .olharEmVolta] { pesos[k] = 0 } }
        if !c.podeDormir { pesos[.dormir] = 0; pesos[.cochilo] = 0 }
        // depois de ficar parado, quase sempre volta a andar
        if case .pose = atual { pesos[.andar, default: 0] += 3 }
        let total = pesos.values.reduce(0, +)
        var sorte = Double.random(in: 0..<max(total, 0.001))
        var escolha: Solo = .andar
        for k in Solo.allCases {
            let v = pesos[k] ?? 0
            if v <= 0 { continue }
            if sorte < v { escolha = k; break }
            sorte -= v
        }
        let destino = xQualquer()
        switch escolha {
        case .andar: return [.ir(alvo: { destino }, vel: 1)]
        case .correr: return [.ir(alvo: { destino }, vel: 2.3)]
        case .sentar: return [.pose(.sentado, dur: .random(in: 3...9))]
        case .dormir: return [.pose(.bocejando, dur: 1.3), .pose(.dormindo, dur: .random(in: 15...40))]
        case .tapaNoAr: return [.emote(.raiva, dur: 1.2), .pose(.arrepiado, dur: 0.8), .pose(.tapa, dur: 1.3), .pose(.sentado, dur: 1.5)]
        case .arrepiar: return [.pose(.arrepiado, dur: 1.6), .virar, .pose(.arrepiado, dur: 1.0)]
        case .bocejo: return [.pose(.bocejando, dur: 1.5), .pose(.sentado, dur: .random(in: 2...4))]
        case .cochilo: return [.pose(.cochilando, dur: .random(in: 6...12)), .pose(.bocejando, dur: 1.2)]
        case .espreguicar: return [.pose(.espreguicando, dur: 2.4), .pose(.sentado, dur: 1.5)]
        case .pular:
            let dir: CGFloat = view.olhandoEsquerda ? -1 : 1
            return [.pulo(alvo: { [unowned self] in self.xInicioPasso + dir * 34 }, altura: 9 * view.px, dur: 0.5),
                    .pulo(alvo: { [unowned self] in self.xInicioPasso + dir * 26 }, altura: 6 * view.px, dur: 0.42),
                    .ir(alvo: { destino }, vel: 1.6)]
        case .girar:
            var p: [Passo] = []
            for _ in 0..<8 { p += [.virar, .pose(.andando, dur: 0.14)] }
            return p + [.pose(.sentado, dur: 1.2)]
        case .seLamber: return [.pose(.lambendo, dur: 2.6), .emote(.coracao, dur: 1.6), .pose(.sentadoFeliz, dur: 2)]
        case .cheirar: return [.pose(.cheirando, dur: 2.2), .emote(.interrogacao, dur: 1.2), .pose(.sentado, dur: 1.2)]
        case .olharEmVolta:
            return [.pose(.sentado, dur: 0.8), .emote(.interrogacao, dur: 1.4), .virar, .pose(.sentado, dur: 0.8), .virar, .pose(.sentado, dur: 0.8)]
        case .susto:
            let fuga = view.olhandoEsquerda ? faixaX.upperBound : faixaX.lowerBound
            return [.emote(.exclamacao, dur: 1.2), .pulo(alvo: { [unowned self] in self.xInicioPasso }, altura: 7 * view.px, dur: 0.35),
                    .pose(.arrepiado, dur: 0.6), .ir(alvo: { fuga }, vel: 2.6)]
        }
    }

    /// Troca o roteiro (usado pelas interações).
    func roteiro(_ passos: [Passo], agora: TimeInterval) {
        fila = passos
        atual = nil
        interagindo = true
        view.dy = 0
        proximo(agora)
    }

    private func proximo(_ agora: TimeInterval) {
        // os instantâneos rodam na hora
        for _ in 0..<50 {
            if fila.isEmpty {
                interagindo = false
                fila = decideSozinho()
            }
            let p = fila.removeFirst()
            switch p {
            case .emote(let e, let dur): view.emote = e; emoteAte = agora + dur; continue
            case .olhar(let g): view.olhandoEsquerda = g.centro < centro; continue
            case .virar: view.olhandoEsquerda.toggle(); continue
            case .chamar(let f): f(); continue
            default: break
            }
            atual = p
            historico.append(descreve(p, calcula: false)); if historico.count > 40 { historico.removeFirst(10) }
            inicioPasso = agora
            xInicioPasso = x
            view.tempoPose = 0
            return
        }
    }

    // MARK: Quadro a quadro

    func passo(agora: TimeInterval, dt: CGFloat, info: InfoDock) {
        self.info = info
        view.tempo += dt
        view.tempoPose += dt
        if atual == nil { proximo(agora) }

        switch atual {
        case .ir(let alvo, let vel):
            let a = alvo().clamped(faixaX.lowerBound, faixaX.upperBound)
            let velocidade = CGFloat(cfg.velocidade * jeito.velocidade) * variacao * vel
            let mov = min(abs(a - x), velocidade * dt)
            if mov > 0.01 { view.olhandoEsquerda = a < x }
            x += (a < x ? -1 : 1) * mov
            view.pose = .andando
            view.fase += mov / (view.px * (vel > 1.8 ? 1.7 : 2.2))
            if abs(a - x) < 0.5 || agora - inicioPasso > 25 { proximo(agora) }
        case .pose(let p, let dur):
            view.pose = p
            if p == .andando { view.fase += dt * 9 }
            if agora - inicioPasso >= dur { proximo(agora) }
        case .pulo(let alvo, let altura, let dur):
            let u = CGFloat(min(1, (agora - inicioPasso) / dur))
            let a = alvo().clamped(faixaX.lowerBound, faixaX.upperBound)
            if abs(a - xInicioPasso) > 0.5 { view.olhandoEsquerda = a < xInicioPasso }
            x = xInicioPasso + (a - xInicioPasso) * u
            view.dy = 4 * altura * u * (1 - u)
            view.pose = .andando
            view.fase = 0
            if u >= 1 { view.dy = 0; proximo(agora) }
        default: break
        }

        let f = faixaX
        if x < f.lowerBound || x > f.upperBound { x = x.clamped(f.lowerBound, f.upperBound) }
        chaoAtual = info.chao

        if agora > emoteAte { view.emote = nil }
        if agora > proxPiscada { view.piscando = true; proxPiscada = agora + .random(in: 2.5...6) }
        else if view.piscando && agora > proxPiscada - 2.35 { view.piscando = false }

        janela.setFrameOrigin(NSPoint(x: x.rounded(), y: (chaoAtual - view.px).rounded()))
        view.needsDisplay = true
    }
}
