pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Shapes


ApplicationWindow {
    id: mainWindow
    width: 1000
    height: 700
	visible: true
	title: qsTr("DFA Visualizer")

    property var dfa_states: ({})
    function hasOneState(): bool {
        for (const x in mainWindow.dfa_states)
            return true
        return false
    }
    property color acceptStateColor: "#a5d6a7"
    property color startStateColor: "#90caf9"
    property color normalStateColor: "#ffffff"
    property color activeStateColor: "#fff59d"
    property color errorColor: "#ef9a9a"

    // Main layout
	ColumnLayout {
        anchors.fill: parent
        spacing: 5

        // Toolbar
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Button {
                text: "Set Alphabet"
                onClicked: alphabetDialog.open()
            }

            Button {
                text: "Add Transition"
                onClicked: {
                    if (!mainWindow.hasOneState() || alphabet.text.length === 0) {
                        statusText.text = "Error: Adding transitions requires at least 1 state and an alphabet";
                        statusText.color = mainWindow.errorColor;
                        return;
                    }
                    transitionDialog.open();
                }
            }

            Label {
                text: "Alphabet: " + alphabet.text // TODO: add back comma list
            }
        }

        // Status bar
        Label {
            id: statusText
            Layout.fillWidth: true
            wrapMode: Text.Wrap
        }

        // Simulation controls
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            TextField {
                id: inputString
                placeholderText: "Enter string to test"
                Layout.fillWidth: true
            }

            Button {
                text: "Test"
                onClicked: {
                    let validation = dfaBackend.validate_dfa()
                    if (validation) {
                        statusText.text = "Error: " + validation;
                        statusText.color = mainWindow.errorColor;
                        return
                    }

                    let accepted = dfaBackend.accepts(inputString.text);
                    statusText.text = "Test result: " + (accepted ? "Accepted" : "Rejected");
                    statusText.color = accepted ? "green" : "red";
                }
            }

            Button {
                text: "Reset"
                onClicked: {
                    dfaBackend.reset();
                    canvas.clear();
                    statusText.text = "DFA Reset";
                    statusText.color = "black";
                }
            }
        }
        // Canvas for DFA visualization
        Rectangle {
            id: canvas
            Layout.fillWidth: true
            Layout.fillHeight: true
            border.color: "gray"
            border.width: 1
            clip: true

            function clear() {
                // Remove all children except the background
                for (var i = children.length - 1; i >= 0; i--) {
                    if (children[i].objectName !== "background") {
                        children[i].destroy();
                    }
                }
            }

            // Clickable area for editing the DFA
            MouseArea {
                id: background
                anchors.fill: parent
                onDoubleClicked: mouse => {
                    stateDialog.clickX = mouse.x;
                    stateDialog.clickY = mouse.y;
                    stateDialog.open()
                }
                acceptedButtons: Qt.LeftButton
            }

            // Initial help text
            Text {
                id: startText
                anchors.centerIn: parent
                text: "Double-click to begin building your DFA"
                color: "gray"
                visible: true
            }
        }
    }

	// Dialog box to set the alphabet
    Dialog {
		id: alphabetDialog
		title: qsTr("Enter Alphabet:")
		modal: true
		anchors.centerIn: parent
		width: parent.width / 2
		standardButtons: Dialog.Ok | Dialog.Cancel

		TextField { id: alphabet; anchors.fill: parent; placeholderText: "abc…"}
        onAccepted: dfaBackend.setAlphabet(alphabet.text)
	}

    // Dialog box to add a transition
    Dialog {
        id: transitionDialog
        title: qsTr("Add Transition")
        modal: true
        anchors.centerIn: parent
        width: parent.width / 3
        standardButtons: Dialog.Ok | Dialog.Cancel

        GridLayout {
            columns: 2
            width: parent.width
            
            Label { text: "From:" }
            ComboBox {
                id: fromStateCombo
                Layout.fillWidth: true
                model: Object.keys(mainWindow.dfa_states)
            }
            
            Label { text: "To:" }
            ComboBox {
                id: toStateCombo
                Layout.fillWidth: true
                model: Object.keys(mainWindow.dfa_states)
            }
            
            Label { text: "On symbol:" }
            ComboBox {
                id: transitionSymbol
                Layout.fillWidth: true
                model: alphabet.text.split("")
            }
        }
        onAboutToShow: {
            fromStateCombo.model = Object.keys(mainWindow.dfa_states);
            toStateCombo.model = Object.keys(mainWindow.dfa_states);
        }
        onAccepted: {
            dfaBackend.add_transition(
                fromStateCombo.currentText,
                transitionSymbol.currentText,
                toStateCombo.currentText
            );
            transitionComponent.createObject(canvas, {fromState: mainWindow.dfa_states[fromStateCombo.currentText], toState: mainWindow.dfa_states[toStateCombo.currentText]})
            statusText.text = "Added transition";
            statusText.color = "black";
        }
    }

    // Dialog box to add a new state
    Dialog {
        id: stateDialog
        title: qsTr("Add New State")
        modal: true
        anchors.centerIn: parent
        width: parent.width / 3
        standardButtons: Dialog.Ok | Dialog.Cancel
        property double clickX;
        property double clickY;
        ColumnLayout {
            width: parent.width
            TextField {
                id: stateName
                Layout.fillWidth: true
                placeholderText: "State name (e.g. q0)"
            }
            CheckBox {
                id: isStartState
                text: "Start state"
            }
            CheckBox {
                id: isAcceptState
                text: "Accept state"
            }
        }

        onAccepted: {
            if (stateName.text === "") {
                statusText.text = "Error: State name cannot be empty";
                statusText.color = mainWindow.errorColor;
                return;
            }
            if (mainWindow.dfa_states[stateName.text] !== undefined) {
                statusText.text = "Error: State name already exists";
                statusText.color = mainWindow.errorColor;
                return;
            }

            if (dfaBackend.add_state(stateName.text, isStartState.checked, isAcceptState.checked) === 1) {
                statusText.text = "Error: There is already a start state. Remove it before adding a new one";
                statusText.color = mainWindow.errorColor;
                return;
            }
            mainWindow.hideIntro();

            // Create visual state
            mainWindow.dfa_states[stateName.text] = stateComponent.createObject(canvas, {
                x: clickX,
                y: clickY,
                stateName: stateName.text,
                isStart: isStartState.checked,
                isAccept: isAcceptState.checked
            });
            statusText.text = "Added state";
            statusText.color = "black";
            stateName.text = "";
            isStartState.checked = false;
            isAcceptState.checked = false;
        }
    }
	
    // State visual component
    Component {
        id: stateComponent
        Rectangle {
            id: stateVisual
            width: 60
            height: 60
            radius: width / 2
            color: isActive ? mainWindow.activeStateColor : 
                  (isAccept ? mainWindow.acceptStateColor : 
                  (isStart ? mainWindow.startStateColor : mainWindow.normalStateColor))
            border.color: "black"
            border.width: 2
            
            property string stateName: ""
            property bool isStart: false
            property bool isAccept: false
            property bool isActive: false
            
            // State name label
            Text {
                anchors.centerIn: parent
                text: parent.stateName
                font.bold: true
            }
            
            // Start state indicator
            Rectangle {
                visible: parent.isStart
                width: 10
                height: 10
                radius: width / 2
                color: "black"
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    top: parent.bottom
                    topMargin: -5
                }
            }
            
            // Accept state indicator (double circle)
            Rectangle {
                visible: parent.isAccept
                width: parent.width - 10
                height: parent.height - 10
                radius: width / 2
                color: "transparent"
                border.color: "black"
                border.width: 2
                anchors.centerIn: parent
            }
            
            // Make draggable
            DragHandler {
                target: stateVisual
            }
            Component.onCompleted: {
                this.x = this.x - this.width / 2;
                this.y = this.y - this.width / 2;
            }
        }
    }
    // Transition visual component
    Component {
        id: transitionComponent        
        Shape {
            id: transitionShape
            anchors.fill: parent
            layer.enabled: true
            layer.samples: 8
            antialiasing: true
            property Rectangle fromState
            property Rectangle toState
            ShapePath {
                id: transitionLine
                property alias a: transitionShape.fromState
                property alias b: transitionShape.toState
                strokeWidth: 2
                strokeColor: "black"
                fillColor: "transparent"
                pathHints: ShapePath.PathLinear | ShapePath.PathNonIntersecting
                // (rsin(θ_a) + x_a, rcos(θ_a) + y_a) => (rsin(θ_b) + x_b, rcos(θ_b) + y_b)
                property double scaleR: a.width / 2 / Math.sqrt((b.x - a.x) * (b.x - a.x) + (b.y - a.y) * (b.y - a.y))
                startX: a.x + a.width / 2 + scaleR * (b.x - a.x)
                startY: a.y + a.width / 2 + scaleR * (b.y - a.y)
                PathLine {
                    property alias a: transitionShape.fromState
                    property alias b: transitionShape.toState
                    x: b.x + b.width / 2 - transitionLine.scaleR * (b.x - a.x)
                    y: b.y + b.height / 2 - transitionLine.scaleR * (b.y - a.y)
                }
            }
            // TODO: tie arrowhead image to the orientation of this^ line
        }
    }
    function hideIntro() {
        startText.visible = false;
    }
}

