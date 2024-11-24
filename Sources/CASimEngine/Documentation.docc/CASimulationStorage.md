# ``CASimulationStorage``


The simulation engine (``CASimEngine``) stores two copies of a type conforming to `CASimulationStorage` to provide a "struct of arrays" data structure for speedy implementations.
During operation, the engine processes the simulation rules using ``CASimulationEngine/tick(deltaTime:)``.
When the engine finishes executing the rules, it swaps the two storage buffers.

The type providing a storage container provides an initializer to set up the storage from a `VoxelArray`, from which it gets its ``bounds``.
The type also provides a regeneration of the `VoxelArray` from its internal state using ``current``.

To support a default implementation of `current`, the type defines ``uninitializedDefault`` which is used to create the array.

## Topics

### Creating Storage

- ``init(_:)``
- ``T``

### Inspecting Storage

- ``bounds``
- ``uninitializedDefault``

### Retrieving Updates

- ``CASimulationStorage/voxelAt(_:)``
- ``CASimulationStorage/current``
