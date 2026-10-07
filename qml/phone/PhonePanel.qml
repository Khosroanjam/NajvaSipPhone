import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../theme"
import "../components"

// Left column: number entry + dialpad, or the active call.
Item {
    id: root
    property string dialedNumber: ""
    property var currentContact: null
    property bool inCall: false
    property int activeCallId: -1
    property int lastCallId: -1          // survives callEnded for the after-call note
    property var lastNotesData: []
    property string callError: ""

    readonly property bool sipReady: typeof sipManager !== "undefined" && sipManager !== null
    readonly property var activeCall: sipReady && activeCallId > 0 ? sipManager.findCall(activeCallId) : null
    readonly property bool canCall: sipReady && sipManager.isRegistered && dialedNumber.trim().length > 0
    readonly property bool dbReady: typeof db !== "undefined" && db !== null
    // Phonebook match for the number being dialled (empty object when none).
    readonly property var dialedContact: dbReady && dialedNumber.trim().length >= 3
                                         ? db.contactByNumber(dialedNumber) : ({})

    function contactName(number) {
        var c = dbReady ? db.contactByNumber(number) : null
        return c && c.id !== undefined ? c.name : ""
    }

    function placeCall() {
        if (!root.canCall) return
        var id = sipManager.makeCall(root.dialedNumber.trim())
        if (id > 0) {
            root.activeCallId = id
            root.lastCallId = id
            root.lastNotesData = typeof db !== "undefined" && db ? db.lastNotesByNumber(root.dialedNumber, 3) : []
            root.inCall = true
        }
    }

    function backspace() {
        if (root.dialedNumber.length > 0)
            root.dialedNumber = root.dialedNumber.slice(0, -1)
    }

    Connections {
        target: root.sipReady ? sipManager : null
        function onIncomingCall(callId, callerNumber, callerName) {
            root.activeCallId = callId
            root.lastCallId = callId
            root.inCall = true
            root.dialedNumber = callerNumber
            root.lastNotesData = []
            if (typeof db !== "undefined" && db && callerNumber)
                root.lastNotesData = db.lastNotesByNumber(callerNumber, 3)
            if (typeof apiClient !== "undefined" && apiClient && apiClient.isConfigured() && callerNumber)
                apiClient.fetchLastNotesByNumber(callerNumber, 3)
        }
        function onCallCreated(callId) {
            if (root.inCall) return
            var call = sipManager.findCall(callId)
            root.activeCallId = callId
            root.lastCallId = callId
            if (call && call.remoteNumber)
                root.dialedNumber = call.remoteNumber
            root.lastNotesData = root.dbReady ? db.lastNotesByNumber(root.dialedNumber, 3) : []
            root.inCall = true
        }
        function onCallFailed(reason) {
            root.callError = reason
            callErrorTimer.restart()
        }
        function onCallEnded(callId) {
            if (callId === root.activeCallId) {
                root.inCall = false
                root.activeCallId = -1
            }
        }
        function onCallHistoryCreated(callId, callHistoryId, number, name) {
            if (callId !== root.lastCallId) return
            afterCallDialog.callHistoryId = callHistoryId
            afterCallDialog.callNumber = number
            afterCallDialog.callName = root.contactName(number) || name
            var call = sipManager.findCall(callId)
            afterCallDialog.callDuration = call ? call.duration : 0
            afterCallDialog.open()
        }
    }

    Timer {
        id: callErrorTimer
        interval: 6000
        onTriggered: root.callError = ""
    }

    // Call-failure banner (e.g. no microphone / audio device).
    Rectangle {
        z: 10
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 16
        height: errorLabel.implicitHeight + 20
        radius: Theme.radius
        color: Theme.dangerSoft
        border.color: Theme.danger
        visible: root.callError !== ""
        opacity: visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.durNormal } }

        Label {
            id: errorLabel
            anchors.fill: parent
            anchors.margins: 10
            text: "تماس برقرار نشد: " + root.callError
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            color: Theme.danger
            font: Theme.fontBody
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.callError = ""
        }
    }

    Connections {
        target: typeof apiClient !== "undefined" ? apiClient : null
        function onLastNotesFetched(number, notes) {
            if (number === root.dialedNumber && notes && notes.length > 0)
                root.lastNotesData = notes
        }
    }

    // ── Dialer ───────────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 0
        visible: !root.inCall
        opacity: visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.durNormal } }

        SectionHeader {
            Layout.fillWidth: true
            title: "Phone"
            iconName: "phone"
            meta: root.sipReady && sipManager.account && sipManager.account.username
                  ? "Ext. " + sipManager.account.username : ""
        }

        Item { Layout.fillHeight: true; Layout.minimumHeight: 12 }

        // Number entry (editable: type, paste or use the keypad)
        TextInput {
            id: numberInput
            Layout.fillWidth: true
            Layout.preferredHeight: 56
            horizontalAlignment: TextInput.AlignHCenter
            verticalAlignment: TextInput.AlignVCenter
            text: root.dialedNumber
            onTextEdited: root.dialedNumber = text.replace(/\s+/g, "")
            color: Theme.textPrimary
            selectionColor: Theme.accent
            selectedTextColor: Theme.textOnAccent
            selectByMouse: true
            clip: true
            focus: true
            font.family: Theme.fontFamily
            font.pixelSize: text.length > 14 ? Theme.textXl : Theme.textDisplay
            font.weight: Font.Light
            Accessible.name: "Number to dial"
            Keys.onReturnPressed: root.placeCall()
            Keys.onEnterPressed: root.placeCall()

            Label {
                anchors.centerIn: parent
                visible: numberInput.text.length === 0
                text: "Enter a number"
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.textXl
            }
        }

        // Name of the matching phonebook contact, if any
        Label {
            Layout.alignment: Qt.AlignHCenter
            Layout.maximumWidth: root.width - 48
            Layout.preferredHeight: 20
            text: root.dialedContact && root.dialedContact.id !== undefined ? root.dialedContact.name : ""
            color: Theme.accent
            font.family: Theme.fontFamily
            font.pixelSize: Theme.textMd
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 64
            Layout.preferredHeight: 2
            Layout.topMargin: 4
            radius: 1
            color: numberInput.activeFocus ? Theme.accent : Theme.border
            Behavior on color { ColorAnimation { duration: Theme.durFast } }
        }

        Dialpad {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 24
            keySize: Math.max(52, Math.min(68, (root.width - 48 - 36) / 3.4))
            onDigitPressed: function(d) {
                root.dialedNumber += d
                numberInput.forceActiveFocus()
            }
        }

        // Call row: [spacer] [call] [backspace]
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 22
            spacing: 26

            Item { Layout.preferredWidth: 44 }

            IconButton {
                variant: "success"
                iconName: "phone"
                iconSize: 26
                buttonSize: 68
                enabled: root.canCall
                opacity: enabled ? 1.0 : 0.5
                tooltip: root.sipReady && !sipManager.isRegistered ? "Not registered" : "Call"
                onClicked: root.placeCall()
            }

            IconButton {
                Layout.preferredWidth: 44
                iconName: "delete"
                iconSize: 20
                buttonSize: 44
                tooltip: "Delete digit"
                opacity: root.dialedNumber.length > 0 ? 1 : 0
                enabled: root.dialedNumber.length > 0
                onClicked: root.backspace()
                onPressAndHold: root.dialedNumber = ""
            }
        }

        Label {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 14
            visible: root.sipReady && !sipManager.isRegistered
            text: "SIP account is not registered — check Settings"
            color: Theme.warning
            font: Theme.fontSmall
        }

        Item { Layout.fillHeight: true; Layout.minimumHeight: 12 }
    }

    // ── Active call ──────────────────────────────────────────────────
    CallScreen {
        anchors.fill: parent
        visible: root.inCall
        opacity: visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.durNormal } }
        call: root.activeCall
        callerNumber: root.dialedNumber
        lastNotesData: root.lastNotesData
        onAnswerPressed: if (root.sipReady && root.activeCallId > 0) sipManager.answerCall(root.activeCallId)
        onHangupPressed: {
            if (root.sipReady && root.activeCallId > 0)
                sipManager.hangupCall(root.activeCallId)
            root.inCall = false
            root.activeCallId = -1
        }
    }

    AfterCallNoteDialog {
        id: afterCallDialog
        parent: Overlay.overlay
    }
}
