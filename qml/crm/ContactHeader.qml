import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../theme"
import "../components"

// Selected contact summary card.
Card {
    id: root
    property var contact: null
    readonly property bool hasContact: contact !== null && contact !== undefined

    implicitHeight: body.implicitHeight + 32

    ColumnLayout {
        id: body
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 16
        spacing: 14

        RowLayout {
            Layout.fillWidth: true
            spacing: 14

            Avatar {
                size: root.hasContact ? 52 : 44
                name: root.hasContact && root.contact.name !== root.contact.phone ? (root.contact.name || "") : ""
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Label {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    text: root.hasContact ? (root.contact.name || "Unknown") : "No contact selected"
                    color: root.hasContact ? Theme.textPrimary : Theme.textSecondary
                    font: root.hasContact ? Theme.fontHeading : Theme.fontTitle
                }
                Label {
                    Layout.fillWidth: true
                    text: root.hasContact ? (root.contact.company || "") : "Pick a call from the history to see details"
                    visible: text !== ""
                    color: Theme.textMuted
                    font: Theme.fontSmall
                    wrapMode: Text.Wrap
                }

                Flow {
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    spacing: 6
                    visible: root.hasContact && !!root.contact.tags && root.contact.tags.length > 0
                    Repeater {
                        model: root.hasContact && root.contact.tags ? root.contact.tags : []
                        delegate: Rectangle {
                            width: tagLabel.implicitWidth + 16
                            height: 22
                            radius: 11
                            color: Theme.accentSoft
                            Label {
                                id: tagLabel
                                anchors.centerIn: parent
                                text: modelData
                                color: Theme.accent
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.textXs
                                font.weight: Font.DemiBold
                            }
                        }
                    }
                }
            }

            IconButton {
                Layout.alignment: Qt.AlignTop
                visible: root.hasContact
                iconName: "phone"
                variant: "success"
                tooltip: "Call " + (root.hasContact ? root.contact.phone : "")
                enabled: typeof sipManager !== "undefined" && sipManager && sipManager.isRegistered
                onClicked: sipManager.makeCall(root.contact.phone)
            }
        }

        Rectangle {
            visible: root.hasContact
            Layout.fillWidth: true
            height: 1
            color: Theme.border
        }

        GridLayout {
            visible: root.hasContact
            Layout.fillWidth: true
            columns: 2
            columnSpacing: 12
            rowSpacing: 10

            Icon { name: "phone"; size: 15; color: Theme.textMuted }
            Label {
                Layout.fillWidth: true
                text: root.hasContact ? (root.contact.phone || "—") : ""
                color: Theme.textPrimary
                font: Theme.fontBody
                elide: Text.ElideRight
            }
            Icon { name: "mail"; size: 15; color: Theme.textMuted }
            Label {
                Layout.fillWidth: true
                text: root.hasContact && root.contact.email && root.contact.email !== "-" ? root.contact.email : "No email"
                color: root.hasContact && root.contact.email && root.contact.email !== "-" ? Theme.textPrimary : Theme.textMuted
                font: Theme.fontBody
                elide: Text.ElideRight
            }
        }
    }
}
