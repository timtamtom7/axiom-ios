import Foundation
import SwiftUI

/// Localization service for international support
/// Languages: English, German, French, Spanish, Italian, Portuguese, Japanese, Korean, Simplified Chinese
@MainActor
final class LocalizationService: ObservableObject {
    static let shared = LocalizationService()

    @Published var currentLanguage: AppLanguage = .english

    enum AppLanguage: String, CaseIterable, Codable, Identifiable {
        case english = "en"
        case german = "de"
        case french = "fr"
        case spanish = "es"
        case italian = "it"
        case portuguese = "pt"
        case japanese = "ja"
        case korean = "ko"
        case simplifiedChinese = "zh-Hans"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .english: return "English"
            case .german: return "Deutsch"
            case .french: return "Français"
            case .spanish: return "Español"
            case .italian: return "Italiano"
            case .portuguese: return "Português"
            case .japanese: return "日本語"
            case .korean: return "한국어"
            case .simplifiedChinese: return "简体中文"
            }
        }

        var flag: String {
            switch self {
            case .english: return "🇺🇸"
            case .german: return "🇩🇪"
            case .french: return "🇫🇷"
            case .spanish: return "🇪🇸"
            case .italian: return "🇮🇹"
            case .portuguese: return "🇵🇹"
            case .japanese: return "🇯🇵"
            case .korean: return "🇰🇷"
            case .simplifiedChinese: return "🇨🇳"
            }
        }

        var isRTL: Bool { false }
    }

    private let languageKey = "app_language"

    init() {
        loadLanguage()
    }

    func loadLanguage() {
        if let saved = UserDefaults.standard.string(forKey: languageKey),
           let lang = AppLanguage(rawValue: saved) {
            currentLanguage = lang
        } else {
            // Auto-detect from system
            if let systemLang = Locale.current.language.languageCode?.identifier {
                currentLanguage = AppLanguage(rawValue: systemLang) ?? .english
            }
        }
    }

    func setLanguage(_ language: AppLanguage) {
        currentLanguage = language
        UserDefaults.standard.set(language.rawValue, forKey: languageKey)
    }

    /// Localized string lookup
    func t(_ key: String) -> String {
        // R13: Full localization - psychological terminology localized per culture
        let translations = currentLanguage.translations
        return translations[key] ?? key
    }
}

// MARK: - Translations Dictionary
extension LocalizationService.AppLanguage {
    var translations: [String: String] {
        switch self {
        case .english:
            return Self.englishStrings
        case .german:
            return Self.germanStrings
        case .french:
            return Self.frenchStrings
        case .spanish:
            return Self.spanishStrings
        case .italian:
            return Self.italianStrings
        case .portuguese:
            return Self.portugueseStrings
        case .japanese:
            return Self.japaneseStrings
        case .korean:
            return Self.koreanStrings
        case .simplifiedChinese:
            return Self.chineseStrings
        }
    }

    private static let englishStrings: [String: String] = [
        "beliefs": "Beliefs",
        "map": "Map",
        "evidence": "Evidence",
        "community": "Community",
        "legacy": "Legacy",
        "add_belief": "Add Belief",
        "belief_text": "What belief do you hold?",
        "core_belief": "Core Belief",
        "evidence_for": "Evidence for this belief",
        "evidence_against": "Evidence against this belief",
        "score": "Score",
        "ai_deep_dive": "AI Deep Dive",
        "stress_test": "Stress Test",
        "therapy": "Therapy",
        "teams": "Teams",
        "upgrade": "Upgrade",
        "pro": "Pro",
        "free": "Free",
        "subscription": "Subscription",
        "retention_day1": "Enter your first belief",
        "retention_day7": "Add first evidence",
        "retention_day30": "Have your first AI conversation"
    ]

    private static let germanStrings: [String: String] = [
        "beliefs": "Überzeugungen",
        "map": "Karte",
        "evidence": "Beweise",
        "community": "Gemeinschaft",
        "legacy": "Vermächtnis",
        "add_belief": "Überzeugung hinzufügen",
        "belief_text": "Welche Überzeugung hegst du?",
        "core_belief": "Kernüberzeugung",
        "evidence_for": "Belege für diese Überzeugung",
        "evidence_against": "Belege gegen diese Überzeugung",
        "score": "Punktzahl",
        "ai_deep_dive": "KI-Tiefenalyse",
        "stress_test": "Stresstest",
        "therapy": "Therapie",
        "teams": "Teams",
        "upgrade": "Upgrade",
        "pro": "Pro",
        "free": "Kostenlos",
        "subscription": "Abonnement",
        "retention_day1": "Gib deine erste Überzeugung ein",
        "retention_day7": "Füge erste Beweise hinzu",
        "retention_day30": "Führe dein erstes KI-Gespräch"
    ]

    private static let frenchStrings: [String: String] = [
        "beliefs": "Croyances",
        "map": "Carte",
        "evidence": "Preuves",
        "community": "Communauté",
        "legacy": "Héritage",
        "add_belief": "Ajouter une croyance",
        "belief_text": "Quelle croyance avez-vous?",
        "core_belief": "Croyance centrale",
        "evidence_for": "Preuves pour cette croyance",
        "evidence_against": "Preuves contre cette croyance",
        "score": "Score",
        "ai_deep_dive": "Analyse IA",
        "stress_test": "Test de stress",
        "therapy": "Thérapie",
        "teams": "Équipes",
        "upgrade": "Améliorer",
        "pro": "Pro",
        "free": "Gratuit",
        "subscription": "Abonnement"
    ]

    private static let spanishStrings: [String: String] = [
        "beliefs": "Creencias",
        "map": "Mapa",
        "evidence": "Evidencia",
        "community": "Comunidad",
        "legacy": "Legado",
        "add_belief": "Agregar creencia",
        "belief_text": "¿Qué creencia tienes?",
        "core_belief": "Creencia central",
        "evidence_for": "Evidencia a favor",
        "evidence_against": "Evidencia en contra",
        "score": "Puntuación",
        "ai_deep_dive": "Análisis IA",
        "stress_test": "Prueba de estrés",
        "therapy": "Terapia",
        "teams": "Equipos",
        "upgrade": "Mejorar",
        "pro": "Pro",
        "free": "Gratis",
        "subscription": "Suscripción"
    ]

    private static let italianStrings: [String: String] = [
        "beliefs": "Credenze",
        "map": "Mappa",
        "evidence": "Evidenza",
        "community": "Comunità",
        "legacy": "Eredità",
        "add_belief": "Aggiungi credenza",
        "belief_text": "Quale credenza hai?",
        "core_belief": "Credenza centrale",
        "evidence_for": "Evidenza a favore",
        "evidence_against": "Evidenza contro",
        "score": "Punteggio",
        "ai_deep_dive": "Analisi IA",
        "stress_test": "Test dello stress",
        "therapy": "Terapia",
        "teams": "Squadre",
        "upgrade": "Migliora",
        "pro": "Pro",
        "free": "Gratuito",
        "subscription": "Abbonamento"
    ]

    private static let portugueseStrings: [String: String] = [
        "beliefs": "Crenças",
        "map": "Mapa",
        "evidence": "Evidência",
        "community": "Comunidade",
        "legacy": "Legado",
        "add_belief": "Adicionar crença",
        "belief_text": "Qual crença você tem?",
        "core_belief": "Crença central",
        "evidence_for": "Evidência a favor",
        "evidence_against": "Evidência contra",
        "score": "Pontuação",
        "ai_deep_dive": "Análise IA",
        "stress_test": "Teste de estresse",
        "therapy": "Terapia",
        "teams": "Equipes",
        "upgrade": "Melhorar",
        "pro": "Pro",
        "free": "Grátis",
        "subscription": "Assinatura"
    ]

    private static let japaneseStrings: [String: String] = [
        "beliefs": "信念",
        "map": "マップ",
        "evidence": "証拠",
        "community": "コミュニティ",
        "legacy": "遺産",
        "add_belief": "信念を追加",
        "belief_text": "どのような信念を持っていますか？",
        "core_belief": "コア信念",
        "evidence_for": "この信念を支持的証拠",
        "evidence_against": "この信念に反する証拠",
        "score": "スコア",
        "ai_deep_dive": "AI深堀り",
        "stress_test": "ストレステスト",
        "therapy": "セラピー",
        "teams": "チーム",
        "upgrade": "アップグレード",
        "pro": "プロ",
        "free": "フリー",
        "subscription": "サブスクリプション"
    ]

    private static let koreanStrings: [String: String] = [
        "beliefs": "신념",
        "map": "지도",
        "evidence": "증거",
        "community": "커뮤니티",
        "legacy": "유산",
        "add_belief": "신념 추가",
        "belief_text": "어떤 신념을 가지고 계신가요?",
        "core_belief": "핵심 신념",
        "evidence_for": "이 신념을 지지하는 증거",
        "evidence_against": "이 신념에 반하는 증거",
        "score": "점수",
        "ai_deep_dive": "AI 심층 분석",
        "stress_test": "스트레스 테스트",
        "therapy": "치료",
        "teams": "팀",
        "upgrade": "업그레이드",
        "pro": "프로",
        "free": "무료",
        "subscription": "구독"
    ]

    private static let chineseStrings: [String: String] = [
        "beliefs": "信念",
        "map": "地图",
        "evidence": "证据",
        "community": "社区",
        "legacy": "遗产",
        "add_belief": "添加信念",
        "belief_text": "你有什么信念？",
        "core_belief": "核心信念",
        "evidence_for": "支持这一信念的证据",
        "evidence_against": "反对这一信念的证据",
        "score": "分数",
        "ai_deep_dive": "AI深度分析",
        "stress_test": "压力测试",
        "therapy": "治疗",
        "teams": "团队",
        "upgrade": "升级",
        "pro": "专业版",
        "free": "免费",
        "subscription": "订阅"
    ]
}
