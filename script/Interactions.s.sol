//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "../lib/forge-std/src/Script.sol";
import {HelperConfig, CodeConstants} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";


contract CreateSubscription is Script {
    function createSubscriptionUsingConfig() public returns(uint256, address){
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getActiveNetworkConfig().vrfCoordinator;
        address account = helperConfig.getActiveNetworkConfig().account;
        (uint256 subId, ) = createSubscription(vrfCoordinator, account);
        return (subId, vrfCoordinator);
    }

    function createSubscription(address vrfCoordinator, address account) public returns(uint256, address){
        console.log("Creating Subscription on chain ID: ", block.chainid);
        vm.startBroadcast(account);
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();
        console.log("Your subscription Id is : ", subId);
        console.log("Please update the subscription Id in HelperConfig.s.sol");
        return (subId, vrfCoordinator);
    }


    function run() public {
        createSubscriptionUsingConfig();
    }
}

contract FundSubscription is Script, CodeConstants {
    uint96 public constant FUND_AMOUNT = 100 ether;


    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getActiveNetworkConfig().vrfCoordinator;
        uint256 subscriptionId = helperConfig.getActiveNetworkConfig().subscriptionId;
        address linkToken = helperConfig.getActiveNetworkConfig().link;
        address account = helperConfig.getActiveNetworkConfig().account;
        fundSubscription(vrfCoordinator, subscriptionId, linkToken, account);
    }

    function fundSubscription(address vrfCoordinator, uint256 subscriptionId, address linkToken, address account) public {
        console.log("Funding Subscription: ", subscriptionId);
        console.log("Using vrfCoordinator: ", vrfCoordinator);
        console.log("On chainId : ", block.chainid);

        if(block.chainid == LOCAL_CHAIN_ID){
            vm.startBroadcast();
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(subscriptionId, FUND_AMOUNT * 10000);
            vm.stopBroadcast();
        }
        else {
            vm.startBroadcast(account);
            LinkToken(linkToken).transferAndCall(vrfCoordinator, FUND_AMOUNT, abi.encode(subscriptionId));
            vm.stopBroadcast();
        }
    }

    function run() public {
        fundSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script {
    function addConsumerUsingConfig(address mostRecentlyDeployed) public {
        HelperConfig helperConfig = new HelperConfig();
        uint256 subId = helperConfig.getActiveNetworkConfig().subscriptionId;
        address vrfCoordinator = helperConfig.getActiveNetworkConfig().vrfCoordinator;
        address account = helperConfig.getActiveNetworkConfig().account;
        addConsumer(mostRecentlyDeployed, vrfCoordinator, subId, account);
    }

    function addConsumer(address contractAddToVrf, address vrfCoordinator, uint256 subId, address account) public{
        console.log("Adding Consumer contract: ", contractAddToVrf);
        console.log("To vrfCoordinator: ", vrfCoordinator);
        console.log("On ChainId: ", block.chainid);
        vm.startBroadcast(account);
        VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(subId, contractAddToVrf);
        vm.stopBroadcast();
    }


    function run() external{
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
        addConsumerUsingConfig(mostRecentlyDeployed);
    }
}