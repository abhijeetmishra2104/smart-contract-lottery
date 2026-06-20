//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script} from "../lib/forge-std/src/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "./Interactions.s.sol";

contract DeployRaffle is Script {
    uint256 public constant LOCAL_CHAIN_ID = 31337;
    
    function run() public {
        deployContract();
    }
    function deployContract() public returns(Raffle, HelperConfig){
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getActiveNetworkConfig();

        if (config.subscriptionId == 0) {
            CreateSubscription subscriptionCreator = new CreateSubscription();
            (config.subscriptionId, config.vrfCoordinator) = subscriptionCreator.createSubscriptionUsingConfig();
        }

        if (block.chainid == LOCAL_CHAIN_ID) {
            FundSubscription subscriptionFunder = new FundSubscription();
            subscriptionFunder.fundSubscription(config.vrfCoordinator, config.subscriptionId, config.link, config.account);
        }

        vm.startBroadcast(config.account);
        Raffle raffle = new Raffle(
            config.entranceFee,
            config.interval,
            config.vrfCoordinator,
            config.gasLane,
            config.subscriptionId,
            config.callbackGasLimit
        );
        vm.stopBroadcast();

        AddConsumer consumerAdder = new AddConsumer();
        consumerAdder.addConsumer(address(raffle), config.vrfCoordinator, config.subscriptionId, config.account);
        return (raffle, helperConfig);
    }
}