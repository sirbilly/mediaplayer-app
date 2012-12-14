import QtQuick 2.0
import QtMultimedia 5.0
import Ubuntu.Components 0.1
import "../common"
import "../common/visibilityBehaviors"
import "../common/units.js" as Units

AbstractPlayer {
    id: player

    property variant nfo
    property int pressCount: 0
    property bool wasPlaying: false
    property string uri

    signal timeClicked

    nfo: VideoInfo {
        uri: source
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            if (!controls.focus) { controls.focus = true }
            else { controls.close() }
        }
    }

    function playUri(uri) {
        source = uri
        play()
    }

    Keys.onPressed: {
        event.accepted = true
        if (event.key == Qt.Key_Left || event.key == Qt.Key_Right && !event.modifiers) {
            controls.focus = true
            if (event.isAutoRepeat) {
                pressCount += 1
            } else {
                wasPlaying = player.playing
                pressCount = 1
            }
        } else if (!event.isAutoRepeat && event.key == Qt.Key_MediaStop || event.key == Qt.Key_Escape) {
            player.stop()
        } else if (event.key == Qt.Key_Return) {
            controls.focus = true
        } else {
            event.accepted = false
        }
    }

    function edgeEvent(event) {
        player.forceActiveFocus()
        event.accepted = true
    }

    Keys.onReleased: {
        if (event.key == Qt.Key_Left || event.key == Qt.Key_Right) {
            event.accepted = true
            if (!event.isAutoRepeat && pressCount == 1) {
                if (event.key == Qt.Key_Left) {
                    player.seekBackward()
                } else {
                    player.seekForward()
                }
            } else if (!event.isAutoRepeat) {
                if (wasPlaying) player.play()
                else player.pause()
            } else if ((event.isAutoRepeat && pressCount == 1) || ((pressCount % 30) == 0)) {
                if (event.key == Qt.Key_Left) {
                    player.rewind()
                } else {
                    player.fastForward()
                }
            }
        }
    }

    Controls {
        id: controls
        anchors.left: parent.left; anchors.right: parent.right
        y: controlsVisibility.shown ? parent.height - height : parent.height
        shown: controlsVisibility.shown

        onYChanged: if (!yBehavior.enabled && (y == player.height - height)) yBehavior.enabled = true

        Behavior on y {
            id: yBehavior
            enabled: false
            NumberAnimation { }
        }

        focus: true

        state: player.state
        video: player.video

        function close() {
            if (player.paused) controlsVisibility.endForceVisible("pause")
            button.focus = true
            focus = false
            player.forceActiveFocus()
        }

        Keys.onPressed: {
            if (event.key == Qt.Key_Escape || event.key == Qt.Key_Backspace) {
                event.accepted = true
                close()
            }
        }

        Keys.forwardTo: [controlsBehavior]

        onButtonClicked: {
            if (["paused", "playing"].indexOf(state) != -1) player.togglePause()
            else player.play()
        }

        onClicked: {
            controlsBehavior.restartTimer()
        }

        onActiveFocusChanged: {
            if (!activeFocus && player.paused) controlsVisibility.endForceVisible("pause")
        }

        onTimeClicked: {
            player.timeClicked()
        }
    }

    Label {
        id: title
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -controls.height / 2

        opacity: player.paused ? 1 : 0

        Behavior on opacity { NumberAnimation {} }

        font.pixelSize: units.gu(10)
        color: "white"

        elide: {
            if (player.nfo.video || video.metaData.title !== undefined) return Text.ElideMiddle
            else return Text.ElideLeft
        }
        text: {
            if (player.nfo.video) return player.nfo.video.title
            else if (video.metaData.title !== undefined) return video.metaData.title
            else return video.source.toString().replace(/.*\//, '')
        }
    }

    VisibilityController {
        id: controlsVisibility
        behavior: controlsBehavior
        shown: false
        onShownChanged: if (!shown && controls.activeFocus) {
            controls.focus = false
            player.forceActiveFocus()
        }

        Connections {
            target: player
            onPausedChanged:
                if (player.paused) controlsVisibility.beginForceVisible("pause")
                else controlsVisibility.endForceVisible("pause")
        }
    }

    TimeoutBehavior {
        id: controlsBehavior
        target: controls
        forcedVisible: controlsVisibility.forceVisible
    }

    onActiveFocusChanged: {
        if (!activeFocus) {
            controls.focus = false
        }
    }
}
