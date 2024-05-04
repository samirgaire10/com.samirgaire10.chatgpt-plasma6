/*
 *   SPDX-FileCopyrightText: 2014, 2016 Mikhail Ivchenko <ematirov@gmail.com>
 *   SPDX-FileCopyrightText: 2018 Kai Uwe Broulik <kde@privat.broulik.de>
 *   SPDX-FileCopyrightText: 2020 Sora Steenvoort <sora@dillbox.me>
 *
 *   SPDX-License-Identifier: GPL-2.0-or-later
 */

import QtQuick
import QtWebEngine
import QtQuick.Layouts 1.1
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.plasmoid 2.0

PlasmoidItem {
    id: root

    switchWidth: Kirigami.Units.gridUnit * 16
    switchHeight: Kirigami.Units.gridUnit * 23

    // Only exists because the default CompactRepresentation doesn't expose
    // a way to display arbitrary images; it can only show icons.
    // TODO remove once it gains that feature.
    compactRepresentation: Loader {
        id: favIconLoader
        active: Plasmoid.configuration.useFavIcon
        asynchronous: true
        sourceComponent: Image {
            asynchronous: true
            cache: false
            fillMode: Image.PreserveAspectFit
            source: Plasmoid.configuration.favIcon
        }

        TapHandler {
            property bool wasExpanded: false

            acceptedButtons: Qt.LeftButton

            onPressedChanged: if (pressed) {
                wasExpanded = root.expanded;
            }
            onTapped: root.expanded = !wasExpanded
        }

        Kirigami.Icon {
            anchors.fill: parent
            visible: favIconLoader.item?.status !== Image.Ready
            source: Plasmoid.configuration.icon || Plasmoid.icon
        }
    }

    fullRepresentation: ColumnLayout {
        anchors.fill: parent
        spacing: PlasmaCore.Units.largeSpacing

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // TODO use contentsSize but that crashes, now mostly for some sane initial size
            Layout.preferredWidth: Kirigami.Units.gridUnit * 40
            Layout.preferredHeight: Kirigami.Units.gridUnit * 100

         

            WebEngineView {
                id: webview
                anchors.fill: parent
                onUrlChanged: plasmoid.configuration.url = url;
                Component.onCompleted: url = plasmoid.configuration.url;

                readonly property bool useMinViewWidth : plasmoid.configuration.useMinViewWidth

                Connections {
                    target: plasmoid.configuration

                    function onMinViewWidthChanged() {updateZoomTimer.start()}

                    function onUseMinViewWidthChanged() {updateZoomTimer.start()}

                    function onConstantZoomFactorChanged() {updateZoomTimer.start()}

                    function onUseConstantZoomChanged() {updateZoomTimer.start()}
                }

                onLinkHovered: hoveredUrl => {
                    if (hoveredUrl.toString() !== "") {
                        mouseArea.cursorShape = Qt.PointingHandCursor;
                    } else {
                        mouseArea.cursorShape = Qt.ArrowCursor;
                    }
                }

                onWidthChanged: {
                    if (useMinViewWidth) {
                        updateZoomTimer.start()
                    }
                }

                onLoadingChanged: loadingInfo => {
                    if (loadingInfo.status === WebEngineLoadingInfo.LoadStartedStatus) {
                        infoButton.dismiss();
                    } else if (loadingInfo.status === WebEngineLoadingInfo.LoadSucceededStatus && useMinViewWidth) {
                        updateZoomTimer.start();
                    }
                }

                onContextMenuRequested: request => {
                    if (request.mediaType === ContextMenuRequest.MediaTypeNone && request.linkUrl.toString() !== "") {
                        linkContextMenu.link = request.linkUrl;
                        linkContextMenu.open(request.position.x, request.position.y);
                        request.accepted = true;
                    }
                }

                onNavigationRequested: request => {
                    var url = request.url;

                    if (request.userInitiated) {
                        Qt.openUrlExternally(url);
                    } else {
                        infoButton.show(i18nc("An unwanted popup was blocked", "Popup blocked"), "document-close",
                                        i18n("Click here to open the following blocked popup:\n%1", url), function () {
                            Qt.openUrlExternally(url);
                            infoButton.dismiss();
                        });
                    }
                }

                onIconChanged: {
                    if (loading && icon == "") {
                        return;
                    }
                    Plasmoid.configuration.favIcon = icon.toString().slice(16 /* image://favicon/ */);
                }
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                acceptedButtons: Qt.BackButton | Qt.ForwardButton
                onPressed: mouse => {
                    if (mouse.button === Qt.BackButton) {
                        webview.goBack();
                    } else if (mouse.button === Qt.ForwardButton) {
                        webview.goForward();
                    }
                }
            }
        }
    }
}
