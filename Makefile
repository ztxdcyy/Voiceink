APP_NAME = VoiceInk
BUNDLE_ID = com.voiceink.app
BUILD_DIR = .build/release
APP_BUNDLE = $(BUILD_DIR)/$(APP_NAME).app

.PHONY: build run install qa clean reset-permissions

build:
	swift build -c release
	mkdir -p "$(APP_BUNDLE)/Contents/MacOS"
	mkdir -p "$(APP_BUNDLE)/Contents/Resources"
	cp "$(BUILD_DIR)/$(APP_NAME)" "$(APP_BUNDLE)/Contents/MacOS/"
	cp "Sources/VoiceInk/Resources/Info.plist" "$(APP_BUNDLE)/Contents/"
	codesign --force --sign - "$(APP_BUNDLE)"
	@tccutil reset Accessibility $(BUNDLE_ID) 2>/dev/null || true
	@tccutil reset Microphone $(BUNDLE_ID) 2>/dev/null || true

run: build
	@pkill -x $(APP_NAME) 2>/dev/null || true
	@killall $(APP_NAME) 2>/dev/null || true
	@sleep 0.5
	open "$(APP_BUNDLE)"

install: build
	cp -R "$(APP_BUNDLE)" /Applications/
	@echo "Installed to /Applications/$(APP_NAME).app"

reset-permissions:
	@echo "Resetting TCC Accessibility for $(BUNDLE_ID)..."
	@tccutil reset Accessibility $(BUNDLE_ID) 2>/dev/null || true
	@echo "Done. Re-run the app and re-authorize in System Settings."

qa: build
	@echo "--- VoiceInk QA Prep ---"
	@echo "1) App bundle: $(APP_BUNDLE)"
	@test -f "$(APP_BUNDLE)/Contents/MacOS/$(APP_NAME)" && echo "2) Binary exists: OK" || (echo "2) Binary missing" && exit 1)
	@test -f "$(APP_BUNDLE)/Contents/Info.plist" && echo "3) Info.plist exists: OK" || (echo "3) Info.plist missing" && exit 1)
	@echo "4) Manual QA checklist: QA_CHECKLIST.md"

clean:
	swift package clean
	rm -rf .build
