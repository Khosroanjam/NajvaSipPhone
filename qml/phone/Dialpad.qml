import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../theme"
import "../components"

// 12-key pad. Emits digits; the owner holds the number.
Item {
    id: root
    property real keySize: 64
    property bool showLetters: true

    signal digitPressed(string digit)

    implicitWidth: grid.implicitWidth
    implicitHeight: grid.implicitHeight

    readonly property var letters: ({
        "1": "", "2": "ABC", "3": "DEF", "4": "GHI", "5": "JKL", "6": "MNO",
        "7": "PQRS", "8": "TUV", "9": "WXYZ", "*": "", "0": "+", "#": ""
    })

    Grid {
        id: grid
        anchors.centerIn: parent
        columns: 3
        columnSpacing: 18
        rowSpacing: 12

        Repeater {
            model: ["1", "2", "3", "4", "5", "6", "7", "8", "9", "*", "0", "#"]
            delegate: DialKey {
                digit: modelData
                sub: root.showLetters ? root.letters[modelData] : ""
                onClicked: root.digitPressed(modelData)
            }
        }
    }

    component DialKey: AbstractButton {
        id: key
        property string digit: ""
        property string sub: ""

        width: root.keySize
        height: root.keySize
        hoverEnabled: true
        focusPolicy: Qt.TabFocus
        Accessible.name: digit
        autoRepeat: false

        HoverHandler { cursorShape: Qt.PointingHandCursor }

        background: Rectangle {
            radius: width / 2
            color: key.down ? Theme.surfacePress
                 : key.hovered ? Theme.surfaceHover : Theme.surfaceRaised
            border.width: 1
            border.color: key.hovered ? Theme.borderStrong : Theme.border
            Behavior on color { ColorAnimation { duration: Theme.durFast } }
            FocusRing { target: key; ringRadius: width / 2 + 3 }
        }

        contentItem: Item {
            Column {
                anchors.centerIn: parent
                spacing: -2
                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: key.digit
                    color: Theme.textPrimary
                    font: Theme.fontDialpad
                }
                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: key.sub
                    visible: key.sub !== ""
                    color: Theme.textMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: 9
                    font.letterSpacing: 1.5
                    font.weight: Font.DemiBold
                }
            }
        }
    }
}
