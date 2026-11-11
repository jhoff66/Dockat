import AppKit

final class Bando {
    let leitor = LeitorDock()
    var gatos: [Gato] = []
    var info: InfoDock
    var ultimo = CACurrentMediaTime()
    var ultimaLeitura: TimeInterval = 0

    // Animação do Dock que se esconde sozinho: o gato desce/sobe no mesmo ritmo.
    var dockArriba = false          // para onde o gato está indo (true = em cima do Dock)
    var animIni: TimeInterval = 0
    var animDe: CGFloat = 0
    var previuEsconder: TimeInterval? // quando o mouse saiu e a gente adiantou a descida
    let duracaoAnim: TimeInterval = 0.26
    var ultimaJanela: TimeInterval = 0
    var janelaDock = false
    var podePrever = true            // só prevê de novo depois que o mouse voltar ao Dock
    var esfriando: [String: TimeInterval] = [:]   // pares de gatos que acabaram de interagir

    init() {
        info = leitor.ler()
        dockArriba = leitor.dockVisivel()
        info.chao = dockArriba ? info.topo : info.base
        recria()
        // raio-x: `notifyutil`-like via notificação distribuída grava o estado dos gatos
        DistributedNotificationCenter.default().addObserver(forName: Notification.Name("app.dockat.raiox"), object: nil, queue: .main) { [weak self] _ in
            self?.gravaRaioX()
        }
        // teste: põe os dois primeiros gatos lado a lado para forçar um encontro
        DistributedNotificationCenter.default().addObserver(forName: Notification.Name("app.dockat.encontro"), object: nil, queue: .main) { [weak self] _ in
            guard let self, self.gatos.count > 1 else { return }
            self.esfriando = [:]
            let a = self.gatos[0], b = self.gatos[1]
            for g in [a, b] { g.roteiro([.pose(.sentado, dur: 3)], agora: CACurrentMediaTime()); g.interagindo = false }
            b.x = a.x + a.largura * 0.3
        }
        Config.shared.aoMudar = { [weak self] in
            DispatchQueue.main.async { self?.recria() }
        }
        let t = Timer(timeInterval: 1.0 / 60, repeats: true) { [weak self] _ in self?.passo() }
        t.tolerance = 0.002
        RunLoop.main.add(t, forMode: .common)
    }

    func recria() {
        let lista = Config.shared.gatos
        let ids = Set(lista.map(\.id))
        for g in gatos where !ids.contains(g.idConfig) { g.fecha() }
        gatos.removeAll { !ids.contains($0.idConfig) }
        for c in lista where !gatos.contains(where: { $0.idConfig == c.id }) {
            gatos.append(Gato(config: c, info: info))
        }
        for g in gatos {
            let c = g.cfg
            g.view.pelagem = Pelagem.por(c.pelagem)
            if g.view.px != CGFloat(c.tamanho) { g.ajustaTamanho() }
            g.view.needsDisplay = true
        }
    }

    func gravaRaioX() {
        var t = "dock: faixa=\(Int(info.faixa.lowerBound))...\(Int(info.faixa.upperBound)) chão=\(Int(info.chao)) topo=\(Int(info.topo)) base=\(Int(info.base)) arriba=\(dockArriba)\n"
        for g in gatos { t += g.estado() + "\n" }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("dockat-raiox.txt")
        try? t.write(to: url, atomically: true, encoding: .utf8)
        try? t.write(toFile: "/tmp/dockat-raiox.txt", atomically: true, encoding: .utf8)
    }

    private func vai(_ arriba: Bool, _ agora: TimeInterval) {
        guard arriba != dockArriba else { return }
        dockArriba = arriba
        animIni = agora
        animDe = info.chao
    }

    func acompanhaDock(_ agora: TimeInterval) {
        if !info.escondeSozinho { info.chao = info.topo; return }
        // a lista de janelas é a parte cara: 1 vez a cada 2 quadros já basta
        if agora - ultimaJanela > 0.03 { janelaDock = leitor.dockVisivel(); ultimaJanela = agora }
        let mouse = NSEvent.mouseLocation

        if mouse.y <= info.topo { podePrever = true }
        if janelaDock {
            if let t = previuEsconder {
                // a gente adiantou a descida, mas o Dock continuou lá (menu aberto, arrastando etc.)
                if agora - t > duracaoAnim + 0.35 { previuEsconder = nil; podePrever = false; vai(true, agora) }
                if mouse.y <= info.topo { previuEsconder = nil; vai(true, agora) }
            } else if dockArriba && podePrever && mouse.y > info.topo + 2 {
                // o Dock começa a descer assim que o mouse sai dele
                previuEsconder = agora
                vai(false, agora)
            } else if !dockArriba {
                vai(true, agora)
            }
        } else {
            previuEsconder = nil
            vai(false, agora)
        }

        let alvo = dockArriba ? info.topo : info.base
        let t = CGFloat(min(1, (agora - animIni) / duracaoAnim))
        let e = t * t * (3 - 2 * t)
        info.chao = animDe + (alvo - animDe) * e
    }

    func passo() {
        let agora = CACurrentMediaTime()
        let dt = CGFloat(min(0.05, agora - ultimo)); ultimo = agora
        let chaoAntes = info.chao
        if agora - ultimaLeitura > 0.5 { info = leitor.ler(); ultimaLeitura = agora }
        info.chao = chaoAntes
        acompanhaDock(agora)
        for g in gatos { g.passo(agora: agora, dt: dt, info: info) }
        confereEncontros(agora)
    }
}
