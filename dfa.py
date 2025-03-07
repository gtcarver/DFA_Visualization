## Class for each state in DFA
class State:
    _id_ = 0 # giving each state a unique id

    def __init__(self, name, is_start=False, is_accept=False):
        self.name = name # string for state label
        self.is_start = is_start # boolean for if state is a start state
        self.is_accept = is_accept # boolean for if state is an accept state
        self.id = State._id_ # assign unique id
        State._id_ += 1

    # used for checking equivalence of states
    def __eq__(self, other):
        return isinstance(other, State) and self.id == other.id

    # used to hash instances of states correctly for the transition function
    def __hash__(self):
        return hash(self.id)
    
    # printing
    def __repr__(self):
        return f"State('{self.name}')"

# Class for the DFA as a whole
class DFA:
    def __init__(self, name, states=[], alphabet=[], delta={}):
        self.name = name # string for DFA name
        self.states = states # list of state objects in DFA
        self.alphabet = alphabet # list of strings representing each symbol in the alphabet

        # dictionary for all state transitions
        # each key should be a tuple (q, a), where q is a state object, and a is a string
        # each value should be a state object
        self.delta = delta

    def __repr__(self):
        states_str = ", ".join(state.name for state in self.states)
        alphabet_str = ", ".join(self.alphabet)
        transitions_str = ", ".join(
            f"({s.name}, '{a}') -> {self.delta[(s, a)].name}"
            for s, a in self.delta
        )
        return f"DFA('{self.name}', States: [{states_str}], Alphabet: [{alphabet_str}], Transitions: {{{transitions_str}}})"

    # Determines if dfa has a valid construction
    # Returns a tuple (b, e), where b is a boolean for validity, and e is a string explaining the result b
    def is_valid(self):
        # Check to ensure there is exactly 1 start state and no state shares a name with another
        found_start = False
        states = []
        for state in self.states:
            if state.is_start == True:
                if found_start:
                    return (False, "Invalid DFA. More than one state.")
                found_start = True

            if state in states:
                return (False, "Invalid DFA. States cannot share a name.")
            states.append(state)

        if not found_start:
            return (False, "Invalid DFA. No start states found.")
        
        # Check to ensure for every state q and every symbol a in the alphabet, there is exactly one defined transition
        # Currently thinking making multiple arrows with the same transitiion value should be handled in the visualizer,
        # because a key will simply be overwritten before this validation check is ran, creating a ghost transition arrow
        for state in self.states:
            for symbol in self.alphabet:
                if (state, symbol) not in self.delta:
                    return (False, "Invalid DFA. (" + state.name + ", " + symbol + ") does not have a defined transition.")
                if self.delta[(state, symbol)] not in self.states:
                    return (False, "Invalid DFA. The state transition is not in the set of states.")

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
            current_state = self.delta[(current_state, symbol)]

        # After reading through string, return whether or not current state is an accept state
        return current_state.is_accept
        
    # Gives a step by step of the machine reading a string
    # User must hit enter to proceed through the simulation
    # Returns nothing
    def walkthrough(self, string):
        print("DFA " + self.name + " processessing string " + string + ":\n")
        # First confirm machine is valid
        input("Validating DFA " + self.name + ". Press enter to continue...")
        valid, explanation = self.is_valid()
        if not valid:
            print(explanation)
            print("Termininating.")
            return
        input(explanation + " Press enter to continue...")
        # Find start state
        current_state = None
        for state in self.states:
            if state.is_start:
                current_state = state
                break
        
        input("Start state is " + current_state.name + ". Press enter to continue...")
                
        # Transition from state to state following the symbols in the string and the transition function
        for symbol in string:
            print("\nCurrent state: " + current_state.name)
            print("Current read symbol: " + symbol)
            input("Press enter to continue...")
            # Confirm symbol is in the alphabet
            if symbol not in self.alphabet:
                print("Symbol", symbol, "is not in the alphabet " + str(self.alphabet) + ".")
                print(string, "is rejected.")
                return
            
            # Transition to next state
            print("\u03b4(" + current_state.name + ", " + symbol + ") -> " + self.delta[(current_state, symbol)].name)
            input("Press enter to continue...")
            current_state = self.delta[(current_state, symbol)]

        # After reading through string, decide whether or not current state is an accept state
        print("No more symbols in string.")
        print("Machine ended on state " + current_state.name + ".")
        if current_state.is_accept:
            print(current_state.name + " is an accept state.")
            print(string, "is accepted.")
            return
        
        print(current_state.name + " is not an accept state.")
        print(string, "is rejected.")


q1 = State("q1", is_start=True)
q2 = State("q2", is_accept=True)
q3 = State("q3")

d1 = DFA("D_1", [q1,q2,q3], ['0','1'])
d1.delta[(q1,'0')] = q1
d1.delta[(q1,'1')] = q2
d1.delta[(q2,'0')] = q3
d1.delta[(q2,'1')] = q2
d1.delta[(q3,'0')] = q2
d1.delta[(q3,'1')] = q2

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
