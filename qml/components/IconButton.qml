import QtQuick
import QtQuick.Controls

import "../theme"

// Icon-only button with tooltip (doubles as accessible name).
// variant: "ghost" | "secondary" | "primary" | "success" | "danger"
AbstractButton {
    id: control
    property string iconName: ""
    property string tooltip: ""
    property string variant: "ghost"
    property real buttonSize: 36
    property real iconSize: 18
    property bool active: false     // toggled state (e.g. muted)
    property color iconColor: {
        if (!enabled) return Theme.textMuted
        if (variant === "primary" || variant === "success" || variant === "danger" || active)
            return Theme.textOnAccent
        return hovered ? Theme.textPrimary : Theme.textSecondary
    }

    implicitWidth: buttonSize
    implicitHeight: buttonSize
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus
    Accessible.name: tooltip

    HoverHandler { cursorShape: Qt.PointingHandCursor }

    ToolTip.visible: tooltip !== "" && hovered
    ToolTip.delay: 600
    ToolTip.text: tooltip

    contentItem: Item {
        Icon {
            anchors.centerIn: parent
            name: control.iconName
            size: control.iconSize
            color: control.iconColor
        }
    }

    background: Rectangle {
        radius: width / 2
        color: {
            if (control.active) return Theme.accent
            switch (control.variant) {
            case "primary": return control.hovered ? Theme.accentHover : Theme.accent
            case "success": return control.hovered ? Theme.successHover : Theme.success
            case "danger":  return control.hovered ? Theme.dangerHover : Theme.danger
            case "secondary":
                return control.down ? Theme.surfacePress
                     : control.hovered ? Theme.surfaceHover : Theme.surfaceRaised
            default:
                return control.down ? Theme.surfacePress
                     : control.hovered ? Theme.surfaceHover : "transparent"
            }
        }
        border.width: control.variant === "secondary" && !control.active ? 1 : 0
        border.color: Theme.border
        Behavior on color { ColorAnimation { duration: Theme.durFast } }

        FocusRing { target: control; ringRadius: width / 2 }
    }
}
