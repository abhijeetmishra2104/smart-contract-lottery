// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";
import {Raffle} from "../src/Raffle.sol";


contract EnterRaffle is Script {
    function run() external {
        address raffleAddress = DevOpsTools.get_most_recent_deployment(
            "Raffle",
            block.chainid
        );

        uint256 entranceFee = Raffle(payable(raffleAddress)).getEntranceFee();

        vm.startBroadcast();

        Raffle(payable(raffleAddress)).enterRaffle{value: entranceFee}();

        vm.stopBroadcast();
    }
}