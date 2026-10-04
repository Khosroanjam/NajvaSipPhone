pragma Singleton
import QtQuick
import QtCore

// Design tokens for SagharSIP. Every color in the UI comes from here so
// dark/light switching is a single property flip (persisted in QSettings).
QtObject {
    id: theme

    property Settings _store: Settings {
        category: "Appearance"
        property alias darkMode: theme.dark
    }

    property bool dark: true
    function toggle() { dark = !dark }

    // ── Surfaces ─────────────────────────────────────────────────────
    readonly property color bg:            dark ? "#0B0F17" : "#F3F5F9"
    readonly property color surface:       dark ? "#121826" : "#FFFFFF"
    readonly property color surfaceRaised: dark ? "#1A2232" : "#F6F8FB"
    readonly property color surfaceHover:  dark ? "#232D41" : "#EAEFF6"
    readonly property color surfacePress:  dark ? "#2A3650" : "#DFE6F0"
    readonly property color rail:          dark ? "#0E131D" : "#E9EDF4"
    readonly property color border:        dark ? "#263045" : "#DCE2EB"
    readonly property color borderStrong:  dark ? "#34405A" : "#C5CEDB"
    readonly property color overlay:       dark ? "#B3000000" : "#66101828"

    // ── Text (all ≥4.5:1 on surface) ─────────────────────────────────
    readonly property color textPrimary:   dark ? "#E8ECF4" : "#0F172A"
    readonly property color textSecondary: dark ? "#A6B0C3" : "#475569"
    readonly property color textMuted:     dark ? "#7D889E" : "#64748B"
    readonly property color textOnAccent:  "#FFFFFF"

    // ── Brand & semantic ─────────────────────────────────────────────
    readonly property color accent:        dark ? "#5B84FF" : "#2F5BEA"
    readonly property color accentHover:   dark ? "#7698FF" : "#2149CC"
    readonly property color accentSoft:    dark ? "#1F2B4D" : "#E3EAFD"
    readonly property color accent2:       "#8B5CF6"
    readonly property color success:       dark ? "#22C55E" : "#16A34A"
    readonly property color successHover:  dark ? "#3AD474" : "#12893E"
    readonly property color successSoft:   dark ? "#13301F" : "#DCF5E4"
    readonly property color danger:        dark ? "#F05252" : "#DC2626"
    readonly property color dangerHover:   dark ? "#F47171" : "#B91C1C"
    readonly property color dangerSoft:    dark ? "#3A1A1D" : "#FDE4E4"
    readonly property color warning:       dark ? "#F5A524" : "#B45309"
    readonly property color warningSoft:   dark ? "#3A2A12" : "#FDF0D9"
    readonly property color focusRing:     accent

    // ── Typography ───────────────────────────────────────────────────
    readonly property string fontFamily: "Segoe UI"
    readonly property int textXs: 11
    readonly property int textSm: 12
    readonly property int textMd: 14
    readonly property int textLg: 16
    readonly property int textXl: 20
    readonly property int text2xl: 26
    readonly property int textDisplay: 34

    readonly property font fontBody:    Qt.font({ family: fontFamily, pixelSize: textMd })
    readonly property font fontSmall:   Qt.font({ family: fontFamily, pixelSize: textSm })
    readonly property font fontLabel:   Qt.font({ family: fontFamily, pixelSize: textSm, weight: Font.DemiBold })
    readonly property font fontTitle:   Qt.font({ family: fontFamily, pixelSize: textLg, weight: Font.DemiBold })
    readonly property font fontHeading: Qt.font({ family: fontFamily, pixelSize: textXl, weight: Font.DemiBold })
    readonly property font fontDialpad: Qt.font({ family: fontFamily, pixelSize: 26, weight: Font.Normal })

    // ── Shape & spacing (4px grid) ───────────────────────────────────
    readonly property int radiusSm: 6
    readonly property int radius: 10
    readonly property int radiusLg: 14
    readonly property int space1: 4
    readonly property int space2: 8
    readonly property int space3: 12
    readonly property int space4: 16
    readonly property int space5: 20
    readonly property int space6: 24
    readonly property int controlHeight: 40

    // ── Motion ───────────────────────────────────────────────────────
    readonly property int durFast: 120
    readonly property int durNormal: 200
    readonly property int durSlow: 300

    // Backwards-compatible aliases
    readonly property color bgPrimary: bg
    readonly property color bgSecondary: surface
    readonly property color bgTertiary: surfaceRaised
    readonly property color bgHover: surfaceHover
    readonly property int radiusSmall: radiusSm
    readonly property int spacing: space3

    function alpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }
}
