// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/OrderBook.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract OrderBookTest is Test {
    OrderBook public orderBook;
    MockERC20 public tradeToken;
    MockERC20 public baseToken;
    OrderBook public orderBookSet;

    function setUp() public {
        tradeToken = new MockERC20("Trade Token", "TKN");
        baseToken = new MockERC20("Base Token", "BASE");
        orderBookSet = new OrderBook(address(tradeToken), address(baseToken));// Mint tokens to the contract so it can facilitate trades
        baseToken.mint(address(orderBookSet), 10000 * 10**18); // Mint sufficient base tokens
        tradeToken.mint(address(orderBookSet), 10000 * 10**18); // Mint sufficient trade tokens
    }

    function testCalculateTotalCost() public view {
        uint256 price = 2 * 10**18; // 2 BASE per TKN
        uint256 amount = 5 * 10**18; // Buying 5 TKN
        uint256 expectedTotalCost = 10 * 10**18; // Total cost is 10 BASE

        uint256 totalCost = orderBookSet.calculateTotalCost(price, amount);
        assertEq(totalCost, expectedTotalCost, "Total cost calculation is incorrect");
    }

    function testMatchAmount() public view {
        uint256 available = 10 * 10**18;
        uint256 requested = 5 * 10**18;
        uint256 expectedMatch = 5 * 10**18;

        uint256 matchedAmount = orderBookSet.matchAmount(available, requested);
        assertEq(matchedAmount, expectedMatch, "Match amount calculation is incorrect");

        available = 3 * 10**18;
        requested = 5 * 10**18;
        expectedMatch = 3 * 10**18;

        matchedAmount = orderBookSet.matchAmount(available, requested);
        assertEq(matchedAmount, expectedMatch, "Match amount calculation with lower available amount is incorrect");
    }

    function testBuyOrder() public {
        tradeToken = new MockERC20("Trade Token", "TKN");
        baseToken = new MockERC20("Base Token", "BASE");
        orderBook = new OrderBook(address(tradeToken), address(baseToken));
        tradeToken.mint(address(orderBook), 1000 * 10**18); // Provide trade tokens to the contract
        baseToken.mint(address(this), 1000 * 10**18); // Provide base tokens to msg.sender

        uint256 price = 2 * 10**18; // 2 BASE per TKN
        uint256 amount = 5 * 10**18; // Buying 5 TKN
        uint256 totalCost = (price * amount) / 1e18;

        emit log_named_uint("Initial baseToken balance", baseToken.balanceOf(address(this)));
        emit log_named_uint("Initial tradeToken balance (contract)", tradeToken.balanceOf(address(orderBook)));

        baseToken.approve(address(orderBook), totalCost); 
        emit log_named_uint("Allowance", baseToken.allowance(address(this), address(orderBook)));

        uint256 initialBaseBalance = baseToken.balanceOf(address(this));
        uint256 initialTradeBalance = tradeToken.balanceOf(address(this));

        orderBook.PlaceBuyOrder(price, amount);

        uint256 finalBaseBalance = baseToken.balanceOf(address(this));
        uint256 finalTradeBalance = tradeToken.balanceOf(address(this));

        emit log_named_uint("Final baseToken balance", finalBaseBalance);
        emit log_named_uint("Final tradeToken balance", finalTradeBalance);

        assertEq(finalBaseBalance, initialBaseBalance - totalCost, "Incorrect baseToken balance after buy order");
        assertEq(finalTradeBalance, initialTradeBalance + amount, "Incorrect tradeToken balance after buy order");
    }

    function testSellOrder() public {
        tradeToken = new MockERC20("Trade Token", "TKN");
        baseToken = new MockERC20("Base Token", "BASE");

        orderBook = new OrderBook(address(tradeToken), address(baseToken));

        tradeToken.mint(address(this), 1000 * 10**18); 
        tradeToken.mint(address(orderBook), 1000 * 10**18); 

        // Approve the trade tokens for sale
        uint256 amount = 5 * 10**18; // Selling 5 TKN
        tradeToken.approve(address(orderBook), amount); // Approve transfer of trade tokens

        uint256 initialTradeBalance = tradeToken.balanceOf(address(this));

        orderBook.PlaceSellOrder(2 * 10**18, amount);
        uint256 finalTradeBalance = tradeToken.balanceOf(address(this));

        assertEq(finalTradeBalance, initialTradeBalance - amount, "Incorrect tradeToken balance after sell order");

        (address user,, uint256 sellAmount) = orderBook.sellOrders(2 * 10**18, 0); // Price 2 * 10**18, first sell order
        assertEq(user, address(this), "Sell order not recorded correctly");
        assertEq(sellAmount, amount, "Sell order amount not recorded correctly");
    }

    function testGetters() public {
        uint256 price = 2 * 10**18;

        uint256 buyOrderCount = orderBookSet.getBuyOrders(price).length;
        uint256 sellOrderCount = orderBookSet.getSellOrders(price).length;

        assertEq(buyOrderCount, 0, "Initial buy order count should be 0");
        assertEq(sellOrderCount, 0, "Initial sell order count should be 0");

        uint256 minSellPrice = orderBookSet.getMinSellPrice();
        uint256 maxBuyPrice = orderBookSet.getMaxBuyPrice();

        assertEq(minSellPrice, 0, "Initial minSellPrice should be 0");
        assertEq(maxBuyPrice, 0, "Initial maxBuyPrice should be 0");

        address tradeTokenAddress = orderBookSet.getTradeToken();
        address baseTokenAddress = orderBookSet.getBaseToken();

        assertEq(tradeTokenAddress, address(tradeToken), "TradeToken address mismatch");
        assertEq(baseTokenAddress, address(baseToken), "BaseToken address mismatch");
    }
}
