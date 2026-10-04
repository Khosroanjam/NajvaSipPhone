import QtQuick
import QtQuick.Controls

import "../theme"

// Initial-letter avatar on the brand gradient.
Rectangle {
    id: root
    property string name: ""
    property real size: 40

    width: size
    height: size
    radius: size / 2
    gradient: Gradient {
        orientation: Gradient.Vertical
        GradientStop { position: 0.0; color: Theme.accent }
        GradientStop { position: 1.0; color: Theme.accent2 }
    }

    readonly property string initial: {
        var n = (root.name || "").toString().trim()
        return n.length > 0 ? n.charAt(0).toUpperCase() : ""
    }

    Label {
        anchors.centerIn: parent
        visible: root.initial !== ""
        text: root.initial
        color: Theme.textOnAccent
        font.family: Theme.fontFamily
        font.pixelSize: root.size * 0.42
        font.weight: Font.DemiBold
    }

    Icon {
        anchors.centerIn: parent
        visible: root.initial === ""
        name: "user"
        size: root.size * 0.5
        color: Theme.textOnAccent
    }
}
