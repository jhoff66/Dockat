import AppKit
import ApplicationServices

// MARK: - Onde está o Dock

struct InfoDock {
    var faixa: ClosedRange<CGFloat>   // x onde o gato pode andar
    var chao: CGFloat                  // y onde o gato pisa agora (animado junto com o Dock)
    var topo: CGFloat = 0              // y do topo do Dock quando ele está à mostra
    var base: CGFloat = 0              // y da borda de baixo da tela
    var escondeSozinho = false
}

final class LeitorDock {
    private var avisouPermissao = false

    func ler() -> InfoDock {
        let tela = NSScreen.screens.first ?? NSScreen.main!
        let f = tela.frame
        let ladoInferior = (UserDefaults(suiteName: "com.apple.dock")?.string(forKey: "orientation") ?? "bottom") == "bottom"
        let visivel = dockVisivel()
        let autohide = UserDefaults(suiteName: "com.apple.dock")?.bool(forKey: "autohide") ?? false

        if AXIsProcessTrusted(), let r = quadroAX(alturaPrincipal: f.height), ladoInferior {
            let topo = max(r.maxY - 1, f.minY + 20)
            return InfoDock(faixa: (r.minX + 4)...(r.maxX - 4), chao: visivel ? topo : f.minY, topo: topo, base: f.minY, escondeSozinho: autohide)
        }

        // Sem permissão de Acessibilidade: estima pelo tamanho dos ícones.
        let d = UserDefaults(suiteName: "com.apple.dock")
        let tile = CGFloat(d?.double(forKey: "tilesize") ?? 48).clamped(16, 128)
        let apps = (d?.array(forKey: "persistent-apps")?.count ?? 10)
        let outros = (d?.array(forKey: "persistent-others")?.count ?? 0)
        let recentes = (d?.object(forKey: "show-recents") as? Bool ?? true) ? 3 : 0
        let n = CGFloat(apps + outros + recentes + 1)
        let largura = min(f.width - 20, n * tile * 1.04 + 24)
        // medido no Mac dele: tilesize 37 reserva 57 pt; o Dock em si termina ~2 pt antes
        let topo = f.minY + tile + 18
        return InfoDock(faixa: (f.midX - largura / 2 + 6)...(f.midX + largura / 2 - 6), chao: visivel ? topo : f.minY,
                        topo: topo, base: f.minY, escondeSozinho: autohide)
    }

    func diagnostico() -> String {
        let ax = quadroAX(alturaPrincipal: NSScreen.screens[0].frame.height).map { "\($0)" } ?? "sem-ax"
        return "visivel=\(dockVisivel()) ax=\(ax)"
    }

    // O Dock só tem janela na camada 20 quando está à mostra.
    func dockVisivel() -> Bool {
        let auto = UserDefaults(suiteName: "com.apple.dock")?.bool(forKey: "autohide") ?? false
        if !auto { return true }
        guard let lista = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] else { return true }
        return lista.contains { ($0[kCGWindowOwnerName as String] as? String) == "Dock" && ($0[kCGWindowLayer as String] as? Int) == 20 }
    }

    private func quadroAX(alturaPrincipal: CGFloat) -> CGRect? {
        guard let pid = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.dock").first?.processIdentifier else { return nil }
        let app = AXUIElementCreateApplication(pid)
        var filhos: CFTypeRef?
        guard AXUIElementCopyAttributeValue(app, kAXChildrenAttribute as CFString, &filhos) == .success,
              let lista = (filhos as? [AXUIElement])?.first(where: { el in
                  var r: CFTypeRef?; AXUIElementCopyAttributeValue(el, kAXRoleAttribute as CFString, &r)
                  return (r as? String) == "AXList"
              }) else { return nil }
        var pos: CFTypeRef?, tam: CFTypeRef?
        AXUIElementCopyAttributeValue(lista, kAXPositionAttribute as CFString, &pos)
        AXUIElementCopyAttributeValue(lista, kAXSizeAttribute as CFString, &tam)
        guard let pos, let tam else { return nil }
        var p = CGPoint.zero, s = CGSize.zero
        AXValueGetValue(pos as! AXValue, .cgPoint, &p)
        AXValueGetValue(tam as! AXValue, .cgSize, &s)
        guard s.width > 50 else { return nil }
        // AX usa origem no topo; o AppKit, embaixo.
        return CGRect(x: p.x, y: alturaPrincipal - p.y - s.height, width: s.width, height: s.height)
    }
}

extension CGFloat {
    func clamped(_ a: CGFloat, _ b: CGFloat) -> CGFloat { Swift.min(b, Swift.max(a, self)) }
}
