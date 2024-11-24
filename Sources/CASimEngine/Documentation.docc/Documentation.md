# ``CASimEngine``

An engine to run cellular automata simulations over a collection of voxels.

## Overview

The library provides the structure drive a cellular automata simulation in 3-dimensions using voxels.
The library provides a structure for rules, which you add to a simulation to run. The engine provides a 
computed property, ``CASimulationEngine/current`` that exposes the current state of the system.
Use ``CASimulationEngine/changes()`` to get a list of the changed values.

Call ``CASimulationEngine/tick(deltaTime:)`` to increment the simulation.

## Topics

### Creating a Simulation Engine

- ``CASimulationEngine``
- ``CASimulationStorage``

### Writing Simulation Rules

- ``CASimulationRule``
- ``CARuleScope``
- ``CARuleResult``

### Receiving Diagnostics from Rules

- ``CADiagnostic``
- ``CADetailedDiagnostic``
