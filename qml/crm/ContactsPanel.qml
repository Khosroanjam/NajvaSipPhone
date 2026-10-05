import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../theme"
import "../components"

// Phonebook: searchable contact list plus an add/edit form.
Item {
    id: root
    property var contacts: []
    property int editingId: -1          // -1 = form closed, 0 = new contact, >0 = contact id
    property bool confirmDelete: false

    readonly property bool dbReady: typeof db !== "undefined" && db !== null
    readonly property bool sipRegistered: typeof sipManager !== "undefined" && sipManager !== null && sipManager.isRegistered
    readonly property bool editing: editingId >= 0
    readonly property bool wide: width >= 720

    // Another contact already saved under the number being typed (matched like caller ID).
    readonly property var duplicateOf: {
        var n = numberField.text.trim()
        if (!editing || n === "" || !dbReady) return null
        var c = db.contactByNumber(n)
        return c && c.id !== undefined && c.id !== editingId ? c : null
    }
    readonly property bool canSave: nameField.text.trim() !== "" && numberField.text.trim() !== "" && duplicateOf === null

    Component.onCompleted: refresh()

    Connections {
        target: root.dbReady ? db : null
        function onContactsChanged() { root.refresh() }
    }

    function refresh() {
        contacts = dbReady ? db.contacts(searchField.text.trim()) : []
    }

    // Open the form for a new contact, optionally prefilled (e.g. from call history).
    function startNew(number, name) {
        editingId = 0
        confirmDelete = false
        nameField.text = name || ""
        numberField.text = number || ""
        emailField.text = ""
        notesArea.text = ""
        if (nameField.text === "")
            nameField.field.forceActiveFocus()
        else
            numberField.field.forceActiveFocus()
    }

    function startEdit(contact) {
        editingId = contact.id
        confirmDelete = false
        nameField.text = contact.name || ""
        numberField.text = contact.number || ""
        emailField.text = contact.email || ""
        notesArea.text = contact.notes || ""
        nameField.field.forceActiveFocus()
    }

    function closeForm() {
        editingId = -1
        confirmDelete = false
    }

    function save() {
        if (!canSave || !dbReady) return
        var name = nameField.text.trim()
        var number = numberField.text.replace(/\s+/g, "")
        if (editingId === 0)
            db.addContact(name, number, emailField.text.trim(), notesArea.text.trim())
        else
            db.updateContact(editingId, name, number, emailField.text.trim(), notesArea.text.trim())
        closeForm()
    }

    function remove() {
        if (editingId > 0 && dbReady)
            db.deleteContact(editingId)
        closeForm()
    }

    Timer {
        id: searchDebounce
        interval: 200
        onTriggered: root.refresh()
    }

    Shortcut {
        sequence: StandardKey.New
        enabled: root.visible
        onActivated: root.startNew("", "")
    }

    GridLayout {
        anchors.fill: parent
        anchors.margins: 24
        columns: root.wide ? 2 : 1
        columnSpacing: 20
        rowSpacing: 20

        // ── Contact list ──
        Card {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 3
            Layout.minimumHeight: 260

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    SectionHeader {
                        Layout.fillWidth: true
                        title: "Phonebook"
                        iconName: "users"
                        meta: root.contacts.length > 0 ? root.contacts.length + (root.contacts.length === 1 ? " contact" : " contacts") : ""
                    }
                    AppButton {
                        text: "New contact"
                        iconName: "user-plus"
                        compact: true
                        onClicked: root.startNew("", "")
                    }
                }

                AppTextField {
                    id: searchField
                    Layout.fillWidth: true
                    leadingIcon: "search"
                    placeholderText: "Search name, number or email"
                    onEdited: searchDebounce.restart()
                }

                ListView {
                    id: list
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: root.contacts.length > 0
                    model: root.contacts
                    clip: true
                    spacing: 2
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                    delegate: ItemDelegate {
                        id: row
                        width: list.width - 8
                        height: 58
                        hoverEnabled: true
                        leftPadding: 10
                        rightPadding: 8
                        topPadding: 0
                        bottomPadding: 0
                        readonly property bool selected: modelData.id === root.editingId
                        Accessible.name: modelData.name + ", " + modelData.number
                        onClicked: root.startEdit(modelData)

                        HoverHandler { cursorShape: Qt.PointingHandCursor }

                        background: Rectangle {
                            radius: Theme.radius
                            color: row.selected ? Theme.accentSoft
                                 : row.hovered ? Theme.surfaceHover : "transparent"
                            Behavior on color { ColorAnimation { duration: Theme.durFast } }
                        }

                        contentItem: RowLayout {
                            spacing: 12

                            Avatar { size: 36; name: modelData.name }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1
                                Label {
                                    Layout.fillWidth: true
                                    text: modelData.name
                                    color: Theme.textPrimary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.textMd
                                    font.weight: Font.DemiBold
                                    elide: Text.ElideRight
                                }
                                Label {
                                    Layout.fillWidth: true
                                    text: modelData.number + (modelData.email ? " · " + modelData.email : "")
                                    color: Theme.textMuted
                                    font: Theme.fontSmall
                                    elide: Text.ElideRight
                                }
                            }

                            IconButton {
                                visible: row.hovered || row.selected
                                iconName: "pencil"
                                iconSize: 16
                                buttonSize: 32
                                tooltip: "Edit"
                                onClicked: root.startEdit(modelData)
                            }
                            IconButton {
                                iconName: "phone"
                                iconSize: 16
                                buttonSize: 32
                                variant: "success"
                                tooltip: root.sipRegistered ? "Call " + modelData.number : "Not registered"
                                enabled: root.sipRegistered
                                onClicked: sipManager.makeCall(modelData.number)
                            }
                        }
                    }
                }

                EmptyState {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: !list.visible
                    iconName: searchField.text.trim() !== "" ? "search" : "users"
                    title: searchField.text.trim() !== "" ? "No matches" : "No contacts yet"
                    hint: searchField.text.trim() !== ""
                          ? "Try another name or part of the number."
                          : "Add one with “New contact”, or save a number from Recent calls."
                }
            }
        }

        // ── Add / edit form ──
        Card {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 2
            Layout.minimumHeight: 260

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 14
                visible: root.editing

                SectionHeader {
                    Layout.fillWidth: true
                    title: root.editingId === 0 ? "New contact" : "Edit contact"
                    iconName: root.editingId === 0 ? "user-plus" : "pencil"
                }

                AppTextField {
                    id: nameField
                    Layout.fillWidth: true
                    label: "Name"
                    placeholderText: "Full name"
                }

                AppTextField {
                    id: numberField
                    Layout.fillWidth: true
                    label: "Phone number"
                    placeholderText: "e.g. 09121234567"
                    leadingIcon: "phone"
                    helperText: root.duplicateOf ? "Already saved as “" + root.duplicateOf.name + "”" : ""
                }

                AppTextField {
                    id: emailField
                    Layout.fillWidth: true
                    label: "Email (optional)"
                    placeholderText: "name@example.com"
                    leadingIcon: "mail"
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 6
                    Label { text: "Notes (optional)"; color: Theme.textSecondary; font: Theme.fontLabel }
                    ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.minimumHeight: 64
                        TextArea {
                            id: notesArea
                            wrapMode: TextEdit.Wrap
                            color: Theme.textPrimary
                            placeholderText: "Company, role, anything useful on a call"
                            placeholderTextColor: Theme.textMuted
                            selectionColor: Theme.accent
                            selectedTextColor: Theme.textOnAccent
                            font: Theme.fontBody
                            selectByMouse: true
                            Accessible.name: "Notes"
                            background: Rectangle {
                                radius: Theme.radius
                                color: Theme.surfaceRaised
                                border.width: notesArea.activeFocus ? 2 : 1
                                border.color: notesArea.activeFocus ? Theme.accent : Theme.border
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    AppButton {
                        visible: root.editingId > 0
                        text: root.confirmDelete ? "Confirm delete" : "Delete"
                        iconName: "trash"
                        variant: root.confirmDelete ? "danger" : "ghost"
                        onClicked: root.confirmDelete ? root.remove() : root.confirmDelete = true
                    }
                    Item { Layout.fillWidth: true }
                    AppButton {
                        text: "Cancel"
                        variant: "ghost"
                        onClicked: root.closeForm()
                    }
                    AppButton {
                        text: "Save"
                        iconName: "check"
                        enabled: root.canSave
                        onClicked: root.save()
                    }
                }
            }

            Connections {
                target: nameField.field
                function onAccepted() { root.save() }
            }
            Connections {
                target: numberField.field
                function onAccepted() { root.save() }
            }

            EmptyState {
                anchors.fill: parent
                visible: !root.editing
                iconName: "user"
                title: "Contact details"
                hint: "Select a contact to edit it, or create a new one. Saved names appear on incoming and outgoing calls."
            }
        }
    }
}
