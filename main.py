import sys
from pathlib import Path
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtCore import QObject, Slot, Property, Signal
from dfa import DFA, State

if __name__ == "__main__":
    app = QGuiApplication(sys.argv)
    engine = QQmlApplicationEngine()

    # Create and expose the backend object
    dfa = DFA()
    engine.rootContext().setContextProperty("dfaBackend", dfa)

    # Load QML file
    qml_file = Path(__file__).resolve().parent / "main.qml"
    engine.load(qml_file)

    if not engine.rootObjects():
        print("Error: Could not load QML.")
        sys.exit(-1)

    sys.exit(app.exec())
