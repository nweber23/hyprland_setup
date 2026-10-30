pragma Singleton
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Networking
import QtQuick

// Shared Wi-Fi / Bluetooth lookups used by the bar and the network panel.
Singleton {
    readonly property var wifiDevice: {
        const ds = Networking.devices.values
        for (let i = 0; i < ds.length; i++) if (ds[i].type === DeviceType.Wifi) return ds[i]
        return null
    }
    readonly property var wifiNetwork: {
        if (!wifiDevice) return null
        const ns = wifiDevice.networks.values
        for (let i = 0; i < ns.length; i++) if (ns[i].connected) return ns[i]
        return null
    }
    readonly property var btDevice: {
        const ds = Bluetooth.devices.values
        for (let i = 0; i < ds.length; i++) if (ds[i].connected) return ds[i]
        return null
    }
    // Networks sorted by signal strength, strongest first.
    readonly property var wifiList: {
        if (!wifiDevice) return []
        return wifiDevice.networks.values.slice().sort((a, b) => b.signalStrength - a.signalStrength)
    }
    readonly property var btList: {
        const ds = Bluetooth.devices.values.slice()
        return ds.filter(d => d.paired || d.connected).sort((a, b) => (b.connected - a.connected))
    }
}
