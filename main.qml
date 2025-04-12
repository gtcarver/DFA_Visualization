import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Dialogs

ApplicationWindow {
	width: 640
	height: 480
	visible: true
	title: qsTr("DFA Visualizer")

	// Dialog box to set the alphabet. Appears only when app is started and must be answered
	Dialog {
		id: alphabetDialog
		title: qsTr("Enter Alphabet:")
		modal: true
		closePolicy: Popup.NoAutoClose
		anchors.centerIn: parent
		width: parent.width / 2
		standardButtons: Dialog.Ok

		TextField { id: alphabet; anchors.fill: parent; placeholderText: "abc…"}
		onAccepted: console.log("Using alphabet: ", alphabet.text)
		Component.onCompleted: this.open()
	}

	// Menu bar type thing
	Item {
		id: menuBar
		height: childrenRect.height
		anchors.left: parent.left
		anchors.right: parent.right
		Button {
			anchors.left: parent.left
			horizontalPadding: 10
			text: qsTr("Add Transition")
			onClicked: transitionDialog.open()
		}
		Button {
			id: runButton
			anchors.right: parent.right
			horizontalPadding: 10
			text: qsTr("Run")
			onClicked: console.log("Simulation word: ", word.text)
		}
		TextField {
			id: word
			placeholderText: "Input word"
			anchors.right: runButton.left
		}
	}

	// Dialog box to add a transition
	Dialog {
		id: transitionDialog
		title: qsTr("New Transition:")
		modal: true
		anchors.centerIn: parent
		standardButtons: Dialog.Ok | Dialog.Cancel
		Grid {
			columns: 2
			Label {text: "from:   "}
			ComboBox {id: fromState}
			Label {text: "to:   "}
			ComboBox {id: toState}
			Label {text: "on:   "}
			ComboBox {id: transitionKey}
		}
		onAccepted: console.log("from:", fromState.currentText, "to: ", toState.currentText, "on:", transitionKey.currentText) // TODO
	}

	// Clickable area for editing the DFA
	MouseArea {
		id: editPane
		anchors.fill: parent
		anchors.topMargin: menuBar.height
		onDoubleClicked: mouse => state.createObject(editPane).setPos(mouse.x, mouse.y);
		acceptedButtons: Qt.LeftButton
	}

	// DFA State (a circle)
	Component {
		id: state
		Rectangle {
			width: 50; height: 50
			radius: width/2
			border.color: "black"
			function setPos(x, y) {
				this.x = x - width/2;
				this.y = y - height/2;
			}
			DragHandler {}
		}
	}
}
