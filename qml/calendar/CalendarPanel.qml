import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../theme"
import "../components"

Item {
    id: root
    property int currentJalaliYear: 1404
    property int currentJalaliMonth: 5
    property int selectedDay: 0
    property var callsForSelectedDay: []

    readonly property var monthNames: [
        "", "Farvardin", "Ordibehesht", "Khordad", "Tir",
        "Mordad", "Shahrivar", "Mehr", "Aban", "Azar",
        "Dey", "Bahman", "Esfand"
    ]
    readonly property var weekdayHeaders: ["Sh", "Ye", "Do", "Se", "Ch", "Pa", "Jo"]

    Component.onCompleted: {
        // Initialize today's Jalali date
        var now = new Date()
        var j = gregorianToJalali(now.getFullYear(), now.getMonth() + 1, now.getDate())
        todayJalaliYear = j.jy
        todayJalaliMonth = j.jm
        todayJalaliDay = j.jd
        currentJalaliYear = j.jy
        currentJalaliMonth = j.jm
        updateCalendar()
    }

    function updateCalendar() {
        var gDate = jalaliToGregorian(currentJalaliYear, currentJalaliMonth, 1)
        var firstDayGreg = new Date(gDate.year, gDate.month - 1, gDate.day)
        var firstDayWeekday = firstDayGreg.getDay()
        var jalaliWeekday = (firstDayWeekday + 1) % 7

        var daysCount = daysInMonth(currentJalaliMonth, currentJalaliYear)

        calendarModel.clear()
        for (var i = 0; i < jalaliWeekday; i++) {
            calendarModel.append({ day: 0, hasCalls: false, isToday: false, isSelected: false })
        }
        for (var d = 1; d <= daysCount; d++) {
            var isToday = (currentJalaliYear === todayJalaliYear &&
                           currentJalaliMonth === todayJalaliMonth && d === todayJalaliDay)
            var isSelected = (selectedDay === d)
            calendarModel.append({ day: d, hasCalls: checkHasCalls(d), isToday: isToday, isSelected: isSelected })
        }
    }

    function checkHasCalls(day) {
        var gDate = jalaliToGregorian(currentJalaliYear, currentJalaliMonth, day)
        var dateStr = gDate.year + "-" +
                      String(gDate.month).padStart(2, '0') + "-" +
                      String(gDate.day).padStart(2, '0')
        if (typeof db !== "undefined" && db) {
            var calls = db.callHistoryByDate(dateStr)
            return calls && calls.length > 0
        }
        return false
    }

    function selectDay(day) {
        selectedDay = day
        var gDate = jalaliToGregorian(currentJalaliYear, currentJalaliMonth, day)
        var dateStr = gDate.year + "-" +
                      String(gDate.month).padStart(2, '0') + "-" +
                      String(gDate.day).padStart(2, '0')
        if (typeof db !== "undefined" && db) {
            callsForSelectedDay = db.callHistoryByDate(dateStr)
        } else {
            callsForSelectedDay = []
        }
        updateCalendar()
    }

    // Borkowski algorithm:
    function jalaliToGregorian(jy, jm, jd) {
        var jy2 = jy - 979
        var jm2 = jm - 1
        var days = jy2 * 365 + Math.floor(jy2 / 33) * 8 + Math.floor(((jy2 % 33) + 3) / 4)
        for (var m = 0; m < jm2; m++) {
            if (m < 6) days += 31
            else if (m < 11) days += 30
            else days += (isJalaliLeap(jy) ? 30 : 29)
        }
        days += jd - 1
        days += 538
        // Gregorian epoch offset
        var epbase = days + 400
        var gy = Math.floor(epbase / 146097) * 400
        var epbase2 = epbase % 146097
        if (epbase2 < 0) epbase2 += 146097
        var gy2 = Math.floor((epbase2) / 36524) * 100
        var epbase3 = epbase2 % 36524
        if (epbase3 < 0) epbase3 += 36524
        var gy3 = Math.floor(epbase3 / 1461) * 4
        var epbase4 = epbase3 % 1461
        if (epbase4 < 0) epbase4 += 1461
        var gy4 = Math.floor(epbase4 / 365)
        if (gy4 > 3) gy4 = 3
        var gyFinal = gy + gy2 + gy3 + gy4
        var remaining = epbase4 - gy4 * 365
        if (remaining < 0) remaining += 365

        var monthLengths = [31, (isGregorianLeap(gyFinal + 1) ? 29 : 28), 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
        var gm = 0
        while (gm < 12 && remaining >= monthLengths[gm]) {
            remaining -= monthLengths[gm]
            gm++
        }
        gm++
        var gd = remaining + 1
        // Fix year increment:
        if (jy > 0) gyFinal++
        return { year: gyFinal, month: gm, day: gd }
    }

    function isJalaliLeap(jy) {
        var breaks = [-61, 9, 38, 199, 426, 686, 756, 818, 1111, 1181, 1210,
                      1635, 2060, 2097, 2192, 2262, 2324, 2394, 2456, 3178]
        for (var i = 0; i < breaks.length; i++) {
            var dm = (breaks[i] - jy) * 31 + (breaks[i] < 0 ? 0 : 1)
            var rem = ((dm % 128) + 128) % 128
            var daysInNextChange = dm > 0 ? (128 - rem) : (rem === 0 ? 128 : rem)
            if (daysInNextChange === 0) return (i % 2 === 0)
        }
        return false
    }

    function isGregorianLeap(gy) {
        return (gy % 4 === 0 && gy % 100 !== 0) || gy % 400 === 0
    }

    function daysInMonth(jm, jy) {
        if (jm <= 6) return 31
        if (jm <= 11) return 30
        return isJalaliLeap(jy) ? 30 : 29
    }

    // Today
    property int todayJalaliYear: 0
    property int todayJalaliMonth: 0
    property int todayJalaliDay: 0

    function gregorianToJalali(gy, gm, gd) {
        var gdm = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334]
        var gy2 = (gm > 2) ? (gy + 1) : gy
        var days = 355666 + (365 * gy) + Math.floor((gy2 + 3) / 4) -
                   Math.floor((gy2 + 99) / 100) + Math.floor((gy2 + 399) / 400) +
                   gd + gdm[gm - 1]

        var jy = -1595 + 33 * Math.floor(days / 12053)
        var remaining = days % 12053
        jy += 4 * Math.floor(remaining / 1461)
        remaining = remaining % 1461
        if (remaining > 365) {
            jy += Math.floor((remaining - 1) / 365)
            remaining = (remaining - 1) % 365
        }
        var jm, jd
        if (remaining < 186) {
            jm = 1 + Math.floor(remaining / 31)
            jd = 1 + (remaining % 31)
        } else {
            jm = 7 + Math.floor((remaining - 186) / 30)
            jd = 1 + ((remaining - 186) % 30)
        }
        return { jy: jy, jm: jm, jd: jd }
    }

    function formatDuration(seconds) {
        var m = Math.floor(seconds / 60)
        var s = seconds % 60
        return (m < 10 ? "0" + m : m) + ":" + (s < 10 ? "0" + s : s)
    }

    function shiftMonth(delta) {
        var m = currentJalaliMonth + delta
        var y = currentJalaliYear
        if (m < 1) { m = 12; y-- }
        if (m > 12) { m = 1; y++ }
        currentJalaliMonth = m
        currentJalaliYear = y
        selectedDay = 0
        callsForSelectedDay = []
        updateCalendar()
    }

    function goToday() {
        currentJalaliYear = todayJalaliYear
        currentJalaliMonth = todayJalaliMonth
        selectDay(todayJalaliDay)
    }

    readonly property bool wide: width >= 760

    ListModel {
        id: calendarModel
    }

    GridLayout {
        anchors.fill: parent
        anchors.margins: 24
        columns: root.wide ? 2 : 1
        columnSpacing: 20
        rowSpacing: 20

        // ── Month grid ──
        Card {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 3
            Layout.minimumHeight: 360

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    ColumnLayout {
                        spacing: 0
                        Label {
                            text: monthNames[currentJalaliMonth]
                            color: Theme.textPrimary
                            font: Theme.fontHeading
                        }
                        Label {
                            text: currentJalaliYear
                            color: Theme.textMuted
                            font: Theme.fontSmall
                        }
                    }

                    Item { Layout.fillWidth: true }

                    AppButton {
                        text: "Today"
                        variant: "secondary"
                        compact: true
                        onClicked: root.goToday()
                    }
                    IconButton {
                        iconName: "chevron-left"
                        tooltip: "Previous month"
                        variant: "secondary"
                        buttonSize: 32
                        iconSize: 16
                        onClicked: root.shiftMonth(-1)
                    }
                    IconButton {
                        iconName: "chevron-right"
                        tooltip: "Next month"
                        variant: "secondary"
                        buttonSize: 32
                        iconSize: 16
                        onClicked: root.shiftMonth(1)
                    }
                }

                // Weekday headers (week starts on Saturday)
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    Repeater {
                        model: weekdayHeaders
                        Label {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            text: modelData
                            color: index === 6 ? Theme.danger : Theme.textMuted
                            font: Theme.fontLabel
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }

                GridLayout {
                    id: daysGrid
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    columns: 7
                    columnSpacing: 6
                    rowSpacing: 6

                    Repeater {
                        model: calendarModel
                        delegate: AbstractButton {
                            id: dayCell
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.preferredWidth: 1
                            Layout.preferredHeight: 1
                            Layout.maximumHeight: 64
                            enabled: model.day > 0
                            hoverEnabled: true
                            focusPolicy: Qt.TabFocus
                            Accessible.name: model.day > 0 ? monthNames[currentJalaliMonth] + " " + model.day : ""
                            onClicked: selectDay(model.day)

                            HoverHandler { cursorShape: dayCell.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor }

                            background: Rectangle {
                                visible: model.day > 0
                                radius: Theme.radius
                                color: model.isSelected ? Theme.accent
                                     : dayCell.hovered ? Theme.surfaceHover
                                     : model.isToday ? Theme.accentSoft : "transparent"
                                border.width: model.isToday && !model.isSelected ? 1 : 0
                                border.color: Theme.accent
                                Behavior on color { ColorAnimation { duration: Theme.durFast } }
                                FocusRing { target: dayCell }
                            }

                            contentItem: Item {
                                visible: model.day > 0
                                Label {
                                    anchors.centerIn: parent
                                    text: model.day > 0 ? model.day : ""
                                    color: model.isSelected ? Theme.textOnAccent
                                         : model.isToday ? Theme.accent : Theme.textPrimary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.textMd
                                    font.weight: model.isToday || model.isSelected ? Font.DemiBold : Font.Normal
                                }
                                Rectangle {
                                    visible: model.hasCalls
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: 6
                                    width: 5; height: 5; radius: 2.5
                                    color: model.isSelected ? Theme.textOnAccent : Theme.success
                                }
                            }
                        }
                    }
                }

                RowLayout {
                    spacing: 6
                    Rectangle { width: 6; height: 6; radius: 3; color: Theme.success }
                    Label { text: "Day with calls"; color: Theme.textMuted; font: Theme.fontSmall }
                }
            }
        }

        // ── Selected day ──
        Card {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 2
            Layout.minimumHeight: 220

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                SectionHeader {
                    Layout.fillWidth: true
                    title: selectedDay > 0 ? monthNames[currentJalaliMonth] + " " + selectedDay : "Day details"
                    iconName: "calendar"
                    meta: selectedDay > 0 && callsForSelectedDay.length > 0
                          ? callsForSelectedDay.length + (callsForSelectedDay.length === 1 ? " call" : " calls") : ""
                }

                ListView {
                    id: callsList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: selectedDay > 0 && callsForSelectedDay.length > 0
                    model: callsForSelectedDay
                    clip: true
                    spacing: 2
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                    delegate: Rectangle {
                        width: callsList.width - 8
                        height: 48
                        radius: Theme.radius
                        color: callHover.hovered ? Theme.surfaceHover : "transparent"
                        readonly property bool incoming: modelData.direction === "incoming"
                        HoverHandler { id: callHover }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 10

                            Rectangle {
                                width: 30; height: 30; radius: 15
                                color: incoming ? Theme.successSoft : Theme.accentSoft
                                Icon {
                                    anchors.centerIn: parent
                                    size: 14
                                    name: incoming ? "arrow-in" : "arrow-out"
                                    color: incoming ? Theme.success : Theme.accent
                                }
                            }
                            Label {
                                Layout.fillWidth: true
                                text: modelData.name && modelData.name !== modelData.number ? modelData.name : (modelData.number || "")
                                color: Theme.textPrimary
                                font: Theme.fontBody
                                elide: Text.ElideRight
                            }
                            Label {
                                text: modelData.timestamp ? Qt.formatDateTime(new Date(modelData.timestamp), "HH:mm") : ""
                                color: Theme.textMuted
                                font: Theme.fontSmall
                            }
                            Label {
                                text: root.formatDuration(modelData.duration || 0)
                                color: Theme.textSecondary
                                font: Theme.fontSmall
                                Layout.preferredWidth: 40
                                horizontalAlignment: Text.AlignRight
                            }
                        }
                    }
                }

                EmptyState {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: !callsList.visible
                    iconName: "calendar"
                    title: selectedDay > 0 ? "No calls on this day" : ""
                    hint: selectedDay > 0 ? "Pick another day with a green dot." : "Select a day to see its calls."
                }
            }
        }
    }
}
