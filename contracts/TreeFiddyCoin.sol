// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./DankMinter.sol";

contract TreeFiddyCoin is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable, OwnableUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}
    DankMinter public dankMinterToken;
    address public dankMinterAddress;

    using SafeMath for uint256;

    /**@dev A function that gets TFs and mints TFCs
     * Requirements:
     *
     * - if the msg.sender is not augurFoundry then it needs to have given setApprovalForAll
     *  to this contract (if the msg.sender is augur foundry then we trust it and know that
     *  it would have transferred the ERC1155s to this contract before calling it)
     * @param _account account the newly minted ERC20s will go to
     * @param _amount amount of tokens to be wrapped
     */
    function wrapTokens(address _account, uint256 _amount) public {
        if (msg.sender != dankMinterAddress) {
            dankMinterToken.safeTransferTreeFiddiesFrom(
                msg.sender,
                address(this),
                _amount,
                ""
            );
        }
        _mint(_account, _amount);
    }

    /**@dev A function that burns TFCs and gives back TFs
     * Requirements:
     *
     * - if the msg.sender is not dankMinter or _account then the caller must have allowance for ``_account``'s tokens of at least
     * `amount`.
     * @param _account account the newly minted ERC20s will go to
     * @param _amount amount of tokens to be unwrapped
     */
    function unWrapTokens(address _account, uint256 _amount) public {
        if (msg.sender != _account && msg.sender != dankMinterAddress) {
            uint256 decreasedAllowance = allowance(_account, msg.sender).sub(
                _amount,
                "ERC20: burn amount exceeds allowance"
            );
            _approve(_account, msg.sender, decreasedAllowance);
        }
        _burn(_account, _amount);

        dankMinterToken.safeTransferTreeFiddiesFrom(
            address(this),
            _account,
            _amount,
            ""
        );
    }

    function onERC721TokenReceived(
        address operator,
        address from,
        uint256 value,
        bytes calldata data
    ) external pure returns (bytes4) {
        return (
            bytes4(
                keccak256(
                    "onERC1155RonERC721TokenReceivedeceived(address,address,uint256,bytes)"
                )
            )
        );
    }

    function initialize(address _dankMinterAddress) initializer public {
        __ERC20_init("TreeFiddyCoin", "TFC");
        __ERC20Burnable_init();
        __Ownable_init();
        dankMinterAddress = _dankMinterAddress;
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}