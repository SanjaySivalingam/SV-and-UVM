UVM Concepts

# SystemVerilog Event Queue

The SystemVerilog event queue refers to the simulator's scheduling mechanism, organizing events. It organizes events into regions within a time step, ensuring deterministic execution and preventing race conditions.

Simulation advances in discrete time steps (e.g., t=1ns). Each time step processes events across all regions before advancing.

## Regions

The event queue comprises 10 regions (Preponed, Active, Inactive, NBA, Observed, Reactive, Re-Inactive, Re-NBA, Re-Observed, Postponed), executed sequentially within a time step.

Events within a region are processed in an implementation-defined order, but region boundaries enforce determinism.

The queue iterates until all regions are empty before advancing time.

### Preponed

* Performs sampling for (signal values) assertions, (coverpoints) coverage, and PLI (Programming Language Interface) callbacks ($monitor) before active simulation events.
* Guarantees assertions see signal values before any changes in Active region, preventing race conditions in checks.

### Active

* Executes the core simulation logic, including combinational logic, blocking assignments, and synchronous processes (always block without delays #, @(), $display, $write (immediate o/p)).
* Updates DUT state based on current inputs, scheduling outputs for later regions.

### Inactive

* Holds events explicitly scheduled with #0 delays, allowing deferred execution within the same time step (race risks).
* Legacy region for fine-grained control; irrelevant for PISO's synchronous design.

### NBA (Non-Blocking Assignments)

* Applies non-blocking assignments scheduled in Active region, updating signals for the next time step or region (driver schedules for next cycle).
* Critical for synchronous designs, preventing races by delaying signal updates (clocking block output drives).

### Observed

* Samples clocking block inputs (eg. input #1step), capturing DUT outputs for testbench use (No procedural code).
* Prevents races by sampling DUT outputs after all DUT assignments settle.

### Reactive

* Executes testbench procedural code, including UVM components' runtime (run_phase, sequence body, drv/mon) behavior (blocking assignments in tb, @(outside cb)).
* Main region for UVM testbench activity, decoupled from DUT updates.

### Re-Inactive

* Handles #0 delays scheduled in Reactive region, allowing deferred testbench updates.
* Legacy region, irrelevant for PISO's disciplined timing.

### Re-NBA

* Applies non-blocking assignments scheduled in Reactive region.
* Supports testbench signal updates, but PISO relies on NBA for vif.

### Re-Observed

* Reserved for sampling in reactive clocking blocks (e.g., clocking blocks triggered by testbench events).

### Postponed

* Finalizes the time step with debug and logging activities (strobe, monitor outputs, PLI callbacks, final assertion evals).
* uvm_info/uvm_error messages queued in Reactive may finalize here.
* Provides stable signal values for logging, critical for debug.


# Virtual Interfaces, Functions and Classes

Virtual functions and classes in SystemVerilog enable polymorphism, allowing UVM components to customize behavior via inheritance, critical for extensibility.

## Virtual Interfaces

* They provide a handle to a physical interface (e.g., piso_if), allowing UVM components to access DUT signals without direct instantiation.
* A virtual pointer to an interface (e.g., virtual piso_if).
* Set via uvm_config_db from the top module.
* **Role** : Drivers use to drive signals (e.g., load). Monitors use to sample signals (e.g., data_out).
* **PISO Use** : Connects testbench to DUT clock, data_in, load, data_out.

## Virtual Function

* Declared with `virtual`, can be overridden in derived classes.
* Enables runtime polymorphism (e.g., do_copy adapts to derived type).
* Example: `do_copy` in uvm_object.
* **Why make do_copy virtual?**
  * It allows derived classes like piso_seq_item to customize copying, ensuring correct field handling for PISO transactions.

## Pure Virtual Function

* Declared pure virtual in a virtual class, must be implemented by derived classes.
* Forces implementation, ensuring consistency.
* Syntax: `pure virtual function void method();`
* Rare in UVM (most methods have defaults).

## Abstract Virtual Class

* Declared with `virtual class`, cannot be instantiated.
* Defines contracts for components (e.g., uvm_driver).
* Used for interfaces or base classes with pure virtual methods.
* **When to use abstract classes?**
  * For base classes needing specific methods, like a PISO protocol checker requiring verify.

## Additional Concepts

* **Virtual Task** : Like virtual function, but for time-consuming operations.
* **Polymorphism** : Base class handles derived objects.
* **Dynamic Binding** :
* Virtual calls resolve to derived class methods.
* Critical for UVM factory overrides.

## Best Practices

* Use `virtual` for extensible methods.
* Avoid pure virtual unless enforcing interfaces.
* Test polymorphism with derived classes.


# Universal Verification Components (UVCs)

A Universal Verification Component (UVC) is a reusable, protocol-specific verification module encapsulating driver, monitor, sequencer, and configuration for an interface.

## Components

* **Agent** : Contains driver, monitor, sequencer.
* **Config** : Parameters (e.g., active/passive).
* **Sequences** : Stimulus generators.

## Features

* Reusable across projects.
* Standardized interface (e.g., SPI, UART).

## Active/Passive

* **Active** : Drives DUT (PISO stimulus).
* **Passive** : Monitors only (protocol checking).

## Scalability

Multiple UVCs verify complex DUTs (e.g., PISO + SPI).

UVC: piso_agent + piso_seq_item + sequences + piso_config.

## FAQs

### What makes a UVC reusable?

Encapsulated components, config objects, and standardized sequences, allowing PISO verification in different SoCs.

### How does a UVC fit in a testbench?

It's instantiated in the env, like piso_agent in piso_env, providing modular verification for one interface.

## Best Practices

* Include config for flexibility.
* Support active/passive modes.
* Document UVC interfaces for reuse.


# UVM Phases

UVM Phases provide a structured execution flow for testbenches, ensuring components are initialized, connected, and run in a consistent order.

Phases are implemented as classes derived from `uvm_phase`, managed by `uvm_domain`.

Each phase is a state in the UVM simulation lifecycle (e.g., build, run).

## Execution

* Controlled by `uvm_root`, executed in a predefined order.
* Components override phase methods (e.g., `build_phase`) to define behavior.

## Build Phases (top-down)

* **build_phase** : Creates components and objects.
* **connect_phase** : Establishes TLM connections (e.g., ports).
* **end_of_elaboration_phase** : Finalizes setup (e.g., print topology). Called after all components are built and connected, before simulation starts.
* **start_of_simulation_phase** : Prepares for simulation (e.g., log settings).

## Run Phases (parallel)

* **run_phase** : Main simulation (e.g., driving transactions).
* **Sub-phases** (time-consuming, optional, useful for complex protocols):
  * reset_phase
  * configure_phase
  * main_phase
  * shutdown_phase

## Cleanup Phases (bottom-up)

* **extract_phase** : Collects results (e.g., coverage).
* **check_phase** : Verifies results (e.g., error counts).
* **report_phase** : Logs summary (e.g., pass/fail).
* **final_phase** : Closes simulation.

## Phase Order

* Top-down ensures parents build children.
* Parallel run_phase allows independent component execution.
* Bottom-up cleanup aggregates results.

## Implementation Details

* **Phase Object** : Each phase is an instance of `uvm_phase`, with methods like `exec_func` (for function phases) and `exec_task` (for task phases).
* **Customization** : Users override virtual methods (e.g., `virtual task run_phase`). Custom phases can be added but are rare.
* **Scheduling** : `uvm_domain` groups phases; default is `uvm_common_phases`. Parallel execution in `run_phase` for components.

## Types

* **Function Phases** : Non-time-consuming (e.g., `build_phase`).
* **Task Phases** : Time-consuming (e.g., `run_phase`).

## FAQs

### Why is build_phase top-down?

Parents must create children before they can be configured, ensuring the hierarchy is fully constructed.

### How are UVM phases implemented?

Phases are `uvm_phase` objects managed by `uvm_root`, executed in order like build, connect, run.
Components override methods like `build_phase` to define behavior, ensuring structured verification, such as setting up PISO's driver.

### Why separate build and connect phases?

Build creates components top-down, ensuring hierarchy exists; connect links ports afterward, like PISO monitor to scoreboard, preventing null pointer issues.


# UVM Objections

Objections in UVM control the duration of time-consuming phases (e.g., run_phase), ensuring simulation runs until all verification tasks complete (e.g., raise_objection in piso_test).

## Mechanism

* Components raise objections to keep a phase active.
* Phase ends when all objections are dropped.

## Methods

* **raise_objection** : Increments objection count.
* **drop_objection** : Decrements count.

## Scope

* Typically in run_phase or sub-phases.
* Managed by uvm_component via phase argument.

## Phase Control

Without objections, run_phase ends immediately. Multiple components can raise objections.

## Granularity

Use in main_phase for finer control (not needed for PISO).

## Debugging

uvm_objection::trace() logs objection activity.

## Starting Phase

**set_starting_phase(phase)** sets the phase in which a sequence's objections are managed (e.g., raising/dropping objections in run_phase).

It's typically used when a sequence needs to control objections explicitly, ensuring the phase doesn't end prematurely.

In our example, the test itself controls objections in run_phase.

set_starting_phase is relevant for sequences that:

* Run indefinitely (e.g., background stimulus).
* Use pre_start/post_start to manage phase state.

## FAQs

### What happens without drop_objection?

Simulation hangs, as the run_phase waits for all objections to clear.

### Why use objections in tests?

They ensure the test runs until verification completes, like driving all PISO sequences, preventing premature termination.

## Best Practices

* Raise objections before stimulus starts.
* Drop after all tasks complete.
* Log objection activity for complex testbenches.


# UVM Hierarchy

Components form a tree (e.g., test -> env -> agent), defining parent-child relationships for initialization, configuration, and reporting.

## Structure

* **Root** : uvm_root (implicit, manages phases).
* **Top Level** : uvm_test (e.g., piso_test).
* **Children** : uvm_env, uvm_agent, uvm_driver, etc.
* Parents create children in build_phase.
* Children inherit context (e.g., config_db scope).
* Methods like get_parent(), get_child() navigate the tree.

## FAQs

### Why is hierarchy important?

It organizes components, ensures top-down initialization, and scopes configurations, like setting PISO's interface in env.

### How do you debug hierarchy issues?

I use uvm_root::print_topology() to inspect the tree and check for missing or misplaced components.

### Why avoid self-creation in build_phase?

It risks recursive instantiation and violates UVM's hierarchical initialization, where parents build children in a top-down order.


# TLM Components

Transaction-Level Modeling (TLM) components in UVM enable communication between testbench components (e.g., monitor to scoreboard) using high-level transactions instead of pin-level signals, improving modularity and scalability.

## Component Types

### Port

* Initiates communication by sending transactions.
* Example: uvm_analysis_port for broadcasting.

### Imp (Implementation)

* Receives transactions, implementing methods like write.
* Example: uvm_analysis_imp in scoreboards.

### Export

* Connects ports to imps, acting as a bridge.
* Example: seq_item_export in sequencers.

### Others

* **Fifo** : Buffers transactions (uvm_tlm_fifo).
* **Analysis Port** : Broadcasts to multiple subscribers.
* **Get/Put Ports** : Support request-response (less common in PISO).

## In This Testbench

* **Port** : ap in piso_monitor sends piso_seq_item.
* **Imp** : ap in piso_scoreboard receives via write.
* **Connection** : connect_phase links them.

## Key Concepts

### Decoupling

TLM ports allow components to communicate without direct references, enhancing reusability.

### Non-Blocking

write in analysis ports ensures no stalls, critical for monitor performance.

### Fifo

Useful for buffering in complex testbenches, not needed for simple PISO.

## FAQs

### Why use TLM over direct method calls?

TLM decouples components, enabling one-to-many communication, like PISO monitor broadcasting to scoreboard and coverage, without modifying code.

## Best Practices

* Use uvm_analysis_port for monitors, uvm_analysis_imp for subscribers.
* Connect in connect_phase.
* Keep port names consistent (e.g., ap).


# TLM Methods

get, peek, put (and try variations) methods facilitate transaction passing between UVM components, typically used with uvm_tlm_fifo, uvm_get_port, or uvm_put_port, enabling blocking and non-blocking communication.

## Core Methods

### get

* Blocking, retrieves and removes a transaction from a FIFO/port.
* Syntax: `get(output T t)`.
* Waits until a transaction is available.

### try_get

* Non-blocking, attempts to retrieve a transaction.
* Syntax: `try_get(output T t)`; returns 1 if successful, 0 if empty.

### put

* Blocking, sends a transaction to a FIFO/port.
* Syntax: `put(input T t)`.
* Waits until the receiver accepts.

### try_put

* Non-blocking, attempts to send a transaction.
* Syntax: `try_put(input T t)`; returns 1 if accepted, 0 if full.

### peek

* Blocking, retrieves a transaction without removing it.
* Syntax: `peek(output T t)`.
* Waits until available.

### try_peek

* Non-blocking, attempts to peek.
* Syntax: `try_peek(output T t)`; returns 1 if successful, 0 if empty.

## Other Variations

* **can_get** : Checks if get would succeed (1 if available).
* **can_put** : Checks if put would succeed (1 if not full).
* **ok_to_put/ok_to_get** : Deprecated, use can_*.

## Usage Considerations

### Blocking vs. Non-Blocking

* get/put suit continuous processing (e.g., coverage).
* try_get/try_put suit polling or timeout scenarios.

## FAQs

### When to use try_get over get?

Use try_get for non-blocking checks, like polling PISO transactions in coverage without stalling, while get ensures waiting for data.

### How does put work in analysis_fifo?

The monitor's write calls put internally, adding transactions to the FIFO, decoupling PISO's monitor from subscribers.

## Best Practices

* Use get for guaranteed retrieval.
* Use try_get/try_put for timeout-sensitive logic.
* Check can_get before get in complex flows.


# UVM Analysis Port

The uvm_analysis_port broadcasts transactions to multiple subscribers (e.g., scoreboards, coverage collectors), supporting one-to-many communication in verification, without knowing their identities, decoupling the monitor from other components.

## Basic Components

### Analysis Port

* Type: `uvm_analysis_port #(T)` (e.g., piso_seq_item).
* Method: `write(T t)` sends transactions to all connected imps.

### Related Components

* **Analysis Export** : Connects to imps (`uvm_analysis_export`).
* **Analysis Fifo** : Buffers transactions (`uvm_tlm_analysis_fifo`).
* **Subscribers** : Classes implementing write (e.g., `uvm_subscriber`).

## Characteristics

### Blocking Ports

uvm_get_port, uvm_put_port for driver-sequencer (not analysis).

### Hierarchical Connections

Via uvm_component hierarchy.

### Broadcast

One port can connect to multiple imps, unlike sequencer-driver (one-to-one).

### Non-Blocking

write executes instantly, preventing monitor stalls.

## Implementation Details

### Fifo Use

uvm_tlm_analysis_fifo decouples timing if subscribers are slow, rare for PISO.

### Push Model

UVM favors push (write) for analysis to simplify monitors.

### Pull Model

uvm_get_port for driver-sequencer, not analysis.

## FAQs

### How does analysis port differ from get/put ports?

Analysis ports broadcast non-blocking to multiple subscribers, ideal for PISO monitoring; get/put are blocking for request-response, like driver-sequencer.

### Why no read in analysis ports?

Analysis ports are push-based for broadcasting, like PISO monitor sending transactions to subscribers, avoiding complex pull semantics.

### Why use analysis ports instead of direct calls?

Ports decouple components, allowing the monitor to send data to multiple subscribers without modifying its code, supporting reuse and flexibility.

## Best Practices

* Use analysis ports for all monitor outputs.
* Connect to subscribers in env.connect_phase.
* Avoid modifying transactions in write.
* Implement custom read only if essential.
* Avoid pull-based designs in analysis paths.


# UVM TLM Analysis FIFO

uvm_tlm_analysis_fifo buffers transactions between an analysis port and a subscriber, decoupling their execution to prevent stalls.

## Role

* Stores transactions from uvm_analysis_port until processed.
* Non-blocking for sender (e.g., monitor).

## Interface

* **write** : Adds transaction to FIFO.
* **get/peek** : Retrieves transactions for subscriber.

## Key Characteristics

### Decoupling

FIFO allows monitor to proceed without waiting for cov.

### Blocking Get

get waits for transactions, suitable for run_phase.

### Size

Default unlimited, configurable via new(size). Monitor's write blocks if FIFO is full.

## FAQs

### Why set FIFO size?

To control memory and introduce backpressure, ensuring PISO's coverage doesn't overwhelm simulation resources.

### What happens if FIFO is full?

put blocks, stalling the monitor, or try_put fails, so I size the FIFO based on expected transaction rates.

### When to use uvm_tlm_analysis_fifo?

When subscribers, like PISO coverage, are slower than monitors, to buffer transactions and prevent stalls, though direct ports suffice for simple designs.

### What's the advantage over direct connection?

It decouples timing, allowing PISO's monitor to run independently of coverage processing.

## Best Practices

* Use for heavy subscribers (e.g., complex coverage).
* Keep FIFO size reasonable (e.g., 100) based on transaction rates.
* Monitor FIFO fullness for debug with fifo.used().


# UVM Primary Operations

## Core Operations

* **Print** : Displays object contents (e.g., transaction fields) for debugging.
* **Copy** : Creates a duplicate of an object (deep or shallow).
* **Compare** : Checks if two objects have identical field values.
* **Pack** : Serializes an object into a bitstream (e.g., for transmission).
* **Unpack** : Deserializes a bitstream back into an object.
* **Record** : Logs object data to a database (e.g., for waveform viewers).

## Implementation in piso_seq_item

* **Print** : `txn.print()` outputs data_in and load in a formatted table.
* **Copy** : `txn.copy()` duplicates data_in and load.
* **Compare** : `txn.compare(other_txn)` checks if data_in and load match.
* **Pack/Unpack** : Rarely used in simple testbenches but could serialize data_in for cross-language interfaces.
* **Record** : Logs txn to a simulator database for waveform analysis.

## Customization Mechanism

Each operation has a default implementation but can be customized via virtual methods (do_print, do_copy, etc.).

Macros like `uvm_field_int` enable automation, while flags (e.g., `UVM_NOCOPY`) modify behavior.

The `do_*` methods are virtual functions in uvm_object that implement UVM operations. They can be overridden to customize behavior.

## FAQs

### How do UVM operations support debugging?

Operations like print and record provide visibility into transaction data, while compare helps identify mismatches in scoreboards, streamlining bug diagnosis.

### When would you avoid uvm_field macros?

For performance-critical classes or non-standard types, I'd override methods like do_copy manually to optimize behavior or handle custom data structures.

## Best Practices

* Call super.do_* to preserve base behavior.
* Use supporting objects (e.g., printer) for flexibility.


# UVM Reporting Macros

UVM provides `uvm_info`, `uvm_warning`, `uvm_error`, `uvm_fatal` to log messages during simulation, aiding debugging and verification tracking. `$sformatf` formats messages for clarity.

## Core Macros

* **`uvm_info(id, msg, verbosity)`** : Logs informational messages (e.g., transaction details).
* **`uvm_warning(id, msg)`** : Logs warnings (e.g., unexpected but non-critical conditions).
* **`uvm_error(id, msg)`** : Logs errors (e.g., verification failures).
* **`uvm_fatal(id, msg)`** : Logs critical errors and terminates simulation.

## Verbosity Levels (for uvm_info)

* **UVM_NONE** : Always displayed.
* **UVM_LOW** : Low detail (e.g., major events).
* **UVM_MEDIUM** : Moderate detail (e.g., transaction data).
* **UVM_HIGH** : High detail (e.g., internal states).
* **UVM_FULL** : All details.
* **UVM_DEBUG** : Debug-specific.

## Verbosity Control

* Set via simulator options or set_report_verbosity_level.
* Example: `+UVM_VERBOSITY=UVM_HIGH` shows UVM_HIGH and below.

## Message IDs

* Unique identifiers (e.g., "DRV", "SCB") categorize messages.
* Enable filtering: `set_report_id_verbosity("DRV", UVM_LOW)`.

## $sformatf

* Formats strings like sprintf (e.g., "%0d", "%b").
* Used in messages: `$sformatf("data_in=%4b", data_in)`.
* Supports formats: %d (decimal), %b (binary), %h (hex), %s (string).


# UVM Factory Macros

`uvm_object_utils` and `uvm_component_utils` register classes with the UVM factory, enabling creation and overrides, but they target different class types.

## uvm_object_utils

* For non-hierarchical classes (e.g., uvm_sequence_item, uvm_sequence).
* Registers piso_seq_item for factory creation.
* Syntax: `uvm_object_utils(class_name)`.

## uvm_component_utils

* For hierarchical components (e.g., uvm_driver, uvm_env).
* Registers piso_driver with parent-child support.
* Syntax: `uvm_component_utils(class_name)`.

## Key Differences

### Hierarchy

* `uvm_component_utils` includes parent argument, supports get_parent, topology.
* `uvm_object_utils` lacks hierarchy, used for transactions.

### Phases

* Components participate in phases (build_phase, run_phase).
* Objects don't (e.g., piso_seq_item is data).

### Factory

* Both enable type_id::create, but components need parent.


# UVM Object Creation

Constructors initialize UVM objects (uvm_object) or components (uvm_component). UVM provides two creation methods:

## new()

* Standard SystemVerilog constructor, directly instantiates an object.
* Syntax: `new(name, parent)` for components; `new(name)` for objects.
* Fixed type; no override possible.

## Factory (create)

* Uses `type_id::create` to instantiate objects via the UVM factory, supporting overrides.
* Allows runtime type overrides (e.g., replacing piso_seq_item with a derived class).
* Requires `uvm_*_utils` macros for registration.

## Constructor Behavior

* Constructor initializes basic properties (name, parent).
* Avoids heavy logic (e.g., object creation) to ensure phase-based initialization.
* Avoid creating objects or accessing config_db, as the hierarchy isn't fully built. Use build_phase for such tasks and for components.

## Hierarchy

* For components, parent sets the hierarchy (e.g., drv under env).
* Objects lack parents, using only name.


# UVM Config DB

`uvm_config_db` is a UVM mechanism for sharing configuration data (e.g., parameters, interfaces) across the testbench hierarchy.

It provides a centralized, hierarchical database to pass data without hard-coding or modifying class interfaces.

A key-value store where keys are strings (scope + field name) and values are typed objects (e.g., int, virtual interface).

## Example Use Case

Using `uvm_config_db` to set and get `num_txns` makes the sequence configurable from the test or environment, enhancing flexibility and reusability.

* **Set Operation** : The test or top module sets `num_txns` in the database, specifying a scope (e.g., sequence path).
* **Get Operation** : The sequence retrieves `num_txns` during its build phase, defaulting to a hardcoded value if not found.

## Syntax

### Set Method

```
uvm_config_db#(T)::set(cntxt, inst_name, field_name, value)
```

* **T** : Type (e.g., int, virtual interface).
* **cntxt** : Component context (e.g., this for current component, null for global).
* **inst_name** : Hierarchical path (e.g., "env.drv.*"). (supports wildcards *)
* **field_name** : Key (e.g., "vif").
* **value** : Data to store (e.g., intf).

### Get Method

```
uvm_config_db#(T)::get(cntxt, inst_name, field_name, value)
```

* Same arguments, but value is an output (populated if found).

## Scope Considerations

* `cntxt=null` makes set global; `cntxt=this` scopes to a component's hierarchy.
* get typically uses `this` for components, `null` for sequences.
* The set scope (e.g., "env.drv.sequencer.seq") must match or be a parent of the get scope (e.g., `get_full_name()`). Wildcards (*) allow broad access.
* If multiple set calls target the same field, the most specific scope wins.
* `get_full_name()` provides the sequence's hierarchical path, ensuring the correct value is fetched.
* If not found, `num_txns` retains its default (10).

## Usage Scenarios

### Global Configuration in TB Initial Block

```
uvm_config_db#(int)::set(null, "*", "num_txns", 20);
```

* `null`, "*" in TB is coarse, affecting all sequences.
* Suitable for global defaults (e.g., simulation-wide settings).
* Less flexible; all tests use the same num_txns.

### Test-Specific Configuration

```
uvm_config_db#(int)::set(this, "env.agt.seqr.seq", "num_txns", 20);
```

* "env.agt.seqr.seq" in test targets a specific sequence or wildcard.
* Allows test-specific configuration (e.g., 20 for one test, 50 for another).
* More granular control, better for regressions.

## FAQs

### How does config_db resolve scope conflicts?

It uses the most specific matching scope. For example, a set to env.drv.seq overrides a set to env.* for the sequence's get call.

### How do you debug a config_db failure?

* Check the scope string for typos
* Verify the set/get types match
* Log the get result to confirm the value was retrieved
* Use uvm_info or simulator debug tools to trace get failures


# SystemVerilog $cast() Function

## Basic Usage

* **Syntax** : `$cast(dest, source)`
* Checks if source is compatible with dest's type
* Fails if rhs isn't a piso_seq_item or derived class

## Cast Types

### Dynamic Cast

```systemverilog
$cast(tmp, rhs); // Used in do_copy, checks at runtime
```

### Static Cast (rare)

```systemverilog
tmp = piso_seq_item'(rhs); // No runtime check; risks errors if type mismatches (compile time check only)
```

### Try-Cast

```systemverilog
if (!$cast(tmp, rhs)) `uvm_fatal("CAST", "Invalid type") //Explicit error handling (to log and recover gracefully)
```

## Forbidden Rules for $cast

* **Type Mismatch** : Can't cast unrelated classes (e.g., piso_seq_item to uvm_driver)
* **Null Source** : Casting null is safe but results in null dest
* **Upcasting Restrictions** : Can't cast to a parent unless guaranteed (use dynamic_cast for safety)
* **Simulation Crash** : Avoid in critical paths without error handling

## Best Practices

* Always cast after super.do_copy
* Check null for nested objects
* Test do_copy with complex transactions


# Coverage in UVM

Coverage in UVM measures the extent to which a design's functionality has been exercised, ensuring verification goals (e.g., testing all input combinations) are met.

## Types of Coverage

* **Functional Coverage** : Tracks user-defined scenarios (e.g., data_in=0, load=1) using covergroups and coverpoints.
* **Code Coverage** : Measures RTL execution (e.g., lines executed), handled by simulators (not UVM).

Covergroups in SystemVerilog/UVM measure functional coverage by tracking whether specified scenarios (e.g., signal values, transitions) are exercised, ensuring verification completeness.

## Components

### Covergroup

Defines a set of coverage points.

### Coverpoint

Tracks values of a variable (e.g., data_in).

### Bins

Subdivide values (e.g., 0, 15, [1:14]).

* **Explicit** : `bins zeros = {0}`
* **Ranges** : `bins others = {[1:14]}`
* **Transitions** : `bins trans_0_to_15 = (0 => 15)` tracks sequences
* **Default** : Catches unlisted values, ignored in coverage if specified

### Cross

Combines multiple coverpoints (e.g., data_in x load).

* Generates bins for all combinations unless filtered (e.g., binsof)
* **How do you manage cross bin explosion?**
  * I limit crosses to critical signals and use binsof to filter irrelevant combinations, like only load=1 with data_in=0.

### Options

Control behavior (e.g., weight, goal).

* **weight** : Adjusts coverage contribution
* **goal** : Sets target coverage (e.g., 100%)
* **at_least** : Minimum hits per bin

## Implementation

* **Sampling** : Triggered by sample() or @(event)
* Typically implemented in monitors or subscribers to sample DUT transactions
* Use uvm_subscriber for dedicated coverage collection

## FAQs

### How do you use coverage in UVM?

I define covergroups in monitors to sample transactions, with coverpoints for inputs and outputs, and crosses for combinations. I analyze reports to add tests for uncovered bins.

### What if coverage is stuck at 90%? (closing coverage gaps)

I'd analyze the report, identify missing bins, and modify sequences or add directed tests to hit them, verifying with regressions.

## Labelling Coverpoints

Labelling coverpoints assigns meaningful names to variables or expressions in covergroups, enhancing coverage report readability and mapping to design intent.

* **Syntax** : `name: coverpoint expr { ... }`
* **Benefit** : Labels like load clarify reports (e.g., load.load_on vs. txn.load)
* **Report** : Shows load.load_on, data_in.zeros

## Best Practices

* Always label coverpoints and crosses
* Use signal names (e.g., data_in)
* Verify labels in coverage reports


# UVM Subscriber

A UVM subscriber is a UVM component that receives transactions via an analysis port, typically for coverage collection or passive analysis.

The connect_phase establishes TLM connections, including monitor-to-subscriber via an agent.

## Structure

* **Base Class** : Extends uvm_component, includes uvm_analysis_export
* **Method** : Implements write to process transactions
* **Passive Role** : Subscribers don't drive DUT, ideal for analysis
* **Scalability** : Multiple subscribers per port (e.g., coverage, logger)

## Implementation

### Subscriber

* Extends uvm_component, includes uvm_analysis_export
* Implements write for transaction processing (e.g., coverage)

### Connect Phase

* Links ports to exports/imps (e.g., mon.ap to cov.analysis_export)
* Executes top-down after build_phase

### Agent Role

* Groups monitor, driver, sequencer
* Monitor's analysis port connects to external subscribers

## Analysis Export

The uvm_analysis_export in uvm_subscriber connects an external analysis port (e.g., from piso_monitor) to the subscriber's write method.

### analysis_export

* Part of uvm_subscriber, exposes write to external ports
* Type: uvm_analysis_export #(T)
* Declares `uvm_analysis_export #(T) analysis_export`
* Internally connects to uvm_analysis_imp #(T, this), which calls write
* analysis_export is instantiated in new
* Routes transactions to write(T t)

### Connection

* `mon.ap.connect(cov.analysis_export)` routes transactions to cov.write

### Why Not Direct Imp?

* uvm_subscriber encapsulates uvm_analysis_imp, simplifying reuse
* analysis_export is standard for subscribers

### Design Benefits

* **Encapsulation** : uvm_subscriber hides uvm_analysis_imp, reducing user code
* **Flexibility** : analysis_export supports multiple connections (e.g., FIFO, direct)

## FAQs

### Why use uvm_subscriber over uvm_scoreboard?

Subscribers are lightweight for tasks like PISO coverage, while scoreboards handle active checking, like verifying data_out.

### Why place subscriber outside agent?

To keep agents protocol-specific; subscribers like coverage are testbench-wide, connected in env for flexibility.

### Why analysis_export in subscriber?

It connects the monitor's analysis port to the subscriber's write, like PISO's coverage, abstracting the TLM implementation for simplicity and reuse.

### How does analysis_export work in subscriber?

It's a TLM export in uvm_subscriber, connecting the monitor's analysis port to the write method, routing PISO transactions to coverage seamlessly.

### Could you use analysis_imp directly?

Yes, but uvm_subscriber's analysis_export is preferred for standard tasks like PISO coverage, reducing boilerplate.

## Best Practices

* Use for coverage or logging, not checking
* Place subscribers in env, not agent
* Keep write simple to avoid delays
* Verify connections with uvm_root::print_topology()
* Connect analysis_export in env.connect_phase


# UVM Agent

A UVM agent encapsulates verification components (driver, monitor, sequencer) for a specific DUT interface, providing modularity and reusability in testbenches.

## Components

* **Driver** : Drives transactions to DUT pins
* **Monitor** : Observes DUT signals and creates transactions
* **Sequencer** : Manages sequence execution

## Configuration

* **is_active** : UVM_ACTIVE (includes driver, sequencer) or UVM_PASSIVE (monitor only)

## Role

* Groups protocol-specific logic (e.g., PISO signals)
* Enables parallel verification of multiple interfaces (e.g., in an SoC)

## FAQs

### Why use an agent?

It encapsulates driver, monitor, and sequencer for one interface, making the testbench modular and reusable, like for a PISO in different SoCs.

### When do you use UVM_PASSIVE?

For verification without stimulus, like monitoring a DUT's output in a system-level test.

### How do agents support complex DUTs?

Each agent handles one interface, running in parallel, so I can verify a PISO and SPI independently in the same testbench.

### How does connect_phase work with agents?

It links TLM ports, like PISO monitor's analysis port to a subscriber's export in env, ensuring transactions flow correctly within the agent hierarchy.


# UVM Sequencer

The UVM sequencer (uvm_sequencer) manages the execution of sequences, arbitrating between multiple sequences and delivering transactions to the driver in a controlled manner.

The seqr is the uvm_sequencer#(piso_seq_item) instantiated in piso_agent.

## Hierarchy

* piso_test creates env (piso_env)
* env creates agt (piso_agent)
* agt creates seqr

## Role

* Acts as a transaction router between sequences and driver
* Handles sequence arbitration (e.g., priority, FIFO)
* Supports randomization and backpressure

## Components

* **seq_item_export** : TLM port for driver connection
* **Sequence Queue** : Stores active sequences
* **Arbitration Mode** : Controls order (e.g., UVM_SEQ_ARB_FIFO)
* Modes: UVM_SEQ_ARB_FIFO (default), UVM_SEQ_ARB_RANDOM, UVM_SEQ_ARB_STRICT_FIFO
* Example: `seqr.set_arbitration(UVM_SEQ_ARB_RANDOM)`
* **Why change arbitration mode?**
  * To prioritize sequences, like ensuring a PISO reset sequence runs first in strict mode

## Backpressure

* Driver controls flow via item_done, pausing sequence if DUT is slow
* **How does sequencer handle driver delays?**
  * It waits for item_done, allowing the driver to throttle stimulus, ensuring PISO signals are driven correctly

## Layered Sequencers

For complex protocols, stack sequencers (e.g., transaction to packet)

## Sequence Control

### start_item/finish_item

UVM sequence macros/methods that manage sequence item execution on a sequencer.

* **start_item(req)** :
* Requests sequencer arbitration for req (e.g., piso_seq_item)
* Randomizes req (if not already done)
* Waits for sequencer approval (handles priority, locks)
* Prepares req for driver consumption
* **finish_item(req)** :
* Sends req to the driver via the sequencer's seq_item_port
* Waits for the driver to call item_done() (indicating completion)
* Completes the transaction, releasing sequencer resources

### Sequence Operation

A sequence is a uvm_object that generates stimulus by creating piso_seq_item transactions.
It runs on a sequencer (uvm_sequencer#(piso_seq_item)), which arbitrates between sequences and forwards items to the driver.

Steps:

1. Sequence's body task creates a req (e.g., piso_seq_item)
2. start_item(req) gains sequencer access and randomizes req
3. finish_item(req) sends req to the driver, waits for completion
4. Driver applies req fields (e.g., req.load, req.data_in) to the DUT
5. Sequence repeats or ends, dropping objections if needed

## UVM Do Macros

The uvm_do macros simplify sequence execution by combining transaction creation, randomization, and sequencer interaction, streamlining stimulus generation.

### uvm_do

* Creates, randomizes, and sends a transaction
* Syntax: `uvm_do(item|req)` expands to:

```systemverilog
req = piso_seq_item::type_id::create("req");
start_item(req);
req.randomize();
finish_item(req);
```

### uvm_do_with

* Like uvm_do, but adds inline constraints
* Syntax: `uvm_do_with(item, { constraints })`

### Others

* **uvm_do_pri** : Sets sequence priority. e.g., `uvm_do_pri(req, 100)`
* **uvm_do_on** : Specifies sequencer. e.g., `uvm_do_on(req, p_sequencer)`
* **uvm_do_pri_with** : Combines priority and constraints. e.g., `uvm_do_pri_with(req, 100, { load == 1; data_in == 4'b0101; })`

### Characteristics

* **Convenience** : Macros reduce boilerplate, but explicit start_item offers more control
* **Constraints** : uvm_do_with overrides default randomization, critical for directed PISO tests
* **Arbitration** : Priority in uvm_do_pri resolves sequence conflicts

## FAQs

### Why use uvm_do_with over uvm_do?

uvm_do_with adds inline constraints, like forcing load=1 in PISO, enabling precise stimulus without modifying the sequence item.

### When to avoid uvm_do?

For complex sequences needing custom randomization or timing, I use explicit start_item and finish_item.

### What's the difference between start_item and uvm_do?

start_item is explicit, giving control over randomization; uvm_do is a shorthand that creates, randomizes, and sends in one step.

### What's p_sequencer used for?

p_sequencer is a typed handle to a sequencer, like piso_sequencer, letting a sequence access custom fields, unlike the generic m_sequencer. For PISO, I'd use it to toggle debug modes, but the default sequencer suffices for simple stimulus.

## Interactions

### Sequence Interaction

* **start_item** : Requests sequencer access, randomizes req
* **finish_item** : Sends req to driver, waits for item_done

### Driver Interaction

* **get_next_item** : Retrieves transaction
* **item_done** : Signals completion

## Best Practices

* Connect sequencer to driver in connect_phase
* Use default arbitration unless specific needs arise
* Debug sequence stalls with sequencer logs


# UVM Virtual Sequences and Sequencers

## UVM Virtual Sequencer

A uvm_sequencer that doesn't generate sequence items itself but acts as a container to reference and control other sequencers.
It's a central hub for coordinating stimulus across multiple agents.

A virtual sequencer is a UVM component (extends uvm_sequencer) that coordinates multiple sequences across different sequencers
without directly driving a DUT interface. It acts as a central controller, delegating sequence execution to "real" sequencers
(e.g., those connected to drivers) for multiple agents or DUT interfaces.

### Key Features

* **Multi-Agent Coordination** : In complex testbenches with multiple agents, a virtual sequencer synchronizes sequences across them.
* **Abstraction** :
* Simplifies test scenarios by managing high-level sequence flows, avoiding direct manipulation of individual sequencers.
* Simplifies testbench hierarchy by providing a single point to start sequences that target multiple DUT interfaces.
* **Reusability** : Enables reusable virtual sequences that can target different sequencers without modifying test code.
* Avoids direct coupling between agents, improving modularity.

### Implementation Details

* Contains handles to "leaf" (target) sequencers.
* Does not connect to a driver (unlike regular sequencers).
* Executes virtual sequences that start sub-sequences on target sequencers.
* **Structure** : A class extending uvm_sequencer, with pointers to other sequencers set via uvm_config_db or direct assignment.
* **Role in Testbench** : Added to the environment, connected to agent sequencers during connect_phase.
* **Usage** : Runs virtual sequences that orchestrate lower-level sequences (e.g., reset, data transfer).

## Virtual Sequence

A virtual sequence is a UVM sequence (extends uvm_sequence) that runs on a virtual sequencer and coordinates sub-sequences on multiple target sequencers.
It defines high-level test scenarios without generating transactions itself.

### Key Features

* **Scenario Control** :
* Combines sequences (e.g., reset followed by data shifts) across multiple agents into a single test case.
* Models high-level test scenarios involving multiple DUTs or protocols (e.g., PISO loading data).
* **Flexibility** : Allows complex, multi-agent test scenarios (e.g., simultaneous PISO load and shift) without modifying agent-level sequences.
* **Test Simplification** : Encapsulates test logic, making tests cleaner and more modular.
* Enhances reusability by combining existing sequences into new test cases.

### Implementation Details

* Uses the virtual sequencer's handles to access leaf sequencers.
* Calls `start()` on sub-sequences, passing the target sequencer (e.g., `seq.start(p_sequencer.seqr)`).
* Can include fork...join for concurrent execution or synchronization logic (e.g., delays, conditions) to align operations across DUTs.
* **Structure** : A sequence with a body() task that calls start() on sub-sequences.
* **Execution** : Runs on the virtual sequencer, delegating to agent sequencers.
* **PISO Context** : Could coordinate a reset sequence followed by a data load/shift sequence.

## Summary

* The **virtual sequencer** is the hub, holding references to agent sequencers.
* The **virtual sequence** is the script, running on the virtual sequencer and directing which sequences run on which agent sequencers.
* In a test, you instantiate a virtual sequence, set its p_sequencer, and start it on the virtual sequencer, which then triggers sub-sequences.


# UVM Factory Type Overrides

The UVM factory allows dynamic type substitution, enabling tests to replace classes (e.g., piso_seq_item) with derived classes without modifying the testbench.

## Mechanism

* Classes register with uvm_object_utils/uvm_component_utils
* type_id::create queries the factory for the actual type
* Overrides redirect creation (e.g., piso_seq_item to extended_seq_item)

## Types of Overrides

### Type Override

* A type override globally replaces all instances of a base class with a derived class across the entire testbench, regardless of where they're instantiated.
* All piso_seq_item creations become extended_seq_item.
* **Syntax** :

```systemverilog
  base_class::type_id::set_type_override(derived_class::get_type());
```

* **Deprecated syntax** :

```systemverilog
  uvm_factory::set_type_override_by_type(base_class::get_type(), derived_class::get_type());
```

### Instance Override

* An instance override replaces a base class with a derived class only for specific instances matching a given hierarchical path.
* Only sequence items under env.agt.seqr are overridden.
* **Syntax** :

```systemverilog
  base_class::type_id::set_inst_override(derived_class::get_type(), "path");
```

* **Deprecated syntax** :

```systemverilog
  uvm_factory::set_inst_override_by_type(base_class::get_type(), derived_class::get_type(), "path");
```

### Key Difference

Type overrides are global; instance overrides are path-specific.

## Factory Role

* Classes register with uvm_object_utils/uvm_component_utils
* type_id::create queries factory for actual type

## Priority

Instance overrides take precedence over type overrides.

## Debugging

Use uvm_factory::print() to verify overrides.

## Best Practices

* Apply overrides in build_phase
* Use instance overrides for targeted changes
* Verify overrides with uvm_factory::print()


# Copying Objects in UVM

Copying objects is essential in UVM for passing transactions (e.g., from monitor to scoreboard) without modifying the original.

`copy()` copies the field values from a source object to an existing target object, typically performing a deep copy by default.

It does not allocate a new object; the target must already exist.

## Shallow Copy

A shallow copy duplicates an object's immediate fields (scalars, strings, handles) but does not clone nested objects referenced by handles.

The copy shares references to the same nested objects, so modifying a nested object in the copy affects the original.

Use it when objects only have scalars or when nested objects are immutable. Faster and saves memory.

### Mechanics

* Performed by the `copy()` method, which calls `do_copy()` (user-overridable)
* For a UVM object (e.g., extending uvm_object), `do_copy()` assigns fields directly
* Handles to nested uvm_object or uvm_component instances are copied as references, not new instances

## Deep Copy (default for uvm factory types)

A deep copy duplicates an object and all its nested objects recursively, creating fully independent instances.

Modifying the copy does not affect the original, ensuring isolation.

### Mechanics

* Requires overriding `do_copy()` to explicitly clone nested objects
* Each nested uvm_object must implement its own `copy()` or `clone()` to support recursion
* Uses `type_id::create()` or `copy()` for nested objects
* Use UVM_DEEP flag for nested objects to deep copy (only if do_copy of nested class is overridden)

## Implementation Details

UVM uses deep copy via uvm_field_* macros to prevent side effects in transactions.

Without uvm_field_object, a shallow copy would copy sub_txn as a reference, so txn.sub_txn and copy.sub_txn point to the same object.

By default with macros, nested objects are not deep copied.

### Syntax

```systemverilog
piso_seq_item req = piso_seq_item::type_id::create("req");
piso_seq_item req_copy = piso_seq_item::type_id::create("req_copy");
req_copy.copy(req);
```

### Key Points

* Operates on an existing object, overwriting its fields
* Deep copy depends on `do_copy()` implementation
* Used when modifying an existing instance rather than creating a new one


# Cloning Objects in UVM

`clone()` creates a new instance of an object and copies the original's field values into it, typically performing a deep copy by default.

It is a factory-based operation that allocates a new object using `type_id::create()` and then calls `copy()` to transfer data. (slower than copy())

## Mechanics

Defined in uvm_object:

```systemverilog
virtual function uvm_object clone();
  uvm_object tmp;
  tmp = this.create(this.get_name());
  tmp.copy(this);
  return tmp;
endfunction
```

### Steps

* Creates a new object of the same type via create()
* Calls copy() to copy fields from the source to the new object
* Returns a uvm_object handle, requiring a $cast to the specific type

## Syntax

```systemverilog
piso_seq_item req = piso_seq_item::type_id::create("req");
piso_seq_item req_clone;
$cast(req_clone, req.clone());
```

## Key Points

* Allocates memory for a new object, ensuring a fresh instance
* Used when a new, independent object is needed


# Dist Operator in SystemVerilog

It constraints specifies weighted randomization distributions for variables, using `:=` (fixed weight) or `:/` (proportional weight).

## := (Fixed Weight)

* Assigns a fixed number of occurrences to a value/range
* Total occurrences may exceed sum of weights
* e.g., load=1 gets ~30 occurrences, load=0 gets ~70 per 100 tries
* Total may vary (e.g., 100–130)
* Independent weights, useful for absolute counts
* May lead to uneven distributions if solver oversamples

## :/ (Proportional Weight)

* Divides occurrences proportionally among values/ranges
* Total occurrences equal solver's sample size
* e.g., load=1 gets ~30% (30/100), load=0 gets ~70%
* Total is exactly 100 (solver-dependent)
* Normalized weights, ensures proportional split
* Preferred for percentage-based control

## FAQ

### What's the difference between := and :/?

`:=` assigns fixed occurrence counts, like 30 load=1 in PISO; `:/` splits proportionally, ensuring 30% load=1, better for balanced stimulus.
