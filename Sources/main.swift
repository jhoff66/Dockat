import SwiftUI
import AppKit
import ApplicationServices

final class AppDelegate: NSObject, NSApplicationDelegate {
    var bando: Bando!
    var item: NSStatusItem!
    let ajustes = JanelaAjustes()

    func applicationDidFinishLaunching(_ n: Notification) {
        bando = Bando()
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.image = Sprite.iconeBarraDeMenu()
        item.button?.toolTip = "Dockat"

        let menu = NSMenu()
        let aj = NSMenuItem(title: "Gatos e ajustes…", action: #selector(abreAjustes), keyEquivalent: ",")
        aj.target = self
        menu.addItem(aj)
        let acc = NSMenuItem(title: "Medir o Dock certinho (Acessibilidade)…", action: #selector(pedirAcessibilidade), keyEquivalent: "")
        acc.target = self
        menu.addItem(acc)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Sair do Dockat", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        item.menu = menu
    }

    @objc func abreAjustes() { ajustes.mostra() }

    @objc func pedirAcessibilidade() {
        let op = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        if !AXIsProcessTrustedWithOptions(op) {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
        }
    }
}

// `--snapshot pasta` salva as poses de cada pelagem em PNG, para conferir o desenho.
if CommandLine.arguments.count > 2, CommandLine.arguments[1] == "--snapshot" {
    let pasta = CommandLine.arguments[2]
    let px: CGFloat = 8
    let poses: [(Pose, Int, Emote?)] = [(.andando, 0, nil), (.arrepiado, 0, .raiva), (.tapa, 0, nil), (.tapa, 1, nil),
        (.lambendo, 0, .coracao), (.espreguicando, 0, nil), (.bocejando, 0, nil), (.cheirando, 0, .interrogacao),
        (.cochilando, 0, nil), (.sentadoFeliz, 0, .exclamacao), (.dormindo, 0, nil)]
    let alt = CGFloat(Sprite.altura + Sprite.margemTopo) * px
    let w = CGFloat(Sprite.largura) * px
    for p in Pelagem.todas {
        let img = NSImage(size: NSSize(width: w * CGFloat(poses.count), height: alt), flipped: true) { _ in
            let ctx = NSGraphicsContext.current!.cgContext
            ctx.setFillColor(NSColor(white: 0.9, alpha: 1).cgColor); ctx.fill(CGRect(x: 0, y: 0, width: w * CGFloat(poses.count), height: alt))
            for (i, (pose, q, emote)) in poses.enumerated() {
                let origem = CGPoint(x: CGFloat(i) * w, y: CGFloat(Sprite.margemTopo) * px)
                Sprite.pinta(ctx, pelagem: p, camadas: Sprite.camadas(pose: pose, quadro: q, rabo: 0, piscando: false, respira: false),
                             px: px, origem: origem, espelhar: false)
                if let emote {
                    let (cx, cy) = Sprite.posCabeca(pose)
                    let gx = cx + 6 - emote.linhas[0].count / 2
                    emote.pinta(ctx, x: origem.x + CGFloat(gx) * px, y: origem.y + CGFloat(cy - emote.linhas.count - 2) * px, px: px)
                }
            }
            return true
        }
        let rep = NSBitmapImageRep(data: img.tiffRepresentation!)!
        try? rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "\(pasta)/\(p.id).png"))
    }
    // confere se toda linha de cada camada tem a mesma largura
    for pose in Pose.allCases {
        for q in 0..<2 {
            for c in Sprite.camadas(pose: pose, quadro: q, rabo: q, piscando: false, respira: false) {
                let l = Set(c.linhas.map(\.count))
                if l.count > 1 { print("largura irregular em \(pose): \(c.linhas.map(\.count))") }
            }
        }
    }
    // folhas de sugestão
    for (nome, v) in [("sug-pelagem", AnyView(SugerirPelagem())), ("sug-personalidade", AnyView(SugerirPersonalidade()))] {
        let h = NSHostingView(rootView: v.background(Color(nsColor: .windowBackgroundColor)))
        h.appearance = NSAppearance(named: .darkAqua)
        h.frame = NSRect(origin: .zero, size: h.fittingSize)
        let jw = NSWindow(contentRect: h.frame, styleMask: [.titled], backing: .buffered, defer: false)
        jw.contentView = h
        h.layoutSubtreeIfNeeded()
        if let rep = h.bitmapImageRepForCachingDisplay(in: h.bounds) {
            h.cacheDisplay(in: h.bounds, to: rep)
            try? rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "\(pasta)/\(nome).png"))
        }
    }
    print(Sugestao.url(["tipo": "Pelagem", "nome": "Lilás + galáctico", "cores": "pelo #9E7ACC, olhos #FACC40", "detalhes": "mancha no olho & rabo"])!.absoluteString)

    // janela de ajustes
    let host = NSHostingView(rootView: AjustesView())
    host.appearance = NSAppearance(named: .darkAqua)
    host.frame = NSRect(origin: .zero, size: host.fittingSize)
    let jan = NSWindow(contentRect: host.frame, styleMask: [.titled], backing: .buffered, defer: false)
    jan.contentView = host
    host.layoutSubtreeIfNeeded()
    if let rep = host.bitmapImageRepForCachingDisplay(in: host.bounds) {
        host.cacheDisplay(in: host.bounds, to: rep)
        try? rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "\(pasta)/ajustes.png"))
    }
    exit(0)
}

// `--diagnostico arquivo` grava por 6 s o que o app enxerga do Dock (permissão, quadro AX, janela).
if CommandLine.arguments.count > 2, CommandLine.arguments[1] == "--diagnostico" {
    var saida = "trusted=\(AXIsProcessTrusted())\n"
    let ini = CACurrentMediaTime()
    let leitor = LeitorDock()
    var ultimo = ""
    while CACurrentMediaTime() - ini < 6 {
        let linha = leitor.diagnostico()
        if linha != ultimo { saida += String(format: "%.3f ", CACurrentMediaTime() - ini) + linha + "\n"; ultimo = linha }
        usleep(4000)
    }
    try? saida.write(toFile: CommandLine.arguments[2], atomically: true, encoding: .utf8)
    exit(0)
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
