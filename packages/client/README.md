# >LORE - Client

This package contains the client for >LORE - a Dojo based, Zork & MUD inspired, fully onchain interactive multiplayer fiction engine.

## Overview

The client is built with React and connects to the Dojo contracts to provide an interactive text adventure experience.

## Development

### Prerequisites

Make sure you have [Bun](https://bun.sh) installed for package management.

### Installation

From the project root:

```bash
bun install
```

### Development Mode

To run the client in local development mode:

```bash
bun run dev
```

For slot development:

```bash
bun run dev:slot
```

### Building

To build the client:

```bash
bun run build
```

For slot build:

```bash
bun run build:slot
```

### Preview

To preview the built client:

```bash
bun run preview
```

### World Editor

Once the development server is running, you can access the world editor at:

```
http://localhost:5173/editor
```

Use this to create and publish your own text adventure world.

## Dependencies

The client runs on:

- React
- Dojo Engine SDK
- Tailwind CSS

## Additional Information

For full project information, including how to set up the contracts and more details about the project, refer to the [root README](../../README.md).
