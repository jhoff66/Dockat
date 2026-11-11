import SwiftUI

// MARK: - Pixel art no SwiftUI

private func pintaPixels(_ ctx: GraphicsContext, pelagem: Pelagem, camadas: [Camada], px: CGFloat, origem: CGPoint, espelhar: Bool, largura: Int = Sprite.largura) {
    for c in camadas {
        for (ly, linha) in c.linhas.enumerated() {
            for (lx, ch) in linha.enumerated() {
                guard ch != ".", let cor = pelagem.cor(ch) else { continue }
                var gx = c.x + lx
                if espelhar { gx = largura - 1 - gx }
                let r = CGRect(x: origem.x + CGFloat(gx) * px, y: origem.y + CGFloat(c.y + ly) * px, width: px + 0.25, height: px + 0.25)
                ctx.fill(Path(r), with: .color(Color(nsColor: cor)))
            }
        }
    }
}

/// Só a cabeça do gato, para avatares e amostras de pelagem.
struct CabecaPixel: View {
    let pelagem: Pelagem
    var px: CGFloat = 3
    var body: some View {
        Canvas { ctx, _ in
            pintaPixels(ctx, pelagem: pelagem, camadas: [Camada(linhas: Sprite.cabeca, x: 0, y: 0)], px: px, origem: .zero, espelhar: false, largura: 12)
        }
        .frame(width: 12 * px, height: 12 * px)
    }
}

/// Prévia ao vivo: o gato anda de um lado pro outro em cima de um Dock de mentirinha.
struct Palco: View {
    let config: GatoConfig
    private let alturaDock: CGFloat = 20

    var body: some View {
        TimelineView(.animation) { linha in
            Canvas { ctx, tam in
                let t = linha.date.timeIntervalSinceReferenceDate
                let px = CGFloat(config.tamanho)
                let largGato = CGFloat(Sprite.largura) * px
                let altGato = CGFloat(Sprite.altura) * px

                // Dock
                let dock = CGRect(x: 28, y: tam.height - alturaDock - 14, width: tam.width - 56, height: alturaDock)
                ctx.fill(Path(roundedRect: dock, cornerRadius: 8), with: .color(.primary.opacity(0.09)))
                let passo = (dock.width - 24) / 9
                for i in 0..<9 {
                    let lado: CGFloat = 12
                    let r = CGRect(x: dock.minX + 12 + CGFloat(i) * passo + (passo - lado) / 2, y: dock.midY - lado / 2, width: lado, height: lado)
                    ctx.fill(Path(roundedRect: r, cornerRadius: 3.5), with: .color(.primary.opacity(0.10)))
                }

                // vai e volta pela largura do Dock
                let percurso = max(1, dock.width - largGato)
                let dist = t * config.velocidade * Personalidade.por(config.personalidade).velocidade
                let volta = dist.truncatingRemainder(dividingBy: Double(percurso * 2))
                let indo = volta < Double(percurso)
                let x = dock.minX + (indo ? CGFloat(volta) : percurso * 2 - CGFloat(volta))
                let fase = Int(dist / Double(px * 2.2))
                let piscando = t.truncatingRemainder(dividingBy: 4.2) < 0.15
                let camadas = Sprite.camadas(pose: .andando, quadro: fase, rabo: [0, 1, 2, 1][Int(t * 2.5) % 4], piscando: piscando, respira: false)
                let origem = CGPoint(x: x.rounded(), y: (dock.minY - altGato + px).rounded())
                pintaPixels(ctx, pelagem: Pelagem.por(config.pelagem), camadas: camadas, px: px, origem: origem, espelhar: !indo)
            }
        }
    }
}

// MARK: - Janela

struct AjustesView: View {
    @ObservedObject var c = Config.shared
    @State private var atual = 0
    @State private var sugestao: Sugestao?

    private var i: Int { min(atual, c.gatos.count - 1) }
    private var gato: Binding<GatoConfig> {
        Binding(get: { c.gato(i) }, set: { novo in if c.gatos.indices.contains(i) { c.gatos[i] = novo } })
    }
    private var tamanhoPct: Binding<Double> {
        Binding(get: { (gato.wrappedValue.tamanho - 1) / 3 * 100 },
                set: { gato.wrappedValue.tamanho = 1 + $0 / 100 * 3 })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            seletor
                .padding(.horizontal, 24)
                .padding(.top, 40)      // abaixo dos botões da janela
                .padding(.bottom, 16)

            palco
                .padding(.horizontal, 24)

            VStack(alignment: .leading, spacing: 22) {
                pelagens
                personalidades
                comportamento
            }
            .padding(24)

            Divider()
            HStack {
                Text("Abrir o Dockat quando ligar o Mac")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Spacer()
                Toggle("", isOn: $c.abrirNoLogin).labelsHidden().toggleStyle(.switch).controlSize(.small)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
        }
        .frame(width: 540)
        .fixedSize(horizontal: false, vertical: true)
        .sheet(item: $sugestao) { tipo in
            switch tipo {
            case .pelagem: SugerirPelagem()
            case .personalidade: SugerirPersonalidade()
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // Avatares dos gatos + botão de adicionar
    private var seletor: some View {
        HStack(alignment: .top, spacing: 14) {
            ForEach(Array(c.gatos.enumerated()), id: \.element.id) { idx, g in
                let sel = idx == i
                Button { withAnimation(.snappy(duration: 0.2)) { atual = idx } } label: {
                    VStack(spacing: 6) {
                        CabecaPixel(pelagem: Pelagem.por(g.pelagem), px: 3)
                            .frame(width: 54, height: 54)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Color.primary.opacity(sel ? 0.08 : 0.04)))
                            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(sel ? Color.accentColor : .clear, lineWidth: 2))
                        Text(g.nome.isEmpty ? "Gato \(idx + 1)" : g.nome)
                            .font(.caption.weight(sel ? .semibold : .regular))
                            .foregroundStyle(sel ? .primary : .secondary)
                            .lineLimit(1)
                            .frame(maxWidth: 64)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .contextMenu {
                    if c.gatos.count > 1 {
                        Button("Remover do Dock", role: .destructive) { remove(idx) }
                    }
                }
            }

            if c.gatos.count < Config.maximo {
                Button {
                    withAnimation(.snappy(duration: 0.2)) { if let novo = c.adiciona() { atual = novo } }
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(.secondary)
                            .frame(width: 54, height: 54)
                            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.primary.opacity(0.18), style: StrokeStyle(lineWidth: 1.5, dash: [4, 3])))
                        Text("Adicionar").font(.caption).foregroundStyle(.secondary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Até \(Config.maximo) gatos no Dock")
            }
            Spacer(minLength: 0)
        }
    }

    // Nome + prévia ao vivo
    private var palco: some View {
        ZStack(alignment: .topLeading) {
            Palco(config: gato.wrappedValue)
                .frame(height: 150)

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    TextField("Nome", text: gato.nome, prompt: Text("Gato \(i + 1)"))
                        .textFieldStyle(.plain)
                        .font(.title2.weight(.semibold))
                    Text("\(Pelagem.por(gato.wrappedValue.pelagem).nome), \(Personalidade.por(gato.wrappedValue.personalidade).nome.lowercased())")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if c.gatos.count > 1 {
                    Button { remove(i) } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 13))
                            .frame(width: 28, height: 28)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.secondary)
                    .help("Tirar este gato do Dock")
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 14)
        }
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.primary.opacity(0.035)))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.primary.opacity(0.06)))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // Fileira de pelagens
    private var pelagens: some View {
        VStack(alignment: .leading, spacing: 10) {
            cabecalho("Pelagem", botao: "Sugerir cor", icone: "paintpalette", .pelagem)
            HStack(spacing: 8) {
                ForEach(Pelagem.todas) { p in
                    let sel = gato.wrappedValue.pelagem == p.id
                    Button { gato.wrappedValue.pelagem = p.id } label: {
                        CabecaPixel(pelagem: p, px: 3)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.primary.opacity(sel ? 0.08 : 0.035)))
                            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(sel ? Color.accentColor : .clear, lineWidth: 2))
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .help(p.nome)
                }
            }
        }
    }

    private func cabecalho(_ titulo: String, botao: String, icone: String, _ tipo: Sugestao) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(titulo).font(.headline)
            Spacer()
            Button { sugestao = tipo } label: {
                Label(botao, systemImage: icone).font(.callout)
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
            .help("Mande sua ideia pro criador do Dockat")
        }
    }

    private var personalidades: some View {
        let jeito = Personalidade.por(gato.wrappedValue.personalidade)
        return VStack(alignment: .leading, spacing: 10) {
            cabecalho("Personalidade", botao: "Sugerir personalidade", icone: "lightbulb", .personalidade)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 112), spacing: 8)], spacing: 8) {
                ForEach(Personalidade.todas) { p in
                    let sel = jeito.id == p.id
                    Button { gato.wrappedValue.personalidade = p.id } label: {
                        HStack(spacing: 6) {
                            Image(systemName: p.icone)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(sel ? Color.accentColor : .secondary)
                                .frame(width: 16)
                            Text(p.nome).font(.callout).lineLimit(1).minimumScaleFactor(0.85)
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 9)
                        .frame(height: 34)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.primary.opacity(sel ? 0.08 : 0.035)))
                        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(sel ? Color.accentColor : .clear, lineWidth: 1.5))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            Text(jeito.descricao)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var comportamento: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Comportamento").font(.headline)
            VStack(spacing: 0) {
                linhaSlider("Tamanho", valor: tamanhoPct, faixa: 0...100, min: "Pequeno", max: "Grande", numero: true)
                Divider().padding(.leading, 14)
                linhaSlider("Velocidade", valor: gato.velocidade, faixa: 12...80, min: "Devagar", max: "Rápido")
                Divider().padding(.leading, 14)
                linhaToggle("Senta para descansar", gato.podeSentar)
                Divider().padding(.leading, 14)
                linhaToggle("Tira cochilos", gato.podeDormir)
            }
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.primary.opacity(0.035)))
        }
    }

    private func linhaSlider(_ titulo: String, valor: Binding<Double>, faixa: ClosedRange<Double>, min: String, max: String, numero: Bool = false) -> some View {
        HStack(spacing: 12) {
            Text(titulo).frame(width: 92, alignment: .leading)
            Text(min).font(.caption).foregroundStyle(.secondary).frame(width: 50, alignment: .trailing)
            Slider(value: valor, in: faixa)
                .controlSize(.small)
            Text(max).font(.caption).foregroundStyle(.secondary).frame(width: 46, alignment: .leading)
            Text(numero ? "\(Int(valor.wrappedValue.rounded()))" : "")
                .font(.callout.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 26, alignment: .trailing)
        }
        .padding(.horizontal, 14)
        .frame(height: 44)
    }

    private func linhaToggle(_ titulo: String, _ valor: Binding<Bool>) -> some View {
        HStack {
            Text(titulo)
            Spacer()
            Toggle("", isOn: valor).labelsHidden().toggleStyle(.switch).controlSize(.small)
        }
        .padding(.horizontal, 14)
        .frame(height: 44)
    }

    private func remove(_ idx: Int) {
        withAnimation(.snappy(duration: 0.2)) {
            c.remove(idx)
            atual = max(0, min(atual, c.gatos.count - 1))
        }
    }
}

final class JanelaAjustes {
    private var janela: NSWindow?

    func mostra() {
        if janela == nil {
            let w = NSWindow(contentViewController: NSHostingController(rootView: AjustesView()))
            w.title = "Dockat"
            w.titleVisibility = .hidden
            w.styleMask = [.titled, .closable, .fullSizeContentView]
            w.titlebarAppearsTransparent = true
            w.isReleasedWhenClosed = false
            w.center()
            janela = w
        }
        NSApp.activate(ignoringOtherApps: true)
        janela?.makeKeyAndOrderFront(nil)
    }
}
