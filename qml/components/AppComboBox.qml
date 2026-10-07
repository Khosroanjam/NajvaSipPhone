import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../theme"

// Labeled, themed ComboBox. Model items are objects with `textRole` field.
ColumnLayout {
    id: root
    property string label: ""
    property string leadingIcon: ""
    property alias model: combo.model
    property alias textRole: combo.textRole
    property alias currentIndex: combo.currentIndex
    property alias combo: combo
    signal activated(int index)

    spacing: 6

    Label {
        visible: root.label !== ""
        text: root.label
        color: Theme.textSecondary
        font: Theme.fontLabel
    }

    ComboBox {
        id: combo
        Layout.fillWidth: true
        implicitHeight: Theme.controlHeight
        font: Theme.fontBody
        hoverEnabled: true
        Accessible.name: root.label
        onActivated: function(i) { root.activated(i) }

        HoverHandler { cursorShape: Qt.PointingHandCursor }

        contentItem: RowLayout {
            spacing: 10
            Item { Layout.preferredWidth: root.leadingIcon !== "" ? 2 : 0 }
            Icon {
                visible: root.leadingIcon !== ""
                name: root.leadingIcon
                size: 16
                color: Theme.textMuted
            }
            Label {
                Layout.fillWidth: true
                leftPadding: root.leadingIcon !== "" ? 0 : 2
                text: combo.displayText
                color: Theme.textPrimary
                font: combo.font
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
            }
        }
        leftPadding: 12
        rightPadding: 36

        indicator: Icon {
            x: combo.width - width - 12
            y: (combo.height - height) / 2
            name: "chevron-right"
            size: 16
            rotation: combo.popup.visible ? -90 : 90
            color: Theme.textMuted
            Behavior on rotation { NumberAnimation { duration: Theme.durFast } }
        }

        background: Rectangle {
            radius: Theme.radius
            color: Theme.surfaceRaised
            border.width: combo.activeFocus ? 2 : 1
            border.color: combo.activeFocus ? Theme.accent
                        : combo.hovered ? Theme.borderStrong : Theme.border
            Behavior on border.color { ColorAnimation { duration: Theme.durFast } }
        }

        delegate: ItemDelegate {
            id: opt
            width: combo.width - 8
            x: 4
            height: 36
            highlighted: combo.highlightedIndex === index
            contentItem: RowLayout {
                spacing: 8
                Label {
                    Layout.fillWidth: true
                    text: {
                        // JS-array models only expose modelData; QAbstractItemModels expose model[role].
                        var v = (typeof modelData === "object" && modelData !== null && combo.textRole)
                                ? modelData[combo.textRole]
                                : (combo.textRole && model ? model[combo.textRole] : modelData)
                        return v === undefined || v === null ? "" : String(v)
                    }
                    color: Theme.textPrimary
                    font: Theme.fontBody
                    elide: Text.ElideRight
                }
                Icon {
                    visible: combo.currentIndex === index
                    name: "check"
                    size: 14
                    color: Theme.accent
                }
            }
            background: Rectangle {
                radius: Theme.radiusSm
                color: opt.highlighted ? Theme.surfaceHover : "transparent"
            }
        }

        popup: Popup {
            y: combo.height + 4
            width: combo.width
            implicitHeight: Math.min(contentItem.implicitHeight + 8, 300)
            padding: 4
            contentItem: ListView {
                clip: true
                implicitHeight: contentHeight
                model: combo.popup.visible ? combo.delegateModel : null
                currentIndex: combo.highlightedIndex
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
            }
            background: Rectangle {
                radius: Theme.radius
                color: Theme.surface
                border.width: 1
                border.color: Theme.borderStrong
            }
        }
    }
}
