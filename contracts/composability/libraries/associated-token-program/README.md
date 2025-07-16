# Solidity libraries for composability with _Solana_'s Associated Token program

## LibAssociatedTokenProgram library

This library provides helper functions for formatting instructions to be executed by _Solana_'s **Associated Token** 
program.

### Available Associated Token program instructions

- `create`: creates and initializes a canonical _Associated Token account_ on _Solana_. Such an account holds 
data related to an SPL token holder. See [instruction formatting](./LibAssociatedTokenProgram.sol#L101).

- `createIdempotent`: creates and initializes a canonical _Associated Token account_ on _Solana_. Such an account holds
  data related to an SPL token holder. Using the `createIdempotent` instruction allows to create the ATA only if it 
  doesn't already exist, and avoids throwing an error if the ATA already exists. An error will be thrown, however, if 
  the ATA already exists but its owner account is different from the one specified in the instruction. See 
  [instruction formatting](./LibAssociatedTokenProgram.sol#L143).