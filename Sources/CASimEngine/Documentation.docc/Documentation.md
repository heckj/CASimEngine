# ``CASimEngine``

An engine to run cellular automata simulations over a collection of voxels.

## Overview

The library provides the structure drive a cellular automata simulation in 3-dimensions using voxels.
The library provides a structure for rules, which you add to a simulation to run. The engine provides a 
computed property, ``CASimEngine/CASimEngine/voxels``, to access the results as you increment the simulation.
The simulation can be incremented either synchronously with ``CASimEngine/tick(deltaTime:)-4dohs`` or asynchronously with ``CASimEngine/tick(deltaTime:)-xlyj``.

## Topics

### Creating a Simulation Engine

- ``CASimEngine``

### Writing Simulation Rules

- ``CASimRule``
- ``CAResult``
- ``CARuleProcessingScope``

### Testing Rules

- ``CADiagnostic``
- ``CADetailedDiagnostic``