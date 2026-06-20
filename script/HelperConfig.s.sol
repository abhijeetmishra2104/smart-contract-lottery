//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script} from "../lib/forge-std/src/Script.sol";
import {VRFCoordinatorV2_5Mock} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";


abstract contract CodeConstants {
    uint96 public MOCK_BASE_FEE = 0.25 ether;
    uint96 public MOCK_GAS_PRICE_LINK = 1e9;
    // The default value from the Cyfrin course makes LINK artificially
    // inexpensive (1 LINK = 1e9 wei), which causes the VRF mock to charge
    // unrealistically large LINK payments during stress tests.
    //
    // We use 1 ether so that 1 LINK = 1 ETH for testing purposes.
    int256 public MOCK_WEI_PER_UNIT_LINK = 1 ether;
    uint256 public constant SEPOLIA_NETWORK_CHAIN_ID = 11155111;
    uint256 public constant LOCAL_CHAIN_ID = 31337;
}

contract HelperConfig is CodeConstants, Script{
    error HelperConfig__InvalidChainId();

    struct NetworkConfig {
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 gasLane;
        uint32 callbackGasLimit;
        uint256 subscriptionId;
        address link;
        address account;
    }

    NetworkConfig public localNetworkConfig;
    mapping(uint256 chainId => NetworkConfig) public networkConfigs;

    constructor(){
        networkConfigs[SEPOLIA_NETWORK_CHAIN_ID] = getSepoliaEthConfig();
    }

    function getConfigByChainId(uint256 chainid) public returns(NetworkConfig memory){
        if(networkConfigs[chainid].vrfCoordinator != address(0)){
            return networkConfigs[chainid];
        }else if(chainid == LOCAL_CHAIN_ID){
            return getAnvilEthConfig();
        }else{
            revert HelperConfig__InvalidChainId();
        }
    }

    function getActiveNetworkConfig() public returns(NetworkConfig memory){
        return getConfigByChainId(block.chainid);
    }

    function getSepoliaEthConfig() public pure returns(NetworkConfig memory){
        return NetworkConfig({
            entranceFee: 0.001 ether,
            interval: 30,
            vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            callbackGasLimit: 250000,
            subscriptionId: 88677543754270709567085237842001876299063513758248655764705309989436128822048, 
            link: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
            account: 0x6011830063913b475BCB0Da5Cdb174304A13e744
        });
    }

    function getAnvilEthConfig() public returns(NetworkConfig memory){
        if(localNetworkConfig.vrfCoordinator != address(0)){
            return localNetworkConfig;
        }
        address deployer = 0x6011830063913b475BCB0Da5Cdb174304A13e744;
        vm.startBroadcast(deployer);
        VRFCoordinatorV2_5Mock vrfCoordinatorMock = new VRFCoordinatorV2_5Mock(MOCK_BASE_FEE, MOCK_GAS_PRICE_LINK, MOCK_WEI_PER_UNIT_LINK);
        LinkToken linkToken = new LinkToken();
        uint256 subscriptionId = vrfCoordinatorMock.createSubscription();
        vm.stopBroadcast();
        localNetworkConfig = NetworkConfig({
            entranceFee: 0.001 ether,
            interval: 30,
            vrfCoordinator: address(vrfCoordinatorMock),
            //does not matter what we put here as long as it is a valid bytes32 value because the mock does not check for the gas lane value
            gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            callbackGasLimit: 250000,
            subscriptionId: subscriptionId, 
            link: address(linkToken),
            account: deployer
        });
        return localNetworkConfig;
    }
}