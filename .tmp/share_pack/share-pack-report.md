# Share Pack Report

- Timestamp: 2025-08-23 16:35:13
- Branch: feat/five-point-alignment
- Commit: 4c56dc2
- Files: 463
- Size: 55.55 MB

## Exclude rules
- --exclude=.git/
- --exclude=DerivedData/
- --exclude=build/
- --exclude=.build/
- --exclude=SourcePackages/
- --exclude=Pods/
- --exclude=Carthage/Build/
- --exclude=Documents/proof/
- --exclude=*.ipa
- --exclude=*.dSYM
- --exclude=*.xcarchive
- --exclude=**/.DS_Store
- --exclude=**/xcuserdata/
- --exclude=Resources/Models/*
- --include=Resources/Models/models.spec.json
- --include=Resources/Models/models.lock.json
- --include=Resources/Models/THIRD_PARTY_MODELS.md
- --exclude=*.pem
- --exclude=*.p12
- --exclude=*.mobileprovision
- --exclude=**/manifest_signing_private.pem
- --exclude=**/manifest_signing_public.pem
- --exclude=beauty/Config/Supabase.xcconfig

## Key paths snapshot (top-level)
.
.github
.github/workflows
.gitignore
.tmp
.tmp/share_pack
.tools
.tools/bin
.tools/gh_2.76.2_macOS_amd64
beauty
beauty.xcodeproj
beauty.xcodeproj/project.pbxproj
beauty.xcodeproj/project.xcworkspace
beauty.xcodeproj/xcshareddata
beauty/.github
beauty/App.swift
beauty/Assets.xcassets
beauty/beauty
beauty/beauty.entitlements
beauty/Config
beauty/ContentView.swift
beauty/Core
beauty/DevTools
beauty/Docs
beauty/Effects
beauty/en.lproj
beauty/Features
beauty/fr.lproj
beauty/home_data.json
beauty/ios
beauty/Item.swift
beauty/knowledge_data.json
beauty/Models
beauty/procedures_cn.json
beauty/procedures_fr.json
beauty/procedures_us.json
beauty/README_RemoteEffects.md
beauty/README.md
beauty/Tests
beauty/UITests
beauty/UnitTests
beauty/Views
beauty/zh-Hans.lproj
beautyTests
beautyTests/AestheticsMetricsTests.swift
beautyTests/beautyTests.swift
beautyTests/TelemetryTests.swift
beautyUITests
beautyUITests/beautyUITests.swift
beautyUITests/beautyUITestsLaunchTests.swift
docs
docs/AB_Metrics_README.md
docs/CalibrationCard_README.md
docs/CELEB_MATCH_README.md
docs/RELEASE_CHECKLIST.md
edge
edge/embedder
edge/kb-crawler
functions
functions/embedder
functions/kb-crawler
functions/manifest-sign
ios
ios/Common
ios/FaceCapture
Makefile
project-inventory.txt
README.md
Resources
Resources/Models
samples
samples/celeb_gallery
scripts
scripts/export_coreml
scripts/models_sync.py
scripts/scan_for_secrets.py
scripts/share_pack.sh
server
server/services
server/supabase
server/utils
Settings
specs
specs/golden_mask
sql
sql/kb_schema.sql
SSH
supabase
supabase/config.toml
supabase/sql
tools
tools/build_celeb_index.py
tools/convert_arcface_to_coreml.py

## Secrets scan

## Required manifests
- [ ] Resources/Models/models.spec.json
- [ ] Resources/Models/models.lock.json
- [ ] Resources/Models/THIRD_PARTY_MODELS.md
- [x] beauty/Config/Supabase.example.xcconfig

## Build environment
- Xcode: Xcode 16.4 Build version 16F6 
- iOS minimum: File Doesn't Exist, Will Create: /Users/zhangliyuan/Desktop/beauty/beauty/beauty/Info.plist
unknown
