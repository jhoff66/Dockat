// Gera o logo do Dockat: Assets/Dockat.iconset + Assets/logo.png + Assets/menubar.png
// Uso: ./Tools/gerar-icone.sh
import AppKit

let saida = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "Assets"
try? FileManager.default.createDirectory(atPath: "\(saida)/Dockat.iconset", withIntermediateDirectories: true)

func png(_ lado: Int, _ desenho: (CGContext, CGFloat) -> Void) -> Data {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: lado, pixelsHigh: lado, bitsPerSample: 8, samplesPerPixel: 4,
                               hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    let gc = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = gc
    let ctx = gc.cgContext
    ctx.translateBy(x: 0, y: CGFloat(lado)); ctx.scaleBy(x: 1, y: -1)   // y para baixo
    desenho(ctx, CGFloat(lado))
    return rep.representation(using: .png, properties: [:])!
}

func cor(_ hex: UInt32) -> CGColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 0xff) / 255, green: CGFloat((hex >> 8) & 0xff) / 255, blue: CGFloat(hex & 0xff) / 255, alpha: 1).cgColor
}

func logo(_ ctx: CGContext, _ L: CGFloat) {
    ctx.setShouldAntialias(true)
    // placa arredondada no padrão do macOS (824/1024)
    let m = L * 100 / 1024, lado = L - 2 * m
    let placa = CGPath(roundedRect: CGRect(x: m, y: m, width: lado, height: lado), cornerWidth: lado * 0.225, cornerHeight: lado * 0.225, transform: nil)
    ctx.saveGState()
    ctx.addPath(placa); ctx.clip()
    let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [cor(0x4B3F8F), cor(0x231B4D)] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(grad, start: CGPoint(x: 0, y: m), end: CGPoint(x: 0, y: L - m), options: [])
    ctx.setShouldAntialias(false)

    // grade de 32 × 32 células dentro da placa
    let u = lado / 32
    func cel(_ x: Int, _ y: Int, _ w: Int = 1, _ h: Int = 1, _ c: UInt32) {
        ctx.setFillColor(cor(c))
        ctx.fill(CGRect(x: m + CGFloat(x) * u, y: m + CGFloat(y) * u, width: CGFloat(w) * u, height: CGFloat(h) * u))
    }
    // estrelinhas
    for (x, y) in [(4, 5), (27, 4), (25, 9), (6, 13), (29, 18)] { cel(x, y, 1, 1, 0xB9AEF5) }
    // o "dock": barra de vidro embaixo, com ícones minúsculos
    cel(3, 25, 26, 5, 0x3A3070)
    cel(3, 25, 26, 1, 0x5B4FA5)
    for (i, c) in [0xF29DAA, 0x7ED957, 0xF2C94C, 0x6AB0F0, 0xE6E7EB].enumerated() { cel(6 + i * 4, 27, 3, 2, UInt32(c)) }

    // o gatinho branco, sentado em cima do dock (cabeça 12 × 12, escala 2 → 24 células)
    var cores = Pelagem.por("branco").cores
    cores["o"] = 0x1B1536
    let pel = Pelagem(id: "logo", nome: "Logo", cores: cores)
    let s = 2
    let ox = (32 - 12 * s) / 2, oy = 25 - 12 * s
    for (ly, linha) in Sprite.cabeca.enumerated() {
        for (lx, ch) in linha.enumerated() {
            guard ch != ".", let c = pel.cores[ch] else { continue }
            cel(ox + lx * s, oy + ly * s, s, s, c)
        }
    }
    ctx.restoreGState()
}

for t in [16, 32, 128, 256, 512] {
    try! png(t, logo).write(to: URL(fileURLWithPath: "\(saida)/Dockat.iconset/icon_\(t)x\(t).png"))
    try! png(t * 2, logo).write(to: URL(fileURLWithPath: "\(saida)/Dockat.iconset/icon_\(t)x\(t)@2x.png"))
}
try! png(1024, logo).write(to: URL(fileURLWithPath: "\(saida)/logo.png"))

// ícone da barra de menus ampliado para o README (a versão do app é desenhada em Sprite.iconeBarraDeMenu)
let barra = Sprite.iconeBarraDeMenu()
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 36, pixelsHigh: 36, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                           isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
barra.draw(in: NSRect(x: 0, y: 0, width: 36, height: 36))
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "\(saida)/menubar.png"))
