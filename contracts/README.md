# Solidity libraries for composability with Solana programs through NeonEVM

## Overview

### Installation

```javascript
npm install @neonevm/call-solana
```

### Usage

Once you have installed the package, you can use the Solidity libraries by importing them in your contracts:

```solidity
pragma solidity 0.8.28;

import { LibSPLTokenData } from "@neonevm/call-solana/composability/libraries/spl-token-program/LibSPLTokenData.sol";

contract CallSPLTokenProgram {
  /// @param tokenAccount The 32 bytes SPL token account public key
  /// @return token account balance as uint64
  function getSPLTokenAccountBalance(bytes32 tokenAccount) external view returns(uint64) {
    return LibSPLTokenData.getSPLTokenAccountBalance(tokenAccount);
  }
}
```

## NeonEVM's composability feature

_NeonEVM_ is a _Solana_ **network extension** enabling EVM dApps to tap into _Solana_'s user base and liquidity. It 
comes with a set of precompiled smart contracts acting as an interface between EVM dApps on _NeonEVM_ and _Solana_'s 
accounts and programs.

The **composability** feature allows EVM dApps deployed on _NeonEVM_ to interact with _Solana_ programs, which involves 
formatting _Solana_ instructions in ways that are specific to each program.

Here we provide a set of **Solidity** libraries which make it possible to easily implement secure interactions with the 
following _Solana_ programs:

* **System program**: `LibSystemProgram`, `LibSystemData` and `LibSystemErrors` libraries
* **SPL Token program**: `LibSPLTokenProgram`, `LibSPLTokenData` and `LibSPLTokenErrors` libraries
* **Associated Token program**: : `LibAssociatedTokenProgram` and `LibAssociatedTokenData` libraries
* **Metaplex program**: `LibMetaplexProgram`, `LibMetaplexData` and `LibMetaplexErrors` libraries
* **Raydium program**: `LibRaydiumProgram`, `LibRaydiumData` and `LibRaydiumErrors` libraries

We also provide a set of example smart-contracts implementing typical use cases for these libraries and best practices 
when it comes to user authentication and _Solana_ accounts management.

> [!CAUTION]
> The following contracts have not been audited yet and are here for educational purposes.

## Examples

### Minting an SPL Token

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { CallSolanaHelperLib } from "@neonevm/call-solana/utils/CallSolanaHelperLib.sol";
import { Constants } from "@neonevm/call-solana/composability/libraries/Constants.sol";
import { LibSystemData } from "@neonevm/call-solana/composability/libraries/system-program/LibSystemData.sol";
import { LibSPLTokenData } from "@neonevm/call-solana/composability/libraries/spl-token-program/LibSPLTokenData.sol";
import { LibSPLTokenProgram } from "@neonevm/call-solana/composability/libraries/spl-token-program/LibSPLTokenProgram.sol";

import { ICallSolana } from '@neonevm/call-solana/precompiles/ICallSolana.sol';

contract CallSPLTokenProgram {
    ICallSolana public constant CALL_SOLANA = ICallSolana(0xFF00000000000000000000000000000000000006);

    function createInitializeTokenMint(bytes memory seed, uint8 decimals) external {
        // Create SPL token mint account: msg.sender and a seed are used to calculate the salt used to derive the token
        // mint account, allowing for future authentication when interacting with this token mint. Note that it is
        // entirely possible to calculate the salt in a different manner and to use a different approach for
        // authentication
        bytes32 tokenMint = CALL_SOLANA.createResource(
            sha256(abi.encodePacked(
                msg.sender, // msg.sender is included here for future authentication
                seed // using different seeds allows msg.sender to create different token mint accounts
            )), // salt
            LibSPLTokenData.SPL_TOKEN_MINT_SIZE, // space
            LibSystemData.getRentExemptionBalance(
                LibSPLTokenData.SPL_TOKEN_MINT_SIZE,
                LibSystemData.getSystemAccountData(
                    Constants.getSysvarRentPubkey(),
                    LibSystemData.getSpace(Constants.getSysvarRentPubkey())
                )
            ), // lamports
            Constants.getTokenProgramId() // Owner must be SPL Token program
        );

        // This contract is mint/freeze authority
        bytes32 authority = CALL_SOLANA.getNeonAddress(address(this));
        // Format initializeMint2 instruction
        (   bytes32[] memory accounts,
            bool[] memory isSigner,
            bool[] memory isWritable,
            bytes memory data
        ) = LibSPLTokenProgram.formatInitializeMint2Instruction(
            decimals,
            tokenMint,
            authority,
            authority
        );

        // Prepare initializeMint2 instruction
        bytes memory initializeMint2Ix = CallSolanaHelperLib.prepareSolanaInstruction(
            Constants.getTokenProgramId(),
            accounts,
            isSigner,
            isWritable,
            data
        );

        // Execute initializeMint2 instruction
        CALL_SOLANA.execute(0, initializeMint2Ix);
    }

    function mint(
        bytes memory seed,
        bytes32 recipientATA,
        uint64 amount
    ) external {
        // Authentication: we derive the token mint account from msg.sender and seed
        bytes32 tokenMint = getTokenMintAccount(msg.sender, seed);
        // Format mintTo instruction
        (   bytes32[] memory accounts,
            bool[] memory isSigner,
            bool[] memory isWritable,
            bytes memory data
        ) = LibSPLTokenProgram.formatMintToInstruction(
            tokenMint,
            recipientATA,
            amount
        );
        // Prepare mintTo instruction
        bytes memory mintToIx = CallSolanaHelperLib.prepareSolanaInstruction(
            Constants.getTokenProgramId(),
            accounts,
            isSigner,
            isWritable,
            data
        );
        // Execute mintTo instruction
        CALL_SOLANA.execute(0, mintToIx);
    }
}
```

### Deploying a Raydium pool

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Constants } from "@neonevm/call-solana/composability/libraries/Constants.sol";
import { CallSolanaHelperLib } from "@neonevm/call-solana/utils/CallSolanaHelperLib.sol";
import { LibAssociatedTokenData } from "@neonevm/call-solana/composability/libraries/associated-token-program/LibAssociatedTokenData.sol";
import { LibRaydiumProgram } from "@neonevm/call-solana/composability/libraries/raydium-cpmm-program/LibRaydiumCPMMProgram.sol";

import { ICallSolana } from "@neonevm/call-solana/precompiles/ICallSolana.sol";

interface IERC20ForSpl {
    function transferSolana(bytes32 to, uint64 amount) external returns(bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external;
    function tokenMint() external view returns(bytes32);
}

contract CallRaydiumProgram {
    ICallSolana public constant CALL_SOLANA = ICallSolana(0xFF00000000000000000000000000000000000006);

    error InvalidTokens();

    function createPool(
        address tokenA,
        address tokenB,
        uint64 mintAAmount,
        uint64 mintBAmount,
        uint64 startTime
    ) public returns(bytes32) {
        bytes32 tokenAMint = IERC20ForSpl(tokenA).tokenMint();
        bytes32 tokenBMint = IERC20ForSpl(tokenB).tokenMint();
        bytes32 payerAccount = CALL_SOLANA.getPayer();
        bytes32 tokenA_ATA = LibAssociatedTokenData.getAssociatedTokenAccount(tokenAMint, payerAccount);
        bytes32 tokenB_ATA = LibAssociatedTokenData.getAssociatedTokenAccount(tokenBMint, payerAccount);

        IERC20ForSpl(tokenA).transferFrom(msg.sender, address(this), mintAAmount);
        IERC20ForSpl(tokenA).transferSolana(
            tokenA_ATA,
            mintAAmount
        );

        IERC20ForSpl(tokenB).transferFrom(msg.sender, address(this), mintBAmount);
        IERC20ForSpl(tokenB).transferSolana(
            tokenB_ATA,
            mintBAmount
        );

        bytes32[] memory premadeAccounts = new bytes32[](20);
        premadeAccounts[0] = payerAccount;
        premadeAccounts[7] = tokenA_ATA;
        premadeAccounts[8] = tokenB_ATA;

        (
            uint64 lamports,
            bytes32[] memory accounts,
            bool[] memory isSigner,
            bool[] memory isWritable,
            bytes memory data
        ) = LibRaydiumProgram.createPoolInstruction(tokenAMint, tokenBMint, mintAAmount, mintBAmount, startTime, 0, true, premadeAccounts);

        CALL_SOLANA.execute(
            lamports,
            CallSolanaHelperLib.prepareSolanaInstruction(
                Constants.getCreateCPMMPoolProgramId(),
                accounts,
                isSigner,
                isWritable,
                data
            )
        );

        return accounts[3]; // poolId
    }
}
```

## Supported Solana programs

### System program
<dl>
  <dd>

* [System program Solidity libraries](https://github.com/neonevm/neon-contracts/blob/main/contracts/composability/libraries/system-program/README.md)

* [CallSystemProgram](https://github.com/neonevm/neon-contracts/blob/main/contracts/composability/CallSystemProgram.sol) example contract demonstrating how the System program 
Solidity libraries can be used in practice to interact with Solana's System program.

  </dd>
</dl>

### SPL Token program
<dl>
  <dd>

* [SPL Token program Solidity libraries](https://github.com/neonevm/neon-contracts/blob/main/contracts/composability/libraries/spl-token-program/README.md)

* [CallSPLTokenProgram](https://github.com/neonevm/neon-contracts/blob/main/contracts/composability/CallSPLTokenProgram.sol) example contract demonstrating how the SPL Token 
program Solidity libraries can be used in practice to interact with Solana's SPL Token program.

  </dd>
</dl>

### Metaplex program
<dl>
  <dd>

* [Metaplex program Solidity libraries](https://github.com/neonevm/neon-contracts/blob/main/contracts/composability/libraries/metaplex-program/README.md)

* [CallMetaplexProgram](https://github.com/neonevm/neon-contracts/blob/main/contracts/composability/CallMetaplexProgram.sol) example contract demonstrating how the Metaplex
  program Solidity libraries can be used in practice to interact with Solana's Metaplex program.

  </dd>
</dl>

### Associated Token program
<dl>
  <dd>

* [Associated Token program Solidity libraries](https://github.com/neonevm/neon-contracts/blob/main/contracts/composability/libraries/associated-token-program/README.md)

* [CallAssociatedTokenProgram](https://github.com/neonevm/neon-contracts/blob/main/contracts/composability/CallAssociatedTokenProgram.sol) example contract demonstrating how the 
Associated Token program Solidity libraries can be used in practice to interact with Solana's Associated Token program.

  </dd>
</dl>

### Raydium CPMM program
<dl>
  <dd>

* [Raydium CPMM program Solidity libraries](https://github.com/neonevm/neon-contracts/blob/main/contracts/composability/libraries/raydium-cpmm-program/README.md)

* [CallRaydiumProgram](https://github.com/neonevm/neon-contracts/blob/main/contracts/composability/CallRaydiumProgram.sol) example contract demonstrating how the Raydium program 
Solidity libraries can be used in practice to interact with Solana's Raydium program.

  </dd>
</dl>

## Composability helper contracts

* [Constants.sol](https://github.com/neonevm/neon-contracts/blob/main/contracts/composability/libraries/Constants.sol) provides commonly used constants for formatting 
instructions to be executed by _Solana_ programs
* [CallSolanaHelperLib.sol](https://github.com/neonevm/neon-contracts/blob/main/contracts/utils/CallSolanaHelperLib.sol) provides helper functions to prepare formatted instructions
right before they are executed on _Solana_
* [SolanaDataConverterLib.sol](https://github.com/neonevm/neon-contracts/blob/main/contracts/utils/SolanaDataConverterLib.sol) provides helper functions for casting data to and 
from various types commonly used on _Solana_
* [ICallSolana.sol](https://github.com/neonevm/neon-contracts/blob/main/contracts/precompiles/ICallSolana.sol) provides an interfacte to the `CallSolana` precompiled contract which 
is the cornerstone of _NeonEVM_'s composability with _Solana_. See: [ICallSolana interface documentation ](https://neonevm.org/docs/composability/call_solana_interface).
* [QueryAccount.sol](https://github.com/neonevm/neon-contracts/blob/main/contracts/precompiles/QueryAccount.sol) provides a set of getter function for reading _Solana_'s state by 
querying data stored on _Solana_ accounts

## Solana specifics

See: [Common Solana terminology](https://neonevm.org/docs/composability/common_solana_terminology)

### Solana Token accounts

#### Associated token accounts vs Arbitrary token accounts

_Arbitrary token accounts_ are derived using a `seed` which includes the token account `owner`'s public key and an 
arbitrary `nonce` (among other parameters). By using different `nonce` values it is possible to derive different 
_arbitrary token accounts_ for the same `owner` which can be useful for some use cases.

The **CallSPLTokenProgram** contract provides its users with methods to create and initialize SPL _token mints_ and
_arbitrary token accounts_ as well as to mint and transfer tokens using those accounts. It features a built-in
authentication logic ensuring that users remain in control of created accounts.

However, there exists a canonical way of deriving a SPL token account for a specific `owner` and this token account is 
called an _Associated Token account_. _Associated Token accounts_ are used widely by application s running on _Solana_ 
and it is generally expected that token transfers are made to and from _Associated Token accounts_.

The **CallAssociatedTokenProgram** contract provides a method to create and initialize canonical _Associated Token
accounts_ for third party _Solana_ users. This method can also be used to create and initialize canonical _Associated
Token accounts_ owned by this contract.

## Ownership and authentication

### SPL token mint ownership and authentication

The `CallSPLTokenProgram.createInitializeTokenMint` function takes a `seed` parameter as input which is used along with 
`msg.sender` to derive the created token mint account. While the **CallSPLTokenProgram** contract is given mint/freeze 
authority on the created token mint account, the `mintTokens` function grants `msg.sender` permission to mint tokens
by providing the `seed` that was used to create the token mint account.

### Metadata accounts ownership and authentication

The `CallMetaplexProgram.createTokenMetadataAccount` function takes a `seed` parameter as input which is used along with
`msg.sender` to derive a token mint account. Created token metadata account is associated with this token mint account 
which must have been created and initialized beforehand by the same `msg.sender`. That same `msg.sender` is also granted 
permission to update the token metadata account in the future, provided that it is set as mutable upon creation.

### Arbitrary token accounts ownership and authentication

Using _arbitrary SPL Token accounts_ created via the `CallSPLTokenProgram` contract deployed on _NeonEVM_ allows for 
cheap and easy authentication of _NeonEVM_ users to let them interact with and effectively control those token accounts 
securely via this contract while this contract is the actual owner of those token accounts on _Solana_. It is also 
possible to create and initialize an _arbitrary SPL Token accounts_ for third party _Solana_ users, granting them full 
ownership of created accounts on _Solana_.

The `CallSPLTokenProgram.createInitializeArbitraryTokenAccount` function can be used for three different purposes:

* To create and initialize an _arbitrary token account_ to be used by `msg.sender` to send tokens through the 
**CallSPLTokenProgram** contract. In this case, both the `owner` and `tokenOwner` parameters passed to the function 
should be left empty. The _arbitrary token account_ to be created is derived from `msg.sender` and a `nonce` (that can 
be incremented to create different _arbitrary token accounts_). Only `msg.sender` is allowed to perform state changes to
the created token account via this contract. The `transferTokens` function grants `msg.sender` permission to transfer 
tokens from this _arbitrary token account_ by providing the `nonce` that was used to create the _arbitrary token account_.

* To create and initialize an _arbitrary token account_ to be used by a third party `user` NeonEVM account through 
the **CallSPLTokenProgram** contract. In this case, the `owner` parameter passed to the function should be  
`CallSPLTokenProgram.getNeonAddress(user)` and the `tokenOwner` parameter should be left empty. The _arbitrary token 
account_ to be created is derived from the `user` account and a `nonce` (that can be incremented to create different 
_arbitrary token accounts_). Only that `user` is allowed to perform state changes to the created token account via this 
contract. The `transferTokens` function grants `user` permission to transfer tokens from this _arbitrary token account_ 
by providing the `nonce` that was used to create the _arbitrary token account_.

* To create and initialize an _arbitrary token account_ to be used by a third party `solanaUser` _Solana_ account
to send tokens directly on _Solana_ without interacting with the **CallSPLTokenProgram** contract. In this case, both the 
`owner` and the `tokenOwner` parameters passed to the function should be `solanaUser`. The _arbitrary token account_ to 
be created is derived from the `solanaUser` account and a `nonce` (that can be incremented to create different 
_arbitrary token accounts_). The owner of the _arbitrary token account_ is the `solanaUser` account. The `solanaUser` 
account cannot transfer tokens from this _arbitrary token account_ by interacting with the **CallSPLTokenProgram** 
contract, instead it must interact directly with the **SPL Token** program on _Solana_ by signing and executing a 
`transfer` instruction.

## License

This software is licensed under the [MIT license](https://github.com/neonevm/neon-contracts/blob/main/LICENSE)
