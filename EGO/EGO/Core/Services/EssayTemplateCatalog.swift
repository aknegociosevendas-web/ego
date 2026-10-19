import Foundation

/// Bundled essay scaffolds (docs/08 §2). Content data in PT-BR, seeded into
/// `EssayTemplate` rows on first launch.
enum EssayTemplateCatalog {
    static let enemKey = "enem-dissertativo"
    static let enemTitle = "ENEM — dissertativo-argumentativo"

    static let enemSections: [EssaySection] = [
        EssaySection(
            title: "Introdução",
            hint: "Contextualize o tema com um repertório (dado, fato histórico, citação) e feche o parágrafo apresentando a sua tese."
        ),
        EssaySection(
            title: "Desenvolvimento 1",
            hint: "Tópico frasal com o primeiro argumento + repertório legitimado + análise ligando o repertório ao tema."
        ),
        EssaySection(
            title: "Desenvolvimento 2",
            hint: "Aprofunde outra causa ou consequência. Use conectivos para amarrar com o parágrafo anterior (coesão)."
        ),
        EssaySection(
            title: "Conclusão — proposta de intervenção",
            hint: "Agente + ação + meio/modo + finalidade + detalhamento, sempre respeitando os direitos humanos."
        ),
    ]
}

/// ENEM rubric — 5 competências, 0–200 each (docs/08 §2).
enum EssayRubricCatalog {
    struct Competency: Identifiable, Equatable {
        let number: Int
        let title: String
        var id: Int { number }
    }

    static let enemKey = "enem-5c"
    static let maxPerCompetency = 200
    static let scoreStep = 40

    static let competencies: [Competency] = [
        Competency(number: 1, title: "Domínio da norma culta"),
        Competency(number: 2, title: "Compreensão da proposta e estrutura dissertativa"),
        Competency(number: 3, title: "Seleção e organização de argumentos"),
        Competency(number: 4, title: "Mecanismos linguísticos (coesão)"),
        Competency(number: 5, title: "Proposta de intervenção"),
    ]
}
