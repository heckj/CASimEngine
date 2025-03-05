# ``CASimEngine``

An engine to run cellular automata simulations in 3D space.

## Overview

The library provides an engine to run a cellular automata simulation in 3-dimensions.
In using the library, you provide types that represent a set of rules and a storage structure to hold the simulation state.
Implement your own storage for the simulation, conforming to `CASimulationStorage`, and establish rules, conforming to `CASimulationRule`.
The protocol `CASimulationStorage` supports representing the cells of the 3D space as voxels in a `VoxelArray`, allowing you to export a subset of the simulation state for visualization or analysis.

The general flow of using this library:

- Use ``CASimulationEngine/init(_:rules:)`` to initialize a simulation with a seed and a set of rules.
- Call ``CASimulationEngine/tick(deltaTime:)`` to increment the simulation, which invokes the rules in the order you provided.
- Use ``CASimulationEngine/changes()`` to get a list of the cells with changed values after incrementing the simulation, or ``CASimulationEngine/current`` to get the current state of the simulation.

## Topics

### Creating a Simulation Engine

- ``CASimulationEngine``
- ``CASimulationStorage``

### Writing Simulation Rules

- ``CASimulationRule``
- ``CAIndex``
- ``CARuleScope``
- ``CARuleResult``

### Receiving Diagnostics from Rules

- ``CADiagnostic``
- ``CADetailedDiagnostic``
