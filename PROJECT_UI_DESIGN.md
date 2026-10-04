# Design UI With This Senario QML
# SagharSIP - UI Design Specification (Phase 3)

## 🎯 هدف پروژه
طراحی رابط کاربری مدرن برای سافت‌فون SagharSIP با استفاده از Qt6/QML. این UI شامل دو پنل اصلی است:
1. **پنل تلفن (Phone Panel)**: برای شماره‌گیری و مدیریت تماس
2. **پنل CRM**: برای نمایش اطلاعات مخاطب، تاریخچه تماس‌ها و یادداشت‌ها

## 🎨 پالت رنگی و تم
- **پس‌زمینه اصلی**: `#0f1419` (تیره)
- **پس‌زمینه ثانویه**: `#1a1f2e`
- **پس‌زمینه سوم**: `#252b3d`
- **رنگ متن اصلی**: `#ffffff`
- **رنگ متن ثانویه**: `#a0aec0`
- **رنگ تأکیدی (آبی)**: `#3b82f6`
- **رنگ موفقیت (سبز)**: `#10b981`
- **رنگ خطر (قرمز)**: `#ef4444`
- **گرادیان آواتار**: از `#3b82f6` به `#8b5cf6`

---

##  ساختار فایل‌ها
qml/
├── Main.qml # پنجره اصلی با SplitView
├── theme/
│ ── Theme.qml # Singleton برای تم و رنگ‌ها
├── phone/
│ ├── PhonePanel.qml # کانتینر پنل تلفن
│ ├── Dialpad.qml # صفحه شماره‌گیری
│ └── CallScreen.qml # صفحه تماس فعال
└── crm/
├── CrmPanel.qml # کانتینر پنل CRM
├── ContactHeader.qml # هدر اطلاعات مخاطب
├── CallHistory.qml # لیست تاریخچه تماس‌ها
└── NotesSection.qml # بخش یادداشت‌ها

---

## 📝 فایل‌های QML

### . `qml/theme/Theme.qml`

```qml
pragma Singleton
import QtQuick 2.15

QtObject {
    // پالت رنگی تیره مدرن
    readonly property color bgPrimary: "#0f1419"
    readonly property color bgSecondary: "#1a1f2e"
    readonly property color bgTertiary: "#252b3d"
    readonly property color bgHover: "#2d3548"
    
    readonly property color textPrimary: "#ffffff"
    readonly property color textSecondary: "#a0aec0"
    readonly property color textMuted: "#6b7280"
    
    readonly property color accent: "#3b82f6"
    readonly property color accentHover: "#2563eb"
    readonly property color success: "#10b981"
    readonly property color danger: "#ef4444"
    readonly property color warning: "#f59e0b"
    
    readonly property color border: "#2d3548"
    readonly property color divider: "#1f2937"
    
    // فونت‌ها
    readonly property font fontBody: Qt.font({ family: "Segoe UI", pixelSize: 14 })
    readonly property font fontHeading: Qt.font({ family: "Segoe UI", pixelSize: 20, weight: Font.DemiBold })
    readonly property font fontSmall: Qt.font({ family: "Segoe UI", pixelSize: 12 })
    readonly property font fontDialpad: Qt.font({ family: "Segoe UI", pixelSize: 28, weight: Font.Light })
    
    // ابعاد
    readonly property int radius: 12
    readonly property int radiusSmall: 8
    readonly property int spacing: 12
}

# qml/Main.qml

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15

import "theme"
import "phone"
import "crm"

ApplicationWindow {
    id: root
    visible: true
    width: 1100
    height: 700
    minimumWidth: 900
    minimumHeight: 600
    title: "SagharSIP"
    color: Theme.bgPrimary

    // هدر اصلی برنامه
    header: Rectangle {
        height: 56
        color: Theme.bgSecondary
        border.color: Theme.border
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.margins: 16

            // لوگو و نام
            RowLayout {
                spacing: 10
                Rectangle {
                    width: 32; height: 32
                    radius: 8
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Theme.accent }
                        GradientStop { position: 1.0; color: "#8b5cf6" }
                    }
                    Label {
                        anchors.centerIn: parent
                        text: "S"
                        color: "white"
                        font.pixelSize: 18
                        font.bold: true
                    }
                }
                Label {
                    text: "SagharSIP"
                    color: Theme.textPrimary
                    font: Theme.fontHeading
                }
            }

            Item { Layout.fillWidth: true }

            // وضعیت ثبت‌نام
            RowLayout {
                spacing: 8
                Rectangle {
                    width: 8; height: 8
                    radius: 4
                    color: sipManager ? (sipManager.isRegistered ? Theme.success : Theme.danger) : Theme.textMuted
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
                Label {
                    text: sipManager ? (sipManager.isRegistered ? "Registered" : "Offline") : "Initializing..."
                    color: Theme.textSecondary
                    font: Theme.fontSmall
                }
            }
        }
    }

    // Split View اصلی
    SplitView {
        anchors.fill: parent
        orientation: Qt.Horizontal

        // پنل چپ: تلفن
        PhonePanel {
            id: phonePanel
            SplitView.preferredWidth: 380
            SplitView.minimumWidth: 320
            SplitView.maximumWidth: 480
        }

        // جداکننده
        Rectangle {
            SplitView.preferredWidth: 1
            color: Theme.border
        }

        // پنل راست: CRM
        CrmPanel {
            id: crmPanel
            SplitView.fillWidth: true
            SplitView.minimumWidth: 400
            currentContact: phonePanel.currentContact
        }
    }

    // اتصال به SipManager (در Phase 2 ساخته می‌شود)
    // property var sipManager: null  // از main.cpp ست می‌شود
}

# qml/phone/PhonePanel.qml
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import "../theme"

Item {
    id: root
    property string dialedNumber: ""
    property var currentContact: null
    property bool inCall: false

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // بخش بالایی: نمایشگر شماره
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 140
            color: Theme.bgSecondary

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 8

                Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.dialedNumber || "Enter number"
                    color: root.dialedNumber ? Theme.textPrimary : Theme.textMuted
                    font.pixelSize: root.dialedNumber ? 32 : 18
                    font.weight: root.dialedNumber ? Font.Light : Font.Normal
                    elide: Text.ElideMiddle
                    Layout.maximumWidth: parent.width - 40
                }

                // دکمه پاک کردن
                ItemButton {
                    visible: root.dialedNumber.length > 0
                    Layout.alignment: Qt.AlignHCenter
                    iconText: ""
                    onClicked: {
                        if (root.dialedNumber.length > 0) {
                            root.dialedNumber = root.dialedNumber.slice(0, -1)
                        }
                    }
                }
            }
        }

        // جداکننده
        Rectangle { height: 1; Layout.fillWidth: true; color: Theme.border }

        // Dialpad یا CallScreen (بسته به وضعیت)
        Loader {
            Layout.fillWidth: true
            Layout.fillHeight: true
            source: root.inCall ? "CallScreen.qml" : "Dialpad.qml"

            onLoaded: {
                if (!root.inCall) {
                    item.dialedNumber = Qt.binding(function() { return root.dialedNumber })
                    item.onDigitPressed.connect(function(digit) {
                        root.dialedNumber += digit
                    })
                    item.onCallPressed.connect(function() {
                        root.inCall = true
                        // TODO: sipManager.makeCall(root.dialedNumber)
                    })
                } else {
                    item.duration = 0
                    item.onHangupPressed.connect(function() {
                        root.inCall = false
                        // TODO: sipManager.hangup()
                    })
                }
            }
        }
    }
}

// کامپوننت دکمه کوچک داخلی
component ItemButton: Rectangle {
    property string iconText: ""
    signal clicked()
    
    width: 40; height: 40
    radius: 20
    color: mouseArea.containsMouse ? Theme.bgHover : "transparent"
    
    Label {
        anchors.centerIn: parent
        text: parent.iconText
        color: Theme.textSecondary
        font.pixelSize: 20
    }
    
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: parent.clicked()
    }
}

# qml/phone/Dialpad.qml
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import "../theme"

Item {
    id: root
    property string dialedNumber: ""
    
    signal digitPressed(string digit)
    signal callPressed()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 16

        // گرید دکمه‌ها
        Grid {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 3
            spacing: 12

            Repeater {
                model: [
                    { digit: "1", letters: "" },
                    { digit: "2", letters: "ABC" },
                    { digit: "3", letters: "DEF" },
                    { digit: "4", letters: "GHI" },
                    { digit: "5", letters: "JKL" },
                    { digit: "6", letters: "MNO" },
                    { digit: "7", letters: "PQRS" },
                    { digit: "8", letters: "TUV" },
                    { digit: "9", letters: "WXYZ" },
                    { digit: "*", letters: "" },
                    { digit: "0", letters: "+" },
                    { digit: "#", letters: "" }
                ]
                delegate: DialpadButton {
                    width: (parent.width - 24) / 3
                    height: (parent.height - 24) / 4
                    digit: modelData.digit
                    letters: modelData.letters
                    onClicked: root.digitPressed(modelData.digit)
                }
            }
        }

        // دکمه تماس
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 64
            radius: 32
            color: callMouse.containsMouse ? "#0ea371" : Theme.success
            
            Behavior on color { ColorAnimation { duration: 150 } }
            
            Row {
                anchors.centerIn: parent
                spacing: 10
                
                Label {
                    text: "📞"
                    font.pixelSize: 22
                    color: "white"
                }
                Label {
                    text: "Call"
                    color: "white"
                    font.pixelSize: 16
                    font.weight: Font.DemiBold
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
            
            MouseArea {
                id: callMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.callPressed()
            }
        }
    }
}

// کامپوننت دکمه Dialpad
component DialpadButton: Rectangle {
    property string digit: ""
    property string letters: ""
    signal clicked()
    
    radius: Theme.radius
    color: btnMouse.containsMouse ? Theme.bgHover : Theme.bgTertiary
    border.color: Theme.border
    border.width: 1
    
    Behavior on color { ColorAnimation { duration: 150 } }
    
    Column {
        anchors.centerIn: parent
        spacing: 2
        
        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: parent.parent.digit
            color: Theme.textPrimary
            font: Theme.fontDialpad
        }
        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: parent.parent.letters
            color: Theme.textMuted
            font.pixelSize: 10
            font.letterSpacing: 2
            visible: parent.parent.letters !== ""
        }
    }
    
    MouseArea {
        id: btnMouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: parent.clicked()
        onPressed: parent.scale = 0.95
        onReleased: parent.scale = 1.0
    }
    
    scale: 1.0
    Behavior on scale { NumberAnimation { duration: 100 } }
}

# qml/phone/CallScreen.qml

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import "../theme"

Item {
    id: root
    property int duration: 0
    property string callerName: "Unknown"
    property string callerNumber: ""
    
    signal hangupPressed()
    signal muteToggled()
    signal speakerToggled()

    property bool isMuted: false
    property bool isSpeaker: false

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 32
        spacing: 24

        Item { Layout.fillHeight: true }

        // آواتار تماس‌گیرنده
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: 120; height: 120
            radius: 60
            gradient: Gradient {
                GradientStop { position: 0.0; color: Theme.accent }
                GradientStop { position: 1.0; color: "#8b5cf6" }
            }
            
            Label {
                anchors.centerIn: parent
                text: root.callerName.charAt(0).toUpperCase()
                color: "white"
                font.pixelSize: 48
                font.weight: Font.Light
            }
            
            // انیمیشن پالس
            Rectangle {
                anchors.centerIn: parent
                width: parent.width
                height: parent.height
                radius: 60
                color: "transparent"
                border.color: Theme.accent
                border.width: 2
                opacity: pulseAnim.running ? 0.6 : 0
                
                SequentialAnimation on scale {
                    id: pulseAnim
                    running: true
                    loops: Animation.Infinite
                    NumberAnimation { from: 1.0; to: 1.4; duration: 1500 }
                    NumberAnimation { from: 1.4; to: 1.0; duration: 0 }
                }
                SequentialAnimation on opacity {
                    running: true
                    loops: Animation.Infinite
                    NumberAnimation { from: 0.6; to: 0; duration: 1500 }
                    NumberAnimation { from: 0; to: 0.6; duration: 0 }
                }
            }
        }

        // نام و شماره
        Column {
            Layout.alignment: Qt.AlignHCenter
            spacing: 6
            
            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.callerName
                color: Theme.textPrimary
                font.pixelSize: 24
                font.weight: Font.DemiBold
            }
            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.callerNumber || root.duration > 0 ? formatTime(root.duration) : "Calling..."
                color: Theme.textSecondary
                font.pixelSize: 14
            }
        }

        Item { Layout.fillHeight: true }

        // دکمه‌های کنترل
        Row {
            Layout.alignment: Qt.AlignHCenter
            spacing: 32
            
            CallActionButton {
                icon: root.isMuted ? "🔇" : "🎤"
                label: "Mute"
                active: root.isMuted
                onClicked: {
                    root.isMuted = !root.isMuted
                    root.muteToggled()
                }
            }
            
            CallActionButton {
                icon: root.isSpeaker ? "🔊" : "🔈"
                label: "Speaker"
                active: root.isSpeaker
                onClicked: {
                    root.isSpeaker = !root.isSpeaker
                    root.speakerToggled()
                }
            }
            
            CallActionButton {
                icon: "⌨"
                label: "Keypad"
                onClicked: { /* TODO */ }
            }
        }

        // دکمه قطع تماس
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 20
            width: 72; height: 72
            radius: 36
            color: hangupMouse.containsMouse ? "#dc2626" : Theme.danger
            
            Behavior on color { ColorAnimation { duration: 150 } }
            
            Label {
                anchors.centerIn: parent
                text: "📵"
                font.pixelSize: 28
                color: "white"
            }
            
            MouseArea {
                id: hangupMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.hangupPressed()
            }
        }

        Item { Layout.preferredHeight: 20 }
    }

    // Timer برای شمارش مدت تماس
    Timer {
        running: root.duration >= 0
        interval: 1000
        repeat: true
        onTriggered: root.duration++
    }

    function formatTime(seconds) {
        var m = Math.floor(seconds / 60)
        var s = seconds % 60
        return (m < 10 ? "0" + m : m) + ":" + (s < 10 ? "0" + s : s)
    }
}

component CallActionButton: Column {
    property string icon: ""
    property string label: ""
    property bool active: false
    signal clicked()
    
    spacing: 8
    
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        width: 56; height: 56
        radius: 28
        color: parent.active ? Theme.accent : (actionMouse.containsMouse ? Theme.bgHover : Theme.bgTertiary)
        border.color: Theme.border
        border.width: 1
        
        Behavior on color { ColorAnimation { duration: 150 } }
        
        Label {
            anchors.centerIn: parent
            text: parent.parent.icon
            font.pixelSize: 22
        }
        
        MouseArea {
            id: actionMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: parent.parent.clicked()
        }
    }
    
    Label {
        anchors.horizontalCenter: parent.horizontalCenter
        text: parent.label
        color: Theme.textSecondary
        font: Theme.fontSmall
    }
}

# qml/crm/CrmPanel.qml
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import "../theme"

Item {
    id: root
    property var currentContact: null

    // داده‌های نمونه (در Phase 4 از C++ می‌آید)
    property var mockContact: ({
        name: "Sarah Johnson",
        company: "Acme Corp",
        phone: "+1 (555) 123-4567",
        email: "sarah@acme.com",
        avatar: "S",
        tags: ["VIP", "Client"]
    })
    
    property var mockHistory: [
        { type: "incoming", time: "Today, 14:32", duration: "5:23", number: "+15551234567" },
        { type: "outgoing", time: "Yesterday, 09:15", duration: "12:45", number: "+15551234567" },
        { type: "missed", time: "2 days ago", duration: "0:00", number: "+15551234567" },
        { type: "incoming", time: "3 days ago", duration: "2:10", number: "+15551234567" }
    ]
    
    property string mockNotes: "Prefers morning calls.\nInterested in enterprise plan.\nFollow up next week about contract renewal."

    Flickable {
        anchors.fill: parent
        contentHeight: mainColumn.height
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: mainColumn
            width: parent.width
            spacing: 0

            // هدر مخاطب
            ContactHeader {
                Layout.fillWidth: true
                contact: root.currentContact || root.mockContact
            }

            // بخش اطلاعات سریع (Quick Actions)
            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 16
                Layout.leftMargin: 24
                Layout.rightMargin: 24
                height: 70
                radius: Theme.radius
                color: Theme.bgSecondary
                border.color: Theme.border
                border.width: 1

                Row {
                    anchors.centerIn: parent
                    spacing: 12
                    
                    QuickAction {
                        icon: ""; label: "Call"
                        onClicked: console.log("Call clicked")
                    }
                    Rectangle { width: 1; height: 40; color: Theme.border }
                    QuickAction {
                        icon: "💬"; label: "Message"
                        onClicked: console.log("Message clicked")
                    }
                    Rectangle { width: 1; height: 40; color: Theme.border }
                    QuickAction {
                        icon: "📧"; label: "Email"
                        onClicked: console.log("Email clicked")
                    }
                    Rectangle { width: 1; height: 40; color: Theme.border }
                    QuickAction {
                        icon: "📅"; label: "Schedule"
                        onClicked: console.log("Schedule clicked")
                    }
                }
            }

            // تاریخچه تماس‌ها
            CallHistory {
                Layout.fillWidth: true
                Layout.topMargin: 24
                Layout.leftMargin: 24
                Layout.rightMargin: 24
                history: root.mockHistory
            }

            // یادداشت‌ها
            NotesSection {
                Layout.fillWidth: true
                Layout.topMargin: 24
                Layout.leftMargin: 24
                Layout.rightMargin: 24
                Layout.bottomMargin: 24
                notes: root.mockNotes
            }
        }
    }
}

component QuickAction: Column {
    property string icon: ""
    property string label: ""
    signal clicked()
    
    spacing: 4
    width: 70
    
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        width: 40; height: 40
        radius: 20
        color: qaMouse.containsMouse ? Theme.bgHover : "transparent"
        
        Label {
            anchors.centerIn: parent
            text: parent.parent.icon
            font.pixelSize: 18
        }
        
        MouseArea {
            id: qaMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: parent.clicked()
        }
    }
    
    Label {
        anchors.horizontalCenter: parent.horizontalCenter
        text: parent.label
        color: Theme.textSecondary
        font: Theme.fontSmall
    }
}
# qml/crm/ContactHeader.qml
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import "../theme"

Rectangle {
    id: root
    property var contact: ({})
    
    height: 180
    color: Theme.bgSecondary
    border.color: Theme.border
    border.width: 1

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 16

            // آواتار
            Rectangle {
                width: 64; height: 64
                radius: 32
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Theme.accent }
                    GradientStop { position: 1.0; color: "#8b5cf6" }
                }
                
                Label {
                    anchors.centerIn: parent
                    text: root.contact.avatar || "?"
                    color: "white"
                    font.pixelSize: 28
                    font.weight: Font.Light
                }
            }

            // اطلاعات
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Label {
                    text: root.contact.name || "Unknown"
                    color: Theme.textPrimary
                    font: Theme.fontHeading
                }
                
                Label {
                    text: root.contact.company || ""
                    color: Theme.textSecondary
                    font: Theme.fontBody
                    visible: text !== ""
                }

                // تگ‌ها
                Row {
                    spacing: 6
                    visible: root.contact.tags && root.contact.tags.length > 0
                    
                    Repeater {
                        model: root.contact.tags || []
                        delegate: Rectangle {
                            width: tagLabel.implicitWidth + 16
                            height: 22
                            radius: 11
                            color: Theme.bgTertiary
                            
                            Label {
                                id: tagLabel
                                anchors.centerIn: parent
                                text: modelData
                                color: Theme.accent
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                            }
                        }
                    }
                }
            }

            // دکمه ویرایش
            Rectangle {
                width: 36; height: 36
                radius: 18
                color: editMouse.containsMouse ? Theme.bgHover : "transparent"
                
                Label {
                    anchors.centerIn: parent
                    text: "✎"
                    color: Theme.textSecondary
                    font.pixelSize: 18
                }
                
                MouseArea {
                    id: editMouse
                    anchors.fill: parent
                    hoverEnabled: true
                }
            }
        }

        // جزئیات تماس
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 8
            spacing: 24

            ContactDetail { icon: ""; value: root.contact.phone || "-" }
            ContactDetail { icon: "✉"; value: root.contact.email || "-" }
        }
    }
}

component ContactDetail: RowLayout {
    property string icon: ""
    property string value: ""
    
    spacing: 8
    
    Label {
        text: parent.icon
        font.pixelSize: 14
    }
    Label {
        text: parent.value
        color: Theme.textSecondary
        font: Theme.fontSmall
        elide: Text.ElideRight
        Layout.fillWidth: true
    }
}
# qml/crm/CallHistory.qml

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import "../theme"

ColumnLayout {
    id: root
    property var history: []
    spacing: 12

    RowLayout {
        Layout.fillWidth: true
        Label {
            text: "Call History"
            color: Theme.textPrimary
            font.pixelSize: 16
            font.weight: Font.DemiBold
        }
        Item { Layout.fillWidth: true }
        Label {
            text: "View all →"
            color: Theme.accent
            font: Theme.fontSmall
        }
    }

    Rectangle {
        Layout.fillWidth: true
        height: historyList.contentHeight + 16
        radius: Theme.radius
        color: Theme.bgSecondary
        border.color: Theme.border
        border.width: 1

        ListView {
            id: historyList
            anchors.fill: parent
            anchors.margins: 8
            model: root.history
            spacing: 4
            interactive: false

            delegate: Rectangle {
                width: historyList.width
                height: 56
                radius: Theme.radiusSmall
                color: histMouse.containsMouse ? Theme.bgHover : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12

                    // آیکون نوع تماس
                    Rectangle {
                        width: 36; height: 36
                        radius: 18
                        color: {
                            switch(modelData.type) {
                                case "incoming": return Theme.success + "20"
                                case "outgoing": return Theme.accent + "20"
                                case "missed": return Theme.danger + "20"
                            }
                        }
                        
                        Label {
                            anchors.centerIn: parent
                            text: {
                                switch(modelData.type) {
                                    case "incoming": return "↙"
                                    case "outgoing": return "↗"
                                    case "missed": return "✕"
                                }
                            }
                            color: {
                                switch(modelData.type) {
                                    case "incoming": return Theme.success
                                    case "outgoing": return Theme.accent
                                    case "missed": return Theme.danger
                                }
                            }
                            font.pixelSize: 16
                            font.bold: true
                        }
                    }

                    // اطلاعات
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        
                        Label {
                            text: modelData.number
                            color: Theme.textPrimary
                            font: Theme.fontBody
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        Label {
                            text: modelData.time
                            color: Theme.textMuted
                            font: Theme.fontSmall
                        }
                    }

                    // مدت
                    Label {
                        text: modelData.duration
                        color: modelData.type === "missed" ? Theme.danger : Theme.textSecondary
                        font: Theme.fontSmall
                    }

                    // دکمه تماس مجدد
                    Rectangle {
                        width: 32; height: 32
                        radius: 16
                        color: callAgainMouse.containsMouse ? Theme.bgTertiary : "transparent"
                        
                        Label {
                            anchors.centerIn: parent
                            text: "📞"
                            font.pixelSize: 14
                        }
                        
                        MouseArea {
                            id: callAgainMouse
                            anchors.fill: parent
                            hoverEnabled: true
                        }
                    }
                }

                MouseArea {
                    id: histMouse
                    anchors.fill: parent
                    hoverEnabled: true
                }
            }
        }
    }
}
# qml/crm/NotesSection.qml
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import "../theme"

ColumnLayout {
    id: root
    property string notes: ""
    spacing: 12

    RowLayout {
        Layout.fillWidth: true
        Label {
            text: "Notes"
            color: Theme.textPrimary
            font.pixelSize: 16
            font.weight: Font.DemiBold
        }
        Item { Layout.fillWidth: true }
        Label {
            text: "✎ Edit"
            color: Theme.accent
            font: Theme.fontSmall
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: Math.max(120, notesArea.contentHeight + 32)
        radius: Theme.radius
        color: Theme.bgSecondary
        border.color: Theme.border
        border.width: 1

        ScrollView {
            anchors.fill: parent
            anchors.margins: 12
            clip: true
            
            TextArea {
                id: notesArea
                readOnly: true
                wrapMode: TextArea.Wrap
                text: root.notes
                color: Theme.textSecondary
                font: Theme.fontBody
                background: Rectangle { color: "transparent" }
                padding: 0
            }
        }
    }
}
# resources.qrc (بروز رسانی شده)
<RCC>
<qresource prefix="/">
    <file>qml/Main.qml</file>
    <file>qml/theme/Theme.qml</file>
    <file>qml/phone/PhonePanel.qml</file>
    <file>qml/phone/Dialpad.qml</file>
    <file>qml/phone/CallScreen.qml</file>
    <file>qml/crm/CrmPanel.qml</file>
    <file>qml/crm/ContactHeader.qml</file>
    <file>qml/crm/CallHistory.qml</file>
    <file>qml/crm/NotesSection.qml</file>
</qresource>
</RCC>

# 🚀 مراحل اجرا
 تمام فایل‌های QML بالا را در پوشه‌های مربوطه در پروژه خود کپی کنید
 فایل resources.qrc را به‌روزرسانی کنید
 پروژه را بیلد کنید: Ctrl + B
 اجرا کنید: Ctrl + R

# 📊 ویژگی‌های پیاده‌سازی شده
✅ طراحی مدرن با تم تیره
 ✅ Split View با قابلیت تغییر اندازه
 ✅ Dialpad کامل با انیمیشن‌های hover و press
 ✅ صفحه تماس فعال با انیمیشن پالس
 ✅ پنل CRM با اطلاعات مخاطب
 ✅ تاریخچه تماس‌ها با آیکون‌های رنگی
 ✅ بخش یادداشت‌ها
 ✅ Hover effects روی تمام دکمه‌ها
 ✅ انیمیشن‌های نرم (fade, scale, pulse)

 # 🔜 مراحل بعدی
 پس از تأیید UI، به Phase 2 می‌رویم:
 ساخت کلاس‌های C++ Bridge (SipManager, SipAccount, SipCall)
 اتصال UI به PJSUA2
 پیاده‌سازی منطق واقعی تماس 
