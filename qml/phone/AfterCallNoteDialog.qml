import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../theme"
import "../components"

// Shown when a call ends: quick note about the call, auto-dismisses if untouched.
Popup {
    id: root
    property int callHistoryId: -1
    property string callNumber: ""
    property string callName: ""
    property int callDuration: 0

    signal noteSaved(int callHistoryId, string text)
    signal dismissed()

    width: Math.min(440, (parent ? parent.width : 440) - 40)
    anchors.centerIn: Overlay.overlay
    modal: true
    padding: 24
    closePolicy: Popup.CloseOnEscape
    onOpened: { noteInput.text = ""; noteInput.forceActiveFocus() }
    onClosed: if (!_saved) dismissed()
    property bool _saved: false
    onAboutToShow: _saved = false

    Overlay.modal: Rectangle { color: Theme.overlay }

    enter: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.durNormal }
            NumberAnimation { property: "scale"; from: 0.96; to: 1; duration: Theme.durNormal; easing.type: Easing.OutCubic }
        }
    }
    exit: Transition {
        NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.durFast }
    }

    Timer {
        interval: 12000
        running: root.opened && noteInput.text.trim().length === 0 && !noteInput.activeFocus
        onTriggered: root.close()
    }

    background: Rectangle {
        radius: Theme.radiusLg
        color: Theme.surface
        border.width: 1
        border.color: Theme.border
    }

    contentItem: ColumnLayout {
        spacing: 16

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Avatar {
                size: 44
                name: root.callName && root.callName !== root.callNumber ? root.callName : ""
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Label {
                    text: "Call ended"
                    color: Theme.textMuted
                    font: Theme.fontLabel
                }
                Label {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    text: root.callName || root.callNumber
                    color: Theme.textPrimary
                    font: Theme.fontTitle
                }
            }

            StatusChip {
                iconName: "clock"
                text: root.formatDuration(root.callDuration)
                tone: "neutral"
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            Label {
                text: "Call note"
                color: Theme.textSecondary
                font: Theme.fontLabel
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.preferredHeight: 96

                TextArea {
                    id: noteInput
                    placeholderText: "What was this call about?"
                    placeholderTextColor: Theme.textMuted
                    color: Theme.textPrimary
                    selectionColor: Theme.accent
                    selectedTextColor: Theme.textOnAccent
                    font: Theme.fontBody
                    wrapMode: TextArea.Wrap
                    Accessible.name: "Call note"
                    background: Rectangle {
                        radius: Theme.radius
                        color: Theme.surfaceRaised
                        border.width: noteInput.activeFocus ? 2 : 1
                        border.color: noteInput.activeFocus ? Theme.accent : Theme.border
                    }
                    Keys.onReturnPressed: function(event) {
                        if (event.modifiers & Qt.ShiftModifier) event.accepted = false
                        else root.saveNote()
                    }
                    Keys.onEnterPressed: root.saveNote()
                }
            }

            Label {
                text: "Enter to save · Shift+Enter for a new line"
                color: Theme.textMuted
                font: Theme.fontSmall
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Item { Layout.fillWidth: true }

            AppButton {
                text: "Skip"
                variant: "ghost"
                onClicked: root.close()
            }
            AppButton {
                text: "Save note"
                iconName: "check"
                variant: "primary"
                enabled: noteInput.text.trim().length > 0
                onClicked: root.saveNote()
            }
        }
    }

    function formatDuration(seconds) {
        var m = Math.floor(seconds / 60)
        var s = seconds % 60
        return (m < 10 ? "0" + m : m) + ":" + (s < 10 ? "0" + s : s)
    }

    function saveNote() {
        var text = noteInput.text.trim()
        if (text.length === 0) return
        if (root.callHistoryId > 0) {
            if (typeof db !== "undefined" && db)
                db.addNote(root.callHistoryId, text)
            if (typeof apiClient !== "undefined" && apiClient && apiClient.isConfigured())
                apiClient.createNote(root.callHistoryId.toString(), text)
        }
        root._saved = true
        root.noteSaved(root.callHistoryId, text)
        root.close()
    }
}
