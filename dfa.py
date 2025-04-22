from PySide6.QtCore import QObject, Property, Slot

class State:
    _id_ = 0  # giving each state a unique id

    def __init__(self, delta: {} = None):
        self.id = State._id_  # assign unique id
        State._id_ += 1
        # dictionary for all transitions from the current state
        # each key should be a string
        # each value should be a state object
        self.delta = delta if delta is not None else {}

    # used for checking equivalence of states
    def __eq__(self, other):
        return isinstance(other, State) and self.id == other.id

    # used to hash instances of states correctly for the transition function
    def __hash__(self):
        return hash(self.id)


class DFA(QObject):
    def __init__(self):
        super().__init__()
        self.reset()

    def __repr__(self):
        states_str = ", ".join(self.states.keys())
        alphabet_str = ", ".join(self.alphabet)
        return f"DFA(States: [{states_str}], Alphabet: [{alphabet_str}])"

    # Determines if dfa has a valid construction
    # Returns an error string, or None if the DFA is valid
    @Slot(result=str)
    def validate_dfa(self) -> str | None:
        if not self.start_state:
            return "Invalid DFA. No start state found."
        
        # Check to ensure for every state q and every symbol a in the alphabet, there is exactly one defined transition
        # Also check to ensure every transition is in the alphabet (Q x Sigma -> Q)
        for state in self.states:
            for symbol in self.alphabet:
                if symbol not in self.states[state].delta:
                    return f"Invalid DFA. ({state}, {symbol}) does not have a defined transition."


    # Checks whether a given string is accepted by the machine
    # Returns a boolean representing if the string is accepted
    @Slot(str, result=bool)
    def accepts(self, string: str) -> bool:
        # Transition from state to state following the symbols in the string and the transition function
        current_state = self.start_state
        for symbol in string:
            # Confirm symbol is in the alphabet
            if symbol not in self.alphabet:
                return False
            
            # Transition to next state
            current_state = current_state.delta[symbol]
        # After reading through string, return whether or not current state is an accept state
        return current_state in self.accepting_states

    @Slot()
    def reset(self):
        self.alphabet = ""
        self.states = {}
        self.accepting_states = {}
        self.start_state = None

    @Slot(str)
    def setAlphabet(self, alphabet):
        self.alphabet = alphabet

    @Slot(str, str, str, result=str)
    def add_transition(self, src, symbol, dst):
        if self.states[src].delta.get(symbol):
            return f"({src}, {symbol}) already exists"
        self.states[src].delta[symbol] = self.states[dst]

    @Slot(str, bool, bool, result=int)
    def add_state(self, name, start, accepting, result=int):
        if start and self.start_state:
            return 1
        self.states[name] = State()
        if start:
            self.start_state = self.states[name]
        if accepting:
            self.accepting_states[self.states[name]] = True
        return 0


