// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Raffle} from "../../src/Raffle.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {HelperConfig, CodeConstants} from "../../script/HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from
    "../../lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {Vm} from "forge-std/Vm.sol";


contract BaseStressTest is Test, CodeConstants {

    uint256 internal constant SMALL = 10;
    uint256 internal constant MEDIUM = 100;
    uint256 internal constant LARGE = 1000;
    uint256 internal constant EXTREME = 10000;

    Raffle internal raffle;
    HelperConfig internal helperConfig;

    uint256 internal entranceFee;
    uint256 internal interval;

    address internal vrfCoordinator;
    uint256 internal subscriptionId;

    struct StressResult {
        address winner;
        uint256 prize;
        uint256 timestamp;
        uint256 requestId;
    }
    function _prepareLottery(uint256 players) internal {
        _enterPlayers(players);
        _moveTimeForward();
    }

    function _enterPlayers(uint256 numberOfPlayers) internal {
        for (uint256 i = 0; i < numberOfPlayers; i++) {
            address player = makeAddr(string.concat("player", vm.toString(i)));

            hoax(player, 10 ether);

            raffle.enterRaffle{value: entranceFee}();
        }
    }

    function _moveTimeForward() internal {
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
    }

    function _performUpkeep() internal returns (uint256 requestId) {
        vm.recordLogs();

        raffle.performUpkeep();

        Vm.Log[] memory logs = vm.getRecordedLogs();

        for (uint256 i = 0; i < logs.length; i++) {
            if (logs[i].emitter == address(raffle)) {
                return uint256(logs[i].topics[1]);
            }
        }

        revert("RequestId not found");
    }

    function _fulfillRandomWords(uint256 requestId) internal {
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(
            requestId,
            address(raffle)
        );
    }

    function _runLottery(uint256 numberOfPlayers) internal returns (StressResult memory result){
        _enterPlayers(numberOfPlayers);

        uint256 prize = entranceFee * numberOfPlayers;

        _moveTimeForward();

        uint256 requestId = _performUpkeep();

        _fulfillRandomWords(requestId);
        assertEq(
            uint256(raffle.getRaffleState()),
            uint256(Raffle.RaffleState.OPEN)
        );

        result = StressResult({
            winner: raffle.getRecentWinner(),
            prize: prize,
            timestamp: raffle.getLastTimeStamp(),
            requestId: requestId
        });
    }

    function _assertLotterySuccess(
        StressResult memory result,
        uint256 expectedPlayers
    ) internal {
        assertTrue(result.winner != address(0));

        assertEq(
            result.prize,
            entranceFee * expectedPlayers
        );

        assertEq(address(raffle).balance, 0);

        assertEq(
            uint256(raffle.getRaffleState()),
            uint256(Raffle.RaffleState.OPEN)
        );

        vm.expectRevert();
        raffle.getPlayer(0);
    }

    function _winnerIsPlayer(
        address winner,
        uint256 numberOfPlayers
    ) internal returns (bool) {
        for (uint256 i = 0; i < numberOfPlayers; i++) {
            address player =
                makeAddr(string.concat("player", vm.toString(i)));

            if (winner == player) {
                return true;
            }
        }

        return false;
    }

    function _deployFreshRaffle() internal {
        DeployRaffle deployer = new DeployRaffle();

        (raffle, helperConfig) = deployer.deployContract();

        HelperConfig.NetworkConfig memory config =
            helperConfig.getActiveNetworkConfig();

        entranceFee = config.entranceFee;
        interval = config.interval;
        vrfCoordinator = config.vrfCoordinator;
        subscriptionId = config.subscriptionId;

        _fundSubscription();
    }

    function setUp() public virtual {
        _deployFreshRaffle();
    }

    function _fundSubscription() internal {
        VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(
            subscriptionId,
            10_000_000 ether
        );
    }
}