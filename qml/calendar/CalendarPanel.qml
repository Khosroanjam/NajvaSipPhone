import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../theme"
import "../components"

// Jalali month grid plus a details card with three views:
//   Day    — the selected day's calls with their after-call notes
//   Report — per-day call counts for the shown month
//   Search — calls whose number, name or note text matches a query
// All date math goes through `jalaliDate` (C++); the DB is keyed by
// Gregorian "yyyy-MM-dd" strings.
Item {
    id: root

    readonly property var monthNames: [
        "", "Farvardin", "Ordibehesht", "Khordad", "Tir",
        "Mordad", "Shahrivar", "Mehr", "Aban", "Azar",
        "Dey", "Bahman", "Esfand"
    ]
    readonly property var weekdayHeaders: ["Sh", "Ye", "Do", "Se", "Ch", "Pa", "Jo"]
    readonly property var weekdayNames: ["Saturday", "Sunday", "Monday", "Tuesday",
                                         "Wednesday", "Thursday", "Friday"]

    readonly property bool dbReady: typeof db !== "undefined" && db !== null

    property int todayJalaliYear: 0
    property int todayJalaliMonth: 0
    property int todayJalaliDay: 0
    property int currentJalaliYear: 1404
    property int currentJalaliMonth: 1
    property int selectedDay: 0

    property var dayStats: ({})      // day of month -> stats row (see Database::callStatsByDateRange)
    property var monthReport: []     // the same rows, in day order
    property var callsForSelectedDay: []
    property int detailTab: 0        // 0 = day, 1 = report, 2 = search
    property string searchQuery: ""
    property var searchResults: []

    readonly property var selectedStats: dayStats[selectedDay] || null
    readonly property var monthTotals: {
        var t = { total: 0, missed: 0, duration: 0, busiest: 0 }
        for (var i = 0; i < monthReport.length; i++) {
            var r = monthReport[i]
            t.total += r.total
            t.missed += r.missed
            t.duration += r.duration
            t.busiest = Math.max(t.busiest, r.total)
        }
        return t
    }

    Component.onCompleted: {
        var t = jalaliDate.today()
        todayJalaliYear = t.year
        todayJalaliMonth = t.month
        todayJalaliDay = t.day
        goToday()
    }

    Connections {
        target: root.dbReady ? db : null
        function onCallHistoryChanged() { root.reload() }
        function onNotesChanged() { root.reload() }
        function onContactsChanged() { root.reload() }
    }

    Shortcut {
        sequence: StandardKey.Find
        enabled: root.visible
        onActivated: root.detailTab = 2
    }

    onDetailTabChanged: if (detailTab === 2) searchField.field.forceActiveFocus()

    // ── Data ─────────────────────────────────────────────────────────
    function gregorianFor(day) {
        return jalaliDate.toGregorianString(currentJalaliYear, currentJalaliMonth, day)
    }

    function refreshMonth() {
        var len = jalaliDate.monthLength(currentJalaliYear, currentJalaliMonth)
        var stats = {}
        var report = []
        if (dbReady) {
            var rows = db.callStatsByDateRange(gregorianFor(1), gregorianFor(len))
            for (var i = 0; i < rows.length; i++) {
                var day = jalaliDate.fromGregorianString(rows[i].date).day
                var row = {
                    day: day, date: rows[i].date, total: rows[i].total,
                    incoming: rows[i].incoming, outgoing: rows[i].outgoing,
                    missed: rows[i].missed, duration: rows[i].duration
                }
                stats[day] = row
                report.push(row)
            }
        }
        dayStats = stats
        monthReport = report

        // Week starts on Saturday: pad with blanks up to the 1st's weekday.
        var lead = jalaliDate.weekdayOf(currentJalaliYear, currentJalaliMonth, 1)
        calendarModel.clear()
        for (var b = 0; b < lead; b++)
            calendarModel.append({ day: 0, count: 0 })
        for (var d = 1; d <= len; d++)
            calendarModel.append({ day: d, count: stats[d] ? stats[d].total : 0 })
    }

    function loadSelectedDay() {
        callsForSelectedDay = selectedDay > 0 && dbReady ? db.callHistoryByDate(gregorianFor(selectedDay)) : []
    }

    function reload() {
        refreshMonth()
        loadSelectedDay()
        if (searchQuery !== "")
            runSearch()
    }

    function selectDay(day) {
        selectedDay = day
        loadSelectedDay()
    }

    function showMonth(year, month) {
        currentJalaliYear = year
        currentJalaliMonth = month
        selectedDay = 0
        callsForSelectedDay = []
        refreshMonth()
    }

    function shiftMonth(delta) {
        var m = currentJalaliMonth + delta
        var y = currentJalaliYear
        if (m < 1) { m = 12; y-- }
        if (m > 12) { m = 1; y++ }
        showMonth(y, m)
    }

    function goToday() {
        showMonth(todayJalaliYear, todayJalaliMonth)
        selectDay(todayJalaliDay)
        detailTab = 0
    }

    // Jump the calendar to the day of a DB timestamp and show its calls.
    function openDate(timestamp) {
        var j = jalaliDate.fromGregorianString(String(timestamp || ""))
        if (!j.year)
            return
        if (j.year !== currentJalaliYear || j.month !== currentJalaliMonth)
            showMonth(j.year, j.month)
        selectDay(j.day)
        detailTab = 0
    }

    function runSearch() {
        searchQuery = searchField.text.trim()
        searchResults = searchQuery !== "" && dbReady ? db.searchCalls(searchQuery) : []
    }

    // ── Formatting ───────────────────────────────────────────────────
    function formatDuration(seconds) {
        var m = Math.floor(seconds / 60)
        var s = seconds % 60
        return (m < 10 ? "0" + m : m) + ":" + (s < 10 ? "0" + s : s)
    }

    function formatTalkTime(seconds) {
        var h = Math.floor(seconds / 3600)
        var m = Math.floor((seconds % 3600) / 60)
        if (h > 0) return h + "h " + (m < 10 ? "0" + m : m) + "m"
        if (m > 0) return m + "m " + (seconds % 60) + "s"
        return seconds + "s"
    }

    // Timestamps come back from SQLite as "yyyy-MM-ddTHH:mm:ss[.zzz]".
    function timeOf(timestamp) {
        var s = String(timestamp || "")
        return s.length >= 16 ? s.substr(11, 5) : ""
    }

    function jalaliLabel(timestamp) {
        var j = jalaliDate.fromGregorianString(String(timestamp || ""))
        return j.year ? j.day + " " + monthNames[j.month] + " " + j.year : ""
    }

    function isMissed(call) {
        return call.direction === "missed" || (call.direction === "incoming" && (call.duration || 0) === 0)
    }

    function escapeHtml(text) {
        return String(text).replace(/&/g, "&amp;").replace(/</g, "&lt;")
                           .replace(/>/g, "&gt;").replace(/"/g, "&quot;")
    }

    // StyledText with every case-insensitive occurrence of `needle` emphasised.
    function highlight(text, needle) {
        var safe = escapeHtml(text || "")
        if (needle) {
            var pattern = new RegExp(escapeHtml(needle).replace(/[.*+?^${}()|[\]\\]/g, "\\$&"), "gi")
            safe = safe.replace(pattern, function(match) {
                return "<b><font color=\"" + Theme.accent + "\">" + match + "</font></b>"
            })
        }
        return safe.replace(/\n/g, "<br>")
    }

    readonly property bool wide: width >= 760

    ListModel {
        id: calendarModel
    }

    Timer {
        id: searchDebounce
        interval: 250
        onTriggered: root.runSearch()
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
            Layout.fillHeight: root.wide
            Layout.preferredWidth: 3
            Layout.preferredHeight: 372
            Layout.minimumHeight: root.wide ? 360 : 372

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
                            text: currentJalaliYear + (root.monthTotals.total > 0
                                  ? " · " + root.monthTotals.total + (root.monthTotals.total === 1 ? " call" : " calls") : "")
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
                            readonly property bool isToday: model.day > 0
                                                            && currentJalaliYear === todayJalaliYear
                                                            && currentJalaliMonth === todayJalaliMonth
                                                            && model.day === todayJalaliDay
                            readonly property bool isSelected: model.day > 0 && model.day === root.selectedDay

                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.preferredWidth: 1
                            Layout.preferredHeight: 1
                            Layout.maximumHeight: 64
                            enabled: model.day > 0
                            hoverEnabled: true
                            focusPolicy: Qt.TabFocus
                            Accessible.name: model.day > 0
                                             ? monthNames[currentJalaliMonth] + " " + model.day
                                               + (model.count > 0 ? ", " + model.count + " calls" : "")
                                             : ""
                            onClicked: {
                                root.selectDay(model.day)
                                root.detailTab = 0
                            }

                            HoverHandler { cursorShape: dayCell.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor }

                            background: Rectangle {
                                visible: model.day > 0
                                radius: Theme.radius
                                color: dayCell.isSelected ? Theme.accent
                                     : dayCell.hovered ? Theme.surfaceHover
                                     : dayCell.isToday ? Theme.accentSoft : "transparent"
                                border.width: dayCell.isToday && !dayCell.isSelected ? 1 : 0
                                border.color: Theme.accent
                                Behavior on color { ColorAnimation { duration: Theme.durFast } }
                                FocusRing { target: dayCell }
                            }

                            contentItem: Item {
                                visible: model.day > 0
                                Label {
                                    anchors.centerIn: parent
                                    text: model.day > 0 ? model.day : ""
                                    color: dayCell.isSelected ? Theme.textOnAccent
                                         : dayCell.isToday ? Theme.accent : Theme.textPrimary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.textMd
                                    font.weight: dayCell.isToday || dayCell.isSelected ? Font.DemiBold : Font.Normal
                                }
                                // Call-count badge
                                Rectangle {
                                    visible: model.count > 0
                                    anchors.top: parent.top
                                    anchors.right: parent.right
                                    anchors.topMargin: 3
                                    anchors.rightMargin: 3
                                    height: 15
                                    width: Math.max(15, countLabel.implicitWidth + 8)
                                    radius: 7.5
                                    color: dayCell.isSelected ? Theme.textOnAccent : Theme.successSoft
                                    Label {
                                        id: countLabel
                                        anchors.centerIn: parent
                                        text: model.count > 99 ? "99+" : model.count
                                        color: dayCell.isSelected ? Theme.accent : Theme.success
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 10
                                        font.weight: Font.DemiBold
                                    }
                                }
                            }
                        }
                    }
                }

                RowLayout {
                    spacing: 6
                    Rectangle {
                        width: 15; height: 15; radius: 7.5
                        color: Theme.successSoft
                        Label {
                            anchors.centerIn: parent
                            text: "n"
                            color: Theme.success
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                        }
                    }
                    Label { text: "Number of calls that day"; color: Theme.textMuted; font: Theme.fontSmall }
                }
            }
        }

        // ── Details ──
        Card {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 2
            Layout.minimumHeight: 260

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                // Segmented tab switcher
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 36
                    radius: Theme.radius
                    color: Theme.surfaceRaised
                    border.width: 1
                    border.color: Theme.border

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 3
                        spacing: 3
                        Repeater {
                            model: [
                                { label: "Day",    icon: "calendar" },
                                { label: "Report", icon: "history" },
                                { label: "Search", icon: "search" }
                            ]
                            delegate: SegmentButton {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Layout.preferredWidth: 1
                                text: modelData.label
                                iconName: modelData.icon
                                checked: root.detailTab === index
                                onClicked: root.detailTab = index
                            }
                        }
                    }
                }

                StackLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    currentIndex: root.detailTab

                    // ── Day: calls + notes ──
                    ColumnLayout {
                        spacing: 12

                        SectionHeader {
                            Layout.fillWidth: true
                            title: selectedDay > 0
                                   ? weekdayNames[jalaliDate.weekdayOf(currentJalaliYear, currentJalaliMonth, selectedDay)]
                                     + ", " + selectedDay + " " + monthNames[currentJalaliMonth]
                                   : "Day details"
                            iconName: "calendar"
                            meta: selectedDay > 0 ? root.gregorianFor(selectedDay) : ""
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            visible: root.selectedStats !== null
                            spacing: 8
                            StatTile { label: "Calls";    value: root.selectedStats ? root.selectedStats.total : 0 }
                            StatTile { label: "Incoming"; value: root.selectedStats ? root.selectedStats.incoming : 0; tone: Theme.success }
                            StatTile { label: "Outgoing"; value: root.selectedStats ? root.selectedStats.outgoing : 0; tone: Theme.accent }
                            StatTile { label: "Missed";   value: root.selectedStats ? root.selectedStats.missed : 0; tone: Theme.danger }
                            StatTile { label: "Talk time"; value: root.selectedStats ? root.formatTalkTime(root.selectedStats.duration) : "" }
                        }

                        ListView {
                            id: dayList
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            visible: callsForSelectedDay.length > 0
                            model: callsForSelectedDay
                            clip: true
                            spacing: 2
                            boundsBehavior: Flickable.StopAtBounds
                            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                            delegate: CallEntry {
                                width: dayList.width - 8
                                call: modelData
                            }
                        }

                        EmptyState {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            visible: !dayList.visible
                            iconName: "calendar"
                            title: selectedDay > 0 ? "No calls on this day" : ""
                            hint: selectedDay > 0 ? "Days with calls show a count badge."
                                                  : "Select a day to see its calls and notes."
                        }
                    }

                    // ── Report: calls per day for the shown month ──
                    ColumnLayout {
                        spacing: 12

                        SectionHeader {
                            Layout.fillWidth: true
                            title: "Daily report · " + monthNames[currentJalaliMonth] + " " + currentJalaliYear
                            iconName: "history"
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            StatTile { label: "Calls";       value: root.monthTotals.total }
                            StatTile { label: "Active days"; value: root.monthReport.length }
                            StatTile {
                                label: "Avg / day"
                                value: root.monthReport.length > 0
                                       ? Math.round(root.monthTotals.total / root.monthReport.length * 10) / 10 : 0
                            }
                            StatTile { label: "Missed";    value: root.monthTotals.missed; tone: Theme.danger }
                            StatTile { label: "Talk time"; value: root.formatTalkTime(root.monthTotals.duration) }
                        }

                        RowLayout {
                            visible: root.monthReport.length > 0
                            spacing: 14
                            LegendDot { tone: Theme.success; text: "Answered in" }
                            LegendDot { tone: Theme.accent;  text: "Outgoing" }
                            LegendDot { tone: Theme.danger;  text: "Missed" }
                        }

                        ListView {
                            id: reportList
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            visible: root.monthReport.length > 0
                            model: root.monthReport
                            clip: true
                            spacing: 2
                            boundsBehavior: Flickable.StopAtBounds
                            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                            delegate: ItemDelegate {
                                id: reportRow
                                width: reportList.width - 8
                                height: 48
                                hoverEnabled: true
                                leftPadding: 8
                                rightPadding: 8
                                Accessible.name: modelData.day + " " + monthNames[currentJalaliMonth] + ": "
                                                 + modelData.total + " calls"
                                onClicked: {
                                    root.selectDay(modelData.day)
                                    root.detailTab = 0
                                }

                                HoverHandler { cursorShape: Qt.PointingHandCursor }
                                background: Rectangle {
                                    radius: Theme.radius
                                    color: reportRow.hovered ? Theme.surfaceHover : "transparent"
                                    Behavior on color { ColorAnimation { duration: Theme.durFast } }
                                }

                                contentItem: RowLayout {
                                    spacing: 12

                                    ColumnLayout {
                                        Layout.preferredWidth: 92
                                        spacing: 0
                                        Label {
                                            text: modelData.day + " " + monthNames[currentJalaliMonth]
                                            color: Theme.textPrimary
                                            font.family: Theme.fontFamily
                                            font.pixelSize: Theme.textMd
                                            font.weight: Font.DemiBold
                                        }
                                        Label {
                                            text: weekdayNames[jalaliDate.weekdayOf(currentJalaliYear, currentJalaliMonth, modelData.day)]
                                            color: Theme.textMuted
                                            font: Theme.fontSmall
                                        }
                                    }

                                    // Stacked bar, scaled to the busiest day of the month
                                    Item {
                                        id: barArea
                                        Layout.fillWidth: true
                                        implicitHeight: 10
                                        readonly property real fullWidth: root.monthTotals.busiest > 0
                                                                          ? width * modelData.total / root.monthTotals.busiest : 0
                                        readonly property int answeredIn: Math.max(0, modelData.total - modelData.outgoing - modelData.missed)

                                        Rectangle {
                                            anchors.fill: parent
                                            radius: 5
                                            color: Theme.surfaceRaised
                                        }
                                        Row {
                                            height: parent.height
                                            Rectangle {
                                                width: barArea.fullWidth * barArea.answeredIn / modelData.total
                                                height: parent.height; radius: 2
                                                color: Theme.success
                                            }
                                            Rectangle {
                                                width: barArea.fullWidth * modelData.outgoing / modelData.total
                                                height: parent.height; radius: 2
                                                color: Theme.accent
                                            }
                                            Rectangle {
                                                width: barArea.fullWidth * modelData.missed / modelData.total
                                                height: parent.height; radius: 2
                                                color: Theme.danger
                                            }
                                        }
                                    }

                                    Label {
                                        Layout.preferredWidth: 28
                                        horizontalAlignment: Text.AlignRight
                                        text: modelData.total
                                        color: Theme.textPrimary
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.textMd
                                        font.weight: Font.DemiBold
                                    }
                                    Label {
                                        Layout.preferredWidth: 62
                                        horizontalAlignment: Text.AlignRight
                                        text: root.formatTalkTime(modelData.duration)
                                        color: Theme.textSecondary
                                        font: Theme.fontSmall
                                    }
                                }
                            }
                        }

                        EmptyState {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            visible: !reportList.visible
                            iconName: "history"
                            title: "No calls this month"
                            hint: "Use the arrows to browse other months."
                        }
                    }

                    // ── Search: numbers, names and note text ──
                    ColumnLayout {
                        spacing: 12

                        AppTextField {
                            id: searchField
                            Layout.fillWidth: true
                            leadingIcon: "search"
                            placeholderText: "Search numbers, names or notes"
                            onEdited: searchDebounce.restart()
                        }

                        Label {
                            visible: root.searchQuery !== ""
                            text: root.searchResults.length === 0 ? "No matches"
                                  : root.searchResults.length + (root.searchResults.length === 1 ? " call" : " calls")
                                    + " · click one to open its day"
                            color: Theme.textMuted
                            font: Theme.fontSmall
                        }

                        ListView {
                            id: searchList
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            visible: root.searchResults.length > 0
                            model: root.searchResults
                            clip: true
                            spacing: 2
                            boundsBehavior: Flickable.StopAtBounds
                            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                            delegate: CallEntry {
                                width: searchList.width - 8
                                call: modelData
                                showDate: true
                                needle: root.searchQuery
                                onClicked: root.openDate(modelData.timestamp)
                            }
                        }

                        EmptyState {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            visible: !searchList.visible
                            iconName: "search"
                            title: root.searchQuery !== "" ? "Nothing found" : ""
                            hint: root.searchQuery !== ""
                                  ? "Try part of a number or a word from a note."
                                  : "Find calls by phone number, contact name or note text."
                        }
                    }
                }
            }
        }
    }

    // ── Inline components ────────────────────────────────────────────

    // One call with its notes. Used by the Day and Search views.
    component CallEntry: ItemDelegate {
        id: entry
        property var call: ({})
        property bool showDate: false
        property string needle: ""

        readonly property bool incoming: call.direction === "incoming"
        readonly property bool missed: root.isMissed(call)
        readonly property bool named: !!call.name && call.name !== call.number
        readonly property var callNotes: call.notes || []

        hoverEnabled: true
        leftPadding: 8
        rightPadding: 8
        topPadding: 8
        bottomPadding: 8
        Accessible.name: (named ? call.name : call.number) + ", " + root.timeOf(call.timestamp)

        HoverHandler { cursorShape: entry.showDate ? Qt.PointingHandCursor : Qt.ArrowCursor }

        background: Rectangle {
            radius: Theme.radius
            color: entry.hovered ? Theme.surfaceHover : "transparent"
            Behavior on color { ColorAnimation { duration: Theme.durFast } }
        }

        contentItem: ColumnLayout {
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                    width: 30; height: 30; radius: 15
                    color: entry.missed ? Theme.dangerSoft : entry.incoming ? Theme.successSoft : Theme.accentSoft
                    Icon {
                        anchors.centerIn: parent
                        size: 14
                        name: entry.incoming || entry.call.direction === "missed" ? "arrow-in" : "arrow-out"
                        color: entry.missed ? Theme.danger : entry.incoming ? Theme.success : Theme.accent
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1
                    Label {
                        Layout.fillWidth: true
                        text: root.highlight(entry.named ? entry.call.name : (entry.call.number || ""), entry.needle)
                        textFormat: Text.StyledText
                        color: entry.missed ? Theme.danger : Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.textMd
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }
                    Label {
                        Layout.fillWidth: true
                        text: (entry.named ? root.highlight(entry.call.number, entry.needle) + " · " : "")
                              + (entry.missed ? "Missed" : entry.incoming ? "Incoming" : "Outgoing")
                              + (entry.showDate ? " · " + root.jalaliLabel(entry.call.timestamp) : "")
                        textFormat: Text.StyledText
                        color: Theme.textMuted
                        font: Theme.fontSmall
                        elide: Text.ElideRight
                    }
                }

                ColumnLayout {
                    spacing: 1
                    Label {
                        Layout.alignment: Qt.AlignRight
                        text: root.timeOf(entry.call.timestamp)
                        color: Theme.textSecondary
                        font: Theme.fontSmall
                    }
                    Label {
                        Layout.alignment: Qt.AlignRight
                        text: root.formatDuration(entry.call.duration || 0)
                        color: Theme.textMuted
                        font: Theme.fontSmall
                    }
                }
            }

            Repeater {
                model: entry.callNotes
                delegate: Rectangle {
                    Layout.fillWidth: true
                    Layout.leftMargin: 40
                    implicitHeight: noteText.implicitHeight + 14
                    radius: Theme.radiusSm
                    color: Theme.surfaceRaised
                    border.width: 1
                    border.color: Theme.border

                    Icon {
                        id: noteIcon
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.leftMargin: 8
                        anchors.topMargin: 8
                        name: "notes"
                        size: 12
                        color: Theme.textMuted
                    }
                    Label {
                        id: noteText
                        anchors.left: noteIcon.right
                        anchors.right: parent.right
                        anchors.leftMargin: 6
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.highlight(modelData.text, entry.needle)
                        textFormat: Text.StyledText
                        wrapMode: Text.Wrap
                        color: Theme.textSecondary
                        font: Theme.fontSmall
                    }
                }
            }
        }
    }

    component StatTile: Rectangle {
        id: tile
        property string label: ""
        property var value: ""
        property color tone: Theme.textPrimary

        Layout.fillWidth: true
        Layout.preferredWidth: 1
        implicitHeight: 54
        radius: Theme.radius
        color: Theme.surfaceRaised

        ColumnLayout {
            anchors.centerIn: parent
            width: parent.width - 8
            spacing: 0
            Label {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: tile.value
                color: tile.tone
                font.family: Theme.fontFamily
                font.pixelSize: Theme.textLg
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }
            Label {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: tile.label
                color: Theme.textMuted
                font: Theme.fontSmall
                elide: Text.ElideRight
            }
        }
    }

    component LegendDot: RowLayout {
        id: legend
        property color tone: Theme.textMuted
        property string text: ""
        spacing: 6
        Rectangle { width: 8; height: 8; radius: 4; color: legend.tone }
        Label { text: legend.text; color: Theme.textMuted; font: Theme.fontSmall }
    }

    component SegmentButton: AbstractButton {
        id: seg
        property string iconName: ""

        hoverEnabled: true
        focusPolicy: Qt.StrongFocus
        Accessible.name: text
        Accessible.role: Accessible.PageTab

        HoverHandler { cursorShape: Qt.PointingHandCursor }

        background: Rectangle {
            radius: Theme.radiusSm
            color: seg.checked ? Theme.surface : seg.hovered ? Theme.surfaceHover : "transparent"
            border.width: seg.checked ? 1 : 0
            border.color: Theme.border
            Behavior on color { ColorAnimation { duration: Theme.durFast } }
            FocusRing { target: seg }
        }

        contentItem: RowLayout {
            spacing: 6
            Item { Layout.fillWidth: true }
            Icon {
                name: seg.iconName
                size: 14
                color: seg.checked ? Theme.accent : Theme.textSecondary
            }
            Label {
                text: seg.text
                color: seg.checked ? Theme.textPrimary : Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.textSm
                font.weight: seg.checked ? Font.DemiBold : Font.Normal
            }
            Item { Layout.fillWidth: true }
        }
    }
}
