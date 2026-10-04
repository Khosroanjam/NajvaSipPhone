import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../theme"

// Text button with optional leading icon.
// variant: "primary" | "success" | "danger" | "secondary" | "ghost"
Button {
    id: control
    property string variant: "primary"
    property string iconName: ""
    property bool compact: false

    readonly property bool _filled: variant === "primary" || variant === "success" || variant === "danger"
    readonly property color _base: variant === "success" ? Theme.success
                                 : variant === "danger"  ? Theme.danger
                                 : Theme.accent
    readonly property color _hover: variant === "success" ? Theme.successHover
                                  : variant === "danger"  ? Theme.dangerHover
                                  : Theme.accentHover
    readonly property color _fg: !enabled ? Theme.textMuted
                               : _filled ? Theme.textOnAccent
                               : variant === "ghost" ? Theme.textSecondary
                               : Theme.textPrimary

    implicitHeight: compact ? 32 : Theme.controlHeight
    leftPadding: compact ? 12 : 16
    rightPadding: compact ? 12 : 16
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus
    font.family: Theme.fontFamily
    font.pixelSize: compact ? Theme.textSm : Theme.textMd
    font.weight: Font.DemiBold

    HoverHandler { cursorShape: Qt.PointingHandCursor }

    contentItem: RowLayout {
        spacing: 8
        Item { Layout.fillWidth: true }
        Icon {
            visible: control.iconName !== ""
            name: control.iconName
            size: control.compact ? 14 : 16
            color: control._fg
        }
        Label {
            text: control.text
            font: control.font
            color: control._fg
            visible: text !== ""
        }
        Item { Layout.fillWidth: true }
    }

    background: Rectangle {
        radius: Theme.radius
        color: {
            if (!control.enabled)
                return control._filled ? Theme.surfaceRaised : "transparent"
            if (control._filled)
                return control.down ? Qt.darker(control._hover, 1.1)
                     : control.hovered ? control._hover : control._base
            if (control.variant === "secondary")
                return control.down ? Theme.surfacePress
                     : control.hovered ? Theme.surfaceHover : Theme.surfaceRaised
            return control.down ? Theme.surfacePress
                 : control.hovered ? Theme.surfaceHover : "transparent"
        }
        border.width: control.variant === "secondary" ? 1 : 0
        border.color: Theme.border
        Behavior on color { ColorAnimation { duration: Theme.durFast } }

        FocusRing { target: control }
    }
}
