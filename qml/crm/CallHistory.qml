import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../theme"
import "../components"

// Recent calls list with search, selection, call-back and save actions.
ColumnLayout {
    id: root
    property var history: []
    property int selectedId: -1
    signal callSelected(var callId, var number, var name)
    signal saveToContacts(var number, var name)

    spacing: 12

    readonly property var filtered: {
        var q = search.text.trim().toLowerCase()
        if (q === "") return root.history
        return root.history.filter(function(c) {
            return (c.number || "").toLowerCase().indexOf(q) >= 0
                || (c.name || "").toLowerCase().indexOf(q) >= 0
        })
    }

    function formatDuration(seconds) {
        var s = seconds || 0
        var m = Math.floor(s / 60)
        var r = s % 60
        return m + ":" + (r < 10 ? "0" : "") + r
    }

    function formatTime(timestamp) {
        if (!timestamp) return ""
        var d = new Date(timestamp)
        var now = new Date()
        if (d.toDateString() === now.toDateString())
            return "Today, " + Qt.formatDateTime(d, "HH:mm")
        return Qt.formatDateTime(d, "MMM d, HH:mm")
    }

    SectionHeader {
        Layout.fillWidth: true
        title: "Recent calls"
        iconName: "history"
        meta: root.history.length === 0 ? "" : root.history.length + " calls"
    }

    AppTextField {
        id: search
        Layout.fillWidth: true
        leadingIcon: "search"
        placeholderText: "Search number or name"
        visible: root.history.length > 0
    }

    ListView {
        id: list
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: root.filtered.length > 0
        model: root.filtered
        spacing: 2
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        delegate: ItemDelegate {
            id: row
            width: list.width - 8
            height: 60
            hoverEnabled: true
            leftPadding: 10
            rightPadding: 8
            topPadding: 0
            bottomPadding: 0
            readonly property bool selected: modelData.id === root.selectedId
            readonly property bool incoming: modelData.direction === "incoming"
            readonly property bool missed: modelData.direction === "missed"
                                           || (incoming && (modelData.duration || 0) === 0)
            onClicked: root.callSelected(modelData.id, modelData.number, modelData.name)

            HoverHandler { cursorShape: Qt.PointingHandCursor }

            background: Rectangle {
                radius: Theme.radius
                color: row.selected ? Theme.accentSoft
                     : row.hovered ? Theme.surfaceHover : "transparent"
                Behavior on color { ColorAnimation { duration: Theme.durFast } }
            }

            contentItem: RowLayout {
                spacing: 12

                Rectangle {
                    width: 36; height: 36; radius: 18
                    color: row.missed ? Theme.dangerSoft : row.incoming ? Theme.successSoft : Theme.accentSoft
                    Icon {
                        anchors.centerIn: parent
                        size: 16
                        name: row.incoming ? "arrow-in" : "arrow-out"
                        color: row.missed ? Theme.danger : row.incoming ? Theme.success : Theme.accent
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1
                    Label {
                        Layout.fillWidth: true
                        text: modelData.name && modelData.name !== modelData.number
                              ? modelData.name : modelData.number
                        color: row.missed ? Theme.danger : Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.textMd
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignLeft
                    }
                    Label {
                        Layout.fillWidth: true
                        text: (modelData.name && modelData.name !== modelData.number ? modelData.number + " · " : "")
                              + (row.missed ? "Missed · " : row.incoming ? "Incoming · " : "Outgoing · ")
                              + root.formatTime(modelData.timestamp)
                        color: Theme.textMuted
                        font: Theme.fontSmall
                        elide: Text.ElideRight
                    }
                }

                Label {
                    text: root.formatDuration(modelData.duration)
                    color: Theme.textSecondary
                    font: Theme.fontSmall
                    visible: !row.hovered || list.width < 360
                }

                IconButton {
                    visible: (row.hovered || row.selected) && !modelData.contactId
                    iconName: "user-plus"
                    iconSize: 16
                    buttonSize: 32
                    tooltip: "Save to contacts"
                    onClicked: root.saveToContacts(modelData.number, modelData.name)
                }
                IconButton {
                    visible: row.hovered || row.selected
                    iconName: "phone"
                    iconSize: 16
                    buttonSize: 32
                    variant: "success"
                    tooltip: "Call back"
                    enabled: typeof sipManager !== "undefined" && sipManager && sipManager.isRegistered
                    onClicked: sipManager.makeCall(modelData.number)
                }
            }
        }
    }

    EmptyState {
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: root.filtered.length === 0
        iconName: root.history.length === 0 ? "phone" : "search"
        title: root.history.length === 0 ? "No calls yet" : "No matches"
        hint: root.history.length === 0
              ? "Calls you make or receive will appear here."
              : "Try a different number or name."
    }
}
