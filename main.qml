import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs


ApplicationWindow {
    id: mainWindow
    width: 1000
    height: 700
	visible: true
	title: qsTr("DFA Visualizer")

    property var dfa_states: [];
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
                    if (dfa_states.length === 0 || alphabet.text.length === 0) {
                        statusText.text = "Error: Adding transitions requires at least 1 state and an alphabet";
                        statusText.color = errorColor;
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
                        statusText.color = errorColor;
                        return
                    }

                    let accepted = dfaBackend.accepts(inputString.text);
                    statusText.text = "Test result: " + (accepted ? "Accepted" : "Rejected");
                    statusText.color = accepted ? "green" : "red";
                }
            }

            Button {
                text: "Simulate"
                onClicked: {
                    simulationDialog.inputString = inputString.text;
                    simulationDialog.open();
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
                onDoubleClicked: mouse => stateDialog.open()

                acceptedButtons: Qt.LeftButton
            }

            // Initial help text
            Text {
                anchors.centerIn: parent
                text: "Double-click to begin building your DFA"
                color: "gray"
                visible: dfa_states.length === 0
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
                model: dfa_states
            }
            
            Label { text: "To:" }
            ComboBox {
                id: toStateCombo
                Layout.fillWidth: true
                model: dfa_states
            }
            
            Label { text: "On symbol:" }
            ComboBox {
                id: transitionSymbol
                Layout.fillWidth: true
                model: alphabet.text.split("")
            }
        }

        onAccepted: {
            dfaBackend.add_transition(
                fromStateCombo.currentText,
                transitionSymbol.currentText,
                toStateCombo.currentText
            );
            
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
                statusText.color = errorColor;
                return;
            }
            if (dfa_states.includes(stateName.text)) {
                statusText.text = "Error: State name already exists";
                statusText.color = errorColor;
                return;
            }

            if (dfaBackend.add_state(stateName.text, isStartState.checked, isAcceptState.checked)) {
                statusText.text = "Error: There is already a start state. Remove it before adding a new one";
                statusText.color = errorColor;
                return;
            }
            dfa_states += stateName.text

            // Create visual state
            var stateVisual = stateComponent.createObject(canvas, {
                x: canvas.width/2 - 25,
                y: canvas.height/2 - 25,
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
            color: isActive ? activeStateColor : 
                  (isAccept ? acceptStateColor : 
                  (isStart ? startStateColor : normalStateColor))
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
        }
    }
}

