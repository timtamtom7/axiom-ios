# Axiom App Store Screenshots — Specification

## Overview

All screenshots use a dark theme with `#0a0a0f` background. Device frames are the native iOS frames (not overlaid). Screenshots are required at two device sizes and four locales.

---

## Device Specifications

| Device | Resolution | PPI | Frame |
|---|---|---|---|
| iPhone 16 Pro Max | 1290 × 2796 px | 460 ppi | Natural Titanium / Black Titanium |
| iPad Pro 13" (M4) | 2064 × 2752 px | 264 ppi | Space Black / Silver |

---

## Localization

All text rendered in screenshots must use the appropriate locale:
- **EN** — English (US)
- **DE** — German
- **FR** — French
- **ES** — Spanish

UI labels (navigation, buttons) use SF Symbols + system font. App name "Axiom" is always English.

---

## Screenshot 1 — Belief List (Home Screen)

### Description
The main screen showing the user's list of tracked beliefs. Each belief is shown as a node with a name and confidence score ring.

### UI Elements

| Element | EN | DE | FR | ES |
|---|---|---|---|---|
| Navigation title | Beliefs | Überzeugungen | Croyances | Creencias |
| + button (top right) | SF Symbol: `plus.circle.fill` | same | same | same |
| Search bar placeholder | Search beliefs… | Überzeugungen suchen… | Rechercher… | Buscar creencias… |
| Empty state heading | Your beliefs, mapped. | Ihre Überzeugungen, erfasst. | Vos croyances, cartographiées. | Tus creencias, mapeadas. |
| Empty state body | Tap + to add your first belief. | Tippen Sie auf +, um Ihre erste Überzeugung hinzuzufügen. | Appuyez sur + pour ajouter votre première croyance. | Toca + para añadir tu primera creencia. |
| Belief row | "[Belief name]" + circular score indicator (0–100%) | same | same | same |
| Score label | "78%" style in SF Mono | same | same | same |

### Sample Data
- Belief 1: "I am not good enough" — 78%
- Belief 2: "I deserve love" — 91%
- Belief 3: "Mistakes are intolerable" — 64%

### Frame
- iPhone: iPhone 16 Pro Max frame, Dark mode
- iPad: iPad Pro 13" frame, Dark mode

---

## Screenshot 2 — Belief Detail with Evidence

### Description
Tapped into a single belief. Shows the belief statement, confidence score, supporting evidence (green), and contradicting evidence (red). Network graph visible in background.

### UI Elements

| Element | EN | DE | FR | ES |
|---|---|---|---|---|
| Back button | SF Symbol: `chevron.left` | same | same | same |
| Share button | SF Symbol: `square.and.arrow.up` | same | same | same |
| Belief headline | "I am not good enough" | "Ich bin nicht gut genug" | "Je ne suis pas assez bon" | "No soy suficientemente bueno" |
| Score badge | "78% — Strong" | "78 % — Stark" | "78 % — Fort" | "78 % — Fuerte" |
| Section: Supporting | SF Symbol: `checkmark.circle` (green) | same | same | same |
| Supporting label | "Supporting Evidence" | "Unterstützende Belege" | "Preuves à l'appui" | "Evidencia favorable" |
| Add supporting button | SF Symbol: `plus.circle` (green) | same | same | same |
| Evidence row 1 | "I got passed over for promotion" | "Ich wurde bei der Beförderung übergangen" | "J'ai été snobé pour une promotion" | "Fui ignorado para un ascenso" |
| Evidence row 2 | "My boss said my work was 'fine'" | "Mein Chef sagte, meine Arbeit sei 'in Ordnung'" | "Mon patron a dit que mon travail était 'correct'" | "Mi jefe dijo que mi trabajo estaba 'bien'" |
| Section: Contradicting | SF Symbol: `xmark.circle` (red) | same | same | same |
| Contradicting label | "Contradicting Evidence" | "Widersprüchliche Belege" | "Preuves contraires" | "Evidencia contradictoria" |
| Add contradicting button | SF Symbol: `plus.circle` (red) | same | same | same |
| Evidence row | "I received three compliments this week" | "Ich habe diese Woche drei Komplimente erhalten" | "J'ai reçu trois compliments cette semaine" | "Recibí tres cumplidos esta semana" |
| AI Challenge button | SF Symbol: `brain` + "AI Challenge" | "KI-Herausforderung" | "Défi IA" | "Desafío IA" |
| Bottom nav | Home, Graph, Settings (SF Symbols) | same | same | same |

### Frame
- iPhone: iPhone 16 Pro Max frame, Dark mode
- iPad: iPad Pro 13" frame, Dark mode

---

## Screenshot 3 — AI Stress Test Results

### Description
The results screen after running an AI Stress Test. Shows the belief, original score, adjusted score, weakest evidence link highlighted, and AI commentary.

### UI Elements

| Element | EN | DE | FR | ES |
|---|---|---|---|---|
| Header | "AI Stress Test" | "KI-Belastungstest" | "Test de résistance IA" | "Prueba de estrés IA" |
| Belief shown | "I am not good enough" | "Ich bin nicht gut genug" | "Je ne suis pas assez bon" | "No soy suficientemente bueno" |
| Score comparison | "78%" → "65%" with down arrow | "78 %" → "65 %" | same | same |
| Adjustment label | "−13% after analysis" | "−13 % nach Analyse" | "−13 % après analyse" | "−13 % tras el análisis" |
| Weak link heading | "Weakest Connection" | "Schwächste Verbindung" | "Connexion la plus faible" | "Conexión más débil" |
| Weak evidence text | "My boss said my work was 'fine'" highlighted in amber | same | same | same |
| AI insight label | "AI Insight" | "KI-Erkenntnis" | "Insight IA" | "Perspectiva IA" |
| AI insight body | "This evidence is subjective. 'Fine' is not a measure of worth — it's a neutral descriptor. Challenge this link." | "Dieser Beleg ist subjektiv. 'In Ordnung' ist kein Maß für Wert — es ist eine neutrale Beschreibung. Hinterfragen Sie diese Verbindung." | "Cette preuve est subjective. 'Correct' n'est pas une mesure de valeur — c'est un descriptif neutre. Remettez en question ce lien." | "Esta evidencia es subjetiva. 'Bien' no es una medida de valor — es un descriptor neutro. Cuestiona este enlace." |
| CTA button | "Revise Belief" | "Überzeugung überarbeiten" | "Réviser la croyance" | "Revisar creencia" |
| Secondary button | "Done" | "Fertig" | "Terminé" | "Hecho" |

### Frame
- iPhone: iPhone 16 Pro Max frame, Dark mode
- iPad: iPad Pro 13" frame, Dark mode

---

## Screenshot 4 — Community / Anonymous Sharing

### Description
The sharing screen showing an anonymous belief card formatted for sharing. Shows belief name, score, and a simplified network graph. No personal data.

### UI Elements

| Element | EN | DE | FR | ES |
|---|---|---|---|---|
| Heading | "Share Belief" | "Überzeugung teilen" | "Partager la croyance" | "Compartir creencia" |
| Privacy label | "Shared anonymously" | "Anonym geteilt" | "Partagé anonymement" | "Compartido anónimamente" |
| Privacy icon | SF Symbol: `eye.slash` | same | same | same |
| Card title | "A belief I'm exploring:" | "Eine Überzeugung, die ich erforsche:" | "Une croyance que j'explore :" | "Una creencia que estoy explorando:" |
| Belief on card | "I am not good enough" | "Ich bin nicht gut genug" | "Je ne suis pas assez bon" | "No soy suficientemente bueno" |
| Score on card | "78% confidence" | "78 % Vertrauen" | "Confiance à 78 %" | "78 % de confianza" |
| Graph preview | Simplified node graph, 4 nodes, 3 edges | same | same | same |
| Share options | SF Symbols: `square.and.arrow.up` (generic), `message.fill` (iMessage), `link` (copy link) | same | same | same |
| Community label | "Share to Community" | "Mit Gemeinschaft teilen" | "Partager avec la communauté" | "Compartir con la comunidad" |
| Community toggle | On/Off switch | same | same | same |
| Community note | "Help others see patterns in anonymous beliefs" | "Helfen Sie anderen, Muster in anonymen Überzeugungen zu erkennen" | "Aidez les autres à voir les schémas dans les croyances anonymes" | "Ayuda a otros a ver patrones en creencias anónimas" |

### Frame
- iPhone: iPhone 16 Pro Max frame, Dark mode
- iPad: iPad Pro 13" frame, Dark mode

---

## Screenshot 5 — Settings / Subscription

### Description
The settings screen showing profile, subscription status, and app preferences.

### UI Elements

| Element | EN | DE | FR | ES |
|---|---|---|---|---|
| Navigation title | "Settings" | "Einstellungen" | "Paramètres" | "Ajustes" |
| Profile section | SF Symbol: `person.circle` + "Tommaso" | same | same | same |
| Subscription card | | | | |
| Plan name | "Axiom Pro" | same | same | same |
| Status | "Active" / "Cancel Anytime" | "Aktiv" / "Jederzeit kündbar" | "Actif" / "Résiliable à tout moment" | "Activo" / "Cancelable en cualquier momento" |
| Price | "$9.99/month" | "9,99 $/Monat" | "9,99 $/mois" | "9,99 $/mes" |
| Renewal date | "Renews March 28, 2027" | "Verlängert am 28. März 2027" | "Renouvelé le 28 mars 2027" | "Se renueva el 28 de marzo de 2027" |
| Features list | | | | |
| Feature 1 | ✓ Unlimited beliefs | ✓ Unbegrenzte Überzeugungen | ✓ Croyances illimitées | ✓ Creencias ilimitadas |
| Feature 2 | ✓ AI Stress Tests | ✓ KI-Belastungstests | ✓ Tests de résistance IA | ✓ Pruebas de estrés IA |
| Feature 3 | ✓ Community sharing | ✓ Gemeinschafts-Sharing | ✓ Partage communautaire | ✓ Compartición comunitaria |
| Feature 4 | ✓ Export data | ✓ Daten exportieren | ✓ Exporter les données | ✓ Exportar datos |
| Manage button | "Manage Subscription" | "Abonnement verwalten" | "Gérer l'abonnement" | "Gestionar suscripción" |
| Privacy row | SF Symbol: `hand.raised` + "Privacy" | same | same | same |
| About row | SF Symbol: `info.circle` + "About Axiom" | "Über Axiom" | "À propos d'Axiom" | "Acerca de Axiom" |
| Version | "Version 1.0.0 (Build 15)" | same | same | same |

### Frame
- iPhone: iPhone 16 Pro Max frame, Dark mode
- iPad: iPad Pro 13" frame, Dark mode

---

## Asset Requirements Summary

| Shot | Device | EN | DE | FR | ES |
|---|---|---|---|---|---|
| 1. Belief List | iPhone | ✓ | ✓ | ✓ | ✓ |
| 1. Belief List | iPad | ✓ | ✓ | ✓ | ✓ |
| 2. Belief Detail | iPhone | ✓ | ✓ | ✓ | ✓ |
| 2. Belief Detail | iPad | ✓ | ✓ | ✓ | ✓ |
| 3. AI Stress Test | iPhone | ✓ | ✓ | ✓ | ✓ |
| 3. AI Stress Test | iPad | ✓ | ✓ | ✓ | ✓ |
| 4. Community Sharing | iPhone | ✓ | ✓ | ✓ | ✓ |
| 4. Community Sharing | iPad | ✓ | ✓ | ✓ | ✓ |
| 5. Settings/Subscription | iPhone | ✓ | ✓ | ✓ | ✓ |
| 5. Settings/Subscription | iPad | ✓ | ✓ | ✓ | ✓ |

**Total: 40 screenshots** (5 shots × 2 devices × 4 locales)

## Notes for Designer

- Use `presentationName` on the device frame to show "iPhone 16 Pro Max" and "iPad Pro 13\""
- Render text at native resolution; do not scale up
- Export as PNG with alpha for maximum compatibility
- For App Store Connect, name files: `{locale}_{shot#}_{device}.png`
  - Example: `en_1_iphone.png`, `de_2_ipad.png`
