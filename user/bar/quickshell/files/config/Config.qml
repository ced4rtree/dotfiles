pragma Singleton

import "root:/utils"
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property alias bar: adapter.bar
    property alias border: adapter.border
    property alias launcher: adapter.launcher
    property alias notifs: adapter.notifs
    property alias osd: adapter.osd
    property alias session: adapter.session

    FileView {
        path: `${Paths.config}/shell.json`
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()

        JsonAdapter {
            id: adapter

            property JsonObject bar: BarConfig {}
            property JsonObject border: BorderConfig {}
            property JsonObject launcher: LauncherConfig {}
            property JsonObject notifs: NotifsConfig {}
            property JsonObject osd: OsdConfig {}
            property JsonObject session: SessionConfig {}
        }
    }
}
