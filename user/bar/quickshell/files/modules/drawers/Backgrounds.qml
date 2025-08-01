import "root:/services"
import "root:/config"
import "root:/modules/osd" as Osd
import "root:/modules/notifications" as Notifications
import "root:/modules/session" as Session
import "root:/modules/launcher" as Launcher
import "root:/modules/bar/popouts" as BarPopouts
import QtQuick
import QtQuick.Shapes

Shape {
    id: root

    required property Panels panels
    required property Item bar

    anchors.fill: parent
    anchors.margins: Config.border.thickness
    anchors.bottomMargin: bar.implicitHeight
    preferredRendererType: Shape.CurveRenderer
    opacity: Colours.transparency.enabled ? Colours.transparency.base : 1

    Osd.Background {
        wrapper: panels.osd

        startX: root.width - panels.session.width
        startY: (root.height - wrapper.height) / 2 - rounding
    }

    Notifications.Background {
        wrapper: panels.notifications

        startX: root.width
        startY: 0
    }

    Session.Background {
        wrapper: panels.session

        startX: root.width
        startY: (root.height - wrapper.height) / 2 - rounding
    }

    Launcher.Background {
        wrapper: panels.launcher

        startX: (root.width - wrapper.width) / 2 - rounding
        startY: root.height
    }

    BarPopouts.Background {
        wrapper: panels.popouts
        invertRightRounding: wrapper.x + wrapper.width + Config.border.thickness >= root.width

        startY: wrapper.y// + rounding//+ wrapper.height
        startX: wrapper.x + rounding// + Appearance.padding.smaller
    }
}
