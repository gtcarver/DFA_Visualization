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

    property var currentState: null
    property var currentStateName: null
    property var previousState: null
    property var previousStateName: null
    property var activeTransition: null
    property var inputStringIndex: 0
    property var simActive: false
    property var inputSymbols: []
    property var symbolsLen: null
    property var currentSymbol: null

    property color acceptStateColor: "#a5d6a7"
    property color startStateColor: "#90caf9"
    property color normalStateColor: "#ffffff"
    property color activeStateColor: "#ff3333"
    property color errorColor: "#ef9a9a"
    property color activeTransitionColor: "#ff3333"


    function findTransition(fromState, toState) {
        for (const child of transition_container.children) {
            if (child.fromState === fromState && 
                child.toState === toState) {
                return child;
            }
        }
        return null; // No transition exists
    }

    // Main layout
	ColumnLayout {
        anchors.fill: parent
        spacing: 5

        // Toolbar
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Button {
                id: setAlphabetButton
                text: "Set Alphabet"
                onClicked: alphabetDialog.open()
            }

            Button {
                id: addTransitionButton
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
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: statusText.implicitHeight
            color: palette.base
            Layout.leftMargin: 10
            Label {
                id: statusText
                anchors.fill: parent
            }
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
                id: testButton
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
                id: resetButton
                text: "Reset"
                onClicked: {
                    parent.clearSim();
                    dfaBackend.reset();
                    canvas.clear();
                    mainWindow.showIntro();
                    mainWindow.dfa_states = {};
                    statusText.text = "DFA Reset";
                    statusText.color = palette.text;
                }
            }

            function toggleSimulControls() {
                visualizeButton.visible = !visualizeButton.visible;
                stepButton.visible = !stepButton.visible;
                stopButton.visible = !stopButton.visible;
                visualizeButton.enabled = !visualizeButton.enabled;
                stepButton.enabled = !stepButton.enabled;
                stopButton.enabled = !stopButton.enabled;

                resetButton.enabled = !resetButton.enabled;
                testButton.enabled = !testButton.enabled;
                setAlphabetButton.enabled = !setAlphabetButton.enabled;
                addTransitionButton.enabled = !addTransitionButton.enabled;

                inputString.enabled = !inputString.enabled;
            }

            function clearSim() {
                if (mainWindow.currentState) {
                    mainWindow.currentState.isActive = false;
                }
                if (mainWindow.activeTransition) {
                    mainWindow.activeTransition.isActive = false;
                }

                mainWindow.currentState = null
                mainWindow.currentStateName = null
                mainWindow.previousState = null
                mainWindow.previousStateName = null
                mainWindow.activeTransition = null
                mainWindow.inputStringIndex = 0
                mainWindow.simActive = false
                mainWindow.inputSymbols = []
                mainWindow.symbolsLen = 0
                mainWindow.currentSymbol = null
            }
            
            function findTransitionWithSymbol(fromState, toState, symbol) {
                for (const child of transition_container.children) {
                    if (child.fromState === fromState && 
                        child.toState === toState && 
                        child.symbol.includes(symbol)) { //child.symbol === symbol
                        return child;
                    }
                }
                return null; // No transition exists
            }

            Button {
                id: visualizeButton
                Layout.preferredWidth: implicitWidth * 1.5;
                text: "Visualize";
                onClicked: {
                    let validation = dfaBackend.validate_dfa()
                    if (validation) {
                        statusText.text = "Error: " + validation;
                        statusText.color = mainWindow.errorColor;
                        return
                    }
                    
                    mainWindow.currentStateName = dfaBackend.get_start_state()
                    mainWindow.currentState = mainWindow.dfa_states[mainWindow.currentStateName]


                    mainWindow.currentState.isActive = true
                    // mainWindow.currentState.border.color = mainWindow.activeColor

                    mainWindow.inputSymbols = inputString.text.split("")
                    mainWindow.symbolsLen = mainWindow.inputSymbols.length
                    mainWindow.inputStringIndex = 0
                    mainWindow.simActive = true


                    parent.toggleSimulControls()

                    statusText.text = "Visualization started. Start state is " + mainWindow.currentStateName
                    statusText.color = palette.text
                }
            }
            Button {
                id: stepButton
                visible: false
                enabled: false
                implicitWidth: visualizeButton.width / 2 - 5 // - 5 for half of spacing
                text: "Step"
                onClicked: {
                    // Check for end of input string
                    if (mainWindow.inputStringIndex == mainWindow.symbolsLen) {
                        stepButton.enabled = false
                        let accepted = dfaBackend.accepts(inputString.text)

                        if (mainWindow.activeTransition) mainWindow.activeTransition.isActive = false;

                        if (accepted) {
                            statusText.text = "The computation terminated in state " + 
                                         mainWindow.currentStateName + 
                                         ", which is an accept state. String '" + 
                                         inputString.text + "' is accepted."
                        }

                        else {
                            statusText.text = "The computation terminated in state " + 
                                         mainWindow.currentStateName + 
                                         ", which is not accept state. String '" + 
                                         inputString.text + "' is rejected."
                        }

                        statusText.color = accepted ? "green" : "red"
                        return
                    }

                    // If it exists, deactivate current transition
                    if (mainWindow.activeTransition) {
                        mainWindow.activeTransition.isActive = false;
                    }

                    // Tracks previous state that still need to be modified
                    mainWindow.previousStateName = mainWindow.currentStateName
                    mainWindow.previousState = mainWindow.currentState

                    mainWindow.currentSymbol = mainWindow.inputSymbols[mainWindow.inputStringIndex]

                    // Check to confirm symbol is in alphabet
                    let inAlph = dfaBackend.is_in_alphabet(mainWindow.currentSymbol)
                    if (!inAlph) {
                        stepButton.enabled = false
                        if (mainWindow.activeTransition) mainWindow.activeTransition.isActive = false;
                        statusText.text = "Symbol '" + mainWindow.currentSymbol + 
                                          "' is not in the alphabet. String '" + 
                                          inputString.text + "' is rejected."
                        statusText.color = "red" 
                        return
                    }
                    
                    // Take next step in simulation
                    mainWindow.currentStateName = dfaBackend.take_step(mainWindow.previousState.stateName, mainWindow.currentSymbol)
                    mainWindow.currentState = mainWindow.dfa_states[mainWindow.currentStateName]

                    // Find the current transition to activate
                    mainWindow.activeTransition = parent.findTransitionWithSymbol(
                        mainWindow.previousState,
                        mainWindow.currentState,
                        mainWindow.currentSymbol
                    );

                    // activate & current state & transition, deactivate old one
                    mainWindow.previousState.isActive = false
                    mainWindow.currentState.isActive = true
                    mainWindow.activeTransition.isActive = true

                    mainWindow.inputStringIndex = mainWindow.inputStringIndex + 1

                    statusText.text = "Transitioned from " + mainWindow.previousStateName + " to " + mainWindow.currentStateName + " on symbol " + mainWindow.currentSymbol
                }
            }        
            Button {
                id: stopButton
                visible: false
                enabled: false
                implicitWidth: visualizeButton.width / 2 - 5 // - 5 for half of spacing
                text: "Stop"
                onClicked: {
                    stepButton.enabled = true
                    parent.toggleSimulControls()
                    parent.clearSim()
                    statusText.text = "Visualization stopped."
                    statusText.color = palette.text
                }
            }
        }
        // Area for DFA visualization
        Rectangle {
            id: canvas
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            
            Item {id: state_container}
            Item {
                id: transition_container;
                anchors.fill: parent;
                layer.enabled: true;
                layer.samples: 8;
                antialiasing: true
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
            function clear() {
                for (const child of transition_container.children) {
                    child.layer.enabled = false;
                    child.destroy();
                }
                for (const child of state_container.children) {
                    child.destroy();
                }
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
            const result = dfaBackend.add_transition(
                fromStateCombo.currentText,
                transitionSymbol.currentText,
                toStateCombo.currentText
            );
            if (result) {
                statusText.color = mainWindow.errorColor;
                statusText.text = result;
                return;
            }
            // check to see if a transition arrow exist, add symbol to its transition label if so
            let transitionArrow = mainWindow.findTransition(mainWindow.dfa_states[fromStateCombo.currentText],
                                                 mainWindow.dfa_states[toStateCombo.currentText])

            if (transitionArrow) {
                transitionArrow.transitionText.text = transitionArrow.transitionText.text + ", " + transitionSymbol.currentText
                transitionArrow.symbol = transitionArrow.symbol + ", " + transitionSymbol.currentText
            }

            else {
                transitionComponent.createObject(transition_container, {
                fromState: mainWindow.dfa_states[fromStateCombo.currentText], 
                toState: mainWindow.dfa_states[toStateCombo.currentText],
                symbol: transitionSymbol.currentText})
            }
        
            statusText.text = "Added transition";
            statusText.color = palette.text;
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
            mainWindow.dfa_states[stateName.text] = stateComponent.createObject(state_container, {
                x: clickX,
                y: clickY,
                stateName: stateName.text,
                isStart: isStartState.checked,
                isAccept: isAcceptState.checked
            });
            statusText.text = "Added state";
            statusText.color = palette.text;
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
            color: isAccept ? mainWindow.acceptStateColor :
                   (isStart ? mainWindow.startStateColor : mainWindow.normalStateColor)
            border.color: isActive ? mainWindow.activeStateColor : "black"
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
                color: stateVisual.isActive ? mainWindow.activeStateColor : "black"
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
                border.color: stateVisual.isActive ? mainWindow.activeStateColor : "black"
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
            id: shape
            anchors.fill: parent

            property alias transitionText: transitionText

            property bool isActive: false
            z: isActive ? 1 : 0

            property Rectangle fromState
            property Rectangle toState
            property string symbol

            property var a: ({x: fromState.x + fromState.width / 2, y: fromState.y + fromState.width / 2})
            property var b: ({x: toState.x + toState.width / 2, y: toState.y + toState.width / 2})
            
            property double yd: b.y - a.y
            property double xd: b.x - a.x

            // line calcs
            property double scaleR: fromState.width / 2 / Math.hypot(b.x - a.x, b.y - a.y)
            property double ax_outer: a.x + scaleR * xd
            property double ay_outer: a.y + scaleR * yd
            property double bx_outer: b.x - scaleR * xd
            property double by_outer: b.y - scaleR * yd

            property double theta: Math.atan2(b.y - a.y, b.x - a.x)

            // boolean for determining if a self loop is created
            property bool isSelfLoop: fromState == toState

            // arrow for non self loops
            ShapePath {
                strokeWidth: 2
                strokeColor: shape.isSelfLoop ? "transparent" : shape.isActive ? mainWindow.activeTransitionColor : "black"

                PathPolyline {
                    property double q: 10
                    property double opening: 90 / 180 * Math.PI
                    property double xPreRotate: -q * Math.cos(opening / 2)
                    property double yPreRotate: -q * Math.sin(opening / 2)
                    property double yPreRotate2: q * Math.sin(opening / 2)
                    property double sn: Math.sin(shape.theta)
                    property double cs: Math.cos(shape.theta)
                    path: [
                        Qt.point(shape.ax_outer, shape.ay_outer),
                        Qt.point(shape.bx_outer, shape.by_outer),
                        Qt.point(
                            shape.bx_outer + xPreRotate * cs - yPreRotate2 * sn,
                            shape.by_outer + xPreRotate * sn + yPreRotate2 * cs
                        ),
                        Qt.point(shape.bx_outer, shape.by_outer),
                        Qt.point(
                            shape.bx_outer + xPreRotate * cs - yPreRotate * sn,
                            shape.by_outer + xPreRotate * sn + yPreRotate * cs
                        )
                    ]
                }
            }

            // arrow for self loops
            ShapePath {
                strokeWidth: 2
                strokeColor: !(shape.isSelfLoop) ? "transparent" : shape.isActive ? mainWindow.activeTransitionColor : "black"
                fillColor: "transparent"

                PathAngleArc {
                    centerX: shape.a.x
                    centerY: shape.a.y - shape.fromState.radius * 1.5
                    radiusX: shape.fromState.radius / 2
                    radiusY: shape.fromState.radius / 2
                    startAngle: 0    
                    sweepAngle: 360  
                }

                PathPolyline {
                    property var tip: ({x: shape.a.x, y: shape.a.y - shape.fromState.radius})

                    // adjust arrowhead lengths later
                    path: [
                        Qt.point(tip.x - 7, tip.y - 7),
                        Qt.point(tip.x, tip.y),
                        Qt.point(tip.x - 7, tip.y + 7),
                    ]
                }
            }

            // transition label
            Item {
                x: shape.isSelfLoop ? shape.a.x - shape.fromState.radius / 10 : (shape.a.x + shape.b.x) / 2
                y: shape.isSelfLoop ? shape.a.y - shape.fromState.radius * 2.5 : (shape.a.y + shape.b.y) / 2
                Text {
                    id: transitionText
                    text: shape.symbol
                    font.bold: true
                    color: shape.isActive ? mainWindow.activeTransitionColor : "black"

                    DragHandler {}
                }
            }
        }
    }
    function hideIntro() {
        startText.visible = false;
    }
    function showIntro() {
        startText.visible = true;
    }
}