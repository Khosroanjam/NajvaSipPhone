import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "theme"
import "components"

Item {
    id: root
    property var account: null
    signal backPressed()

    readonly property bool sipReady: typeof sipManager !== "undefined" && sipManager !== null
    readonly property bool apiReady: typeof apiClient !== "undefined" && apiClient !== null
    property bool savedFlash: false

    // Device lists with a "System default" entry; ids are PJSIP device ids.
    property var captureModel: []
    property var playbackModel: []

    function loadDevices() {
        if (!sipReady) return
        captureModel = [{ id: -1, name: "System default" }].concat(sipManager.captureDevices())
        playbackModel = [{ id: -2, name: "System default" }].concat(sipManager.playbackDevices())
    }
    function indexOfDevice(list, id) {
        for (var i = 0; i < list.length; i++)
            if (list[i].id === id) return i
        return 0
    }

    Component.onCompleted: loadDevices()

    Timer { id: flashTimer; interval: 2500; onTriggered: root.savedFlash = false }

    ScrollView {
        id: scroll
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: Math.min(scroll.availableWidth - 48, 760)
            x: 24
            spacing: 20

            Item { Layout.preferredHeight: 4 }

            // ── SIP account ─────────────────────────────────────────
            SettingsCard {
                Layout.fillWidth: true
                iconName: "phone"
                title: "SIP account"
                subtitle: "Credentials used to register with your PBX."

                GridLayout {
                    Layout.fillWidth: true
                    columns: scroll.availableWidth > 620 ? 2 : 1
                    columnSpacing: 16
                    rowSpacing: 14

                    AppTextField {
                        Layout.fillWidth: true
                        label: "Username / extension"
                        text: root.account ? root.account.username : ""
                        onEdited: function(t) { if (root.account) root.account.username = t }
                    }
                    AppTextField {
                        Layout.fillWidth: true
                        label: "Password"
                        password: true
                        text: root.account ? root.account.password : ""
                        onEdited: function(t) { if (root.account) root.account.password = t }
                    }
                    AppTextField {
                        Layout.fillWidth: true
                        label: "Server / domain"
                        placeholderText: "e.g. 192.168.1.200"
                        leadingIcon: "server"
                        text: root.account ? root.account.server : ""
                        onEdited: function(t) { if (root.account) root.account.server = t }
                    }
                    AppTextField {
                        Layout.fillWidth: true
                        label: "Outbound proxy (optional)"
                        text: root.account ? root.account.proxy : ""
                        onEdited: function(t) { if (root.account) root.account.proxy = t }
                    }
                    AppTextField {
                        Layout.fillWidth: true
                        label: "Display name"
                        text: root.account ? root.account.displayName : ""
                        onEdited: function(t) { if (root.account) root.account.displayName = t }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        Label { text: "Transport"; color: Theme.textSecondary; font: Theme.fontLabel }
                        Segmented {
                            Layout.fillWidth: true
                            options: ["UDP", "TCP", "TLS"]
                            current: root.account ? root.account.transport : "UDP"
                            onSelected: function(v) { if (root.account) root.account.transport = v }
                        }
                    }
                }

                CardFooter {
                    StatusChip {
                        text: root.account && root.account.isRegistered ? "Registered" : "Not registered"
                        tone: root.account && root.account.isRegistered ? "success" : "danger"
                    }
                    Label {
                        visible: root.savedFlash
                        text: "Saved — registering…"
                        color: Theme.textMuted
                        font: Theme.fontSmall
                    }
                    Item { Layout.fillWidth: true }
                    AppButton {
                        text: "Save & register"
                        iconName: "check"
                        variant: "primary"
                        enabled: root.account !== null
                        onClicked: {
                            root.account.saveConfig()
                            if (root.sipReady) sipManager.reregister()
                            root.savedFlash = true
                            flashTimer.restart()
                        }
                    }
                }
            }

            // ── Sync server ─────────────────────────────────────────
            SettingsCard {
                Layout.fillWidth: true
                iconName: "cloud"
                title: "Central server (sync)"
                subtitle: "Sync contacts, call logs and notes with the Najva CRM server."

                GridLayout {
                    Layout.fillWidth: true
                    columns: scroll.availableWidth > 620 ? 2 : 1
                    columnSpacing: 16
                    rowSpacing: 14

                    AppTextField {
                        Layout.fillWidth: true
                        label: "Server URL"
                        placeholderText: "http://server:8000"
                        leadingIcon: "server"
                        text: root.apiReady ? apiClient.serverUrl : ""
                        onEdited: function(t) { if (root.apiReady) apiClient.serverUrl = t }
                    }
                    AppTextField {
                        Layout.fillWidth: true
                        label: "API key"
                        password: true
                        text: root.apiReady ? apiClient.apiKey : ""
                        onEdited: function(t) { if (root.apiReady) apiClient.apiKey = t }
                    }
                }

                CardFooter {
                    StatusChip {
                        text: !root.apiReady ? "Unavailable"
                              : apiClient.authenticated ? "Connected"
                              : apiClient.isConfigured() ? "Not connected" : "Not configured"
                        tone: root.apiReady && apiClient.authenticated ? "success" : "warning"
                    }
                    Item { Layout.fillWidth: true }
                    AppButton {
                        text: "Connect & sync"
                        iconName: "refresh"
                        variant: "secondary"
                        enabled: root.apiReady && apiClient.isConfigured()
                        onClicked: apiClient.authenticate()
                    }
                }
            }

            // ── Audio ───────────────────────────────────────────────
            SettingsCard {
                Layout.fillWidth: true
                iconName: "headphones"
                title: "Audio devices"
                subtitle: "Devices used for calls. Changes apply immediately."

                AppComboBox {
                    Layout.fillWidth: true
                    label: "Microphone"
                    leadingIcon: "mic"
                    textRole: "name"
                    model: root.captureModel
                    currentIndex: root.sipReady ? root.indexOfDevice(root.captureModel, sipManager.currentCaptureDevice()) : 0
                    onActivated: function(i) {
                        if (root.sipReady) sipManager.setCaptureDevice(root.captureModel[i].id)
                    }
                }
                AppComboBox {
                    Layout.fillWidth: true
                    label: "Speaker"
                    leadingIcon: "volume"
                    textRole: "name"
                    model: root.playbackModel
                    currentIndex: root.sipReady ? root.indexOfDevice(root.playbackModel, sipManager.currentPlaybackDevice()) : 0
                    onActivated: function(i) {
                        if (root.sipReady) sipManager.setPlaybackDevice(root.playbackModel[i].id)
                    }
                }

                CardFooter {
                    Item { Layout.fillWidth: true }
                    AppButton {
                        text: "Refresh devices"
                        iconName: "refresh"
                        variant: "ghost"
                        compact: true
                        onClicked: root.loadDevices()
                    }
                }
            }

            // ── Appearance ──────────────────────────────────────────
            SettingsCard {
                Layout.fillWidth: true
                iconName: Theme.dark ? "moon" : "sun"
                title: "Appearance"
                subtitle: "Choose the color theme."

                Segmented {
                    Layout.preferredWidth: 260
                    options: ["Dark", "Light"]
                    current: Theme.dark ? "Dark" : "Light"
                    onSelected: function(v) { Theme.dark = (v === "Dark") }
                }
            }

            // ── About ───────────────────────────────────────────────
            SettingsCard {
                Layout.fillWidth: true
                iconName: "user"
                title: "About"
                subtitle: "Najva SIP Phone · version " + Qt.application.version

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: devRow.implicitHeight + 32
                    radius: Theme.radius
                    color: Theme.surfaceRaised
                    border.width: 1
                    border.color: Theme.border

                    RowLayout {
                        id: devRow
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: 16
                        spacing: 14

                        Avatar {
                            size: 52
                            name: "Sadegh Khosroanjam"
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Label {
                                text: "DEVELOPER"
                                color: Theme.accent
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.textXs
                                font.weight: Font.DemiBold
                                font.letterSpacing: 1.2
                            }
                            Label {
                                Layout.fillWidth: true
                                text: "Sadegh Khosroanjam"
                                color: Theme.textPrimary
                                font: Theme.fontTitle
                                elide: Text.ElideRight
                            }
                            Label {
                                text: "@khosroanjam"
                                color: Theme.textSecondary
                                font: Theme.fontBody
                            }
                        }
                    }
                }
            }

            Item { Layout.preferredHeight: 24 }
        }
    }

    // Card with icon header; children are stacked below the header.
    component SettingsCard: Card {
        id: sc
        property string iconName: ""
        property string title: ""
        property string subtitle: ""
        default property alias content: inner.data

        implicitHeight: col.implicitHeight + 40

        ColumnLayout {
            id: col
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 20
            spacing: 18

            RowLayout {
                spacing: 12
                Rectangle {
                    width: 36; height: 36; radius: 10
                    color: Theme.accentSoft
                    Icon { anchors.centerIn: parent; name: sc.iconName; size: 18; color: Theme.accent }
                }
                ColumnLayout {
                    spacing: 1
                    Label { text: sc.title; color: Theme.textPrimary; font: Theme.fontTitle }
                    Label { text: sc.subtitle; color: Theme.textMuted; font: Theme.fontSmall }
                }
            }

            ColumnLayout {
                id: inner
                Layout.fillWidth: true
                spacing: 14
            }
        }
    }

    component CardFooter: RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: 4
        spacing: 10
    }

    // Segmented control for small option sets.
    component Segmented: Rectangle {
        id: seg
        property var options: []
        property string current: ""
        signal selected(string value)

        implicitHeight: Theme.controlHeight
        radius: Theme.radius
        color: Theme.surfaceRaised
        border.width: 1
        border.color: Theme.border

        RowLayout {
            anchors.fill: parent
            anchors.margins: 3
            spacing: 3
            Repeater {
                model: seg.options
                delegate: AbstractButton {
                    id: optBtn
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    readonly property bool on: seg.current === modelData
                    hoverEnabled: true
                    focusPolicy: Qt.StrongFocus
                    Accessible.name: modelData
                    onClicked: seg.selected(modelData)
                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                    background: Rectangle {
                        radius: Theme.radius - 3
                        color: optBtn.on ? Theme.accent : optBtn.hovered ? Theme.surfaceHover : "transparent"
                        Behavior on color { ColorAnimation { duration: Theme.durFast } }
                        FocusRing { target: optBtn }
                    }
                    contentItem: Label {
                        text: modelData
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        color: optBtn.on ? Theme.textOnAccent : Theme.textSecondary
                        font: Theme.fontLabel
                    }
                }
            }
        }
    }
}
