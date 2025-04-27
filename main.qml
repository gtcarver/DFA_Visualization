pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Shapes

ApplicationWindow {
    id: main
    width: 1000
    height: 700
	visible: true
	title: qsTr("DFA Visualizer")

    property var dfa_states: ({})
    function hasOneState(): bool {
        for (const x in main.dfa_states)
            return true
        return false
    }

    property var colors: ({
        acceptState: "#a5d6a7",
        startState: "#90caf9",
        normalState: "#ffffff",
        activeState: "#ff3333",
        accepted: "green",
        rejected: "red",
        error: "#ef9a9a",
        activeTransition: "#ff3333"
    })

    Item {
        id: simulator
        property var currentState: null
        property var currentStateName: null
        property var previousState: null
        property var previousStateName: null
        property var activeTransition: null
        property var inputStringIndex: 0
        property var simActive: false
        property var inputSymbols: []
        property var currentSymbol: null

        function findTransition(fromState, toState) {
            for (const child of transition_container.children) {
                if (child.fromState === fromState && 
                    child.toState === toState) {
                    return child;
                }
            }
            return null; // No transition exists
        }
        function clearSim() {
            if (currentState) {
                currentState.isActive = false;
            }
            if (activeTransition) {
                activeTransition.isActive = false;
            }

            currentState = null
            currentStateName = null
            previousState = null
            previousStateName = null
            activeTransition = null
            inputStringIndex = 0
            simActive = false
            inputSymbols = []
            currentSymbol = null
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
        function start() {
            currentStateName = dfaBackend.get_start_state()
            currentState = main.dfa_states[currentStateName]


            currentState.isActive = true
            // mainWindow.currentState.border.color = mainWindow.activeColor

            inputSymbols = inputString.text.split("")
            inputStringIndex = 0
            simActive = true


            simulationControls.toggleSimulControls()

            statusText.set("Visualization started. Start state is " + currentStateName);
        }
        function step() {
            // Check for end of input string
            if (inputStringIndex == inputSymbols.length) {
                stepButton.enabled = false
                let accepted = dfaBackend.accepts(inputString.text)

                if (activeTransition)
                    activeTransition.isActive = false;
                statusText.set(`The computation terminated in state ${currentStateName}, ` +
                    `which is ${accepted ? "" : "not "}an accepting state. String '${inputString.text}' is ${accepted ? "accepted" : "rejected"}.`,
                    accepted ? main.colors.accepted : main.colors.rejected);
                return
            }

            // If it exists, deactivate current transition
            if (activeTransition) {
                activeTransition.isActive = false;
            }

            // Tracks previous state that still need to be modified
            previousStateName = currentStateName
            previousState = currentState

            currentSymbol = inputSymbols[inputStringIndex]

            // Check to confirm symbol is in alphabet
            let inAlph = dfaBackend.is_in_alphabet(currentSymbol)
            if (!inAlph) {
                stepButton.enabled = false
                if (activeTransition)
                    activeTransition.isActive = false;
                statusText.set(`Symbol '${currentSymbol}' is not in the alphabet. String '${inputString.text}' is rejected.`, main.colors.rejected);
                return
            }
            
            // Take next step in simulation
            currentStateName = dfaBackend.take_step(previousState.stateName, currentSymbol)
            currentState = main.dfa_states[currentStateName]

            // Find the current transition to activate
            activeTransition = findTransitionWithSymbol(
                previousState,
                currentState,
                currentSymbol
            );

            // activate & current state & transition, deactivate old one
            previousState.isActive = false
            currentState.isActive = true
            activeTransition.isActive = true

            inputStringIndex++;

            statusText.text = "Transitioned from " + previousStateName + " to " + currentStateName + " on symbol " + currentSymbol
        }
        function stop() {
            stepButton.enabled = true
            simulationControls.toggleSimulControls()
            clearSim()
            statusText.text = "Visualization stopped."
            statusText.color = palette.text
        }
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
                    if (!main.hasOneState() || alphabet.text.length === 0) {
                        statusText.text = "Error: Adding transitions requires at least 1 state and an alphabet";
                        statusText.color = main.colors.error;
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
                function set(msg, col) {
                    text = msg;
                    color = col || palette.text;
                }
            }
        }

        // Simulation controls
        RowLayout {
            id: simulationControls
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
                        statusText.set("Error: " + validation, main.colors.error);
                        return
                    }

                    let accepted = dfaBackend.accepts(inputString.text);
                    statusText.set("Test result: " + (accepted ? "Accepted" : "Rejected"), accepted ? main.colors.accepted : main.colors.rejected);
                }
            }

            Button {
                id: resetButton
                text: "Reset"
                onClicked: {
                    simulator.clearSim();
                    dfaBackend.reset();
                    dfaBackend.setAlphabet(alphabet.text)
                    canvas.clear();
                    main.showIntro();
                    main.dfa_states = {};
                    statusText.set("DFA Reset");
                }
            }

            function toggleSimulControls() {
                for (const comp of [visualizeButton, stepButton, stopButton]) {
                    comp.visible = !comp.visible;
                    comp.enabled = !comp.enabled;
                }
                for (const comp of [resetButton, testButton, setAlphabetButton, addTransitionButton, inputString]) {
                    comp.enabled = !comp.enabled;
                }
            }

            Button {
                id: visualizeButton
                Layout.preferredWidth: implicitWidth * 1.5;
                text: "Visualize";
                onClicked: {
                    let validation = dfaBackend.validate_dfa()
                    if (validation) {
                        statusText.set("Error: " + validation, main.colors.error)
                        return
                    }
                    simulator.start()
                }
            }
            Button {
                id: stepButton
                visible: false
                enabled: false
                implicitWidth: visualizeButton.width / 2 - 5 // - 5 for half of spacing
                text: "Step"
                onClicked: simulator.step()
            }        
            Button {
                id: stopButton
                visible: false
                enabled: false
                implicitWidth: visualizeButton.width / 2 - 5 // - 5 for half of spacing
                text: "Stop"
                onClicked: simulator.stop()
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
                model: Object.keys(main.dfa_states)
            }
            
            Label { text: "To:" }
            ComboBox {
                id: toStateCombo
                Layout.fillWidth: true
                model: Object.keys(main.dfa_states)
            }
            
            Label { text: "On symbol:" }
            ComboBox {
                id: transitionSymbol
                Layout.fillWidth: true
                model: alphabet.text.split("")
            }
        }
        onAboutToShow: {
            fromStateCombo.model = Object.keys(main.dfa_states);
            toStateCombo.model = Object.keys(main.dfa_states);
        }
        onAccepted: {
            const result = dfaBackend.add_transition(
                fromStateCombo.currentText,
                transitionSymbol.currentText,
                toStateCombo.currentText
            );
            if (result) {
                statusText.set(result, main.colors.error);
                return;
            }
            // check to see if a transition arrow exist, add symbol to its transition label if so
            let transitionArrow = simulator.findTransition(main.dfa_states[fromStateCombo.currentText],
                main.dfa_states[toStateCombo.currentText])
            if (transitionArrow) {
                transitionArrow.symbol += ", " + transitionSymbol.currentText
            }
            else {
                transitionComponent.createObject(transition_container, {
                fromState: main.dfa_states[fromStateCombo.currentText], 
                toState: main.dfa_states[toStateCombo.currentText],
                symbol: transitionSymbol.currentText})
            }
        
            statusText.set("Added transition");
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
                statusText.set("Error: State name cannot be empty", main.colors.error);
                return;
            }
            if (main.dfa_states[stateName.text] !== undefined) {
                statusText.set("Error: State name already exists", main.colors.error);
                return;
            }

            if (dfaBackend.add_state(stateName.text, isStartState.checked, isAcceptState.checked) === 1) {
                statusText.set("Error: There is already a start state. Remove it before adding a new one", main.colors.error);
                return;
            }
            main.hideIntro();

            // Create visual state
            main.dfa_states[stateName.text] = stateComponent.createObject(state_container, {
                x: clickX,
                y: clickY,
                stateName: stateName.text,
                isStart: isStartState.checked,
                isAccept: isAcceptState.checked
            });
            statusText.set("Added state");
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
            color: isAccept ? main.colors.acceptState :
                   (isStart ? main.colors.startState : main.colors.normalState)
            border.color: isActive ? main.colors.activeState : "black"
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
                color: stateVisual.isActive ? main.colors.activeState : "black"
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
                border.color: stateVisual.isActive ? main.colors.activeState : "black"
                border.width: 2
                anchors.centerIn: parent
            }
            
            DragHandler {}

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

            property bool isActive: false
            z: isActive ? 1 : 0

            property Rectangle fromState
            property Rectangle toState
            property string symbol

            property var a: ({x: fromState.x + fromState.radius, y: fromState.y + fromState.radius})
            property var b: ({x: toState.x + toState.radius, y: toState.y + toState.radius})

            // line calcs
            property vector2d v: Qt.vector2d(b.x - a.x, b.y - a.y).normalized();
            property vector2d v_orth: Qt.vector2d(-v.y, v.x);
            property vector2d a_side: Qt.vector2d(a.x, a.y).plus(v.times(fromState.radius));
            property vector2d b_side: Qt.vector2d(b.x, b.y).minus(v.times(fromState.radius));
            property double controlX: (shape.a.x + shape.b.x) / 2 + 50 * shape.v_orth.x
            property double controlY: (shape.a.y + shape.b.y) / 2 + 50 * shape.v_orth.y
            property vector2d v_arrowhead: b_side.minus(Qt.vector2d(controlX, controlY))
            property vector2d v_arrowhead_orth: Qt.vector2d(-v_arrowhead.y, v_arrowhead.x).normalized()

            function vec_to_point(v) {
                return Qt.point(v.x, v.y)
            }

            // boolean for determining if a self loop is created
            property bool isSelfLoop: fromState == toState

            // arrow for non self loops
            ShapePath {
                joinStyle: ShapePath.RoundJoin
                capStyle: ShapePath.RoundCap
                strokeWidth: 2
                strokeColor: shape.isSelfLoop ? "transparent" : shape.isActive ? main.colors.activeTransition : "black"
                fillColor: "transparent"
                startX: shape.a_side.x
                startY: shape.a_side.y
                PathQuad {
                    x: shape.b_side.x
                    y: shape.b_side.y
                    controlX: shape.controlX
                    controlY: shape.controlY
                }
                PathPolyline {
                    property vector2d anchorPoint: shape.b_side.minus(shape.v_arrowhead.times(0.15))
                    property vector2d offset: shape.v_arrowhead_orth.times(7)
                    path: [
                        shape.vec_to_point(anchorPoint.plus(offset)),
                        shape.vec_to_point(shape.b_side),
                        shape.vec_to_point(anchorPoint.minus(offset))
                    ]
                }
            }

            // arrow for self loops
            ShapePath {
                strokeWidth: 2
                strokeColor: !(shape.isSelfLoop) ? "transparent" : shape.isActive ? main.colors.activeTransition : "black"
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
                Text {
                    x: (shape.isSelfLoop ? shape.a.x - shape.fromState.radius / 10 : shape.controlX + shape.v_arrowhead_orth.x * 4) - implicitWidth / 2
                    y: (shape.isSelfLoop ? shape.a.y - shape.fromState.radius * 2.5 : shape.controlY + shape.v_arrowhead_orth.y * 4) - implicitHeight / 2
                    text: shape.symbol
                    font.bold: true
                    color: shape.isActive ? main.colors.activeTransition : "black"
                    z: 1
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