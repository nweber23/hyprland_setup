//@ pragma UseQApplication
import Quickshell
import QtQuick

ShellRoot {
    Variants {
        model: Quickshell.screens
        Wallpaper {
            required property var modelData
            screen: modelData
        }
    }
    Variants {
        model: Quickshell.screens
        Scope {
            id: perScreen
            required property var modelData
            Bar { screen: perScreen.modelData }
            CalendarPanel { screen: perScreen.modelData; screenName: perScreen.modelData.name; screenWidth: perScreen.modelData.width }
            NetworkPanel { screen: perScreen.modelData; screenName: perScreen.modelData.name; screenWidth: perScreen.modelData.width }
            PowerPanel { screen: perScreen.modelData; screenName: perScreen.modelData.name; screenWidth: perScreen.modelData.width }
        }
    }
}
