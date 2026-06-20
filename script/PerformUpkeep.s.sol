// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";
import {Raffle} from "../src/Raffle.sol";

contract PerformUpkeep is Script {
    function run() external {
        address raffleAddress = DevOpsTools.get_most_recent_deployment(
            "Raffle",
            block.chainid
        );

        performUpkeep(raffleAddress);
    }

    function performUpkeep(address raffleAddress) public {
        console2.log("Raffle:", raffleAddress);

        Raffle raffle = Raffle(payable(raffleAddress));

        (bool upkeepNeeded,) = raffle.checkUpkeep("");

        console2.log("Upkeep Needed:", upkeepNeeded);

        if (!upkeepNeeded) {
            console2.log("Upkeep not needed.");
            return;
        }

        vm.startBroadcast();

        raffle.performUpkeep();

        vm.stopBroadcast();

        console2.log("performUpkeep() executed successfully.");
    }
}