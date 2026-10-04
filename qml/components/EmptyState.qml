import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../theme"

// Centered icon + title + hint for empty lists. The root is a plain Item so
// it can absorb Layout.fillHeight (a nested layout would cap its max height).
Item {
    id: root
    property string iconName: "history"
    property string title: ""
    property string hint: ""

    implicitWidth: col.implicitWidth
    implicitHeight: col.implicitHeight

    ColumnLayout {
        id: col
        anchors.centerIn: parent
        width: Math.min(parent.width, 320)
        spacing: 8

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 48
            Layout.preferredHeight: 48
            radius: 24
            color: Theme.surfaceRaised
            Icon {
                anchors.centerIn: parent
                name: root.iconName
                size: 22
                color: Theme.textMuted
            }
        }
        Label {
            Layout.alignment: Qt.AlignHCenter
            text: root.title
            color: Theme.textPrimary
            font: Theme.fontTitle
            visible: text !== ""
        }
        Label {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            text: root.hint
            color: Theme.textMuted
            font: Theme.fontSmall
            visible: text !== ""
        }
    }
}
