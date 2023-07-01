import QtQuick 2.6
import QtQuick.Layouts 1.0
import QtQuick.Controls 2.0
import QtQuick.Controls.Material 2.0
import QtQml.Models 2.2

import org.electrum 1.0

import "controls"

Pane {
    id: rootItem
    visible: Daemon.currentWallet
    padding: 0
    clip: true

    background: Rectangle {
        color: constants.darkerBackground
    }

    ListView {
        id: listview
        width: parent.width
        height: parent.height
        boundsBehavior: Flickable.StopAtBounds

        model: visualModel

        header: Item {
            width: parent.width
            height: headerLayout.height
            ColumnLayout {
                id: headerLayout
                anchors.centerIn: parent
                BalanceSummary {
                    Layout.topMargin: constants.paddingXLarge
                    Layout.bottomMargin: constants.paddingXLarge
                }
            }
        }
        headerPositioning: ListView.InlineHeader

        readonly property variant sectionLabels: {
            'local': qsTr('Local'),
            'mempool': qsTr('Mempool'),
            'today': qsTr('Today'),
            'yesterday': qsTr('Yesterday'),
            'lastweek': qsTr('Last week'),
            'lastmonth': qsTr('Last month'),
            'older': qsTr('Older')
        }

        section.property: 'section'
        section.criteria: ViewSection.FullString
        section.delegate: RowLayout {
            width: ListView.view.width
            required property string section
            Label {
                text: listview.sectionLabels[section]
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: constants.paddingLarge
                font.pixelSize: constants.fontSizeMedium
                color: Material.accentColor
            }
        }

        DelegateModel {
            id: visualModel
            model: Daemon.currentWallet.historyModel

            groups: [
                DelegateModelGroup { name: 'today'; includeByDefault: false },
                DelegateModelGroup { name: 'yesterday'; includeByDefault: false },
                DelegateModelGroup { name: 'lastweek'; includeByDefault: false },
                DelegateModelGroup { name: 'lastmonth'; includeByDefault: false },
                DelegateModelGroup { name: 'older'; includeByDefault: false }
            ]

            delegate: HistoryItemDelegate { }
        }

        ScrollIndicator.vertical: ScrollIndicator { }

        Label {
            visible: Daemon.currentWallet.historyModel.count == 0 && !Daemon.currentWallet.synchronizing
            anchors.centerIn: parent
            width: listview.width * 4/5
            font.pixelSize: constants.fontSizeXXLarge
            color: constants.mutedForeground
            text: qsTr('No transactions in this wallet yet')
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter
        }
    }

    MouseArea {
        id: vdragscroll
        anchors {
            top: listview.top
            right: listview.right
            bottom: listview.bottom
        }
        width: constants.fingerWidth
        drag.target: dragb
        onPressedChanged: if (pressed) {
            dragb.y = mouseY + listview.y - dragb.height/2
        }
    }

    MouseArea {
        // cover list items, make left side insensitive to clicks
        // this helps with the back gesture on newer androids
        id: left_backgesture_hack
        anchors {
            top: listview.top
            left: listview.left
            bottom: listview.bottom
        }
        width: constants.fingerWidth
    }

    Rectangle {
        id: dragb
        anchors.right: vdragscroll.left
        width: postext.width + constants.paddingXXLarge
        height: postext.height + constants.paddingXXLarge
        radius: constants.paddingXSmall

        color: constants.colorAlpha(Material.accentColor, 0.33)
        border.color: Material.accentColor
        opacity : vdragscroll.drag.active ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 300 } }

        onYChanged: {
            if (vdragscroll.drag.active) {
                listview.contentY =
                    Math.max(listview.originY,
                    Math.min(listview.contentHeight - listview.height + listview.originY,
                        ((y-listview.y)/(listview.height - dragb.height)) * (listview.contentHeight - listview.height + listview.originY) ))
            }
        }
        Label {
            id: postext
            anchors.centerIn: parent
            text: dragb.opacity
                    ? listview.itemAt(0,listview.contentY + (dragb.y + dragb.height/2)).delegateModel.date
                    : ''
            font.pixelSize: constants.fontSizeLarge
        }
    }

    Connections {
        target: Network
        function onHeightChanged(height) {
            Daemon.currentWallet.historyModel.updateBlockchainHeight(height)
        }
    }

    Connections {
        target: Daemon
        function onWalletLoaded() {
            listview.positionViewAtBeginning()
        }
    }
}