import QtQuick

import "../theme"

// Surface container with border. Children go inside; set padding via anchors.
Rectangle {
    radius: Theme.radiusLg
    color: Theme.surface
    border.width: 1
    border.color: Theme.border
}
