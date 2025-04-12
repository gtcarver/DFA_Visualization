# This Python file uses the following encoding: utf-8
# main.py
# This lets users define their own DFA using the GUI
# The user can enter states, transitions, and input strings from the frontend

import sys
from pathlib import Path

# PySide6 modules for building GUI apps
from PySide6.QtGui import QGuiApplication  # Handles the app lifecycle
from PySide6.QtQml import QQmlApplicationEngine  # Loads the QML GUI file
from PySide6.QtCore import QObject, Slot  # Base class and decorator to allow GUI to call Python

# Import DFA logic that we already defined in dfa.py
from dfa import DFA, State


# This class is the bridge between QML and Python
# QML will call the methods in this class to build and run the DFA
class DFAInterface(QObject):
    def __init__(self):
        super().__init__()
        self.user_states = {}  # stores State objects the user creates
        self.user_dfa = None   # stores the DFA object after it's built
        self.alphabet = ['0', '1']  # hardcoded alphabet (for now)

    # This method is called from QML when the user wants to build a DFA
    # Parameters:
    # - state_names: list of all state names (e.g., ["q0", "q1", "q2"])
    # - start_state_name: string name of the start state (e.g., "q0")
    # - accept_states: list of accepting state names (e.g., ["q2"])
    # - transitions: list of transitions (each one is a dict with "from", "input", "to")
    @Slot('QVariantList', str, 'QVariantList', 'QVariantList', result=str)
    def build_dfa(self, state_names, start_state_name, accept_states, transitions):
        self.user_states = {}  # clear previous DFA

        # Create State objects for each name
        for name in state_names:
            self.user_states[name] = State(
                name,
                is_start=(name == start_state_name),
                is_accept=(name in accept_states)
            )

        # Assign transitions to each state
        for t in transitions:
            from_state = t['from']
            symbol = t['input']
            to_state = t['to']

            # Validate the symbol
            if symbol not in self.alphabet:
                return f"Error: Invalid symbol '{symbol}' not in alphabet {self.alphabet}"

            # Make sure both source and destination states exist
            if from_state not in self.user_states or to_state not in self.user_states:
                return "Error: Transition refers to undefined state"

            # Add the transition to the source state's delta map
            self.user_states[from_state].delta[symbol] = self.user_states[to_state]

        # Create the DFA from the list of State objects
        self.user_dfa = DFA("UserDFA", list(self.user_states.values()), self.alphabet)

        # Validate the DFA
        valid, msg = self.user_dfa.is_valid()
        if not valid:
            return "Invalid DFA: " + msg

        return "DFA built successfully."

    # This method is called when the user wants to test a string on the built DFA
    # Parameter: input_string (e.g., "10101")
    # Returns: "Accepted" or "Rejected"
    @Slot(str, result=str)
    def test_string(self, input_string):
        # Make sure the DFA is built first
        if self.user_dfa is None:
            return "Error: No DFA has been built yet."

        # Check if user entered a string
        if input_string == "":
            return "Please enter a string to test."

        # Check for invalid characters
        for c in input_string:
            if c not in self.alphabet:
                return f"Invalid input character: '{c}' (only 0 and 1 allowed)"

        # Run the string through the DFA
        if self.user_dfa.accepts(input_string):
            return "Accepted"
        else:
            return "Rejected"


# This is the entry point of the program — it launches the app
if __name__ == "__main__":
    # Create the Qt app instance
    app = QGuiApplication(sys.argv)

    # Load the QML engine that handles the GUI
    engine = QQmlApplicationEngine()

    # Create an instance of our Python logic class and expose it to the GUI
    dfa_interface = DFAInterface()
    engine.rootContext().setContextProperty("dfaBackend", dfa_interface)

    # Load the GUI file (main.qml must be in the same directory)
    qml_file = Path(__file__).resolve().parent / "main.qml"
    engine.load(qml_file)

    # If loading the GUI fails (like missing file or syntax error), exit
    if not engine.rootObjects():
        print("Error: Could not load QML.")
        sys.exit(-1)

    # Run the app
    sys.exit(app.exec())
