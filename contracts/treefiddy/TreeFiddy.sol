// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "../DankMinter.sol";

contract TreeFiddy is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable, OwnableUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}
    address public dankMinterAddress;
    uint transferIncrement;

    function initialize(address _dankMinterAddress) initializer public {
        __ERC20_init("TreeFiddy", "TF");
        __ERC20Burnable_init();
        __Ownable_init();
        dankMinterAddress = _dankMinterAddress;
        transferIncrement = 3 * 10 ** 18;
        transferIncrement = transferIncrement + (5 * 10 ** 17);
    }

    function mint(address to, uint256 amount) public {
        require(msg.sender == dankMinterAddress || msg.sender == owner(), "Sender is not Owner or DankMinter");
        _mint(to, amount);
    }

    function transferDankMinter(address from, address to, uint amount) public {
        require(msg.sender == dankMinterAddress, "Sender is not DankMinter");
        _transfer(from, to, amount); 
    }

    function burnFromDankMinter(address from, uint amount) public {
        require(msg.sender == dankMinterAddress, "Sender is not DankMinter");
        _burn(from, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal virtual override
    {
        super._beforeTokenTransfer(from, to, amount);
        if (msg.sender != dankMinterAddress) {
            require(amount % transferIncrement == 0, "This is a treefiddy dude, obviously you can only send it in increments of 3.5.");
        }
    }
}