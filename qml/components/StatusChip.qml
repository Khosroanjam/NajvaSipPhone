import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../theme"

// Pill showing a status with colored dot + text (color is never the only cue).
// tone: "success" | "danger" | "warning" | "neutral"
Rectangle {
    id: root
    property string text: ""
    property string tone: "neutral"
    property string iconName: ""
    property bool pulsing: false

    readonly property color toneColor: tone === "success" ? Theme.success
                                     : tone === "danger"  ? Theme.danger
                                     : tone === "warning" ? Theme.warning
                                     : Theme.textMuted
    readonly property color toneSoft: tone === "success" ? Theme.successSoft
                                    : tone === "danger"  ? Theme.dangerSoft
                                    : tone === "warning" ? Theme.warningSoft
                                    : Theme.surfaceRaised

    onPulsingChanged: if (!pulsing) dot.opacity = 1

    implicitHeight: 26
    implicitWidth: row.implicitWidth + 20
    radius: height / 2
    color: toneSoft
    Behavior on color { ColorAnimation { duration: Theme.durNormal } }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 6

        Rectangle {
            id: dot
            visible: root.iconName === ""
            width: 7; height: 7; radius: 3.5
            color: root.toneColor
            SequentialAnimation on opacity {
                running: root.pulsing
                loops: Animation.Infinite
                NumberAnimation { to: 0.35; duration: 700 }
                NumberAnimation { to: 1.0; duration: 700 }
            }
        }
        Icon {
            visible: root.iconName !== ""
            name: root.iconName
            size: 13
            color: root.toneColor
        }
        Label {
            text: root.text
            color: root.toneColor
            font.family: Theme.fontFamily
            font.pixelSize: Theme.textSm
            font.weight: Font.DemiBold
        }
    }
}
