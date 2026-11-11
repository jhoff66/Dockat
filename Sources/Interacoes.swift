import AppKit

/// O que acontece quando dois gatos se encontram no Dock.
extension Bando {

    /// Confere os pares de gatos e começa um encontro quando dois ficam perto.
    func confereEncontros(_ agora: TimeInterval) {
        guard gatos.count > 1 else { return }
        for i in 0..<gatos.count {
            for j in (i + 1)..<gatos.count {
                let a = gatos[i], b = gatos[j]
                if a.interagindo || b.interagindo || a.pulando || b.pulando { continue }
                let chave = [a.idConfig.uuidString, b.idConfig.uuidString].sorted().joined()
                if (esfriando[chave] ?? 0) > agora { continue }
                guard abs(a.centro - b.centro) < min(a.largura, b.largura) * 0.75 else { continue }
                if a.dormindo && b.dormindo { continue }
                esfriando[chave] = agora + .random(in: 20...40)
                encontro(a, b, agora)
            }
        }
    }

    private func encontro(_ a: Gato, _ b: Gato, _ agora: TimeInterval) {
        // quem tem mais iniciativa puxa; quem está dormindo não puxa
        var (A, B) = a.jeito.iniciativa == b.jeito.iniciativa ? (Bool.random() ? (a, b) : (b, a))
            : (a.jeito.iniciativa > b.jeito.iniciativa ? (a, b) : (b, a))
        if A.dormindo { swap(&A, &B) }

        let jA = A.jeito.id, jB = B.jeito.id
        let bDormia = B.dormindo
        let poseB: Pose = bDormia ? .dormindo : .sentado
        let lado: CGFloat = A.centro < B.centro ? -1 : 1      // A fica deste lado de B
        let d = min(A.largura, B.largura) * 0.5

        // Lugares calculados na hora, porque os dois se mexem.
        let colado: () -> CGFloat = { [weak A, weak B] in
            guard let A, let B else { return 0 }
            return B.x + (B.largura - A.largura) / 2 + lado * d
        }
        let doOutroLado: () -> CGFloat = { [weak A, weak B] in
            guard let A, let B else { return 0 }
            return B.x + (B.largura - A.largura) / 2 - lado * d * 1.4
        }
        let aproxima = Passo.ir(alvo: colado, vel: 1.3)
        /// Foge para um ponto escolhido uma vez só, quando começa a correr.
        /// (Recalcular a cada quadro fazia o gato virar pra lá e pra cá quando o outro andava junto.)
        func longe(_ g: Gato, de o: Gato) -> Passo {
            var fixo: CGFloat?
            return .ir(alvo: { [weak g, weak o] in
                if let fixo { return fixo }
                guard let g, let o else { return 0 }
                let v = g.xLongeDe(o)
                fixo = v
                return v
            }, vel: 2.5)
        }
        func recua(_ g: Gato, de o: Gato) -> Passo {
            .pulo(alvo: { [weak g, weak o] in
                guard let g, let o else { return 0 }
                return g.xInicioPasso + (g.centro < o.centro ? -22 : 22)
            }, altura: 5 * g.view.px, dur: 0.32)
        }
        /// Passo de A que dá o roteiro de B na hora certa.
        func reage(_ passos: [Passo]) -> Passo {
            .chamar { [weak B] in B?.roteiro(passos, agora: CACurrentMediaTime()) }
        }
        let foge: [Passo] = [.olhar(A), .emote(.exclamacao, dur: 1.2), recua(B, de: A), .pose(.arrepiado, dur: 0.5), longe(B, de: A)]

        A.janela.orderFrontRegardless()
        // B fica parado olhando enquanto A chega
        B.roteiro(bDormia ? [.pose(.dormindo, dur: 8)] : [.olhar(A), .pose(.sentado, dur: 8)], agora: agora)

        var roteiroA: [Passo]

        // Medroso foge de quem chega com tudo
        if jB == "medroso" && ["brigao", "brincalhao", "curioso"].contains(jA) {
            roteiroA = [.olhar(B), .pose(.sentado, dur: 0.3),
                        reage([.olhar(A), .emote(.exclamacao, dur: 1.2), .pose(.arrepiado, dur: 0.6), longe(B, de: A)]),
                        .pose(.sentado, dur: 1.0), .emote(.interrogacao, dur: 1.4), .pose(.sentado, dur: 1.4)]
            A.roteiro(roteiroA, agora: agora)
            return
        }

        switch jA {
        case "brigao":
            if jB == "brigao" {
                // briga de verdade: os dois arrepiam e trocam tapa
                let briga: [Passo] = [.emote(.raiva, dur: 2.6), .pose(.arrepiado, dur: 0.9), .pose(.tapa, dur: 1.4), .pose(.arrepiado, dur: 0.6)]
                roteiroA = [aproxima, .olhar(B), reage([.olhar(A)] + briga + [.pose(.sentado, dur: 1.5)])]
                    + briga + [.virar, longe(A, de: B)]
            } else {
                // arrepia, bate e o outro sai correndo
                roteiroA = [aproxima, .olhar(B),
                            reage([.olhar(A), .pose(poseB, dur: 1.0)] + foge),
                            .emote(.raiva, dur: 1.6), .pose(.arrepiado, dur: 0.8), .pose(.tapa, dur: 0.9), .pose(.sentado, dur: 2.0)]
            }

        case "carinhoso":
            if jB == "brigao" {
                // tenta lamber e leva um tapa
                roteiroA = [aproxima, .olhar(B),
                            reage([.olhar(A), .pose(.sentado, dur: 1.0), .emote(.raiva, dur: 1.2), .pose(.tapa, dur: 0.5), .pose(.sentado, dur: 1.5)]),
                            .pose(.lambendo, dur: 1.0), .emote(.exclamacao, dur: 1.0), recua(A, de: B), .pose(.sentado, dur: 1.4)]
            } else {
                let reacao: [Passo] = bDormia
                    ? [.pose(.dormindo, dur: 2.4), .emote(.coracao, dur: 1.6), .pose(.dormindo, dur: 6)]
                    : [.olhar(A), .emote(.coracao, dur: 2.6), .pose(.sentadoFeliz, dur: 2.6), .pose(.sentado, dur: 1.5)]
                roteiroA = [aproxima, .olhar(B), reage(reacao),
                            .emote(.coracao, dur: 2.4), .pose(.lambendo, dur: 2.4), .pose(.sentadoFeliz, dur: 2.0)]
            }

        case "dorminhoco":
            let dormeJunto = bDormia || ["dorminhoco", "preguicoso", "carinhoso"].contains(jB)
            let tempo = Double.random(in: 12...20)
            let reacao: [Passo] = dormeJunto
                ? [.olhar(A)] + (jB == "carinhoso" ? [.emote(.coracao, dur: 1.4)] : []) + [.pose(.sentado, dur: 1.3), .pose(.dormindo, dur: tempo)]
                : [.olhar(A), .emote(.interrogacao, dur: 1.4), .pose(.sentado, dur: 2.0)]
            roteiroA = [.ir(alvo: colado, vel: 0.8), .olhar(B), reage(reacao), .pose(.bocejando, dur: 1.3), .pose(.dormindo, dur: tempo)]

        case "preguicoso":
            // nem se levanta: deita ali mesmo
            roteiroA = [reage(bDormia ? [.pose(.dormindo, dur: 6)] : [.olhar(A), .emote(.interrogacao, dur: 1.2), .pose(.sentado, dur: 1.6)]),
                        .olhar(B), .pose(.bocejando, dur: 1.3), .pose(.espreguicando, dur: 2.2), .pose(.dormindo, dur: .random(in: 8...14))]

        case "brincalhao":
            // pula por cima do outro e sai correndo
            var reacao: [Passo] = [.pose(poseB, dur: 0.5), .emote(.exclamacao, dur: 1.2), .pose(.sentado, dur: 0.6), .olhar(A)]
            switch jB {
            case "brincalhao": reacao += [.ir(alvo: { [weak A] in A?.x ?? 0 }, vel: 2.4)]        // corre atrás
            case "brigao": reacao += [.emote(.raiva, dur: 1.4), .pose(.arrepiado, dur: 1.2)]
            default: reacao += [.emote(.interrogacao, dur: 1.2), .pose(.sentado, dur: 1.4)]
            }
            roteiroA = [.olhar(B), .pose(.sentado, dur: 0.35), reage(reacao),
                        .pulo(alvo: doOutroLado, altura: 15 * A.view.px, dur: 0.8),
                        .olhar(B), .pose(.sentado, dur: 0.4), longe(A, de: B)]

        case "curioso":
            if jB == "brigao" {
                roteiroA = [aproxima, .olhar(B),
                            reage([.olhar(A), .pose(.sentado, dur: 1.2), .emote(.raiva, dur: 1.2), .pose(.tapa, dur: 0.5), .pose(.sentado, dur: 1.4)]),
                            .pose(.cheirando, dur: 1.6), .emote(.exclamacao, dur: 1.0), recua(A, de: B), .pose(.sentado, dur: 1.0)]
            } else {
                let reacao: [Passo] = jB == "carinhoso"
                    ? [.olhar(A), .pose(.sentado, dur: 1.0), .emote(.coracao, dur: 1.6), .pose(.sentadoFeliz, dur: 2)]
                    : [.olhar(A), .pose(poseB, dur: 2.0), .emote(.interrogacao, dur: 1.2), .pose(.sentado, dur: 1.2)]
                roteiroA = [aproxima, .olhar(B), reage(reacao),
                            .pose(.cheirando, dur: 2.0), .emote(.interrogacao, dur: 1.4), .pose(.sentado, dur: 1.4)]
            }

        default: // medroso puxando: leva susto e foge
            roteiroA = [reage([.olhar(A), .emote(.interrogacao, dur: 1.4), .pose(poseB, dur: 1.6)]),
                        .olhar(B), .emote(.exclamacao, dur: 1.2), .pose(.arrepiado, dur: 0.6), longe(A, de: B)]
        }

        A.roteiro(roteiroA, agora: agora)
    }
}
