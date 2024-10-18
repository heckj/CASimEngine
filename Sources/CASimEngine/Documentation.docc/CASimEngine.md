# ``CASimEngine/CASimEngine``

## Topics

### Creating a Simulation Engine

- ``init(_:rules:)``

### Running the simulation

- ``tick(deltaTime:)``
- ``tickSync(deltaTime:)``

### Accessing the simulation

- ``voxels``
- ``diagnosticStream``

### Testing Rules

- ``tick(deltaTime:rule:)``
- ``diagnosticEvaluate(deltaTime:rule:)``
