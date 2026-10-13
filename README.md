# Base44 Xcode Bridge

Een eerste macOS SwiftUI-app die als prototype kan dienen voor:
- verbinding met Base44
- ophalen van een projectlijst
- downloaden van een Xcode-projectarchive
- uitpakken en openen in Xcode
- build/run op een simulator

Deze versie is een startpunt voor een app die later ook op echte iPhone/iPad-apparaten kan installeren.

## Snel starten

1. Open het project in Xcode via `Open Package` of met:
   ```bash
   swift build
   ```
2. Run het project in Xcode.
3. Vul in de UI:
   - Base44 URL (bijv. `https://api.base44.example`)
   - token
4. Klik op `Load projects`
5. Kies een project en klik op `Open in Xcode`

## Belangrijk

- De echte Base44 API-endpoints verschillen per account en kunnen worden aangepast.
- Voor echte device-installatie heb je een Apple Developer-account, provisioning profiles en code signing nodig.
- Deze code is een starter en bevat voorbeeld-implementaties, geen echte private credentials.

## Structuur

- `Sources/Base44XcodeBridge/main.swift` – SwiftUI app
- `Sources/Base44XcodeBridge/Base44Client.swift` – Base44 API-client
- `Sources/Base44XcodeBridge/XcodeProjectManager.swift` – unzip, detecteren en openen van Xcode-projecten

## Volgende stap

In de volgende versie kunnen we toevoegen:
- simulator build flow met `xcodebuild`
- device installatie met `xcrun` / Fastlane
- Keychain voor tokens
- imports van projectbestanden en editing van `.xcodeproj`
- automatische upload terug naar Base44
