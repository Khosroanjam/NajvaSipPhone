import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../theme"

// Labeled text input. Bind `text` and handle `edited(text)` to write back.
ColumnLayout {
    id: root
    property string label: ""
    property alias text: field.text
    property alias placeholderText: field.placeholderText
    property alias field: field
    property string helperText: ""
    property bool password: false
    property string leadingIcon: ""
    signal edited(string text)

    spacing: 6

    Label {
        visible: root.label !== ""
        text: root.label
        color: Theme.textSecondary
        font: Theme.fontLabel
    }

    TextField {
        id: field
        Layout.fillWidth: true
        implicitHeight: Theme.controlHeight
        leftPadding: root.leadingIcon !== "" ? 38 : 12
        rightPadding: root.password ? 40 : 12
        color: Theme.textPrimary
        placeholderTextColor: Theme.textMuted
        selectionColor: Theme.accent
        selectedTextColor: Theme.textOnAccent
        font: Theme.fontBody
        echoMode: root.password && !reveal.active ? TextInput.Password : TextInput.Normal
        selectByMouse: true
        Accessible.name: root.label
        onTextEdited: root.edited(text)

        background: Rectangle {
            radius: Theme.radius
            color: Theme.surfaceRaised
            border.width: field.activeFocus ? 2 : 1
            border.color: field.activeFocus ? Theme.accent
                        : fieldHover.hovered ? Theme.borderStrong : Theme.border
            Behavior on border.color { ColorAnimation { duration: Theme.durFast } }
            HoverHandler { id: fieldHover; cursorShape: Qt.IBeamCursor }
        }

        Icon {
            visible: root.leadingIcon !== ""
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            name: root.leadingIcon
            size: 16
            color: Theme.textMuted
        }

        IconButton {
            id: reveal
            visible: root.password
            anchors.right: parent.right
            anchors.rightMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            buttonSize: 32
            iconSize: 16
            iconName: active ? "eye-off" : "eye"
            tooltip: active ? "Hide password" : "Show password"
            iconColor: hovered ? Theme.textPrimary : Theme.textMuted
            onClicked: active = !active
            background: Item {}
        }
    }

    Label {
        visible: root.helperText !== ""
        text: root.helperText
        color: Theme.textMuted
        font: Theme.fontSmall
        Layout.fillWidth: true
        wrapMode: Text.Wrap
    }
}
