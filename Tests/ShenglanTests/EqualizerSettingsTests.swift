import Foundation
import Testing
@testable import Shenglan

@Test("Volume percentage conversion is rounded, clamped, and reversible")
func volumePercentageConversion() {
    #expect(VolumeLevel.percentage(from: -0.4) == 0)
    #expect(VolumeLevel.percentage(from: 0.079_999) == 8)
    #expect(VolumeLevel.percentage(from: 0.124) == 12)
    #expect(VolumeLevel.percentage(from: 0.125) == 13)
    #expect(VolumeLevel.percentage(from: 1.4) == 100)

    #expect(VolumeLevel.scalar(fromPercentage: -4) == 0)
    #expect(VolumeLevel.scalar(fromPercentage: 7) == 0.07)
    #expect(VolumeLevel.scalar(fromPercentage: 100) == 1)
    #expect(VolumeLevel.scalar(fromPercentage: 140) == 1)
}

@Test("Precision-volume controls are localized in every supported language")
func precisionVolumeControlsAreLocalized() {
    let labels: [AppLanguage: String] = [
        .simplifiedChinese: "输入精确音量百分比",
        .english: "Enter exact volume percentage",
        .japanese: "正確な音量のパーセント値を入力",
        .french: "Saisir le pourcentage exact du volume",
        .german: "Genauen Lautstärkeprozentsatz eingeben",
        .korean: "정확한 음량 백분율 입력"
    ]

    for language in AppLanguage.allCases {
        #expect(L10n.tr("输入精确音量百分比", language: language) == labels[language])
        #expect(L10n.tr("精调", language: language) != "精调" || language == .simplifiedChinese)
        #expect(L10n.tr("增加 1%", language: language) != "增加 1%" || language == .simplifiedChinese)
        #expect(L10n.tr("减少 1%", language: language) != "减少 1%" || language == .simplifiedChinese)
        #expect(L10n.tr("每次调整 1%", language: language) != "每次调整 1%" || language == .simplifiedChinese)
        #expect(L10n.tr("输入 0 到 100；选中滑杆后方向键每次调整 1%", language: language) != "输入 0 到 100；选中滑杆后方向键每次调整 1%" || language == .simplifiedChinese)
    }
}

@Test("Each EQ preset retains its own adjusted profile")
func eachPresetRetainsItsOwnAdjustedProfile() {
    var settings = EqualizerSettings()
    settings.apply(.vocal)
    settings.bandGainsDB[0] = 7.3
    settings.bandGainsDB[5] = -2.4
    settings.preampDB = -8.1
    settings.stereoBalance = -0.35
    settings.reverb = EqualizerReverbSettings(
        wetMix: 0.37,
        roomSize: 0.74,
        damping: 0.43,
        preDelayMS: 31,
        stereoWidth: 0.86
    )
    settings.saveCurrentPresetProfile()
    let savedVocal = settings.savedProfiles[EqualizerPreset.vocal.rawValue]

    settings.apply(.rock)
    settings.bandGainsDB[1] = 9.1
    settings.stereoBalance = 0.42
    settings.saveCurrentPresetProfile()
    let savedRock = settings.savedProfiles[EqualizerPreset.rock.rawValue]

    settings.apply(.vocal)

    #expect(settings.preset == .vocal)
    #expect(settings.isEnabled)
    #expect(settings.preampDB == savedVocal?.preampDB)
    #expect(settings.bandGainsDB == savedVocal?.bandGainsDB)
    #expect(settings.reverb == savedVocal?.reverb)
    #expect(settings.stereoBalance == savedVocal?.stereoBalance)

    settings.apply(.rock)
    #expect(settings.bandGainsDB == savedRock?.bandGainsDB)
    #expect(settings.stereoBalance == savedRock?.stereoBalance)
}

@Test("Reset restores only the active preset")
func resetRestoresOnlyTheActivePreset() {
    var settings = EqualizerSettings()
    settings.apply(.vocal)
    settings.bandGainsDB[2] = 5.6
    settings.stereoBalance = -0.6
    settings.saveCurrentPresetProfile()

    settings.apply(.rock)
    settings.bandGainsDB[8] = 9.4
    settings.stereoBalance = 0.25
    settings.saveCurrentPresetProfile()
    let savedRock = settings.savedProfiles[EqualizerPreset.rock.rawValue]

    settings.apply(.vocal)
    settings.resetCurrentPreset()

    #expect(settings.preset == .vocal)
    #expect(settings.isEnabled)
    #expect(settings.bandGainsDB == EqualizerPreset.vocal.bandGainsDB)
    #expect(settings.preampDB == EqualizerPreset.vocal.preampDB)
    #expect(settings.stereoBalance == 0)
    #expect(!settings.hasSavedProfile(for: .vocal))

    settings.apply(.rock)
    #expect(settings.savedProfiles[EqualizerPreset.rock.rawValue] == savedRock)
    #expect(settings.bandGainsDB == savedRock?.bandGainsDB)
    #expect(settings.stereoBalance == savedRock?.stereoBalance)
}

@Test("Legacy saved EQ without a custom slot remains decodable")
func legacySettingsRemainDecodable() throws {
    let legacy = Data(
        #"{"isEnabled":true,"preset":"custom","preampDB":-4.5,"bandGainsDB":[1,2,3,4,5,4,3,2,1,0]}"#.utf8
    )

    let decoded = try JSONDecoder().decode(EqualizerSettings.self, from: legacy)

    #expect(decoded.customProfile != nil)
    #expect(decoded.customProfile?.preampDB == -4.5)
    #expect(decoded.customProfile?.bandGainsDB == [1, 2, 3, 4, 5, 4, 3, 2, 1, 0])
    #expect(decoded.customProfile?.stereoBalance == 0)
    #expect(decoded.savedProfiles[EqualizerPreset.custom.rawValue] == decoded.customProfile)
}

@Test("Disable all EQ keeps every preset value and memory")
func disableAllEqualizersKeepsPresetValues() {
    var master = EqualizerSettings()
    master.apply(.vocal)
    master.bandGainsDB[3] = 6.8
    master.saveCurrentPresetProfile()
    let masterProfile = master.currentProfile

    var music = EqualizerSettings()
    music.apply(.rock)
    music.stereoBalance = -0.4
    music.saveCurrentPresetProfile()
    var applications = ["bundle:music": music]
    let musicProfile = music.currentProfile

    #expect(EqualizerBatchState.hasEnabled(master: master, applications: applications))

    EqualizerBatchState.disableAll(master: &master, applications: &applications)

    #expect(!EqualizerBatchState.hasEnabled(master: master, applications: applications))
    #expect(!master.isEnabled)
    #expect(applications.values.allSatisfy { !$0.isEnabled })
    #expect(master.currentProfile == masterProfile)
    #expect(master.savedProfiles[EqualizerPreset.vocal.rawValue] == masterProfile)
    #expect(applications["bundle:music"]?.currentProfile == musicProfile)
    #expect(applications["bundle:music"]?.savedProfiles[EqualizerPreset.rock.rawValue] == musicProfile)
}

@Test("Disable-all EQ action follows total EQ or current app EQ")
func disableAllEqualizersActionVisibility() {
    var master = EqualizerSettings()
    var currentApplications: [EqualizerSettings] = []

    master.apply(.rock)
    #expect(EqualizerBatchState.shouldShowDisableAllAction(
        master: master,
        currentApplications: currentApplications
    ))

    master.isEnabled = false
    #expect(!EqualizerBatchState.shouldShowDisableAllAction(
        master: master,
        currentApplications: currentApplications
    ))

    var appEqualizer = EqualizerSettings()
    appEqualizer.apply(.vocal)
    currentApplications = [appEqualizer]
    #expect(EqualizerBatchState.shouldShowDisableAllAction(
        master: master,
        currentApplications: currentApplications
    ))

    appEqualizer.isEnabled = false
    currentApplications = [appEqualizer]
    #expect(!EqualizerBatchState.shouldShowDisableAllAction(
        master: master,
        currentApplications: currentApplications
    ))
}

@Test("Compact EQ-off action is localized in every supported language")
func compactEqualizerOffActionIsLocalized() {
    let expected: [AppLanguage: String] = [
        .simplifiedChinese: "关闭EQ",
        .english: "Turn Off EQ",
        .japanese: "EQをオフ",
        .french: "Désactiver l’EQ",
        .german: "EQ ausschalten",
        .korean: "EQ 끄기"
    ]

    for language in AppLanguage.allCases {
        #expect(L10n.tr("关闭EQ", language: language) == expected[language])
    }
}
