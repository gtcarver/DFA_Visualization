## Class for each state in DFA
class State:
    _id_ = 0 # giving each state a unique id

    def __init__(self, name, delta=None, is_start=False, is_accept=False):
        self.name = name # string for state label
        self.is_start = is_start # boolean for if state is a start state
        self.is_accept = is_accept # boolean for if state is an accept state
        self.id = State._id_ # assign unique id
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
    
    # printing
    def __repr__(self):
        transitions_str = ", ".join(
            f"({self.name}, '{a}') -> {self.delta[a].name}"
            for a in self.delta
        )
        return f"State('{self.name}', Start state: {self.is_start}, Accept state: {self.is_accept}, Transitions: [{transitions_str}])"

# Class for the DFA as a whole
class DFA:
    def __init__(self, name, states=None, alphabet=None):
        self.name = name # string for DFA name
        self.states = states if states is not None else [] # list of state objects in DFA
        self.alphabet = alphabet if states is not None else [] # list of strings representing each symbol in the alphabet

    def __repr__(self):
        states_str = ", ".join(state.name for state in self.states)
        alphabet_str = ", ".join(self.alphabet)
        return f"DFA('{self.name}', States: [{states_str}], Alphabet: [{alphabet_str}])"

    # Determines if dfa has a valid construction
    # Returns a tuple (b, e), where b is a boolean for validity, and e is a string explaining the result b
    def is_valid(self):
        # Check to ensure there is exactly 1 start state and no state shares a name with another
        found_start = False
        state_names = []
        for state in self.states:
            if state.is_start == True:
                if found_start:
                    return (False, "Invalid DFA. More than one start state.")
                found_start = True

            if state.name in state_names:
                return (False, "Invalid DFA. States cannot share a name.")
            state_names.append(state.name)

        if not found_start:
            return (False, "Invalid DFA. No start states found.")
        
        # Check to ensure for every state q and every symbol a in the alphabet, there is exactly one defined transition
        # Also check to ensure every transition is in the alphabet (Q x Sigma -> Q)
        # Currently thinking making multiple arrows with the same transitiion value should be handled in the visualizer,
        # because a key will simply be overwritten before this validation check is ran, creating a ghost transition arrow
        for state in self.states:
            for symbol in self.alphabet:
                if symbol not in state.delta:
                    return (False, f"Invalid DFA. ({state.name}, {symbol}) does not have a defined transition.")
                if state.delta[symbol] not in self.states:
                    return (False, f"Invalid DFA. \u03b4({state.name}, {symbol}) -> {state.delta[symbol].name} is not in the set of states.")
            # Ensuring each transition is in the alphabet
            for symbol in state.delta:
                if symbol not in self.alphabet:
                    return (False, f"{state.name} has a transition on '{symbol}', but '{symbol}' is not in the alphabet.")

        return (True, "Valid DFA.")

    # Checks whether a given string is accepted by the machine
    # Returns a boolean representing if the string is accepted
    # Automatically returns False if the machine is not a valid DFA,
    def accepts(self, string):
        # First confirm machine is valid
        if not self.is_valid()[0]:
            return False
            
        # Find start state
        current_state = None
        for state in self.states:
            if state.is_start:
                current_state = state
                break

        # Transition from state to state following the symbols in the string and the transition function
        for symbol in string:
            # Confirm symbol is in the alphabet
            if symbol not in self.alphabet:
                return False
            
            # Transition to next state
            current_state = current_state.delta[symbol]

        # After reading through string, return whether or not current state is an accept state
        return current_state.is_accept
        
    # Gives a step by step of the machine reading a string
    # User must hit enter to proceed through the simulation
    # Returns nothing
    def walkthrough(self, string):
        print(f"DFA {self.name} processessing string {string}:\n")
        # First confirm machine is valid
        input(f"Validating DFA {self.name}. Press enter to continue...")
        valid, explanation = self.is_valid()
        if not valid:
            print(explanation)
            print("Termininating.")
            return
        input(f"{explanation} Press enter to continue...")

        # Find start state
        current_state = None
        for state in self.states:
            if state.is_start:
                current_state = state
                break
        
        input(f"Start state is {current_state.name}. Press enter to continue...")
                
        # Transition from state to state following the symbols in the string and the transition function
        for symbol in string:
            print(f"\nCurrent state: {current_state.name}")
            print(f"Current read symbol: {symbol}")
            input("Press enter to continue...")
            # Confirm symbol is in the alphabet
            if symbol not in self.alphabet:
                print(f"Symbol '{symbol}' is not in the alphabet {self.alphabet}.")
                print(f"{string} is rejected by DFA {self.name}.")
                return
            
            # Transition to next state
            print(f"\u03b4({current_state.name}, '{symbol}') -> {current_state.delta[symbol].name}")
            input("Press enter to continue...")
            current_state = current_state.delta[symbol]

        # After reading through string, decide whether or not current state is an accept state
        print("No more symbols in string.")
        print(f"Machine ended on state {current_state.name}.")
        if current_state.is_accept:
            print(f"{current_state.name} is an accept state.")
            print(f"{string} is accepted by DFA {self.name}.")
            return
        
        print(f"{current_state.name} is not an accept state.")
        print(f"{string} is rejected by DFA {self.name}.")


q1 = State("q1", is_start=True)
q2 = State("q2", is_accept=True)
q3 = State("q3")

d1 = DFA("D_1", [q1,q2,q3], ['0','1'])

q1.delta['0'] = q1
q1.delta['1'] = q2
q2.delta['0'] = q3
q2.delta['1'] = q2
q3.delta['0'] = q2
q3.delta['1'] = q2

print(q1)
print(q2)
print(q3)
print()
print(d1)
print()
print("Is DFA valid? -> ", d1.is_valid())
print()

test_strings = ['1','01','11','0101010101','0','1','100','1000']
for s in test_strings:
    print("DFA " + d1.name + " accepts " + s + ":", d1.accepts(s))

print('\n')

d1.walkthrough("00101")
print('\n')
d1.walkthrough("1000")
print('\n')
d1.walkthrough("01a1")
