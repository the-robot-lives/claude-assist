import AppKit
import AVFoundation

@MainActor
private final class TextChangeDelegate: NSObject, NSTextFieldDelegate {
    let onChange: () -> Void
    init(onChange: @escaping () -> Void) { self.onChange = onChange }
    func controlTextDidChange(_ obj: Notification) { onChange() }
}

@MainActor
private final class ModalCloseDelegate: NSObject, NSWindowDelegate {
    private let onClose: () -> Void

    init(onClose: @escaping () -> Void) {
        self.onClose = onClose
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        return true
    }

    func windowWillClose(_ notification: Notification) {
        onClose()
    }
}

@MainActor
func showConfigDialog(config: QueuePopulatorConfig) -> QueuePopulatorConfig? {
    let app = NSApplication.shared
    DebugLog.log("[DIALOG] opening")

    let panel = NSPanel(
        contentRect: NSRect(x: 0, y: 0, width: 480, height: 680),
        styleMask: [.titled, .closable],
        backing: .buffered,
        defer: false
    )
    panel.title = "Queue Populator — Configuration"

    let contentView = NSView(frame: panel.contentView!.bounds)
    contentView.autoresizingMask = [.width, .height]
    panel.contentView = contentView

    let fieldX: CGFloat = 120
    let fieldWidth: CGFloat = 330
    let rowHeight: CGFloat = 32
    let sectionGap: CGFloat = 12
    var y: CGFloat = 645
    let audioDevices = AVCaptureDevice.DiscoverySession(
        deviceTypes: [.microphone, .external],
        mediaType: .audio,
        position: .unspecified
    ).devices

    func makeLabel(_ text: String) -> NSTextField {
        let lbl = NSTextField(labelWithString: text)
        lbl.font = NSFont.systemFont(ofSize: 13)
        return lbl
    }

    func makeSectionHeader(_ text: String) {
        y -= sectionGap
        let lbl = NSTextField(labelWithString: text)
        lbl.font = NSFont.boldSystemFont(ofSize: 12)
        lbl.textColor = .secondaryLabelColor
        lbl.frame = NSRect(x: 12, y: y - 18, width: 440, height: 18)
        contentView.addSubview(lbl)
        y -= 22
    }

    func addRow(label: String, value: String, placeholder: String = "") -> NSTextField {
        let lbl = makeLabel(label)
        lbl.frame = NSRect(x: 12, y: y - rowHeight + 6, width: 100, height: 20)
        contentView.addSubview(lbl)

        let field = NSTextField(frame: NSRect(x: fieldX, y: y - rowHeight + 4, width: fieldWidth, height: 24))
        field.stringValue = value
        field.placeholderString = placeholder
        contentView.addSubview(field)
        y -= rowHeight
        return field
    }

    // --- Phrases ---
    makeSectionHeader("VOICE PHRASES")
    let wakeField = addRow(label: "Wake:", value: config.phrases.wake, placeholder: "hey robot")
    let endField = addRow(label: "End:", value: config.phrases.end, placeholder: "full stop")
    let approveMemoField = addRow(label: "Approve memo:", value: config.phrases.approveMemo, placeholder: "approve memo")
    let cancelField = addRow(label: "Cancel:", value: config.phrases.cancel, placeholder: "cancel that")
    let approveField = addRow(label: "Approve:", value: config.phrases.approve, placeholder: "looks good")
    let reviseField = addRow(label: "Revise:", value: config.phrases.revise, placeholder: "revise that")

    // --- Queue ---
    makeSectionHeader("QUEUE")
    let queuePathField = addRow(label: "Base path:", value: config.queueBasePath, placeholder: "~/personal-development/queue")

    // --- Recognition ---
    makeSectionHeader("RECOGNITION")

    let deviceLabel = makeLabel("Microphone:")
    deviceLabel.frame = NSRect(x: 12, y: y - rowHeight + 6, width: 100, height: 20)
    contentView.addSubview(deviceLabel)

    let devicePopup = NSPopUpButton(frame: NSRect(x: fieldX, y: y - rowHeight + 2, width: fieldWidth, height: 26), pullsDown: false)
    devicePopup.addItem(withTitle: "System Default")
    for device in audioDevices {
        devicePopup.addItem(withTitle: device.localizedName)
        devicePopup.lastItem?.representedObject = device.uniqueID
    }
    if let selectedDeviceId = config.recognition.inputDeviceId,
       let item = devicePopup.itemArray.first(where: { ($0.representedObject as? String) == selectedDeviceId }) {
        devicePopup.select(item)
    }
    contentView.addSubview(devicePopup)
    y -= rowHeight

    // --- LLM ---
    makeSectionHeader("LLM INFERENCE")

    let provLabel = makeLabel("Provider:")
    provLabel.frame = NSRect(x: 12, y: y - rowHeight + 6, width: 100, height: 20)
    contentView.addSubview(provLabel)

    let providerPopup = NSPopUpButton(frame: NSRect(x: fieldX, y: y - rowHeight + 2, width: fieldWidth, height: 26), pullsDown: false)
    providerPopup.addItems(withTitles: LlmConfig.providers)
    providerPopup.selectItem(withTitle: config.llm.provider)
    contentView.addSubview(providerPopup)
    y -= rowHeight

    // API key — plain NSTextField, monospaced so long keys are readable
    let hasEncryptedKey = config.llm.apiKey.map { SecretStore.isEncrypted($0) } ?? false
    let apiKeyDisplayValue: String
    let apiKeyPlaceholder: String
    if hasEncryptedKey, let alias = config.llm.apiKeyAlias {
        apiKeyDisplayValue = ""
        apiKeyPlaceholder = "🔑 \(alias) — enter new key to replace"
    } else {
        apiKeyDisplayValue = config.llm.apiKey ?? ""
        apiKeyPlaceholder = "env: ANTHROPIC_API_KEY"
    }

    let apiKeyLbl = makeLabel("API Key:")
    apiKeyLbl.frame = NSRect(x: 12, y: y - rowHeight + 6, width: 100, height: 20)
    contentView.addSubview(apiKeyLbl)

    let apiKeyField = NSTextField(frame: NSRect(x: fieldX, y: y - rowHeight + 4, width: fieldWidth, height: 24))
    apiKeyField.stringValue = apiKeyDisplayValue
    apiKeyField.placeholderString = apiKeyPlaceholder
    apiKeyField.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
    apiKeyField.lineBreakMode = .byTruncatingMiddle
    contentView.addSubview(apiKeyField)
    y -= rowHeight

    let envHintButton = NSButton(frame: NSRect(x: fieldX, y: y - 18, width: fieldWidth, height: 16))
    envHintButton.isBordered = false
    envHintButton.setButtonType(.momentaryLight)
    envHintButton.alignment = .left
    envHintButton.font = NSFont.systemFont(ofSize: 11)
    envHintButton.title = ""
    contentView.addSubview(envHintButton)

    func resolveEnvCandidates(_ prov: String) -> (varName: String, value: String)? {
        let candidates = LlmConfig.envVarFallbacks[prov]
            ?? LlmConfig.envVarKeys[prov].map { [$0] }
            ?? []
        for varName in candidates {
            if let val = EnvResolver.resolve(varName) { return (varName, val) }
        }
        return nil
    }

    func updateEnvHint() {
        let prov = providerPopup.titleOfSelectedItem ?? "anthropic"
        let fieldText = apiKeyField.stringValue.trimmingCharacters(in: .whitespaces)

        if fieldText.lowercased().hasPrefix("env:") {
            let varName = String(fieldText.dropFirst(4)).trimmingCharacters(in: .whitespaces)
            if let val = EnvResolver.resolve(varName) {
                let last4 = String(val.suffix(4))
                envHintButton.title = "\u{2705} \(varName) resolved (…\(last4)) — click to fill"
                envHintButton.contentTintColor = .systemGreen
            } else {
                envHintButton.title = "\u{274C} \(varName) not found in environment"
                envHintButton.contentTintColor = .systemRed
            }
            return
        }

        if !fieldText.isEmpty || (hasEncryptedKey && fieldText.isEmpty) {
            envHintButton.title = ""
            return
        }

        let candidates = LlmConfig.envVarFallbacks[prov]
            ?? LlmConfig.envVarKeys[prov].map { [$0] }
            ?? []
        if candidates.isEmpty {
            envHintButton.title = ""
            return
        }
        if let found = resolveEnvCandidates(prov) {
            let last4 = String(found.value.suffix(4))
            envHintButton.title = "\u{2705} \(found.varName) available (…\(last4)) — click to use"
            envHintButton.contentTintColor = .systemGreen
        } else {
            let names = candidates.joined(separator: " / ")
            envHintButton.title = "\u{274C} \(names) not set"
            envHintButton.contentTintColor = .systemRed
        }
    }
    updateEnvHint()

    let apiKeyDelegate = TextChangeDelegate(onChange: { updateEnvHint() })
    apiKeyField.delegate = apiKeyDelegate

    let envHintTarget = BlockTarget {
        let prov = providerPopup.titleOfSelectedItem ?? "anthropic"
        let fieldText = apiKeyField.stringValue.trimmingCharacters(in: .whitespaces)
        if fieldText.lowercased().hasPrefix("env:") {
            let varName = String(fieldText.dropFirst(4)).trimmingCharacters(in: .whitespaces)
            if let val = EnvResolver.resolve(varName) {
                apiKeyField.stringValue = val
                updateEnvHint()
            }
            return
        }
        if let found = resolveEnvCandidates(prov) {
            apiKeyField.stringValue = found.value
            updateEnvHint()
        }
    }
    envHintButton.target = envHintTarget
    envHintButton.action = #selector(BlockTarget.invoke)
    y -= 20

    let baseUrlField = addRow(label: "Base URL:", value: config.llm.baseUrl ?? "", placeholder: LlmConfig.defaultBaseUrls[config.llm.provider] ?? "https://api.example.com/v1")

    let modelLabel = makeLabel("Model:")
    modelLabel.frame = NSRect(x: 12, y: y - rowHeight + 6, width: 100, height: 20)
    contentView.addSubview(modelLabel)

    let modelPopup = NSPopUpButton(frame: NSRect(x: fieldX, y: y - rowHeight + 2, width: fieldWidth - 110, height: 26), pullsDown: false)
    modelPopup.addItem(withTitle: config.llm.model ?? LlmConfig.defaultModels[config.llm.provider] ?? "—")
    contentView.addSubview(modelPopup)

    let fetchButton = NSButton(frame: NSRect(x: fieldX + fieldWidth - 104, y: y - rowHeight + 2, width: 104, height: 26))
    fetchButton.title = "Fetch Models"
    fetchButton.bezelStyle = .rounded
    contentView.addSubview(fetchButton)
    y -= rowHeight

    let testButton = NSButton(frame: NSRect(x: fieldX, y: y - rowHeight + 2, width: 120, height: 26))
    testButton.title = "Test Inference"
    testButton.bezelStyle = .rounded
    contentView.addSubview(testButton)
    y -= rowHeight

    let statusLabel = NSTextField(labelWithString: "")
    statusLabel.frame = NSRect(x: fieldX, y: y - 20, width: fieldWidth, height: 18)
    statusLabel.font = NSFont.systemFont(ofSize: 11)
    statusLabel.textColor = .secondaryLabelColor
    contentView.addSubview(statusLabel)

    let providerChangeTarget = BlockTarget {
        let prov = providerPopup.titleOfSelectedItem ?? "anthropic"
        updateEnvHint()

        baseUrlField.stringValue = ""
        if let placeholder = LlmConfig.defaultBaseUrls[prov] {
            baseUrlField.placeholderString = placeholder
        } else {
            baseUrlField.placeholderString = "https://api.example.com/v1"
        }

        let primaryEnvVar = LlmConfig.envVarFallbacks[prov]?.first
            ?? LlmConfig.envVarKeys[prov]
        if let envVar = primaryEnvVar {
            apiKeyField.placeholderString = "env: \(envVar)"
        } else {
            apiKeyField.placeholderString = ""
        }

        modelPopup.removeAllItems()
        modelPopup.addItem(withTitle: LlmConfig.defaultModels[prov] ?? "—")
    }
    providerPopup.target = providerChangeTarget
    providerPopup.action = #selector(BlockTarget.invoke)

    func currentLlmConfig() -> LlmConfig {
        var llm = LlmConfig()
        llm.provider = providerPopup.titleOfSelectedItem ?? "anthropic"
        let apiKey = apiKeyField.stringValue.trimmingCharacters(in: .whitespaces)
        if apiKey.isEmpty && hasEncryptedKey {
            llm.apiKey = config.llm.apiKey
            llm.apiKeyAlias = config.llm.apiKeyAlias
        } else {
            llm.apiKey = apiKey.isEmpty ? nil : apiKey
            llm.apiKeyAlias = nil
        }
        let baseUrl = baseUrlField.stringValue.trimmingCharacters(in: .whitespaces)
        llm.baseUrl = baseUrl.isEmpty ? nil : baseUrl
        llm.model = modelPopup.titleOfSelectedItem
        return llm
    }

    // --- Fetch models ---
    let fetchTarget = BlockTarget {
        let prov = providerPopup.titleOfSelectedItem ?? "anthropic"
        let key = apiKeyField.stringValue.trimmingCharacters(in: .whitespaces)
        let url = baseUrlField.stringValue.trimmingCharacters(in: .whitespaces)

        let effectiveKey: String? = key.isEmpty ? {
            if let envVar = LlmConfig.envVarKeys[prov] {
                return EnvResolver.resolve(envVar)
            }
            return nil
        }() : key

        statusLabel.stringValue = "Fetching models..."
        fetchButton.isEnabled = false

        Task {
            let models = await fetchModels(
                provider: prov,
                apiKey: effectiveKey,
                baseUrl: url.isEmpty ? LlmConfig.defaultBaseUrls[prov] : url
            )
            await MainActor.run {
                fetchButton.isEnabled = true
                modelPopup.removeAllItems()
                if models.isEmpty {
                    modelPopup.addItem(withTitle: LlmConfig.defaultModels[prov] ?? "—")
                    statusLabel.stringValue = "Could not fetch — using default"
                } else {
                    modelPopup.addItems(withTitles: models)
                    statusLabel.stringValue = "\(models.count) models loaded"
                }
            }
        }
    }
    fetchButton.target = fetchTarget
    fetchButton.action = #selector(BlockTarget.invoke)

    // --- Test inference ---
    let testTarget = BlockTarget {
        let llmConfig = currentLlmConfig()
        let client = LlmClient(config: llmConfig)

        statusLabel.stringValue = "Testing inference..."
        testButton.isEnabled = false

        Task {
            do {
                let response = try await client.classify(
                    system: """
                    Return only valid JSON in this exact shape:
                    {"entries":[{"file":"tasks.jsonl","type":"task","text":"test inference"}],"reasoning":"ok"}
                    Use tasks.jsonl as the file.
                    """,
                    user: "Classify this memo: test inference for queue populator"
                )
                await MainActor.run {
                    testButton.isEnabled = true
                    statusLabel.stringValue = "Inference OK — \(response.entries.count) test entry"
                }
            } catch {
                await MainActor.run {
                    testButton.isEnabled = true
                    statusLabel.stringValue = "Inference failed — \(error)"
                }
            }
        }
    }
    testButton.target = testTarget
    testButton.action = #selector(BlockTarget.invoke)

    // --- Buttons ---
    let saveButton = NSButton(frame: NSRect(x: 480 - 130, y: 12, width: 110, height: 32))
    saveButton.title = "Save"
    saveButton.bezelStyle = .rounded
    saveButton.keyEquivalent = "\r"
    contentView.addSubview(saveButton)

    let cancelButton = NSButton(frame: NSRect(x: 480 - 240, y: 12, width: 100, height: 32))
    cancelButton.title = "Cancel"
    cancelButton.bezelStyle = .rounded
    cancelButton.keyEquivalent = "\u{1b}"
    contentView.addSubview(cancelButton)

    let saveTarget = BlockTarget {
        DebugLog.log("[DIALOG] save pressed")
        app.stopModal(withCode: .OK)
    }
    let cancelTarget = BlockTarget {
        DebugLog.log("[DIALOG] cancel pressed")
        app.stopModal(withCode: .cancel)
    }
    let closeDelegate = ModalCloseDelegate(onClose: {
        DebugLog.log("[DIALOG] window close (willClose)")
        app.stopModal(withCode: .cancel)
    })
    panel.delegate = closeDelegate
    saveButton.target = saveTarget
    saveButton.action = #selector(BlockTarget.invoke)
    cancelButton.target = cancelTarget
    cancelButton.action = #selector(BlockTarget.invoke)

    DebugLog.log("[DIALOG] setup complete, launching modal")
    panel.center()
    panel.makeKeyAndOrderFront(nil)
    app.activate(ignoringOtherApps: true)
    DebugLog.log("[DIALOG] calling runModal")
    let response = app.runModal(for: panel)
    DebugLog.log("[DIALOG] runModal returned \(response.rawValue)")
    panel.orderOut(nil)
    panel.delegate = nil
    panel.close()
    DebugLog.log("[DIALOG] panel closed")

    _ = (fetchTarget, testTarget, saveTarget, cancelTarget, closeDelegate, providerChangeTarget, envHintTarget, apiKeyDelegate)

    guard response == .OK else { return nil }

    var updated = config
    updated.phrases.wake = wakeField.stringValue.lowercased().trimmingCharacters(in: .whitespaces)
    updated.phrases.end = endField.stringValue.lowercased().trimmingCharacters(in: .whitespaces)
    updated.phrases.approveMemo = approveMemoField.stringValue.lowercased().trimmingCharacters(in: .whitespaces)
    updated.phrases.cancel = cancelField.stringValue.lowercased().trimmingCharacters(in: .whitespaces)
    updated.phrases.approve = approveField.stringValue.lowercased().trimmingCharacters(in: .whitespaces)
    updated.phrases.revise = reviseField.stringValue.lowercased().trimmingCharacters(in: .whitespaces)
    updated.queueBasePath = queuePathField.stringValue.trimmingCharacters(in: .whitespaces)
    updated.recognition.inputDeviceId = devicePopup.selectedItem?.representedObject as? String
    updated.llm = currentLlmConfig()

    DebugLog.log("[DIALOG] returning updated config")
    return updated
}
