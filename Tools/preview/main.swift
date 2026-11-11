// Gera Assets/preview.png: uma ilustração do Dockat em ação (gatos passeando em cima do Dock).
// Uso: ./Tools/gerar-preview.sh
import AppKit

let saida = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "Assets/preview.png"
let W = 1600, H = 560
func cor(_ hex: UInt32, _ a: CGFloat = 1) -> CGColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 0xff) / 255, green: CGFloat((hex >> 8) & 0xff) / 255, blue: CGFloat(hex & 0xff) / 255, alpha: a).cgColor
}
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: W, pixelsHigh: H, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                           isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
let gc = NSGraphicsContext(bitmapImageRep: rep)!
NSGraphicsContext.current = gc
let ctx = gc.cgContext
ctx.translateBy(x: 0, y: CGFloat(H)); ctx.scaleBy(x: 1, y: -1)

// papel de parede
let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [cor(0x5B4FA5), cor(0xD9789C), cor(0xF7B267)] as CFArray, locations: [0, 0.65, 1])!
ctx.drawLinearGradient(grad, start: .zero, end: CGPoint(x: 0, y: H), options: [])

// barra de menus com o ícone do Dockat
ctx.setFillColor(cor(0x14102B, 0.55)); ctx.fill(CGRect(x: 0, y: 0, width: W, height: 36))
ctx.interpolationQuality = .none
Sprite.iconeBarraDeMenu().draw(in: NSRect(x: W - 190, y: 6, width: 24, height: 24))
ctx.setFillColor(cor(0xFFFFFF, 0.85))
for i in 0..<3 { ctx.fill(CGRect(x: W - 130 + i * 30, y: 16, width: 20, height: 4)) }
for i in 0..<4 { ctx.fill(CGRect(x: 24 + i * 52, y: 16, width: 36, height: 4)) }

// Dock
let dockTopo: CGFloat = 430
let dock = CGPath(roundedRect: CGRect(x: 120, y: dockTopo, width: 1360, height: 100), cornerWidth: 28, cornerHeight: 28, transform: nil)
ctx.addPath(dock); ctx.setFillColor(cor(0xFFFFFF, 0.28)); ctx.fillPath()
ctx.addPath(dock); ctx.setStrokeColor(cor(0xFFFFFF, 0.45)); ctx.setLineWidth(2); ctx.strokePath()
let icones: [UInt32] = [0x4FA3F7, 0x7ED957, 0xF2C94C, 0xF29DAA, 0xB48CF2, 0x5CD6C9, 0xF58B54, 0x6C7AE0, 0xE6E7EB, 0x8ED16F, 0xF2708B, 0x4FA3F7, 0xF2C94C, 0xB48CF2]
for (i, c) in icones.enumerated() {
    let r = CGRect(x: 150 + CGFloat(i) * 94, y: dockTopo + 14, width: 72, height: 72)
    ctx.addPath(CGPath(roundedRect: r, cornerWidth: 17, cornerHeight: 17, transform: nil)); ctx.setFillColor(cor(c)); ctx.fillPath()
}

// os gatos em cima do Dock
let px: CGFloat = 6
let cenas: [(String, Pose, Int, Emote?, Bool, CGFloat)] = [
    ("frajola", .andando, 0, nil, false, 110),
    ("laranja", .lambendo, 0, .coracao, false, 320),
    ("cinza", .sentadoFeliz, 0, .exclamacao, false, 520),
    ("branco", .tapa, 0, nil, true, 710),
    ("siames", .cheirando, 0, .interrogacao, false, 900),
    ("preto", .dormindo, 0, nil, false, 1075),
    ("rajado", .espreguicando, 0, nil, true, 1310),
]
for (id, pose, q, emote, espelhar, x) in cenas {
    let origem = CGPoint(x: x, y: dockTopo - CGFloat(Sprite.altura) * px + 2)
    let pel = Pelagem.por(id)
    Sprite.pinta(ctx, pelagem: pel, camadas: Sprite.camadas(pose: pose, quadro: q, rabo: 0, piscando: false, respira: false),
                 px: px, origem: origem, espelhar: espelhar)
    if let emote {
        let (cx, cy) = Sprite.posCabeca(pose)
        let gx = cx + 6 - emote.linhas[0].count / 2
        emote.pinta(ctx, x: origem.x + CGFloat(gx) * px, y: origem.y + CGFloat(cy - emote.linhas.count - 2) * px, px: px)
    }
}
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: saida))
