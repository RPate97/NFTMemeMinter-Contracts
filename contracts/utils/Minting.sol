// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Bytes.sol";

library Minting {
    // Split the minting blob into token_id and blueprint portions
    // {token_id}:{blueprint}

    function split(bytes calldata blob)
        internal
        pure
        returns (uint256, bytes32, address)
    {
        int256 index = Bytes.indexOf(blob, ":", 0);
        require(index >= 0, "Separator must exist");
        // Trim the { and } from the parameters
        uint256 tokenID = Bytes.toUint(blob[1:uint256(index) - 1]);
        bytes calldata blueprint = blob[uint256(index) + 2:blob.length - 1];
        (bytes32 _hash, address _creator) = splitBlueprint(blueprint);
        return (tokenID, _hash, _creator);
    }

    function splitBlueprint(bytes calldata blueprint) 
        internal
        pure
        returns (bytes32 _hash, address _creator) 
    {
        require(blueprint.length == 52, "Blueprint must be 52 bytes");
        _hash = bytes32(blueprint[0:31]);
        _creator = Bytes.bytesToAddress(blueprint[32:52]);
    }
}
