// Globalne skróty klawiszowe do przełączania aplikacji (zamiennik Raycasta).
// Czyta hotkeys.conf (`alt+r = Slack`), rejestruje skróty przez Carbon
// RegisterEventHotKey (nie wymaga uprawnień Accessibility) i na wciśnięcie
// aktywuje aplikację albo ją uruchamia. Budowa i LaunchAgent: install.sh.
import AppKit
import Carbon.HIToolbox

let configPath = CommandLine.arguments.count > 1
  ? CommandLine.arguments[1]
  : NSString(string: "~/.config/hotkeys/hotkeys.conf").expandingTildeInPath

let keyCodes: [String: Int] = [
  "a": kVK_ANSI_A, "b": kVK_ANSI_B, "c": kVK_ANSI_C, "d": kVK_ANSI_D, "e": kVK_ANSI_E,
  "f": kVK_ANSI_F, "g": kVK_ANSI_G, "h": kVK_ANSI_H, "i": kVK_ANSI_I, "j": kVK_ANSI_J,
  "k": kVK_ANSI_K, "l": kVK_ANSI_L, "m": kVK_ANSI_M, "n": kVK_ANSI_N, "o": kVK_ANSI_O,
  "p": kVK_ANSI_P, "q": kVK_ANSI_Q, "r": kVK_ANSI_R, "s": kVK_ANSI_S, "t": kVK_ANSI_T,
  "u": kVK_ANSI_U, "v": kVK_ANSI_V, "w": kVK_ANSI_W, "x": kVK_ANSI_X, "y": kVK_ANSI_Y,
  "z": kVK_ANSI_Z,
  "0": kVK_ANSI_0, "1": kVK_ANSI_1, "2": kVK_ANSI_2, "3": kVK_ANSI_3, "4": kVK_ANSI_4,
  "5": kVK_ANSI_5, "6": kVK_ANSI_6, "7": kVK_ANSI_7, "8": kVK_ANSI_8, "9": kVK_ANSI_9,
  "space": kVK_Space, "enter": kVK_Return, "tab": kVK_Tab, "esc": kVK_Escape,
]

let modifierFlags: [String: Int] = [
  "ctrl": controlKey, "control": controlKey,
  "alt": optionKey, "opt": optionKey, "option": optionKey,
  "shift": shiftKey,
  "cmd": cmdKey, "command": cmdKey,
]

let appDirs = ["/Applications", "/System/Applications", "/System/Applications/Utilities",
               NSString(string: "~/Applications").expandingTildeInPath]

func log(_ message: String) {
  FileHandle.standardError.write((message + "\n").data(using: .utf8)!)
}

func findApp(_ name: String) -> URL? {
  for dir in appDirs {
    let url = URL(fileURLWithPath: dir).appendingPathComponent(name + ".app")
    if FileManager.default.fileExists(atPath: url.path) { return url }
  }
  return nil
}

var targets: [URL] = []  // index = EventHotKeyID.id

func activate(_ url: URL) {
  let config = NSWorkspace.OpenConfiguration()
  config.activates = true
  NSWorkspace.shared.openApplication(at: url, configuration: config) { _, error in
    if let error { log("hotkeys: \(url.lastPathComponent): \(error.localizedDescription)") }
  }
}

guard let text = try? String(contentsOfFile: configPath, encoding: .utf8) else {
  log("hotkeys: cannot read \(configPath)")
  exit(1)
}

var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
InstallEventHandler(GetApplicationEventTarget(), { _, event, _ in
  var id = EventHotKeyID()
  GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID),
                    nil, MemoryLayout<EventHotKeyID>.size, nil, &id)
  if Int(id.id) < targets.count { activate(targets[Int(id.id)]) }
  return noErr
}, 1, &spec, nil, nil)

for (number, raw) in text.components(separatedBy: .newlines).enumerated() {
  let line = raw.trimmingCharacters(in: .whitespaces)
  if line.isEmpty || line.hasPrefix("#") { continue }
  let parts = line.split(separator: "=", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
  guard parts.count == 2 else { log("hotkeys: line \(number + 1): expected `key = App`"); continue }

  var keys = parts[0].lowercased().split(separator: "+").map(String.init)
  guard let key = keys.popLast(), let code = keyCodes[key] else {
    log("hotkeys: line \(number + 1): unknown key in \(parts[0])"); continue
  }
  var mods = 0
  var badModifier = false
  for m in keys {
    if let flag = modifierFlags[m] { mods |= flag } else { badModifier = true }
  }
  guard !badModifier else { log("hotkeys: line \(number + 1): unknown modifier in \(parts[0])"); continue }
  guard let app = findApp(parts[1]) else { log("hotkeys: line \(number + 1): no app named \(parts[1])"); continue }

  var ref: EventHotKeyRef?
  let id = EventHotKeyID(signature: OSType(0x686B_6579), id: UInt32(targets.count))  // 'hkey'
  let status = RegisterEventHotKey(UInt32(code), UInt32(mods), id, GetApplicationEventTarget(), 0, &ref)
  if status != noErr {
    log("hotkeys: \(parts[0]) is taken by another app (status \(status))"); continue
  }
  targets.append(app)
  log("hotkeys: \(parts[0]) -> \(app.lastPathComponent)")
}

NSApplication.shared.setActivationPolicy(.prohibited)
NSApplication.shared.run()
