//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test , console2} from "lib/forge-std/src/Test.sol";
import {Raffle, Raffle__SendMoreToEnterRaffle, Raffle__RaffleNotOpen, Raffle__UpKeepNotNeeded} from "../../src/Raffle.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Vm} from "lib/forge-std/src/Vm.sol";
import {VRFCoordinatorV2_5Mock} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {CodeConstants} from "../../script/HelperConfig.s.sol";

contract RaffleTest is CodeConstants, Test { 
    Raffle public raffle;
    HelperConfig public helperConfig;
    
    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_USER_BALANCE = 10 ether;

    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint32 callbackGasLimit;
    uint256 subscriptionId;

    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.deployContract();
        HelperConfig.NetworkConfig memory config = helperConfig.getActiveNetworkConfig();
        entranceFee = config.entranceFee;
        interval = config.interval;
        vrfCoordinator = raffle.getVrfCoordinator();
        gasLane = config.gasLane;
        callbackGasLimit = config.callbackGasLimit;
        subscriptionId = config.subscriptionId;

        vm.deal(PLAYER, STARTING_USER_BALANCE);
    }

    function testRaffleInitializesInOpenState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    function testRaffleRevertsWhenNotPaidEnough() public {
        vm.prank(PLAYER);

        vm.expectRevert(Raffle__SendMoreToEnterRaffle.selector);
        raffle.enterRaffle();
    }

    function testRaffleRecordsPlayersWhenEntered() public {
        //Arrange 
        vm.prank(PLAYER);
        // ACT
        raffle.enterRaffle{value: entranceFee}();
        // ASSERT
        address playerRecorded = raffle.getPlayer(0);
        assert(playerRecorded == PLAYER);
    }

    function testEnteringRaffleEmitsEvent() public {
        // Arrange
        vm.prank(PLAYER);
        //Act
        vm.expectEmit(true, false, false, false, address(raffle));
        emit RaffleEntered(PLAYER);
        // Assert
        raffle.enterRaffle{value: entranceFee}();
    }

    function testDontAllowPlayersToEnterWhileRaffleIsCalculating() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();

        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep();

        vm.expectRevert(Raffle__RaffleNotOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }

    function testUpKeepReturnsFalseWhenItHasNoBalance() public {
        vm.warp(block.timestamp+interval+1);
        vm.roll(block.number+1);

        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(!upkeepNeeded);
    }

    function testUpKeepReturnsFalseWhenRaffleIsNotOpen() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();

        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep();
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(!upkeepNeeded);
    }

    function testPeformUpKeepCanOnlyRunIfCheckUpkeepIsTrue() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp+interval+1);
        vm.roll(block.number+1);

        raffle.performUpkeep();
    }

    function testPerformUpkeepRevertsIfCheckUpkeepIsFalse() public {
        uint256 currentBalance = 0;
        uint256 numPlayers = 0;
        Raffle.RaffleState rState = raffle.getRaffleState();

        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        currentBalance = currentBalance + entranceFee;
        numPlayers = 1;

        vm.expectRevert(abi.encodeWithSelector(Raffle__UpKeepNotNeeded.selector, currentBalance, numPlayers, rState));
        raffle.performUpkeep();
    }

    modifier raffleEntered(){
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp+interval+1);
        vm.roll(block.number+1);
        _;
    }

    function testPerformUpkeepUpdatesRaffleStateAndEmitsRequestId() public raffleEntered {
        vm.recordLogs();
        raffle.performUpkeep();
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        assert(uint256(requestId) > 0);
        assert(uint256(raffleState) == 1);
    }

    modifier skipFork() {
        if (block.chainid != 31337) {
            return;
         }
         _;
    }

    // stateless fuzz test
    function testFulfillrandomWordsCanOlyBeCalledAfterPerformUpkeep(uint256 randomRequestId) public raffleEntered skipFork{
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(randomRequestId, address(raffle));
    }

    function testFulfillRandomWordsPicksAWinnerResetsAndSendsMoney() public raffleEntered skipFork {
        address expectedWinner = address(1);

        // Arrange
        uint256 additionalEntrances = 3;
        uint256 startingIndex = 1; // We have starting index be 1 so we can start with address(1) and not address(0)

        for (uint256 i = startingIndex; i < startingIndex + additionalEntrances; i++) {
            address player = address(uint160(i));
            hoax(player, 1 ether); // deal 1 eth to the player
            raffle.enterRaffle{value: entranceFee}();
        }

        uint256 startingTimeStamp = raffle.getLastTimeStamp();
        uint256 startingBalance = expectedWinner.balance;

        // Act
        vm.recordLogs();
        raffle.performUpkeep(); // emits requestId
        Vm.Log[] memory entries = vm.getRecordedLogs();
        
        bytes32 requestId;
        // Find the RequestedRaffleWinner event from the Raffle contract
        for (uint256 i = 0; i < entries.length; i++) {
            if (entries[i].emitter == address(raffle)) {
                requestId = entries[i].topics[1];
                break;
            }
        }

        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(uint256(requestId), address(raffle));

        // Assert
        address recentWinner = raffle.getRecentWinner();
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        uint256 winnerBalance = recentWinner.balance;
        uint256 endingTimeStamp = raffle.getLastTimeStamp();
        uint256 prize = entranceFee * (additionalEntrances + 1);

        assert(recentWinner == expectedWinner);
        assert(uint256(raffleState) == 0);
        assert(winnerBalance == startingBalance + prize);
        assert(endingTimeStamp > startingTimeStamp);
    }

    

    function testStress100PlayersCompleteLottery() public skipFork {
        VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(
            subscriptionId,
            10_000_000 ether
        );
        uint256 numberOfPlayers = 1000;

        // Arrange
        for (uint256 i = 0; i < numberOfPlayers; i++) {
            address player = makeAddr(string.concat("player", vm.toString(i)));
            hoax(player, 10 ether);
            raffle.enterRaffle{value: entranceFee}();
        }

        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        // Record requestId
        vm.recordLogs();

        raffle.performUpkeep();

        Vm.Log[] memory logs = vm.getRecordedLogs();

        bytes32 requestId;

        for (uint256 i = 0; i < logs.length; i++) {
            if (logs[i].emitter == address(raffle)) {
                requestId = logs[i].topics[1];
                break;
            }
        }

        // VRF fulfills randomness
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(
            uint256(requestId),
            address(raffle)
        );

        // Assertions

        assertEq(
            uint256(raffle.getRaffleState()),
            uint256(Raffle.RaffleState.OPEN)
        );

        vm.expectRevert();
        raffle.getPlayer(0);

        assertGt(raffle.getLastTimeStamp(), 0);

        address winner = raffle.getRecentWinner();

        console2.log("Winner:", winner);
    }
}
