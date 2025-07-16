// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/// @title LibRaydiumCPMMErrors
/// @author https://twitter.com/mnedelchev_
/// @notice Helper contract used to unify all Solidity errors to be returned by the Raydium's CPMM library
library LibRaydiumCPMMErrors {
    error InvalidPool(bytes32 poolId);
    error AlreadyExistingPool(bytes32 poolId);
    error InvalidConfig(bytes32 configAccount);
    error ZeroSupply();
    error IdenticalTokenAddresses();
    error EmptyTokenAddress();
    error InsufficientInputAmount();
    error InsufficientOutputAmount();
}
