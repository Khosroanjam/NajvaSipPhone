import QtQuick
import QtQuick.Shapes

// Stroke icon (Lucide geometry, 24×24 grid) rendered with Shapes so it
// can be tinted by any theme color. Usage: Icon { name: "phone"; color: ... }
Item {
    id: root
    property string name: ""
    property color color: "white"
    property real size: 20
    property real strokeWidth: 2

    implicitWidth: size
    implicitHeight: size
    width: size
    height: size

    // One MSAA layer at the final pixel size keeps strokes crisp when scaled.
    layer.enabled: true
    layer.samples: 4
    layer.smooth: true

    function circle(cx, cy, r) {
        return "M" + (cx - r) + " " + cy + " a" + r + " " + r + " 0 1 0 " + (2 * r) + " 0"
             + " a" + r + " " + r + " 0 1 0 " + (-2 * r) + " 0"
    }

    readonly property var paths: {
        var phone = "M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92z"
        var dots = []
        for (var y = 5; y <= 19; y += 7)
            for (var x = 5; x <= 19; x += 7)
                dots.push(circle(x, y, 1))
        switch (root.name) {
        case "phone":         return [phone]
        case "phone-outgoing":return [phone, "M16 2h6v6", "M22 2l-7 7"]
        case "phone-incoming":return [phone, "M16 2v6h6", "M22 2l-6 6"]
        case "mic":           return ["M12 2a3 3 0 0 0-3 3v7a3 3 0 0 0 6 0V5a3 3 0 0 0-3-3z", "M19 10v2a7 7 0 0 1-14 0v-2", "M12 19v3"]
        case "mic-off":       return ["M2 2l20 20", "M18.89 13.23A7.12 7.12 0 0 0 19 12v-2", "M5 10v2a7 7 0 0 0 12 5", "M15 9.34V5a3 3 0 0 0-5.68-1.33", "M9 9v3a3 3 0 0 0 5.12 2.12", "M12 19v3"]
        case "volume":        return ["M11 5L6 9H2v6h4l5 4V5z", "M15.54 8.46a5 5 0 0 1 0 7.07", "M19.07 4.93a10 10 0 0 1 0 14.14"]
        case "volume-low":    return ["M11 5L6 9H2v6h4l5 4V5z", "M15.54 8.46a5 5 0 0 1 0 7.07"]
        case "keypad":        return dots
        case "delete":        return ["M20 5H9l-7 7 7 7h11a2 2 0 0 0 2-2V7a2 2 0 0 0-2-2z", "M18 9l-6 6", "M12 9l6 6"]
        case "settings":      return ["M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z", circle(12, 12, 3)]
        case "calendar":      return ["M8 2v4", "M16 2v4", "M5 4h14a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2z", "M3 10h18"]
        case "users":         return ["M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2", circle(9, 7, 4), "M22 21v-2a4 4 0 0 0-3-3.87", "M16 3.13a4 4 0 0 1 0 7.75"]
        case "user":          return ["M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2", circle(12, 7, 4)]
        case "user-plus":     return ["M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2", circle(9, 7, 4), "M19 8v6", "M22 11h-6"]
        case "mail":          return ["M4 4h16a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2z", "M22 7l-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7"]
        case "pencil":        return ["M17 3a2.85 2.83 0 1 1 4 4L7.5 20.5 2 22l1.5-5.5z", "M15 5l4 4"]
        case "arrow-in":      return ["M17 7L7 17", "M17 17H7V7"]
        case "arrow-out":     return ["M7 17L17 7", "M7 7h10v10"]
        case "chevron-left":  return ["M15 18l-6-6 6-6"]
        case "chevron-right": return ["M9 18l6-6-6-6"]
        case "check":         return ["M20 6L9 17l-5-5"]
        case "trash":         return ["M3 6h18", "M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6", "M8 6V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2", "M10 11v6", "M14 11v6"]
        case "x":             return ["M18 6L6 18", "M6 6l12 12"]
        // Window controls (thin, Windows-like proportions; use strokeWidth ~1.4)
        case "win-minimize":  return ["M6 12h12"]
        case "win-maximize":  return ["M6.5 6.5h11v11h-11z"]
        case "win-restore":   return ["M6.5 9h8.5v8.5H6.5z", "M9 9V6.5h8.5V15H15"]
        case "win-close":     return ["M7 7l10 10", "M17 7L7 17"]
        case "sun":           return [circle(12, 12, 4), "M12 2v2", "M12 20v2", "M4.93 4.93l1.41 1.41", "M17.66 17.66l1.41 1.41", "M2 12h2", "M20 12h2", "M6.34 17.66l-1.41 1.41", "M19.07 4.93l-1.41 1.41"]
        case "moon":          return ["M12 3a6 6 0 0 0 9 9 9 9 0 1 1-9-9z"]
        case "notes":         return ["M15 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7z", "M14 2v4a2 2 0 0 0 2 2h4", "M10 9H8", "M16 13H8", "M16 17H8"]
        case "clock":         return [circle(12, 12, 10), "M12 6v6l4 2"]
        case "history":       return ["M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8", "M3 3v5h5", "M12 7v5l4 2"]
        case "cloud":         return ["M17.5 19H9a7 7 0 1 1 6.71-9h1.79a4.5 4.5 0 1 1 0 9z"]
        case "refresh":       return ["M3 12a9 9 0 0 1 9-9 9.75 9.75 0 0 1 6.74 2.74L21 8", "M21 3v5h-5", "M21 12a9 9 0 0 1-9 9 9.75 9.75 0 0 1-6.74-2.74L3 16", "M8 16H3v5"]
        case "headphones":    return ["M3 14h3a2 2 0 0 1 2 2v3a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-7a9 9 0 0 1 18 0v7a2 2 0 0 1-2 2h-1a2 2 0 0 1-2-2v-3a2 2 0 0 1 2-2h3"]
        case "eye":           return ["M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7z", circle(12, 12, 3)]
        case "eye-off":       return ["M9.88 9.88a3 3 0 1 0 4.24 4.24", "M10.73 5.08A10.43 10.43 0 0 1 12 5c7 0 10 7 10 7a13.16 13.16 0 0 1-1.67 2.68", "M6.61 6.61A13.53 13.53 0 0 0 2 12s3 7 10 7a9.74 9.74 0 0 0 5.39-1.61", "M2 2l20 20"]
        case "server":        return ["M4 2h16a2 2 0 0 1 2 2v4a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2z", "M4 14h16a2 2 0 0 1 2 2v4a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2v-4a2 2 0 0 1 2-2z", "M6 6h.01", "M6 18h.01"]
        case "search":        return [circle(11, 11, 8), "M21 21l-4.3-4.3"]
        default:              return []
        }
    }

    Item {
        width: 24
        height: 24
        scale: root.size / 24
        transformOrigin: Item.TopLeft

        Repeater {
            model: root.paths
            delegate: Shape {
                anchors.fill: parent
                ShapePath {
                    strokeColor: root.color
                    strokeWidth: root.strokeWidth
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    joinStyle: ShapePath.RoundJoin
                    PathSvg { path: modelData }
                }
            }
        }
    }
}
