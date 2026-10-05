import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../theme"
import "../components"

Item {
    id: root
    property var currentContact: null
    property var history: []
    property int selectedCallId: -1
    property string pendingNumber: ""

    readonly property bool wide: width >= 720

    Connections {
        target: typeof db !== "undefined" ? db : null
        function onCallHistoryChanged() { root.refreshHistory() }
        // History rows carry phonebook names, so re-read when contacts change.
        function onContactsChanged() {
            root.refreshHistory()
            if (root.currentContact)
                root.currentContact = root.contactFor(root.currentContact.phone, "")
        }
    }

    Component.onCompleted: root.refreshHistory()

    // Contact card data for a number: the phonebook entry when there is one.
    function contactFor(number, fallbackName) {
        var c = typeof db !== "undefined" && db ? db.contactByNumber(number) : null
        var known = c && c.id !== undefined
        var name = known ? c.name : (fallbackName || number)
        return {
            name: name,
            phone: number,
            email: known ? c.email : "",
            company: known ? c.notes : "",
            saved: known,
            avatar: String(name).charAt(0).toUpperCase()
        }
    }

    function refreshHistory() {
        if (typeof db !== "undefined" && db)
            root.history = db.callHistory(100)
    }

    GridLayout {
        anchors.fill: parent
        anchors.margins: 24
        columns: root.wide ? 2 : 1
        columnSpacing: 20
        rowSpacing: 20

        // ── Recent calls ──
        Card {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 3
            Layout.minimumHeight: 260

            CallHistory {
                anchors.fill: parent
                anchors.margins: 16
                history: root.history
                selectedId: root.selectedCallId
                onSaveToContacts: function(number, name) {
                    root.pendingNumber = number
                    contactNameField.text = name && name !== number ? name : ""
                    addContactDialog.open()
                }
                onCallSelected: function(callId, number, name) {
                    root.selectedCallId = callId
                    root.currentContact = root.contactFor(number, name)
                }
            }
        }

        // ── Contact + notes ──
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 2
            spacing: 20

            ContactHeader {
                Layout.fillWidth: true
                contact: root.currentContact
            }

            Card {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 240

                NotesSection {
                    anchors.fill: parent
                    anchors.margins: 16
                    callHistoryId: root.selectedCallId
                }
            }
        }
    }

    // ── Save to contacts ──
    Popup {
        id: addContactDialog
        parent: Overlay.overlay
        anchors.centerIn: Overlay.overlay
        width: 380
        modal: true
        padding: 24
        onOpened: contactNameField.field.forceActiveFocus()

        Overlay.modal: Rectangle { color: Theme.overlay }
        background: Rectangle {
            radius: Theme.radiusLg
            color: Theme.surface
            border.width: 1
            border.color: Theme.border
        }

        contentItem: ColumnLayout {
            spacing: 16

            RowLayout {
                spacing: 12
                Rectangle {
                    width: 40; height: 40; radius: 20
                    color: Theme.accentSoft
                    Icon { anchors.centerIn: parent; name: "user-plus"; size: 18; color: Theme.accent }
                }
                ColumnLayout {
                    spacing: 2
                    Label { text: "Save to contacts"; color: Theme.textPrimary; font: Theme.fontTitle }
                    Label { text: root.pendingNumber; color: Theme.textMuted; font: Theme.fontSmall }
                }
            }

            AppTextField {
                id: contactNameField
                Layout.fillWidth: true
                label: "Name"
                placeholderText: "Contact name"
            }
            Connections {
                target: contactNameField.field
                function onAccepted() { saveBtn.clicked() }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Item { Layout.fillWidth: true }
                AppButton {
                    text: "Cancel"
                    variant: "ghost"
                    onClicked: addContactDialog.close()
                }
                AppButton {
                    id: saveBtn
                    text: "Save"
                    iconName: "check"
                    enabled: contactNameField.text.trim().length > 0
                    onClicked: {
                        if (!enabled) return
                        if (typeof db !== "undefined" && db) {
                            var existing = db.contactByNumber(root.pendingNumber)
                            if (existing && existing.id !== undefined)
                                db.updateContact(existing.id, contactNameField.text.trim(), existing.number,
                                                 existing.email, existing.notes)
                            else
                                db.addContact(contactNameField.text.trim(), root.pendingNumber)
                        }
                        addContactDialog.close()
                    }
                }
            }
        }
    }
}
