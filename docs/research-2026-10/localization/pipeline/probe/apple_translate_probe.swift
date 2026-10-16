// apple_translate_probe.swift
//
// Purpose: the i18n research-pipeline step's one probe of Apple's on-device Translation framework
// (macOS 15+, the installed-only session needs macOS 26+). It answers two questions and nothing else:
//   1. For English to each language in `probeTargets`, what does LanguageAvailability report
//      (installed / supported-but-not-downloaded / unsupported)?
//   2. For the trial languages whose pair is ALREADY installed in both directions, what do the
//      12 sample lines translate to, and what does that translation back-translate to?
//
// Contract:
//   usage: apple_translate_probe <lines.json> <out.json> [name=translations.json ...]
//   <lines.json> is pipeline/lines.json ({"lines":[{"id","text","speaker","placeholders"}]}).
//   Each optional name=file is another translator's output ({"translations":{lang:{id:text}}});
//   the probe back-translates those lines into English as an independent check ("backChecks").
//   <out.json> receives {"availability":[...], "trials":[...], "backChecks":[...]} as UTF-8 JSON.
//   Exit 0 on success; 2 on bad arguments or unreadable input.
//
// Safety (the job's hard rule: no window, no prompt, no language download):
//   - It never calls `prepareTranslation()` and never uses the SwiftUI `.translationTask` modifier;
//     those are the only APIs that ask the user to download a language.
//   - It only builds sessions with `TranslationSession(installedSource:target:)`, which the SDK
//     interface pairs with `TranslationError.notInstalled` instead of a download, and it only builds
//     one after LanguageAvailability already said `.installed` for that exact direction.
//   - It is a plain command-line tool: no NSApplication, so it has no window to show.
//   - It uses the default strategy. `.highFidelity` (macOS 26.4) is only queried, never used to
//     translate, because whether it stays on device is not documented in the SDK interface.
//
// Gotchas:
//   - Speaker tags ("WOLF: ") are stripped before translation and re-attached, exactly as the game's
//     DialogueBoxes splitter needs them untouched.
//   - Placeholders (%s, %d, {name}) and the name WOLF are marked with the macOS 26.4
//     `skipsTranslation` attribute so the engine copies them through rather than translating them.
//   - Locale.Language identifiers: Apple names Latin American Spanish by region where it supports it;
//     the probe asks for "es-419" and "es" separately and reports both.

import Foundation
import Translation

/// One sample line as `lines.json` stores it (only the fields this probe needs).
struct SampleLine: Codable {
    let id: String
    let text: String
    let speaker: String
    let placeholders: [String]
}

struct SampleFile: Codable { let lines: [SampleLine] }

/// One availability answer: English to `target`, with the default and high-fidelity strategies.
struct AvailabilityRow: Codable {
    let target: String
    let status: String
    let statusHighFidelity: String
    let reverseStatus: String
}

/// One translated line and its back-translation, or the error that stopped it.
struct TrialRow: Codable {
    let id: String
    let target: String
    let translation: String?
    let backTranslation: String?
    let error: String?
}

/// Another translator's translation file, as trial.py and the Codex run write it.
struct TranslationFile: Codable { let translations: [String: [String: String]] }

/// One back-translation of another translator's line into English.
struct BackCheckRow: Codable {
    let translator: String
    let target: String
    let id: String
    let backTranslation: String?
    let error: String?
}

struct ProbeOutput: Codable {
    let probedAt: String
    let osVersion: String
    let availability: [AvailabilityRow]
    let trials: [TrialRow]
    let backChecks: [BackCheckRow]
}

/// The languages the job asked about, plus the regional spellings the trial languages might need.
let probeTargets = ["es", "es-419", "es-MX", "fr", "de", "it", "pt", "pt-BR", "pl", "ja", "ko",
                    "zh", "zh-Hans", "zh-Hant", "ru", "uk", "tr", "nl"]
/// The trial languages, in the order the report lists them; each maps to the probe identifiers to try.
let trialTargets: [(String, [String])] = [("es-419", ["es-419", "es-MX", "es"]), ("de", ["de"]), ("ja", ["ja"])]

func describe(_ status: LanguageAvailability.Status) -> String {
    switch status {
    case .installed: return "installed"
    case .supported: return "supported-not-installed"
    case .unsupported: return "unsupported"
    @unknown default: return "unknown"
    }
}

/// `text` as an AttributedString whose placeholders and the name WOLF skip translation.
func protected(_ text: String, placeholders: [String]) -> AttributedString {
    var attributed = AttributedString(text)
    for token in Set(placeholders + ["WOLF"]) {
        var searchStart = attributed.startIndex
        while let range = attributed[searchStart...].range(of: token) {
            attributed[range].translation.skipsTranslation = true
            searchStart = range.upperBound
        }
    }
    return attributed
}

/// Splits "TAG: words" into ("TAG: ", "words") for the line's speaker; narration returns ("", text).
func splitTag(_ line: SampleLine) -> (String, String) {
    let prefix = line.speaker.isEmpty ? "" : line.speaker + ": "
    if !prefix.isEmpty && line.text.hasPrefix(prefix) {
        return (prefix, String(line.text.dropFirst(prefix.count)))
    }
    return ("", line.text)
}

@main
struct Probe {
    static func main() async {
        let args = CommandLine.arguments
        guard args.count >= 3, let data = FileManager.default.contents(atPath: args[1]),
              let samples = try? JSONDecoder().decode(SampleFile.self, from: data) else {
            FileHandle.standardError.write("usage: apple_translate_probe <lines.json> <out.json>\n".data(using: .utf8)!)
            exit(2)
        }
        let english = Locale.Language(identifier: "en")
        let availability = LanguageAvailability()
        let highFidelity = LanguageAvailability(preferredStrategy: .highFidelity)

        var rows: [AvailabilityRow] = []
        var status: [String: (LanguageAvailability.Status, LanguageAvailability.Status)] = [:]
        for code in probeTargets {
            let target = Locale.Language(identifier: code)
            let forward = await availability.status(from: english, to: target)
            let reverse = await availability.status(from: target, to: english)
            let fidelity = await highFidelity.status(from: english, to: target)
            status[code] = (forward, reverse)
            rows.append(AvailabilityRow(target: code, status: describe(forward),
                                        statusHighFidelity: describe(fidelity), reverseStatus: describe(reverse)))
        }

        var trials: [TrialRow] = []
        for (label, candidates) in trialTargets {
            // The first candidate spelling installed in both directions, or none.
            guard let code = candidates.first(where: { status[$0]?.0 == .installed && status[$0]?.1 == .installed }) else {
                trials.append(TrialRow(id: "*", target: label, translation: nil, backTranslation: nil,
                                       error: "not installed in both directions; skipped (no download requested)"))
                continue
            }
            let target = Locale.Language(identifier: code)
            let forward = TranslationSession(installedSource: english, target: target)
            let backward = TranslationSession(installedSource: target, target: english)
            for line in samples.lines {
                let (tag, body) = splitTag(line)
                do {
                    let out = try await forward.translate(protected(body, placeholders: line.placeholders))
                    let back = try await backward.translate(protected(out.targetText, placeholders: line.placeholders))
                    trials.append(TrialRow(id: line.id, target: "\(label) (as \(code))", translation: tag + out.targetText,
                                           backTranslation: tag + back.targetText, error: nil))
                } catch {
                    trials.append(TrialRow(id: line.id, target: label, translation: nil, backTranslation: nil,
                                           error: String(describing: error)))
                }
            }
        }

        // Back-translate the other translators' lines with the same installed-only sessions.
        var backChecks: [BackCheckRow] = []
        for spec in args.dropFirst(3) {
            let parts = spec.split(separator: "=", maxSplits: 1).map(String.init)
            guard parts.count == 2, let fileData = FileManager.default.contents(atPath: parts[1]),
                  let file = try? JSONDecoder().decode(TranslationFile.self, from: fileData) else { continue }
            for (label, candidates) in trialTargets {
                guard let code = candidates.first(where: { status[$0]?.1 == .installed }),
                      let byId = file.translations[label] else { continue }
                let backward = TranslationSession(installedSource: Locale.Language(identifier: code), target: english)
                for line in samples.lines {
                    guard let text = byId[line.id] else { continue }
                    let tag = line.speaker.isEmpty || !text.hasPrefix(line.speaker + ": ") ? "" : line.speaker + ": "
                    do {
                        let back = try await backward.translate(protected(String(text.dropFirst(tag.count)), placeholders: line.placeholders))
                        backChecks.append(BackCheckRow(translator: parts[0], target: label, id: line.id, backTranslation: tag + back.targetText, error: nil))
                    } catch {
                        backChecks.append(BackCheckRow(translator: parts[0], target: label, id: line.id, backTranslation: nil, error: String(describing: error)))
                    }
                }
            }
        }

        let output = ProbeOutput(probedAt: ISO8601DateFormatter().string(from: Date()),
                                 osVersion: ProcessInfo.processInfo.operatingSystemVersionString,
                                 availability: rows, trials: trials, backChecks: backChecks)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        try? encoder.encode(output).write(to: URL(fileURLWithPath: args[2]))
    }
}
