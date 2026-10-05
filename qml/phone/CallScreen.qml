import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../theme"
import "../components"

// Active / incoming call view. `call` is the SipCall object (may become null).
Item {
    id: root
    property var call: null
    property string callerNumber: ""
    property var lastNotesData: []

    signal hangupPressed()
    signal answerPressed()

    readonly property string state_: call ? call.callState : "DISCONNECTED"
    readonly property bool connected: state_ === "CONFIRMED" || state_ === "CONNECTING"
    readonly property bool ended: state_ === "DISCONNECTED"
    readonly property bool incoming: call !== null && call.direction === "incoming"
    readonly property bool ringingIn: incoming && !connected && !ended
    readonly property int duration: call ? call.duration : 0
    // Phonebook entry for the other party (empty object when unknown).
    readonly property var contact: callerNumber !== "" && typeof db !== "undefined" && db
                                   ? db.contactByNumber(callerNumber) : ({})
    readonly property bool knownContact: contact && contact.id !== undefined
    readonly property string displayName: knownContact ? contact.name
                                        : call && call.callerName ? call.callerName : callerNumber
    property bool keypadOpen: false
    property string dtmfSent: ""

    onCallChanged: { keypadOpen = false; dtmfSent = "" }

    function formatTime(seconds) {
        var m = Math.floor(seconds / 60)
        var s = seconds % 60
        return (m < 10 ? "0" + m : m) + ":" + (s < 10 ? "0" + s : s)
    }

    readonly property string statusText: {
        if (ended) return "Call ended"
        if (connected) return formatTime(duration)
        if (ringingIn) return "Incoming call"
        if (state_ === "EARLY") return "Ringing…"
        return "Calling…"
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 0

        Item { Layout.fillHeight: true; Layout.minimumHeight: 8 }

        // ── Caller identity ──
        Item {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 112
            Layout.preferredHeight: 112

            // Soft ring pulse only while the call is being set up.
            Rectangle {
                id: pulse
                anchors.centerIn: parent
                width: 96; height: 96; radius: 48
                color: "transparent"
                border.width: 2
                border.color: root.ringingIn ? Theme.success : Theme.accent
                visible: !root.connected && !root.ended
                ParallelAnimation {
                    running: pulse.visible
                    loops: Animation.Infinite
                    NumberAnimation { target: pulse; property: "scale"; from: 1.0; to: 1.35; duration: 1400; easing.type: Easing.OutCubic }
                    NumberAnimation { target: pulse; property: "opacity"; from: 0.7; to: 0.0; duration: 1400; easing.type: Easing.OutCubic }
                }
            }

            Avatar {
                anchors.centerIn: parent
                size: 96
                name: root.displayName && root.displayName !== root.callerNumber ? root.displayName : ""
            }
        }

        Label {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 16
            Layout.maximumWidth: root.width - 48
            elide: Text.ElideMiddle
            text: root.displayName || "Unknown"
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: Theme.text2xl
            font.weight: Font.DemiBold
        }

        Label {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 2
            visible: root.displayName !== root.callerNumber && root.callerNumber !== ""
            text: root.callerNumber
            color: Theme.textSecondary
            font: Theme.fontBody
        }

        StatusChip {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 12
            text: root.statusText
            iconName: root.connected ? "clock" : ""
            tone: root.ended ? "danger" : root.connected ? "success" : "warning"
            pulsing: !root.connected && !root.ended
        }

        // ── Previous interactions or in-call keypad ──
        Item {
            Layout.fillWidth: true
            Layout.topMargin: 20
            Layout.preferredHeight: root.keypadOpen ? keypad.implicitHeight + 36
                                  : (lastNotes.visible ? lastNotes.implicitHeight : 0)
            Behavior on Layout.preferredHeight { NumberAnimation { duration: Theme.durNormal; easing.type: Easing.OutCubic } }
            clip: true

            LastNotesView {
                id: lastNotes
                anchors.left: parent.left
                anchors.right: parent.right
                visible: !root.keypadOpen && notesData && notesData.length > 0
                notesData: root.lastNotesData
                callerNumber: root.callerNumber
            }

            ColumnLayout {
                anchors.fill: parent
                visible: root.keypadOpen
                spacing: 8

                Label {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredHeight: 28
                    text: root.dtmfSent || "Tones are sent to the call"
                    color: root.dtmfSent ? Theme.textPrimary : Theme.textMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: root.dtmfSent ? Theme.textXl : Theme.textSm
                    elide: Text.ElideLeft
                    Layout.maximumWidth: root.width - 48
                }
                Dialpad {
                    id: keypad
                    Layout.alignment: Qt.AlignHCenter
                    keySize: 54
                    showLetters: false
                    onDigitPressed: function(d) {
                        root.dtmfSent += d
                        if (root.call) root.call.sendDtmf(d)
                    }
                }
            }
        }

        Item { Layout.fillHeight: true; Layout.minimumHeight: 16 }

        // ── In-call actions ──
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 28
            visible: !root.ringingIn

            CallAction {
                iconName: root.call && root.call.muted ? "mic-off" : "mic"
                label: root.call && root.call.muted ? "Unmute" : "Mute"
                active: root.call !== null && root.call.muted
                enabled: root.connected
                onClicked: if (root.call) root.call.muted = !root.call.muted
            }
            CallAction {
                iconName: "keypad"
                label: "Keypad"
                active: root.keypadOpen
                enabled: root.connected
                onClicked: root.keypadOpen = !root.keypadOpen
            }
        }

        // ── Answer / hang up ──
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 24
            spacing: 48

            ColumnLayout {
                visible: root.ringingIn
                spacing: 8
                IconButton {
                    Layout.alignment: Qt.AlignHCenter
                    variant: "success"
                    iconName: "phone"
                    iconSize: 26
                    buttonSize: 68
                    tooltip: "Answer"
                    onClicked: root.answerPressed()
                }
                Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Answer"
                    color: Theme.textSecondary
                    font: Theme.fontSmall
                }
            }

            ColumnLayout {
                spacing: 8
                IconButton {
                    id: hangupBtn
                    Layout.alignment: Qt.AlignHCenter
                    variant: "danger"
                    iconName: "phone"
                    iconSize: 26
                    buttonSize: 68
                    tooltip: root.ringingIn ? "Decline" : "Hang up"
                    onClicked: root.hangupPressed()
                    // Hang-up glyph: handset turned down.
                    contentItem: Item {
                        Icon {
                            anchors.centerIn: parent
                            name: "phone"
                            size: hangupBtn.iconSize
                            color: Theme.textOnAccent
                            rotation: 135
                        }
                    }
                }
                Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.ringingIn ? "Decline" : "End"
                    color: Theme.textSecondary
                    font: Theme.fontSmall
                }
            }
        }

        Item { Layout.preferredHeight: 8 }
    }

    component CallAction: ColumnLayout {
        id: act
        property string iconName: ""
        property string label: ""
        property bool active: false
        signal clicked()

        spacing: 8
        opacity: enabled ? 1.0 : 0.45

        IconButton {
            Layout.alignment: Qt.AlignHCenter
            variant: "secondary"
            iconName: act.iconName
            iconSize: 22
            buttonSize: 56
            active: act.active
            enabled: act.enabled
            tooltip: act.label
            onClicked: act.clicked()
        }
        Label {
            Layout.alignment: Qt.AlignHCenter
            text: act.label
            color: Theme.textSecondary
            font: Theme.fontSmall
        }
    }
}
