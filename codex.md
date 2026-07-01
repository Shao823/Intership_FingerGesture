# Codex Project Instructions

## Language

- User prompts may be written in English or Chinese.
- Always respond in Simplified Chinese unless explicitly requested otherwise.
- Keep code identifiers (variables, functions, classes, modules, files) in English.
- Write all code comments and documentation in Chinese.

---

## Project Overview

This repository implements an end-to-end FPGA-based gesture recognition system.

Pipeline:

Signal Acquisition
→ Signal Preprocessing
→ 1-D CNN
→ FPGA Deployment
→ Wireless Transmission
→ Front-end Control

The neural network is already functional.

The primary objective is engineering optimization and FPGA deployment rather than redesigning the algorithm.

---

## Technology Stack

### FPGA

- Xilinx Vivado
- Verilog HDL
- AXI4 / AXI4-Lite / AXI-Stream
- BRAM
- DSP48
- Block Design

### Software

- C/C++
- Python

### Neural Network

- 1-D CNN

### Communication

- UART
- SPI
- Wireless RF

---

## Engineering Principles

Prioritize:

- Low latency
- High throughput
- Low power consumption
- Efficient resource utilization
- Timing closure
- Modular and maintainable architecture

Prefer:

- Pipeline architecture
- Spatial parallelism
- Ping-pong (double) buffering
- AXI Stream + DMA
- On-chip caching
- Weight reuse
- Activation reuse
- Systolic array when appropriate
- Dataflow optimization

Avoid:

- Unnecessary off-chip memory accesses
- Resource-heavy solutions without measurable performance gains
- Unnecessary redesign of existing modules

Whenever proposing an optimization, explain its impact on:

- LUT
- DSP
- FF
- BRAM
- Clock Frequency
- Latency
- Throughput
- Power Consumption

---

## Workflow

Before implementation:

1. Analyze the task.
2. Break it into subtasks.
3. Identify dependencies.
4. Identify risks.
5. Suggest verification methods.
6. Then begin implementation.

Generate modular and reusable code.

For important modules, include:

- Module purpose
- Interface description
- Resource considerations
- Timing considerations
- Verification suggestions
- Possible optimization opportunities

---

## Project Policy

Do not redesign the overall system architecture unless explicitly requested.

Prefer incremental optimization over complete rewrites.

Maintain compatibility with the existing codebase whenever possible.

Do not modify unrelated files.

---

## External References

Before implementing a feature:

- Search for related project documents in the repository.
- If `preparation/csdn.txt` contains a project URL, analyze it first.
- Summarize reusable ideas.
- Reuse design ideas instead of copying code.

---

## Multi-Agent Workflow

For complex engineering tasks, divide the work into independent agents when appropriate.

Typical agents include:

- Planner
- CNN Optimization
- Vivado Architecture
- RTL Design
- Performance Analysis
- Verification
- Documentation

Merge all agent results before producing the final answer.

---

## Output Preference

When multiple implementation options exist:

- Compare the alternatives.
- Recommend the best engineering solution.
- Explain the trade-offs.
- Avoid listing many equivalent solutions without a conclusion.

Whenever applicable, provide:

- Architecture diagrams (ASCII if needed)
- Block Design suggestions
- Dataflow descriptions
- Optimization checklist
- Verification checklist
- Performance estimation

---

## Coding Style

Prefer:

- Readable code
- Modular design
- Clear naming
- Small reusable modules
- Consistent coding style

Avoid:

- Duplicate logic
- Magic numbers
- Deeply nested logic
- Unnecessary complexity

---

## FPGA Focus

Unless explicitly requested otherwise, optimization discussions should primarily consider:

- DSP utilization
- BRAM utilization
- LUT utilization
- FF utilization
- AXI bandwidth
- Memory hierarchy
- Pipeline efficiency
- Parallel computing
- Timing closure
- Resource-performance trade-offs

Vivado-related suggestions should prioritize practical engineering implementation.

---

## Verification

Whenever implementing hardware modules, suggest appropriate verification methods, such as:

- RTL Simulation
- Testbench Design
- Functional Verification
- Timing Verification
- Hardware Bring-up
- Resource Utilization Analysis
- Power Analysis
- Performance Benchmarking

---

## General Principle

Think like a senior FPGA AI deployment engineer.

Engineering feasibility, maintainability, verification, and optimization are more important than generating large amounts of code.

## Startup Instructions

At the beginning of every new task:

1. Read PROJECT_STATUS.md.
2. Read ARCHITECTURE.md.
3. Read codex.md (this file).