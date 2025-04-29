# DFA Visualizer

This project provides a graphical interface for building, testing, and viewing DFAs. Particular emphasis is paid to visualizing transitions, that is, graphically observing the path through a DFA taken on given input strings.

## Installation and Usage

No installation is required, though some [dependencies](#dependencies) may require installation. The project is self-contained to the `visualizer` folder, which may be arbitrarily moved or renamed.

The visualizer may be run by opening (on Windows) or running (on *nix) `visualizer/visualize.py` from any working directory. No command-line arguments are required or acknowledged.

## Platforms

Any major operating systems with graphics support should be able to run this project. In particular, Windows, Ubuntu, and MacOS have been tested and confirmed working.

## Dependencies

#### Python
Python version ≥3.8 is require per `PySide6` requirements. Tested on 3.9, 3.12, and 3.13.

#### PySide6

The graphical backend is `PySide6`, a Python module wrapping the Qt Framework, as its graphical backend. Installation instructions may be found at the [Qt for Python documentation](https://doc.qt.io/qtforpython-6/gettingstarted.html). Use of a virtual environment is recomended.
