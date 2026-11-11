// Pede ao Dockat aberto para gravar o estado dos gatos em /tmp/dockat-raiox.txt
import Foundation
DistributedNotificationCenter.default().postNotificationName(Notification.Name("app.dockat.raiox"), object: nil, userInfo: nil, deliverImmediately: true)
usleep(300_000)
print((try? String(contentsOfFile: "/tmp/dockat-raiox.txt", encoding: .utf8)) ?? "sem resposta (o Dockat está aberto?)")
