#!/usr/bin/env python3

import sys
from pathlib import Path
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine
from dfa import DFA

if __name__ == "__main__":
    app = QGuiApplication()
    engine = QQmlApplicationEngine()

    # Create and expose the backend object
    dfa = DFA()
    engine.rootContext().setContextProperty("dfaBackend", dfa)    

    # Load QML file
    qml_file = Path(__file__).resolve().parent / "qt.qml"
    engine.load(qml_file)

    if not engine.rootObjects():
        print("Error: Could not load QML.")
        sys.exit(-1)

    sys.exit(app.exec())
