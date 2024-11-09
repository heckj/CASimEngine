# ``CASimEngine``

An engine to run cellular automata simulations over a collection of voxels.

## Overview

The library provides the structure drive a cellular automata simulation in 3-dimensions using voxels.
The library provides a structure for rules, which you add to a simulation to run. The engine provides a 
computed property, ``CASimEngine/CASimEngine/voxels``, to access the results as you increment the simulation.
Call ``CASimEngine/tick(deltaTime:)`` to increment the simulation.

## Topics

### Creating a Simulation Engine

- ``CASimEngine``

### Writing Simulation Rules

- ``CASimulationRule``
- ``CARuleScope``
- ``CARuleResult``

### Diagnostics

- ``CADiagnostic``
- ``CADetailedDiagnostic``
