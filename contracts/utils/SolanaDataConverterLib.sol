// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @title SolanaDataConverterLib
/// @author https://twitter.com/mnedelchev_
/// @notice This contract serves as a helper library when interacting with precompile QueryAccount ( 0xFF00000000000000000000000000000000000002 )
library SolanaDataConverterLib {
    // Custom error
    error OutOfBounds();

    function toBool(bytes memory _bytes, uint256 _start) internal pure returns (bool result) {
        require(_bytes.length >= _start + 1, OutOfBounds());
        bool tempBool;

        assembly {
            tempBool := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBool;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_bytes.length >= _start + 20, OutOfBounds());
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32) {
        require(_bytes.length >= _start + 32, OutOfBounds());
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_bytes.length >= _start + 1, OutOfBounds());
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint256 _start) internal pure returns (uint16) {
        require(_bytes.length >= _start + 2, OutOfBounds());
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint256 _start) internal pure returns (uint32) {
        require(_bytes.length >= _start + 4, OutOfBounds());
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint256 _start) internal pure returns (uint64) {
        require(_bytes.length >= _start + 8, OutOfBounds());
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint256 _start) internal pure returns (uint96) {
        require(_bytes.length >= _start + 12, OutOfBounds());
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint256 _start) internal pure returns (uint128) {
        require(_bytes.length >= _start + 16, OutOfBounds());
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        require(_bytes.length >= _start + 32, OutOfBounds());
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function readLittleEndianUnsigned16(uint16 input) internal pure returns (uint16) {
        // swap bytes
        return (input >> 8) | (input << 8);
    }

    function readLittleEndianSigned16(uint16 input) internal pure returns (int16) {
        // swap bytes and cast to signed
        return int16((input >> 8) | (input << 8));
    }

    function readLittleEndianUnsigned32(uint32 input) internal pure returns (uint32) {
        // swap bytes
        input = ((input & 0xFF00FF00) >> 8) | ((input & 0x00FF00FF) << 8);

        // swap 2-byte long pairs
        return (input >> 16) | (input << 16);
    }

    function readLittleEndianSigned32(uint32 input) internal pure returns (int32) {
        input = ((input << 8) & 0xFF00FF00) | ((input >> 8) & 0x00FF00FF);
        return int32((input << 16) | ((input >> 16) & 0xFFFF));
    }

    function readLittleEndianUnsigned64(uint64 input) internal pure returns (uint64) {
        // swap bytes
        input = ((input & 0xFF00FF00FF00FF00) >> 8) | ((input & 0x00FF00FF00FF00FF) << 8);

        // swap 2-byte long pairs
        input = ((input & 0xFFFF0000FFFF0000) >> 16) | ((input & 0x0000FFFF0000FFFF) << 16);

        // swap 4-byte long pairs
        return(input >> 32) | (input << 32);
    }

    function readLittleEndianSigned64(uint64 input) internal pure returns (int64) {
        input = ((input << 8) & 0xFF00FF00FF00FF00) | ((input >> 8) & 0x00FF00FF00FF00FF);
        input = ((input << 16) & 0xFFFF0000FFFF0000) | ((input >> 16) & 0x0000FFFF0000FFFF);
        return int64((input << 32) | ((input >> 32) & 0xFFFFFFFF));
    }

    function readLittleEndianUnsigned128(uint128 input) internal pure returns (uint128) {
        // swap bytes
        input = ((input & 0xFF00FF00FF00FF00FF00FF00FF00FF00) >> 8) | ((input & 0x00FF00FF00FF00FF00FF00FF00FF00FF) << 8);

        // swap 2-byte long pairs
        input = ((input & 0xFFFF0000FFFF0000FFFF0000FFFF0000) >> 16) | ((input & 0x0000FFFF0000FFFF0000FFFF0000FFFF) << 16);

        // swap 4-byte long pairs
        input = ((input & 0xFFFFFFFF00000000FFFFFFFF00000000) >> 32) | ((input & 0x00000000FFFFFFFF00000000FFFFFFFF) << 32);

        // swap 8-byte long pairs
        return (input >> 64) | (input << 64);
    }

    function readLittleEndianSigned128(uint128 input) internal pure returns (int128) {
        input = ((input << 8) & 0xFF00FF00FF00FF00FF00FF00FF00FF00) | ((input >> 8) & 0x00FF00FF00FF00FF00FF00FF00FF00FF);
        input = ((input << 16) & 0xFFFF0000FFFF0000FFFF0000FFFF0000) | ((input >> 16) & 0x0000FFFF0000FFFF0000FFFF0000FFFF);
        input = ((input << 32) & 0xFFFFFFFF00000000FFFFFFFF00000000) | ((input >> 32) & 0x00000000FFFFFFFF00000000FFFFFFFF);
        return int128((input << 64) | ((input >> 64) & 0xFFFFFFFFFFFFFFFF));
    }

    function readLittleEndianUnsigned256(uint256 input) internal pure returns (uint256) {
        // swap bytes
        input = ((input & 0xFF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00) >> 8) |
            ((input & 0x00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF) << 8);

        // swap 2-byte long pairs
        input = ((input & 0xFFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000) >> 16) |
            ((input & 0x0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF) << 16);

        // swap 4-byte long pairs
        input = ((input & 0xFFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000) >> 32) |
            ((input & 0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF) << 32);

        // swap 8-byte long pairs
        input = ((input & 0xFFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF0000000000000000) >> 64) |
            ((input & 0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF) << 64);

        // swap 16-byte long pairs
        return (input >> 128) | (input << 128);
    }

    function readLittleEndianSigned256(uint256 input) internal pure returns (int256) {
        input = ((input << 8) & 0xFF00FF00FF00FF00FF00FF00FF00FF00) | ((input >> 8) & 0x00FF00FF00FF00FF00FF00FF00FF00FF);
        input = ((input << 16) & 0xFFFF0000FFFF0000FFFF0000FFFF0000) | ((input >> 16) & 0x0000FFFF0000FFFF0000FFFF0000FFFF);
        input = ((input << 32) & 0xFFFFFFFF00000000FFFFFFFF00000000) | ((input >> 32) & 0x00000000FFFFFFFF00000000FFFFFFFF);
        input = ((input << 64) & 0xFFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF0000000000000000) | ((input >> 64) & 0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF);
        return int256((input << 128) | ((input >> 128) & 0xFFFFFFFFFFFFFFFF));
    }

    function sliceBytes(bytes memory _bytes, uint256 _start, uint256 _length, bool _shift) internal pure returns (bytes memory) {
        require(_bytes.length >= _start + _length, OutOfBounds());

        bytes memory tempBytes;
        if(_length == 0) return tempBytes;

        assembly {
            // Have tempBytes point to the current free memory pointer
            tempBytes := mload(0x40)
            // Calculate length % 32 to get the length of the first slice (the first slice may be less than 32 bytes)
            // while all slices after will be 32 bytes)
            let firstSliceLength := and(_length, 31) // &(x, n-1) == x % n
            // Calculate 32 bytes slices count (excluding the first slice)
            let fullSlicesCount := div(_length, 0x20)
            // Calculate the start position of the first 32 bytes slice to copy, which will include the first slice and
            // some extra data on the left that we will overwrite
            let firstSliceStartPosition := add(add(_bytes, _start), sub(0x20, firstSliceLength))
            // Calculate the end position of the last slice to copy
            let lastSliceEndPosition := add(add(firstSliceStartPosition, 0x20), mul(fullSlicesCount, 0x20))
            // Calculate the position where we will copy the first 32 bytes of data, which will include the first slice
            // and some extra data on the left that we will overwrite
            let firstSliceCopyPosition := add(tempBytes, sub(0x20, firstSliceLength))
            // Copy slices in memory
            for {
                let nextSliceStartPosition := firstSliceStartPosition
                let nextSliceCopyPosition := firstSliceCopyPosition
            }
            lt(nextSliceStartPosition, lastSliceEndPosition)
            {
                // Update the start position of the next slice to copy
                nextSliceStartPosition := add(nextSliceStartPosition, 0x20)
                // Update the position where we will copy the next slice
                nextSliceCopyPosition := add(nextSliceCopyPosition, 0x20)
            } {
                // Copy the slice
                mcopy(nextSliceCopyPosition, nextSliceStartPosition, 0x20)
            }
            // Store copied data length a the tempBytes position, overwriting extra data that was copied with the first
            // slice
            mstore(tempBytes, _length)
            // Update the free memory pointer to: tempBytes position + 32 bytes length + (32 bytes * fullSlicesCount)
            // + 32 bytes for the first slice (if it has non-zero length)
            mstore(0x40, add(
                add(tempBytes, 0x20),
                add(
                    mul(fullSlicesCount, 0x20),
                    mul(sub(1, iszero(firstSliceLength)), 0x20)
                )
            ))
            // If only one slice was copied and its length is less than 32 bytes, shift those bytes to the right when
            // the _shift flag is set to true (to facilitate casting of returned data to non-dynamic types)
            if and(_shift, and(eq(fullSlicesCount, 0), lt(firstSliceLength, 32))) {
                // Calculate bits shift value
                let bitsShift := mul(sub(32, firstSliceLength), 8)
                // Load slice to be shifted
                let slice := mload(add(tempBytes, 0x20))
                // Store slice after shifting its bits to the right
                mstore(add(tempBytes, 0x20), shr(bitsShift, slice))
                // Update slice length in tempBytes length slot to be 32 bytes
                mstore(tempBytes, 0x20)
            }
        }

        return tempBytes;
    }
}