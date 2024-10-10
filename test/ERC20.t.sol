// SPDX-License-Identifier: MIT
pragma solidity >=0.6.8;

import "forge-std/Test.sol";
import "../src/ERC20.sol"; // Assuming the contract file is named Erc20Test.sol

contract Erc20TestUnit is Test {
    Erc20 public erc20;

    function setUp() public {
        erc20 = new Erc20("Test Token", "TST");
    }

    function testInitialSupply() public {
        uint256 expectedSupply = 1000000 * (10 ** 18);
        assertEq(erc20.totalSupply(), expectedSupply, "Initial supply should be 1,000,000 tokens");
    }

    function testMintingToOwner() public {
        uint256 ownerBalance = erc20.balanceOf(address(this));
        uint256 expectedBalance = 1000000 * (10 ** 18);
        assertEq(ownerBalance, expectedBalance, "Owner should have the full initial supply");
    }

    function testTokenTransfer() public {
        address recipient = address(0x123);
        uint256 transferAmount = 1000 * (10 ** 18);
        erc20.transfer(recipient, transferAmount);

        uint256 recipientBalance = erc20.balanceOf(recipient);
        assertEq(recipientBalance, transferAmount, "Recipient should receive transferred tokens");
    }
}
