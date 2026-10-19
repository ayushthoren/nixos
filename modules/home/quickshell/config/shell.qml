//@ pragma UseQApplication
import Quickshell
import Quickshell.Io

import "ui"

ShellRoot {
    Theme {
        id: theme
    }

    LockScreen {
        id: lockScreen
        theme: theme
    }

    IpcHandler {
        target: "lock"

        function lock(): void {
            lockScreen.lock();
        }
    }

    Bar {
        lockScreen: lockScreen
        theme: theme
    }
    NotificationLayer {
        theme: theme
    }
}
