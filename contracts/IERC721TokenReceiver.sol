// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

/**
 * @dev _Available since v3.1._
 */
interface IERC721TokenReceiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC721 fungible token type. This function is
        called at the end of a `safeTransferTreeFiddiesFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC721TokenReceived(address,address,uint256)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        An ERC721 fungible token type is a semifunctional token implemented within an ERC721. 
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC721TokenReceived(address,address,uint256,bytes)"))` if transfer is allowed
    */
    function onERC721TokenReceived(
        address operator,
        address from,
        uint256 value,
        bytes calldata data
    ) external pure returns (bytes4);
}