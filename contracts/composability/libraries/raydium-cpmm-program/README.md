# Solidity libraries for composability with _Solana_'s Raydium CPMM program

## LibRaydiumCPMMProgram library
This library provides helper functions for formatting instructions to be executed by _Solana_'s **Raydium** 
program.

### Available Raydium CPMM program instructions
* `createPoolInstruction` - Deploying CPMM pool on Raydium for selected tokens pair. This method also returns the needed `lamports` amount for the instruction to be processed successfully in Solana, this amount constains several account creations plus the pool creation fee paid to Raydium. [Info](LibRaydiumCPMMProgram.sol#L30)
* `addLiquidityInstruction` - Adding liquidity for selected tokens pair. [Info](LibRaydiumCPMMProgram.sol#L152)
* `withdrawLiquidityInstruction` - Withdrawing liquidity from selected tokens pair. [Info](LibRaydiumCPMMProgram.sol#L246)
* `lockLiquidityInstruction` - Locking liquidity position. This method also returns the needed `lamports` amount for the instruction to be processed successfully in Solana, this amount constains several account creations plus a fee if `withMetadata` is set to `true`. [Info](LibRaydiumCPMMProgram.sol#L331)
* `collectFeesInstruction` - Collecting fees for locked LP position. This instruction can be sent to Solana only if there is already existing locked LP position and there are some pending fees to be collected. [Info](LibRaydiumCPMMProgram.sol#L460)
* `swapInputInstruction` - Swapping exact token input amount, example - swap 100 tokensA for X tokensB. [Info](LibRaydiumCPMMProgram.sol#L559)
* `swapOutputInstruction` - Swapping tokens to exact token output amount, example - swap X tokensA for 100 tokensB. [Info](LibRaydiumCPMMProgram.sol#L605)

## LibRaydiumCPMMData library
This library provides a set of getter functions for querying different accounts & data. Also some calculations such as swap input or output amount; convert LP amount to tokens amounts; etc. Here are some of the getters:
* `getPoolData` - Returns the data of Raydium CPMM pool. [Info](LibRaydiumCPMMData.sol#L150)
* `getConfigData` - Returns the data for requested utils index. [Info](LibRaydiumCPMMData.sol#L173)
* `getTokenReserve` - Returns pool token reserve for selected token mint. [Info](LibRaydiumCPMMData.sol#L194)
* `getPoolLpAmount` - Returns the pool's LP amount. [Info](LibRaydiumCPMMData.sol#L199)
* `lpToAmount` - Converts LP amount to reserves amounts. [Info](LibRaydiumCPMMData.sol#L204)
* `getSwapOutput` - Returns a swap quote of provided exact input amount. [Info](LibRaydiumCPMMData.sol#L224)
* `getSwapInput` - Returns a swap quote of provided exact output amount. [Info](LibRaydiumCPMMData.sol#L240)


## LibRaydiumCPMMErrors library
This library provides a set of custom errors that may be thrown when using **LibRaydiumCPMMProgram** and **LibRaydiumCPMMData** 
libraries.