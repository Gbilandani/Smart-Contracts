// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract PriceConsumerV3 {
    AggregatorV3Interface internal Etherprice;
    AggregatorV3Interface internal Bitcoinprice;

    /**
     * Network: Sepolia
     * Aggregator: ETH/USD
     * Address: 0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43
     */
    constructor() {
        Etherprice = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
        Bitcoinprice = AggregatorV3Interface(0xA39434A63A52E749F02807ae27335515BA4b07F7);
    }

    /**
     * Returns the latest price.
     */
    function getLatestPrice() public view returns (int256,int256) {
        // prettier-ignore
        (
            /* uint80 roundID */,
            int256 Ether,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = Etherprice.latestRoundData();
        ( , int256 Bitcoin, , , ) = Bitcoinprice.latestRoundData();
        Ether = (Ether/10**8);
        Bitcoin = (Bitcoin/10**8);
        return (Ether, Bitcoin);
    }
}
