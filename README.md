# DefiMon Staking v2

## Setup

Before running and compiling the project, follow these steps to set up your development environment:

1. **Install Dependencies:**

   Ensure you have `pnpm` installed. If not, install it from [pnpm.io](https://pnpm.io/installation).

   ```shell
   pnpm install
   ```

2. **Initialize and Update Git Submodules:**

   Initialize and update the Git submodules required for the project.

   ```shell
   git submodule init
   git submodule update
   ```

## Usage

### Build

Compile the smart contracts using Forge:

```shell
forge compile
```

### Test

Run the test suite:

```shell
forge test
```

## Issues:

The following test files currently encounter stack too deep errors during coverage analysis:

- MonStakingTestBaseIntegration.t.sol
- MonStakingTestBaseIntegration3Chains.t.sol
