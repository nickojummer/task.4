// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Constants } from "../Constants.sol";
import { LibSystemData } from "../system-program/LibSystemData.sol";
import { LibMetaplexErrors } from "./LibMetaplexErrors.sol";
import { QueryAccount } from "../../../precompiles/QueryAccount.sol";
import { SolanaDataConverterLib } from "../../../utils/SolanaDataConverterLib.sol";

import { ICallSolana } from '../../../precompiles/ICallSolana.sol';

/// @title LibMetaplexData
/// @notice Helper library for getting data from Solana's Metaplex program
/// @author maxpolizzo@gmail.com
library LibMetaplexData {
    using SolanaDataConverterLib for bytes;

    ICallSolana public constant CALL_SOLANA = ICallSolana(0xFF00000000000000000000000000000000000006);

    // See: https://github.com/metaplex-foundation/mpl-token-metadata/blob/23aee718e723578ee5df411f045184e0ac9a9e63/programs/token-metadata/program/src/state/metadata.rs#L16
    // and: https://github.com/metaplex-foundation/mpl-token-metadata/blob/23aee718e723578ee5df411f045184e0ac9a9e63/clients/rust/src/lib.rs#L19
    uint8 public constant MAX_NAME_LENGTH = 32;
    uint8 public constant MAX_SYMBOL_LENGTH = 10;
    uint8 public constant MAX_URI_LENGTH = 200;
    uint8 public constant MAX_CREATOR_LIMIT = 5;
    uint8 public constant MAX_CREATOR_LEN = 34;
    uint16 public constant MAX_DATA_SIZE = 431;
    uint16 public constant MAX_METADATA_LEN = 607;
    // See: https://github.com/metaplex-foundation/mpl-token-metadata/blob/23aee718e723578ee5df411f045184e0ac9a9e63/programs/token-metadata/program/src/state/fee.rs#L14
    uint16 public constant CREATE_FEE_SCALAR = 1308;
    uint16 public constant CREATE_FEE_OFFSET = 5440;

    struct TokenMetadata {
        string tokenName;
        string tokenSymbol;
        string uri;
        bool isMutable;
        bytes32 updateAuthority;
    }

    /// @notice Function to get the 32 bytes program derived address (PDA) derived from a token mint
    /// and Solana's Metaplex program Id
    /// @param tokenMint The 32 bytes public key of the token mint
    function getMetadataPDA(
        bytes32 tokenMint
    ) internal view returns(bytes32) {
        return CALL_SOLANA.getSolanaPDA(
            Constants.getMetaplexProgramId(),
            abi.encodePacked(
                'metadata',
                Constants.getMetaplexProgramId(),
                tokenMint
            )
        );
    }

    /// @notice Function to get Solana's Metaplex program creation fee for a token metadata account
    function getMetaplexCreateFee(bytes memory rentDataBytes) internal pure returns(uint64) {
        // See: https://github.com/metaplex-foundation/mpl-token-metadata/blob/23aee718e723578ee5df411f045184e0ac9a9e63/programs/token-metadata/program/src/state/fee.rs#L17
        return  CREATE_FEE_OFFSET + LibSystemData.getRentExemptionBalance(CREATE_FEE_SCALAR, rentDataBytes);
    }

    // @notice Function to validate provided token metadata
    function validateTokenMetadata(
        string memory tokenName,
        string memory tokenSymbol,
        string memory tokenUri
    ) internal pure {
        // See: https://github.com/metaplex-foundation/mpl-token-metadata/blob/23aee718e723578ee5df411f045184e0ac9a9e63/programs/token-metadata/program/src/assertions/metadata.rs#L22
        require(
            bytes(tokenName).length <= MAX_NAME_LENGTH,
            LibMetaplexErrors.InvalidTokenMetadata()
        );
        require(
            bytes(tokenSymbol).length <= MAX_SYMBOL_LENGTH,
            LibMetaplexErrors.InvalidTokenMetadata()
        );
        require(
            bytes(tokenUri).length <= MAX_URI_LENGTH,
            LibMetaplexErrors.InvalidTokenMetadata()
        );
    }

    // @notice Function to get deserialized token metadata
    function getDeserializedMetadata(bytes32 tokenMint) internal view returns(TokenMetadata memory) {
        (bool success, bytes memory data) = QueryAccount.data(
            uint256(LibMetaplexData.getMetadataPDA(tokenMint)),
            0,
            MAX_METADATA_LEN
        );
        require(success, LibMetaplexErrors.MetadataAccountDataQuery());

        return TokenMetadata (
            string(data.sliceBytes(69, 32, false)), // 32 utf-8 bytes token name
            string(data.sliceBytes(105, 10, false)), // 10 utf-8 bytes token symbol
            string(data.sliceBytes(119, 200, false)), // 200 utf-8 bytes token uri
            data.sliceBytes(323, 1, true).toBool(0), // 1 byte isMutable flag
            data.toBytes32(1) // 32 bytes token metadata update authority public key
        );
    }

    // @notice Function to get deserialized token name
    function getDeserializedTokenName(bytes32 tokenMint) internal view returns(string memory) {
        (bool success, bytes memory data) = QueryAccount.data(
            uint256(LibMetaplexData.getMetadataPDA(tokenMint)),
            69,
            32
        );
        require(success, LibMetaplexErrors.MetadataAccountDataQuery());

        return string(data);
    }

    // @notice Function to get deserialized token symbol
    function getDeserializedTokenSymbol(bytes32 tokenMint) internal view returns(string memory) {
        (bool success, bytes memory data) = QueryAccount.data(
            uint256(LibMetaplexData.getMetadataPDA(tokenMint)),
            105,
            10
        );
        require(success, LibMetaplexErrors.MetadataAccountDataQuery());

        return string(data);
    }

    // @notice Function to get deserialized token uri
    function getDeserializedTokenUri(bytes32 tokenMint) internal view returns(string memory) {
        (bool success, bytes memory data) = QueryAccount.data(
            uint256(LibMetaplexData.getMetadataPDA(tokenMint)),
            119,
            200
        );
        require(success, LibMetaplexErrors.MetadataAccountDataQuery());

        return string(data);
    }

    // @notice Function to get deserialized token isMutable flag
    function getDeserializedTokenIsMutable(bytes32 tokenMint) internal view returns(bool) {
        (bool success, bytes memory data) = QueryAccount.data(
            uint256(LibMetaplexData.getMetadataPDA(tokenMint)),
            323,
            1
        );
        require(success, LibMetaplexErrors.MetadataAccountDataQuery());

        return data.toBool(0);
    }

    // @notice Function to get deserialized token updateAuthority public key
    function getDeserializedTokenUpdateAuthority(bytes32 tokenMint) internal view returns(bytes32) {
        (bool success, bytes memory data) = QueryAccount.data(
            uint256(LibMetaplexData.getMetadataPDA(tokenMint)),
            1,
            32
        );
        require(success, LibMetaplexErrors.MetadataAccountDataQuery());

        return data.toBytes32(0);
    }
}
