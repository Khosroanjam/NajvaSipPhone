import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../theme"
import "../components"

// Up to three most recent notes for the caller, shown during a call.
ColumnLayout {
    id: root
    property var notesData: []
    property string callerNumber: ""

    spacing: 8

    SectionHeader {
        Layout.fillWidth: true
        title: "Previous interactions"
        iconName: "notes"
        meta: root.notesData ? root.notesData.length + "" : ""
    }

    Repeater {
        model: root.notesData
        delegate: Rectangle {
            Layout.fillWidth: true
            implicitHeight: noteCol.implicitHeight + 20
            radius: Theme.radius
            color: Theme.surfaceRaised
            border.width: 1
            border.color: Theme.border

            readonly property string dir: modelData.direction || ""

            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                Rectangle {
                    Layout.alignment: Qt.AlignTop
                    width: 26; height: 26; radius: 13
                    color: dir === "incoming" ? Theme.successSoft
                         : dir === "outgoing" ? Theme.accentSoft : Theme.dangerSoft
                    Icon {
                        anchors.centerIn: parent
                        size: 14
                        name: dir === "incoming" ? "arrow-in" : dir === "outgoing" ? "arrow-out" : "x"
                        color: dir === "incoming" ? Theme.success
                             : dir === "outgoing" ? Theme.accent : Theme.danger
                    }
                }

                ColumnLayout {
                    id: noteCol
                    Layout.fillWidth: true
                    spacing: 2
                    Label {
                        Layout.fillWidth: true
                        text: modelData.text || ""
                        color: Theme.textPrimary
                        font: Theme.fontBody
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                    }
                    Label {
                        text: {
                            var ts = modelData.timestamp || modelData.created
                            return ts ? Qt.formatDateTime(new Date(ts), "yyyy/MM/dd · HH:mm") : ""
                        }
                        color: Theme.textMuted
                        font: Theme.fontSmall
                    }
                }
            }
        }
    }
}
