// SPDX-License-Identifier: MIT

pragma solidity >=0.6.8;
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract OrderBook is ReentrancyGuard {
    IERC20 public tradeToken;
    IERC20 public baseToken;

    struct Order {
        address user;
        uint256 price;
        uint256 amount;
    }

    // Mappings to store buy and sell orders
    mapping(uint256 => Order[]) public buyOrders;
    mapping(uint256 => Order[]) public sellOrders;

    uint256 public minSellPrice;
    uint256 public maxBuyPrice;

    constructor(address _tradeToken, address _baseToken) {
        tradeToken = IERC20(_tradeToken);
        baseToken = IERC20(_baseToken);
    }

    // Helper function to calculate the total cost of a buy order
    function calculateTotalCost(uint256 price, uint256 amount) public pure returns (uint256) {
        return (price * amount) / 1e18;
    }

    // Helper function to find the remaining trade amount after matching
    function matchAmount(uint256 available, uint256 requested) public pure returns (uint256) {
        return available > requested ? requested : available;
    }

    function PlaceBuyOrder(uint256 price, uint256 amount) external nonReentrant {
        uint256 totalCost = calculateTotalCost(price, amount);

        // Check allowances and balances before transfer
        require(baseToken.allowance(msg.sender, address(this)) >= totalCost, "ERC20: insufficient allowance");
        require(baseToken.balanceOf(msg.sender) >= totalCost, "ERC20: insufficient balance");

        baseToken.transferFrom(msg.sender, address(this), totalCost);
        require(tradeToken.balanceOf(address(this)) >= amount, "ERC20: insufficient contract balance");

        tradeToken.transfer(msg.sender, amount);

        // Match orders if applicable
        if (minSellPrice != 0 && price >= minSellPrice) {
            matchBuyOrder(price, amount);
        } else {
            buyOrders[price].push(Order({ user: msg.sender, price: price, amount: amount }));
            if (price > maxBuyPrice) {
                maxBuyPrice = price;
            }
        }
    }

    function PlaceSellOrder(uint256 price, uint256 amount) external nonReentrant {
        tradeToken.transferFrom(msg.sender, address(this), amount);

        // Match orders if applicable
        if (maxBuyPrice != 0 && price <= maxBuyPrice) {
            matchSellOrder(price, amount);
        } else {
            sellOrders[price].push(Order({ user: msg.sender, price: price, amount: amount }));
            if (minSellPrice == 0 || price < minSellPrice) {
                minSellPrice = price;
            }
        }
    }

    function matchBuyOrder(uint256 price, uint256 amount) internal {
        uint256 remainingAmount = amount;

        if (sellOrders[minSellPrice].length > 0 && price >= minSellPrice) {
            for (uint256 p = minSellPrice; p <= price && remainingAmount > 0; p++) {
                Order[] storage sellOrdersAtPrice = sellOrders[p];
                for (uint256 i = 0; i < sellOrdersAtPrice.length && remainingAmount > 0; i++) {
                    Order storage sellOrder = sellOrdersAtPrice[i];

                    uint256 tradeAmount = matchAmount(sellOrder.amount, remainingAmount);
                    tradeToken.transfer(msg.sender, tradeAmount);
                    baseToken.transfer(sellOrder.user, tradeAmount * p);

                    sellOrder.amount -= tradeAmount;
                    remainingAmount -= tradeAmount;

                    if (sellOrder.amount == 0) {
                        delete sellOrdersAtPrice[i];
                    }
                }

                if (sellOrders[p].length == 0) {
                    minSellPrice = p + 1;
                }
            }
        }

        if (remainingAmount > 0) {
            buyOrders[price].push(Order({ user: msg.sender, price: price, amount: remainingAmount }));
            if (price > maxBuyPrice) {
                maxBuyPrice = price;
            }
        }
    }

    function matchSellOrder(uint256 price, uint256 amount) internal {
    uint256 remainingAmount = amount;

    for (uint256 p = maxBuyPrice; p >= price && remainingAmount > 0; p--) {
        Order[] storage buyOrdersAtPrice = buyOrders[p];
        for (uint256 i = 0; i < buyOrdersAtPrice.length && remainingAmount > 0; i++) {
            Order storage buyOrder = buyOrdersAtPrice[i];

            uint256 tradeAmount = matchAmount(buyOrder.amount, remainingAmount);
            uint256 totalBaseTokenAmount = tradeAmount * p;

            // Ensure contract has enough base tokens before proceeding
            require(baseToken.balanceOf(address(this)) >= totalBaseTokenAmount, "ERC20: insufficient contract balance");

            tradeToken.transfer(buyOrder.user, tradeAmount);
            baseToken.transfer(msg.sender, totalBaseTokenAmount);

            buyOrder.amount -= tradeAmount;
            remainingAmount -= tradeAmount;

            if (buyOrder.amount == 0) {
                delete buyOrdersAtPrice[i];
            }
        }

        if (buyOrders[p].length == 0) {
            maxBuyPrice = p - 1;
        }
    }

    // Handle any remaining sell amount (if not fully matched)
    if (remainingAmount > 0) {
        sellOrders[price].push(Order({ user: msg.sender, price: price, amount: remainingAmount }));
        if (minSellPrice == 0 || price < minSellPrice) {
            minSellPrice = price;
            }
        }
    }


    function getBuyOrders(uint256 price) external view returns (Order[] memory) {
        return buyOrders[price];
    }

    function getSellOrders(uint256 price) external view returns (Order[] memory) {
        return sellOrders[price];
    }

    function getMinSellPrice() external view returns (uint256) {
        return minSellPrice;
    }

    function getMaxBuyPrice() external view returns (uint256) {
        return maxBuyPrice;
    }

    function getTradeToken() external view returns (address) {
        return address(tradeToken);
    }

    function getBaseToken() external view returns (address) {
        return address(baseToken);
    }
}
