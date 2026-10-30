import QtQuick

// Material Symbols glyph: Icon { name: "wifi" }. Names are ligatures of the icon font.
Text { textFormat: Text.PlainText;
    property string name
    property real size: 20
    property real fill: 0
    text: name
    color: Theme.on_surface
    font.family: "Material Symbols Rounded"
    font.pixelSize: size
    font.variableAxes: ({ "FILL": fill, "wght": 400 })
    verticalAlignment: Text.AlignVCenter
}
