import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../theme"

// Section title with optional icon and trailing meta text.
RowLayout {
    id: root
    property string title: ""
    property string iconName: ""
    property string meta: ""

    spacing: 8

    Icon {
        visible: root.iconName !== ""
        name: root.iconName
        size: 16
        color: Theme.textSecondary
    }
    Label {
        text: root.title
        color: Theme.textPrimary
        font: Theme.fontTitle
    }
    Item { Layout.fillWidth: true }
    Label {
        text: root.meta
        color: Theme.textMuted
        font: Theme.fontSmall
        visible: text !== ""
    }
}
