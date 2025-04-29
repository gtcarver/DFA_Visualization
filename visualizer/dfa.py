from PySide6.QtCore import QObject, Property, Slot

class State:
    _id_ = 0  # giving each state a unique id

    def __init__(self, delta = None):
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
    def validate_dfa(self):
        if not self.start_state:
            return "Invalid DFA. No start state found."
        
        # Check to ensure for every state q and every symbol a in the alphabet, there is exactly one defined transition
        # Also check to ensure every transition is in the alphabet (Q x Sigma -> Q)
        for state in self.states:
            for symbol in self.alphabet:
                if symbol not in self.states[state].delta:
                    return f"Invalid DFA. \u03B4({state}, {symbol}) does not have a defined transition."
            if len(self.states[state].delta) > len(self.alphabet):
                return f"Invalid DFA. Transition(s) exist on symbol(s) outside the alphabet."


    # Checks whether a given string is accepted by the machine
    # Returns a boolean representing if the string is accepted
    @Slot(str, result=bool)
    def accepts(self, string) -> bool:
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
    def set_alphabet(self, alphabet):
        self.alphabet = alphabet

    @Slot(str, result=bool)
    def is_in_alphabet(self, symbol) -> bool: 
        return symbol in self.alphabet

    @Slot(str, str, str, result=str)
    def add_transition(self, src, symbol, dst):
        if self.states[src].delta.get(symbol):
            return f"\u03B4({src}, {symbol}) already exists"
        self.states[src].delta[symbol] = self.states[dst]

    @Slot(str, bool, bool, result=int)
    def add_state(self, name, start, accepting):
        if start and self.start_state:
            return 1
        self.states[name] = State()
        if start:
            self.start_state = self.states[name]
        if accepting:
            self.accepting_states[self.states[name]] = True
        return 0
    
    # deletes state with given name (and transitions including it)
    @Slot(str)
    def delete_state(self, del_name):
        del_state = self.states[del_name]
        # delete transitions to & from the state
        for name, state in self.states.items():
            if name != del_name:
                transitions_to_delete = []
                for symbol, dst in state.delta.items():
                    if dst == del_state:
                        transitions_to_delete.append(symbol)
                for symbol in transitions_to_delete:
                    del state.delta[symbol]

        # delete the state itself
        if del_state in self.accepting_states:
            del self.accepting_states[del_state]
        if self.start_state == del_state:
            self.start_state = None
        del del_state

    # deletes transition with given state names and symbol
    @Slot(str, str, str)
    def delete_transition(self, src, symbol, dst):
        from_state = self.states[src]
        to_state = self.states[dst]
        for sym, dest in from_state.delta.items():
            if dest == to_state:
                del from_state.delta[symbol]
                return
    
    # returns the name of the start state
    @Slot(result=str)
    def get_start_state(self) -> str:
        if not self.start_state:
            return ""
        
        for name, state in self.states.items():
            if state == self.start_state:
                return name
            
    # returns the name of the state to transtition to based off the current state and read symbol
    # empty return string signifies an error
    @Slot(str, str, result=str)
    def take_step(self, current_state_name, symbol) -> str:
        if current_state_name not in self.states or symbol not in self.alphabet:
            return ""

        current_state = self.states[current_state_name]
        if symbol not in current_state.delta:
            return ""
        
        next_state = current_state.delta[symbol]

        for name, state in self.states.items():
            if state == next_state:
                return name
        return ""
