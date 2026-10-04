import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "theme"
import "components"
import "phone"
import "crm"
import "calendar"

ApplicationWindow {
    id: root
    visible: true
    width: 1180
    height: 780
    minimumWidth: 960
    minimumHeight: 620
    title: "Saghar — Tarazpouyesh SIP Phone"
    color: Theme.bg

    property int pageIndex: 0  // 0=CRM, 1=Calendar, 2=Settings
    readonly property var pages: [
        { title: "Contacts & History", subtitle: "Recent calls, contact details and call notes", icon: "users",    nav: "CRM" },
        { title: "Calendar",           subtitle: "Call activity by Jalali date",                 icon: "calendar", nav: "Calendar" },
        { title: "Settings",           subtitle: "SIP account, sync server and audio devices",   icon: "settings", nav: "Settings" }
    ]

    readonly property bool sipReady: typeof sipManager !== "undefined" && sipManager !== null
    readonly property bool registered: sipReady && sipManager.isRegistered
    readonly property bool sipConfigured: sipReady && sipManager.account
                                          && sipManager.account.username !== ""
                                          && sipManager.account.server !== ""
    readonly property bool apiReady: typeof apiClient !== "undefined" && apiClient !== null

    // Basic-style controls (ComboBox popups, ToolTip, ScrollBar) pick these up.
    palette {
        window: Theme.bg
        windowText: Theme.textPrimary
        base: Theme.surfaceRaised
        alternateBase: Theme.surface
        text: Theme.textPrimary
        button: Theme.surfaceRaised
        buttonText: Theme.textPrimary
        highlight: Theme.accent
        highlightedText: Theme.textOnAccent
        placeholderText: Theme.textMuted
        toolTipBase: Theme.surfaceRaised
        toolTipText: Theme.textPrimary
        mid: Theme.border
        dark: Theme.borderStrong
        light: Theme.surfaceHover
        midlight: Theme.surfaceHover
        shadow: "#000000"
    }
    font.family: Theme.fontFamily
    font.pixelSize: Theme.textMd

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // ── Navigation rail ──────────────────────────────────────────
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 76
            color: Theme.rail

            Rectangle {
                anchors.right: parent.right
                width: 1; height: parent.height
                color: Theme.border
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.topMargin: 16
                anchors.bottomMargin: 16
                spacing: 6

                // Brand mark
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.bottomMargin: 18
                    width: 40; height: 40
                    radius: 12
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Theme.accent }
                        GradientStop { position: 1.0; color: Theme.accent2 }
                    }
                    Icon {
                        anchors.centerIn: parent
                        name: "phone"
                        size: 20
                        color: Theme.textOnAccent
                    }
                    Accessible.name: "Saghar"
                }

                Repeater {
                    model: root.pages
                    delegate: NavButton {
                        Layout.alignment: Qt.AlignHCenter
                        iconName: modelData.icon
                        text: modelData.nav
                        checked: root.pageIndex === index
                        onClicked: root.pageIndex = index
                    }
                }

                Item { Layout.fillHeight: true }

                IconButton {
                    Layout.alignment: Qt.AlignHCenter
                    iconName: Theme.dark ? "sun" : "moon"
                    tooltip: Theme.dark ? "Switch to light theme" : "Switch to dark theme"
                    buttonSize: 40
                    onClicked: Theme.toggle()
                }

                // SIP registration indicator
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 6
                    width: 40; height: 40; radius: 20
                    color: "transparent"
                    border.width: 1
                    border.color: Theme.border

                    Avatar {
                        anchors.centerIn: parent
                        size: 30
                        name: root.sipReady && sipManager.account ? sipManager.account.username : ""
                    }
                    Rectangle {
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.rightMargin: 1
                        anchors.bottomMargin: 1
                        width: 12; height: 12; radius: 6
                        color: root.registered ? Theme.success : Theme.danger
                        border.width: 2
                        border.color: Theme.rail
                    }
                    HoverHandler { id: accHover }
                    ToolTip.visible: accHover.hovered
                    ToolTip.delay: 400
                    ToolTip.text: (root.sipReady && sipManager.account && sipManager.account.username
                                   ? "Ext. " + sipManager.account.username + " — " : "")
                                  + (root.registered ? "Registered" : "Not registered")
                }
            }
        }

        // ── Phone column ─────────────────────────────────────────────
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 360
            color: Theme.surface

            Rectangle {
                anchors.right: parent.right
                width: 1; height: parent.height
                color: Theme.border
                z: 2
            }

            PhonePanel {
                id: phonePanel
                anchors.fill: parent
            }
        }

        // ── Content area ─────────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // Top bar
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 68
                color: Theme.bg

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 28
                    anchors.rightMargin: 24
                    spacing: 12

                    ColumnLayout {
                        spacing: 2
                        Label {
                            text: root.pages[root.pageIndex].title
                            color: Theme.textPrimary
                            font: Theme.fontHeading
                        }
                        Label {
                            text: root.pages[root.pageIndex].subtitle
                            color: Theme.textMuted
                            font: Theme.fontSmall
                        }
                    }

                    Item { Layout.fillWidth: true }

                    StatusChip {
                        visible: root.apiReady && apiClient.isConfigured()
                        iconName: "cloud"
                        text: {
                            if (!root.apiReady) return ""
                            var s = apiClient.syncStatus
                            if (s === "syncing") return "Syncing"
                            if (apiClient.authenticated && (s === "idle" || s === "")) return "Synced"
                            return "Sync offline"
                        }
                        tone: {
                            if (!root.apiReady) return "neutral"
                            var s = apiClient.syncStatus
                            if (s === "syncing") return "warning"
                            if (apiClient.authenticated && (s === "idle" || s === "")) return "success"
                            return "danger"
                        }
                    }

                    StatusChip {
                        text: {
                            if (!root.sipReady) return "Initializing"
                            if (root.registered) return "Registered"
                            if (!root.sipConfigured) return "Not configured"
                            return "Offline"
                        }
                        tone: root.registered ? "success" : (root.sipConfigured ? "danger" : "warning")
                        pulsing: !root.registered && root.sipConfigured
                    }
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width; height: 1
                    color: Theme.border
                }
            }

            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: root.pageIndex

                CrmPanel {
                    id: crmPanel
                    currentContact: phonePanel.currentContact
                }

                CalendarPanel {
                    id: calendarPanel
                }

                SettingsPage {
                    id: settingsPage
                    account: root.sipReady ? sipManager.account : null
                    onBackPressed: root.pageIndex = 0
                }
            }
        }
    }

    // Rail navigation item: icon + caption, accent indicator when selected.
    component NavButton: AbstractButton {
        id: nav
        property string iconName: ""

        implicitWidth: 60
        implicitHeight: 58
        checkable: false
        hoverEnabled: true
        focusPolicy: Qt.StrongFocus
        Accessible.name: text

        HoverHandler { cursorShape: Qt.PointingHandCursor }

        background: Rectangle {
            radius: Theme.radius
            color: nav.checked ? Theme.accentSoft
                 : nav.hovered ? Theme.surfaceHover : "transparent"
            Behavior on color { ColorAnimation { duration: Theme.durFast } }

            Rectangle {
                visible: nav.checked
                anchors.left: parent.left
                anchors.leftMargin: -8
                anchors.verticalCenter: parent.verticalCenter
                width: 3; height: 24; radius: 2
                color: Theme.accent
            }
            FocusRing { target: nav }
        }

        contentItem: ColumnLayout {
            spacing: 4
            Icon {
                Layout.alignment: Qt.AlignHCenter
                name: nav.iconName
                size: 20
                color: nav.checked ? Theme.accent : (nav.hovered ? Theme.textPrimary : Theme.textSecondary)
            }
            Label {
                Layout.alignment: Qt.AlignHCenter
                text: nav.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.textXs
                font.weight: nav.checked ? Font.DemiBold : Font.Normal
                color: nav.checked ? Theme.accent : Theme.textSecondary
            }
        }
    }
}
