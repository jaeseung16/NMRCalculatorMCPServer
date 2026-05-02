# NMRCalculatorMCPServer

A [Model Context Protocol (MCP)](https://modelcontextprotocol.io) server that exposes NMR calculation tools over stdio. Ask Claude questions like *"What is the ¹H Larmor frequency at 14 T?"* and get back a physics-accurate answer.

The nucleus database (120 nuclei) is embedded at compile time, so the binary has no external dependencies.

---

## Requirements

- macOS 13 or later
- Xcode 15 or later (provides Swift 5.9+)

---

## Installation

### Option A: Build from source

### 1. Build

```bash
git clone https://github.com/jaeseung-lee/NMRCalculatorMCPServer.git
cd NMRCalculatorMCPServer
swift build -c release
```

### 2. Copy the binary to a stable path (optional)

```bash
sudo cp .build/release/NMRCalculatorMCPServer /usr/local/bin/
```

If you skip this step, use the full path to `.build/release/NMRCalculatorMCPServer` in the registration commands below.

### 3. Register with Claude Code

```bash
claude mcp add nmr-calculator /usr/local/bin/NMRCalculatorMCPServer
```

Or, if you skipped step 2:

```bash
claude mcp add nmr-calculator $(pwd)/.build/release/NMRCalculatorMCPServer
```

### 4. Register with Claude Desktop

Add the following to `~/Library/Application Support/Claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "nmr-calculator": {
      "command": "/usr/local/bin/NMRCalculatorMCPServer"
    }
  }
}
```

Then restart Claude Desktop.

---

### Option B: Install with mint

[mint](https://github.com/yonaskolb/Mint) is a package manager for Swift CLI tools that handles building and installing in one step.

**1. Install mint** (if not already installed):

```bash
brew install mint
```

**2. Install NMRCalculatorMCPServer:**

```bash
mint install jaeseung-lee/NMRCalculatorMCPServer
```

**3. Register with Claude Code:**

```bash
claude mcp add nmr-calculator ~/.mint/bin/NMRCalculatorMCPServer
```

**4. Register with Claude Desktop** — add to `~/Library/Application Support/Claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "nmr-calculator": {
      "command": "/Users/YOUR_USERNAME/.mint/bin/NMRCalculatorMCPServer"
    }
  }
}
```

Then restart Claude Desktop.

---

## Available Tools

### `calculate_larmor_frequency`

Calculates the Larmor frequency of a nucleus at a given magnetic field strength (ω = γ × B₀).

| Parameter | Type | Description |
|---|---|---|
| `nucleus` | string | Nucleus identifier, e.g. `"1H"`, `"13C"`, `"31P"` |
| `magnetic_field` | number | Magnetic field strength in Tesla |

**Returns:** Larmor frequency in MHz.

**Example:** *"What is the NMR frequency of ¹H at 7 T?"* → `298.0423 MHz`

---

### `calculate_magnetic_field`

Calculates the magnetic field required to observe a nucleus at a given Larmor frequency (B₀ = ω / γ).

| Parameter | Type | Description |
|---|---|---|
| `nucleus` | string | Nucleus identifier |
| `larmor_frequency` | number | Larmor frequency in MHz |

**Returns:** Magnetic field strength in Tesla.

---

### `get_nucleus_info`

Returns properties of an NMR-active nucleus.

| Parameter | Type | Description |
|---|---|---|
| `nucleus` | string | Nucleus identifier |

**Returns:** Gyromagnetic ratio (MHz/T), nuclear spin, and natural abundance.

---

### `list_nuclei`

Lists all 120 NMR-active nuclei in the database with their identifiers and gyromagnetic ratios. Takes no parameters.

---

### `calculate_ernst_angle`

Calculates the Ernst angle — the optimal flip angle for maximum SNR in a repetitively pulsed experiment (θ = arccos(exp(−TR/T₁))).

| Parameter | Type | Description |
|---|---|---|
| `repetition_time` | number | Repetition time TR in seconds |
| `t1` | number | Longitudinal relaxation time T₁ in seconds |

**Returns:** Ernst angle in degrees.

---

### `calculate_pulse_amplitude`

Calculates the RF amplitude needed to achieve a flip angle in a given pulse duration (A = (θ/360°) / τ).

| Parameter | Type | Description |
|---|---|---|
| `flip_angle` | number | Desired flip angle in degrees |
| `duration` | number | Pulse duration in microseconds |

**Returns:** RF amplitude in Hz.

---

### `calculate_pulse_duration`

Calculates the pulse duration needed to achieve a flip angle at a given RF amplitude (τ = (θ/360°) / A).

| Parameter | Type | Description |
|---|---|---|
| `flip_angle` | number | Desired flip angle in degrees |
| `amplitude` | number | RF amplitude in Hz |

**Returns:** Pulse duration in microseconds.

---

## Nucleus Identifier Format

Nucleus identifiers can be entered in either plain ASCII (`1H`, `13C`, `31P`) or Unicode superscript form (`¹H`, `¹³C`, `³¹P`). Both formats are accepted by all tools.

---

## License

Copyright © 2026 Jae-Seung Lee. All rights reserved.
