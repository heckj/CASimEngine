# ``CASimEngine``

An engine to run cellular automata simulations in 3D space.

## Overview

The library provides an engine to run a cellular automata simulation in 3-dimensions.
In using the library, you provide types that represent a set of rules and a storage structure to hold the simulation state.
The storage engine protocol, `CASimulationStorage`, allows you to structure the underlying data efficiently
as well as export the resulting state to a `VoxelArray` for visualization or further processing.

Use ``CASimulationEngine/changes()`` to get a list of the changed values.

Call ``CASimulationEngine/tick(deltaTime:)`` to increment the simulation.

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
