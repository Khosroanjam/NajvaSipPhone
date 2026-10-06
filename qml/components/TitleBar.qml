import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../theme"

// Custom window title bar for a frameless window: drag to move, double-click
// to maximize/restore, and themed minimize / maximize / close buttons.
Rectangle {
    id: bar
    property string title: ""
    default property alias trailing: extras.data   // optional items left of the buttons

    readonly property var win: Window.window
    readonly property bool maximized: win !== null && win.visibility === Window.Maximized

    function toggleMaximize() {
        if (!win) return
        if (maximized) win.showNormal()
        else win.showMaximized()
    }

    implicitHeight: 38
    color: Theme.rail

    // Move the window with the OS (keeps Aero snap / multi-monitor behavior).
    DragHandler {
        target: null
        grabPermissions: PointerHandler.TakeOverForbidden
        onActiveChanged: if (active && bar.win) bar.win.startSystemMove()
    }
    TapHandler {
        acceptedButtons: Qt.LeftButton
        gesturePolicy: TapHandler.DragThreshold
        onDoubleTapped: bar.toggleMaximize()
    }

    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: Theme.border
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        spacing: 10

        // App icon; the simplified variant stays legible at title-bar size.
        Image {
            Layout.preferredWidth: 24
            Layout.preferredHeight: 24
            source: "qrc:/icons/najva-small.svg"
            sourceSize: Qt.size(96, 96)
            smooth: true
            mipmap: true
        }

        Label {
            Layout.fillWidth: true
            text: bar.title
            elide: Text.ElideRight
            color: bar.win && bar.win.active ? Theme.textSecondary : Theme.textMuted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.textSm
            font.weight: Font.DemiBold
        }

        RowLayout {
            id: extras
            Layout.rightMargin: 8
            spacing: 8
        }

        // ── Window buttons ──
        Row {
            Layout.fillHeight: true
            spacing: 0

            WindowButton {
                iconName: "win-minimize"
                tooltip: "Minimize"
                onClicked: bar.win.showMinimized()
            }
            WindowButton {
                iconName: bar.maximized ? "win-restore" : "win-maximize"
                tooltip: bar.maximized ? "Restore" : "Maximize"
                onClicked: bar.toggleMaximize()
            }
            WindowButton {
                iconName: "win-close"
                tooltip: "Close"
                danger: true
                onClicked: bar.win.close()
            }
        }
    }

    component WindowButton: AbstractButton {
        id: wb
        property string iconName: ""
        property string tooltip: ""
        property bool danger: false

        width: 46
        height: bar.height - 1
        hoverEnabled: true
        focusPolicy: Qt.NoFocus
        Accessible.name: tooltip

        ToolTip.visible: hovered && tooltip !== ""
        ToolTip.delay: 800
        ToolTip.text: tooltip

        background: Rectangle {
            color: {
                if (wb.danger)
                    return wb.down ? "#B5121B" : wb.hovered ? "#E81123" : "transparent"
                return wb.down ? Theme.surfacePress : wb.hovered ? Theme.surfaceHover : "transparent"
            }
            Behavior on color { ColorAnimation { duration: Theme.durFast } }
        }

        contentItem: Item {
            Icon {
                anchors.centerIn: parent
                name: wb.iconName
                size: 16
                strokeWidth: 1.4
                color: wb.danger && wb.hovered ? "#FFFFFF"
                     : bar.win && bar.win.active ? Theme.textPrimary : Theme.textMuted
            }
        }
    }
}
