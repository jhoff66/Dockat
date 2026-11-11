// Força um encontro entre os dois primeiros gatos e grava o raio-x a cada 0,25 s por 9 s
import Foundation
let dc = DistributedNotificationCenter.default()
dc.postNotificationName(Notification.Name("app.dockat.encontro"), object: nil, userInfo: nil, deliverImmediately: true)
var ultimo = ""
for i in 0..<36 {
    usleep(250_000)
    dc.postNotificationName(Notification.Name("app.dockat.raiox"), object: nil, userInfo: nil, deliverImmediately: true)
    usleep(30_000)
    let t = (try? String(contentsOfFile: "/tmp/dockat-raiox.txt", encoding: .utf8)) ?? ""
    let linhas = t.split(separator: "\n").filter { !$0.contains("histórico") && !$0.hasPrefix("dock") }
    let resumo = linhas.map { l -> String in
        let partes = l.split(separator: " ")
        return partes.filter { $0.hasPrefix("x=") || $0.hasPrefix("dy=") || $0.hasPrefix("pose=") || $0.hasPrefix("atual=") || $0.hasPrefix("esquerda=") }.joined(separator: " ")
    }.joined(separator: " | ")
    if resumo != ultimo { print(String(format: "%.2f", Double(i + 1) * 0.28), resumo); ultimo = resumo }
}
print((try? String(contentsOfFile: "/tmp/dockat-raiox.txt", encoding: .utf8)) ?? "")
