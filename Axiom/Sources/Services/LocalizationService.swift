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
        case traditionalChinese = "zh-Hant"

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
            case .traditionalChinese: return "繁體中文"
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
            case .traditionalChinese: return "🇹🇼"
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

    /// Localized string lookup using Bundle.main.localizedString
    func t(_ key: String) -> String {
        // R13: Full localization - psychological terminology localized per culture
        // Use Bundle.main.localizedString for proper .stringsdict/.xcstrings support
        let bundleString = Bundle.main.localizedString(forKey: key, value: nil, table: "Localizable")
        if bundleString != key {
            return bundleString
        }
        // Fallback to in-memory translations for languages not yet in .strings files
        let translations = currentLanguage.translations
        return translations[key] ?? key
    }

    /// Static access for use in non-@MainActor contexts
    static func localized(_ key: String) -> String {
        shared.t(key)
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
        case .traditionalChinese:
            return Self.traditionalChineseStrings
        }
    }

    private static let englishStrings: [String: String] = [
        // Navigation
        "beliefs": "Beliefs",
        "map": "Map",
        "evidence": "Evidence",
        "community": "Community",
        "settings": "Settings",
        "legacy": "Legacy",
        // Belief
        "add_belief": "Add Belief",
        "belief_text": "What belief do you hold?",
        "supporting": "Supporting",
        "contradicting": "Contradicting",
        "core_belief": "Core Belief",
        "evidence_for": "Evidence for this belief",
        "evidence_against": "Evidence against this belief",
        "score": "Score",
        // AI
        "challenge": "Challenge",
        "stress_test": "Stress Test",
        "ai_insight": "AI Insight",
        "ai_deep_dive": "AI Deep Dive",
        // Actions
        "save": "Save",
        "cancel": "Cancel",
        "delete": "Delete",
        "edit": "Edit",
        // Subscription
        "upgrade": "Upgrade",
        "pro": "Pro",
        "therapy": "Therapy",
        "teams": "Teams",
        "free_tier": "Free",
        "unlimited": "Unlimited",
        "beliefs_limit": "3 beliefs",
        "subscription": "Subscription",
        "manage_subscription": "Manage Subscription",
        // Retention
        "retention_day1": "Enter your first belief",
        "retention_day7": "Add first evidence",
        "retention_day30": "Have your first AI conversation"
    ]

    private static let germanStrings: [String: String] = [
        // Navigation
        "beliefs": "Überzeugungen",
        "map": "Karte",
        "evidence": "Beweise",
        "community": "Gemeinschaft",
        "settings": "Einstellungen",
        "legacy": "Vermächtnis",
        // Belief
        "add_belief": "Überzeugung hinzufügen",
        "belief_text": "Welche Überzeugung hegst du?",
        "supporting": "Unterstützend",
        "contradicting": "Widersprüchlich",
        "core_belief": "Kernüberzeugung",
        "evidence_for": "Belege für diese Überzeugung",
        "evidence_against": "Belege gegen diese Überzeugung",
        "score": "Punktzahl",
        // AI
        "challenge": "Herausfordern",
        "stress_test": "Stresstest",
        "ai_insight": "KI-Erkenntnis",
        "ai_deep_dive": "KI-Tiefenalyse",
        // Actions
        "save": "Speichern",
        "cancel": "Abbrechen",
        "delete": "Löschen",
        "edit": "Bearbeiten",
        // Subscription
        "upgrade": "Upgrade",
        "pro": "Pro",
        "therapy": "Therapie",
        "teams": "Teams",
        "free_tier": "Kostenlos",
        "unlimited": "Unbegrenzt",
        "beliefs_limit": "3 Überzeugungen",
        "subscription": "Abonnement",
        "manage_subscription": "Abonnement verwalten",
        // Retention
        "retention_day1": "Gib deine erste Überzeugung ein",
        "retention_day7": "Füge erste Beweise hinzu",
        "retention_day30": "Führe dein erstes KI-Gespräch"
    ]

    private static let frenchStrings: [String: String] = [
        // Navigation
        "beliefs": "Croyances",
        "map": "Carte",
        "evidence": "Preuves",
        "community": "Communauté",
        "settings": "Paramètres",
        "legacy": "Héritage",
        // Belief
        "add_belief": "Ajouter une croyance",
        "belief_text": "Quelle croyance avez-vous?",
        "supporting": "Soutenant",
        "contradicting": "Contredisant",
        "core_belief": "Croyance centrale",
        "evidence_for": "Preuves pour cette croyance",
        "evidence_against": "Preuves contre cette croyance",
        "score": "Score",
        // AI
        "challenge": "Défier",
        "stress_test": "Test de stress",
        "ai_insight": "Insight IA",
        "ai_deep_dive": "Analyse IA",
        // Actions
        "save": "Enregistrer",
        "cancel": "Annuler",
        "delete": "Supprimer",
        "edit": "Modifier",
        // Subscription
        "upgrade": "Améliorer",
        "pro": "Pro",
        "therapy": "Thérapie",
        "teams": "Équipes",
        "free_tier": "Gratuit",
        "unlimited": "Illimité",
        "beliefs_limit": "3 croyances",
        "subscription": "Abonnement",
        "manage_subscription": "Gérer l'abonnement",
        // Retention
        "retention_day1": "Entrez votre première croyance",
        "retention_day7": "Ajoutez vos premières preuves",
        "retention_day30": "Ayez votre premier échange IA"
    ]

    private static let spanishStrings: [String: String] = [
        // Navigation
        "beliefs": "Creencias",
        "map": "Mapa",
        "evidence": "Evidencia",
        "community": "Comunidad",
        "settings": "Configuración",
        "legacy": "Legado",
        // Belief
        "add_belief": "Agregar creencia",
        "belief_text": "¿Qué creencia tienes?",
        "supporting": "Apoyando",
        "contradicting": "Contradiciendo",
        "core_belief": "Creencia central",
        "evidence_for": "Evidencia a favor",
        "evidence_against": "Evidencia en contra",
        "score": "Puntuación",
        // AI
        "challenge": "Desafiar",
        "stress_test": "Prueba de estrés",
        "ai_insight": "Perspicacia IA",
        "ai_deep_dive": "Análisis IA",
        // Actions
        "save": "Guardar",
        "cancel": "Cancelar",
        "delete": "Eliminar",
        "edit": "Editar",
        // Subscription
        "upgrade": "Mejorar",
        "pro": "Pro",
        "therapy": "Terapia",
        "teams": "Equipos",
        "free_tier": "Gratis",
        "unlimited": "Ilimitado",
        "beliefs_limit": "3 creencias",
        "subscription": "Suscripción",
        "manage_subscription": "Gestionar suscripción",
        // Retention
        "retention_day1": "Ingresa tu primera creencia",
        "retention_day7": "Agrega tus primeras evidencias",
        "retention_day30": "Ten tu primera conversación IA"
    ]

    private static let italianStrings: [String: String] = [
        // Navigation
        "beliefs": "Credenze",
        "map": "Mappa",
        "evidence": "Evidenza",
        "community": "Comunità",
        "settings": "Impostazioni",
        "legacy": "Eredità",
        // Belief
        "add_belief": "Aggiungi credenza",
        "belief_text": "Quale credenza hai?",
        "supporting": "Supportante",
        "contradicting": "Contraddicente",
        "core_belief": "Credenza centrale",
        "evidence_for": "Evidenza a favore",
        "evidence_against": "Evidenza contro",
        "score": "Punteggio",
        // AI
        "challenge": "Sfidare",
        "stress_test": "Test dello stress",
        "ai_insight": "Insight IA",
        "ai_deep_dive": "Analisi IA",
        // Actions
        "save": "Salva",
        "cancel": "Annulla",
        "delete": "Elimina",
        "edit": "Modifica",
        // Subscription
        "upgrade": "Migliora",
        "pro": "Pro",
        "therapy": "Terapia",
        "teams": "Squadre",
        "free_tier": "Gratuito",
        "unlimited": "Illimitato",
        "beliefs_limit": "3 credenze",
        "subscription": "Abbonamento",
        "manage_subscription": "Gestisci abbonamento",
        // Retention
        "retention_day1": "Inserisci la tua prima credenza",
        "retention_day7": "Aggiungi le tue prime evidenze",
        "retention_day30": "Fai la tua prima conversazione IA"
    ]

    private static let portugueseStrings: [String: String] = [
        // Navigation
        "beliefs": "Crenças",
        "map": "Mapa",
        "evidence": "Evidência",
        "community": "Comunidade",
        "settings": "Configurações",
        "legacy": "Legado",
        // Belief
        "add_belief": "Adicionar crença",
        "belief_text": "Qual crença você tem?",
        "supporting": "Apoiando",
        "contradicting": "Contradizendo",
        "core_belief": "Crença central",
        "evidence_for": "Evidência a favor",
        "evidence_against": "Evidência contra",
        "score": "Pontuação",
        // AI
        "challenge": "Desafiar",
        "stress_test": "Teste de estresse",
        "ai_insight": "Insight IA",
        "ai_deep_dive": "Análise IA",
        // Actions
        "save": "Salvar",
        "cancel": "Cancelar",
        "delete": "Excluir",
        "edit": "Editar",
        // Subscription
        "upgrade": "Melhorar",
        "pro": "Pro",
        "therapy": "Terapia",
        "teams": "Equipes",
        "free_tier": "Grátis",
        "unlimited": "Ilimitado",
        "beliefs_limit": "3 crenças",
        "subscription": "Assinatura",
        "manage_subscription": "Gerenciar assinatura",
        // Retention
        "retention_day1": "Digite sua primeira crença",
        "retention_day7": "Adicione suas primeiras evidências",
        "retention_day30": "Tenha sua primeira conversa IA"
    ]

    private static let japaneseStrings: [String: String] = [
        // Navigation
        "beliefs": "信念",
        "map": "マップ",
        "evidence": "証拠",
        "community": "コミュニティ",
        "settings": "設定",
        "legacy": "遺産",
        // Belief
        "add_belief": "信念を追加",
        "belief_text": "どのような信念を持っていますか？",
        "supporting": "支持する",
        "contradicting": "矛盾する",
        "core_belief": "コア信念",
        "evidence_for": "この信念を支持的証拠",
        "evidence_against": "この信念に反する証拠",
        "score": "スコア",
        // AI
        "challenge": "挑む",
        "stress_test": "ストレステスト",
        "ai_insight": "AI洞察",
        "ai_deep_dive": "AI深堀り",
        // Actions
        "save": "保存",
        "cancel": "キャンセル",
        "delete": "削除",
        "edit": "編集",
        // Subscription
        "upgrade": "アップグレード",
        "pro": "プロ",
        "therapy": "セラピー",
        "teams": "チーム",
        "free_tier": "フリー",
        "unlimited": "無制限",
        "beliefs_limit": "3つの信念",
        "subscription": "サブスクリプション",
        "manage_subscription": "サブスクリプション管理",
        // Retention
        "retention_day1": "最初の信念を入力してください",
        "retention_day7": "最初の証拠を追加してください",
        "retention_day30": "最初のAI会話をお楽しみください"
    ]

    private static let koreanStrings: [String: String] = [
        // Navigation
        "beliefs": "신념",
        "map": "지도",
        "evidence": "증거",
        "community": "커뮤니티",
        "settings": "설정",
        "legacy": "유산",
        // Belief
        "add_belief": "신념 추가",
        "belief_text": "어떤 신념을 가지고 계신가요?",
        "supporting": "지지하는",
        "contradicting": "모순하는",
        "core_belief": "핵심 신념",
        "evidence_for": "이 신념을 지지하는 증거",
        "evidence_against": "이 신념에 반하는 증거",
        "score": "점수",
        // AI
        "challenge": "도전하다",
        "stress_test": "스트레스 테스트",
        "ai_insight": "AI 통찰",
        "ai_deep_dive": "AI 심층 분석",
        // Actions
        "save": "저장",
        "cancel": "취소",
        "delete": "삭제",
        "edit": "편집",
        // Subscription
        "upgrade": "업그레이드",
        "pro": "프로",
        "therapy": "치료",
        "teams": "팀",
        "free_tier": "무료",
        "unlimited": "무제한",
        "beliefs_limit": "3개의 신념",
        "subscription": "구독",
        "manage_subscription": "구독 관리",
        // Retention
        "retention_day1": "첫 번째 신념을 입력하세요",
        "retention_day7": "첫 번째 증거를 추가하세요",
        "retention_day30": "첫 번째 AI 대화를 즐기세요"
    ]

    private static let chineseStrings: [String: String] = [
        // Navigation
        "beliefs": "信念",
        "map": "地图",
        "evidence": "证据",
        "community": "社区",
        "settings": "设置",
        "legacy": "遗产",
        // Belief
        "add_belief": "添加信念",
        "belief_text": "你有什么信念？",
        "supporting": "支持的",
        "contradicting": "矛盾的",
        "core_belief": "核心信念",
        "evidence_for": "支持这一信念的证据",
        "evidence_against": "反对这一信念的证据",
        "score": "分数",
        // AI
        "challenge": "挑战",
        "stress_test": "压力测试",
        "ai_insight": "AI洞察",
        "ai_deep_dive": "AI深度分析",
        // Actions
        "save": "保存",
        "cancel": "取消",
        "delete": "删除",
        "edit": "编辑",
        // Subscription
        "upgrade": "升级",
        "pro": "专业版",
        "therapy": "治疗",
        "teams": "团队",
        "free_tier": "免费",
        "unlimited": "无限",
        "beliefs_limit": "3个信念",
        "subscription": "订阅",
        "manage_subscription": "管理订阅",
        // Retention
        "retention_day1": "输入你的第一个信念",
        "retention_day7": "添加你的第一个证据",
        "retention_day30": "进行你的第一次AI对话"
    ]

    private static let traditionalChineseStrings: [String: String] = [
        // Navigation
        "beliefs": "信念",
        "map": "地圖",
        "evidence": "證據",
        "community": "社區",
        "settings": "設定",
        "legacy": "遺產",
        // Belief
        "add_belief": "新增信念",
        "belief_text": "你有什麼信念？",
        "supporting": "支持的",
        "contradicting": "矛盾的",
        "core_belief": "核心信念",
        "evidence_for": "支持這一信念的證據",
        "evidence_against": "反對這一信念的證據",
        "score": "分數",
        // AI
        "challenge": "挑戰",
        "stress_test": "壓力測試",
        "ai_insight": "AI洞察",
        "ai_deep_dive": "AI深度分析",
        // Actions
        "save": "儲存",
        "cancel": "取消",
        "delete": "刪除",
        "edit": "編輯",
        // Subscription
        "upgrade": "升級",
        "pro": "專業版",
        "therapy": "治療",
        "teams": "團隊",
        "free_tier": "免費",
        "unlimited": "無限",
        "beliefs_limit": "3個信念",
        "subscription": "訂閱",
        "manage_subscription": "管理訂閱",
        // Retention
        "retention_day1": "輸入你的第一個信念",
        "retention_day7": "添加你的第一個證據",
        "retention_day30": "進行你的第一次AI對話"
    ]
}
