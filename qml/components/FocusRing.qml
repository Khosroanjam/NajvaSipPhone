import QtQuick

import "../theme"

// Keyboard focus indicator. Place inside a control's background.
Rectangle {
    property Item target: null
    property real ringRadius: parent ? parent.radius + 3 : Theme.radius + 3

    anchors.fill: parent
    anchors.margins: -3
    radius: ringRadius
    color: "transparent"
    border.width: 2
    border.color: Theme.focusRing
    visible: target && target.visualFocus
}
