# ``CASimulationRule``

## Overview

The simulation engine (``CASimEngine``) processes the rules in the order you provide them on each iteration of ``CASimulationEngine/tick(deltaTime:)``.
During the processing, the first storage buffer represents the current state of the simulation, and
the second storage buffer is where you should write the updated state. 
At the end of the sequence of rules, the engine swaps the two storage buffers, incrementing the simulation.

There engine supports two kinds of rules, `eval` and `swap`. 
The first, ``CASimulationRule/eval(name:scope:_:)`` provides a rule that evaluates a set of cells within the simulation.
Eval rules conform to ``EvaluateStep``, providing the function ``EvaluateStep/evaluate(cell:deltaTime:storage0:storage1:)`` to do the evaluation.

The second, ``CASimulationRule/swap(name:_:)`` provides a way to swap all or some of the storage between the two systems. 
The `swap` rule supports iterating over a subset of values within the larger scope of the rules. 
For example, in a fluid simulation, you can solve divergent pressure values using an iterative relaxation algorithm.    


## Topics

### Defining Simulation Rules

- ``CASimulationRule/eval(name:scope:_:)``
- ``EvaluateStep``

- ``CASimulationRule/swap(name:_:)``
- ``SwapStep``
