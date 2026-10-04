import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../theme"
import "../components"

// Notes attached to the selected call + composer.
ColumnLayout {
    id: root
    property int callHistoryId: -1
    property var notesList: []

    spacing: 12

    function loadNotes() {
        if (callHistoryId < 0 || typeof db === "undefined" || !db) {
            root.notesList = []
            return
        }
        root.notesList = db.notes(callHistoryId)
    }

    function save() {
        var t = noteInput.text.trim()
        if (t.length === 0 || root.callHistoryId < 0 || typeof db === "undefined" || !db) return
        db.addNote(root.callHistoryId, t)
        noteInput.text = ""
        root.loadNotes()
    }

    onCallHistoryIdChanged: {
        noteInput.text = ""
        root.loadNotes()
    }

    SectionHeader {
        Layout.fillWidth: true
        title: "Notes"
        iconName: "notes"
        meta: root.callHistoryId < 0 ? "" : root.notesList.length + (root.notesList.length === 1 ? " note" : " notes")
    }

    ListView {
        id: notesListView
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: root.notesList.length > 0
        clip: true
        spacing: 8
        model: root.notesList
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        delegate: Rectangle {
            width: notesListView.width - 8
            implicitHeight: noteBody.implicitHeight + 20
            radius: Theme.radius
            color: Theme.surfaceRaised
            border.width: 1
            border.color: Theme.border

            ColumnLayout {
                id: noteBody
                anchors.fill: parent
                anchors.margins: 10
                spacing: 4
                Label {
                    Layout.fillWidth: true
                    text: modelData.text
                    color: Theme.textPrimary
                    font: Theme.fontBody
                    wrapMode: Text.Wrap
                }
                Label {
                    text: Qt.formatDateTime(new Date(modelData.created), "MMM d, HH:mm")
                    color: Theme.textMuted
                    font: Theme.fontSmall
                }
            }
        }
    }

    EmptyState {
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: root.notesList.length === 0
        iconName: "notes"
        title: root.callHistoryId < 0 ? "" : "No notes yet"
        hint: root.callHistoryId < 0
              ? "Select a call to read or add notes."
              : "Add the first note for this call below."
    }

    // Composer
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 92
        radius: Theme.radius
        color: Theme.surfaceRaised
        border.width: noteInput.activeFocus ? 2 : 1
        border.color: noteInput.activeFocus ? Theme.accent : Theme.border
        opacity: root.callHistoryId >= 0 ? 1 : 0.55

        ScrollView {
            anchors.fill: parent
            anchors.margins: 2
            anchors.rightMargin: 52

            TextArea {
                id: noteInput
                enabled: root.callHistoryId >= 0
                placeholderText: root.callHistoryId < 0 ? "Select a call first" : "Write a note… (Enter to save)"
                placeholderTextColor: Theme.textMuted
                color: Theme.textPrimary
                selectionColor: Theme.accent
                selectedTextColor: Theme.textOnAccent
                wrapMode: TextArea.Wrap
                font: Theme.fontBody
                background: null
                Accessible.name: "New note"
                Keys.onReturnPressed: function(event) {
                    if (event.modifiers & Qt.ShiftModifier) event.accepted = false
                    else root.save()
                }
            }
        }

        IconButton {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 8
            iconName: "check"
            variant: "primary"
            buttonSize: 36
            iconSize: 16
            tooltip: "Save note"
            enabled: root.callHistoryId >= 0 && noteInput.text.trim().length > 0
            opacity: enabled ? 1 : 0.5
            onClicked: root.save()
        }
    }
}
