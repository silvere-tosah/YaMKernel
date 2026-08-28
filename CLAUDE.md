# YaMKernel: SPARK/Ada Microkernel Project

*This file gives Claude Code project context and working rules. It's read automatically at the start of every session — keep it accurate, since Claude will act on it directly.*

## Project Overview
- **Name:** YaMKernel (Yet Another MicroKernel)
- **Goal:** A formally verified microkernel written in SPARK/Ada, inspired by seL4, Google's KataOS (which is built on seL4), and Minix.
- **Core motivating question:** seL4 achieves formal verification via Isabelle/HOL, a separate theorem prover. This project explores building the proof obligations directly into the language/toolchain instead, using SPARK's own verification system.
- **Target Hardware:** Raspberry Pi 3 (aarch64, baremetal).
- **Portability:** The Pi 3 is the bring-up target, not the end goal — keep architecture-specific code isolated so a future port to another board stays realistic.
- **Core Philosophy:** Minimal kernel space. Networking, filesystems, and drivers run in user space as servers. The kernel itself only handles physical memory allocation, scheduling, and IPC.

## Technology Stack
- **Language:** SPARK 2014 / Ada 2012.
- **Toolchain:** GNATpro (aarch64-elf baremetal) or Alire (for an AArch64 cross-compiler).
- **Ada Runtime:** a target-specific generated runtime (handles startup code, interrupt setup, memory layout, IO) — generated rather than hand-written, to avoid reimplementing low-level boilerplate.
- **Core Files:** `boot.S` (entry point), `linker.ld` (memory layout), plus kernel sources.
- **Current Focus:** MiniUART bring-up, for serial debug output.

## Build, Prove & Run
These are commands Claude Code can actually run — keep this section correct, since it drives real terminal actions, not just background context.

```bash
# Build the kernel
gprbuild -P yamkernel.gpr

# Run SPARK formal verification (Absence of Runtime Errors)
gnatprove -P yamkernel.gpr --level=2 --mode=all

# Run under QEMU emulation
# NOTE: verify the machine name/flags against your installed QEMU version —
# Raspberry Pi 3 machine support/naming has changed across QEMU releases.
qemu-system-aarch64 -M <raspi3-machine-name> -kernel <built-image> -serial stdio -display none

# Deploy to real hardware
# e.g. copy the built image to the SD card's boot partition as kernel8.img
```
*(No formal test harness yet — right now, validation is manual via UART output under emulation/hardware.)*

> Fill in and correct anything above against your actual project file names, GNAT project structure, and QEMU setup. Wrong commands here are worse than no commands, since Claude Code will run them as-is.

## AI Assistant Rules & Guardrails

### 1. Language & Verification Constraints
- **Strict SPARK:** write code within the SPARK-analyzable subset of Ada. If a construct falls outside it, flag that explicitly rather than quietly falling back to full Ada.
- **Contracts first:** define `Global`, `Depends`, `Pre`, and `Post` aspects for a subprogram before implementing its body.
- **Proof goal, not just error handling:** the target is Absence of Runtime Errors (AoRTE) — code structured so no exception can ever be raised, proven by `gnatprove`, rather than code that raises and catches exceptions at runtime. (If you adopt a restricted tasking profile like Ravenscar or Jorvik for the bare-metal runtime, state that explicitly here once decided.)
- **No dynamic memory in kernel space:** no `new` / unchecked deallocation. Use static allocation and fixed-size pools.

### 2. Architecture & Hardware Constraints (aarch64 / Raspberry Pi 3)
- **Hardware abstraction:** isolate architecture-specific code (aarch64 registers, Pi-specific MMIO addresses, board timers) from generic microkernel logic.
- **MMIO access:** default to `Volatile` for hardware registers — it's what stops the compiler from caching, reordering, or eliding accesses, which is the main risk with register I/O. Reserve `Atomic` for registers/flags genuinely shared with an interrupt handler, where indivisible read-modify-write matters. Use `Volatile_Full_Access` where a register must always be read/written at its full declared width in one access (common for UART/GPIO controllers).
- **Address typing:** give MMIO addresses precise types (e.g. a record with an `Address` aspect and representation clause) rather than raw integer casts.

### 3. Workflow & Code Style
- **Read-before-write:** check `linker.ld` and `boot.S` before modifying memory layout or initialization sequences.
- **Naming:** Mixed_Case for variables, types, and subprograms (Ada's standard convention — underscore-separated, each word capitalized); ALL_CAPS for constants.
- **Modularity:** keep kernel modules tightly scoped (e.g. `yamkernel.ads/adb`, `yamkernel-uart.ads/adb`).
- **Dependencies:** this is a minimal-dependency project by design — ask before introducing a new external dependency (Alire crate or otherwise).

### 4. Definition of Done
- Compiles with the AArch64 Ada cross-compiler with zero warnings.
- `gnatprove` verifies contracts and confirms AoRTE at the project's configured proof level.
- For anything touching boot/runtime behavior: boots and produces the expected UART output under emulation or on hardware — not just "compiles and proves."

## Reference Material
- seL4 whitepaper — microkernel vs. monolithic tradeoffs, security rationale.
- KataOS (Google) — seL4-based OS that partly motivated this project; useful for design comparison.
- OSDev wiki — general reference.
- *Operating Systems: Design and Implementation* — foundational textbook.
- raspi-os tutorial — structural reference for baremetal bring-up (follow the approach, don't copy code verbatim).

## Directory Layout
<!-- Update once it solidifies. Suggested starting shape: -->
```
src/
  kernel/     # architecture-independent microkernel logic
  hal/rpi3/   # Raspberry Pi 3 / aarch64-specific code
  runtime/    # generated Ada runtime
docs/
```

## Known Gotchas & Decisions Log
<!-- Append short entries here as you hit non-obvious bugs or make a call worth remembering
     (e.g. "the generated runtime needed X workaround because Y"). This is what stops
     Claude from re-deriving or re-breaking the same thing in a future session. -->
