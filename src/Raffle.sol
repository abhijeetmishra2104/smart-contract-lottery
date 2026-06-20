// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

error Raffle__SendMoreToEnterRaffle();
error Raffle__TransferFailed();
error Raffle__RaffleNotOpen();
error Raffle__UpKeepNotNeeded(uint256 balance, uint256 playersLenght, uint256 raffleState);

/** @title A sample Raffle contract
    * @author Abhijeet Mishra
    * @notice This contract is for creating a sample raffle
    * @dev Implements Chailink VRFv2.5
 */


contract Raffle is VRFConsumerBaseV2Plus {

    enum RaffleState{
        OPEN,  // 0
        CALCULATING // 1
    }
   
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    uint32 private immutable i_callbackGasLimit;
    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
    uint256 private immutable i_subscriptionId;
    uint256 private s_lastTimeStamp;
    bytes32 private immutable i_keyHash;
    address payable[] private s_players;
    address payable private s_recentWinner;
    RaffleState private s_raffleState;
    

    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);
    event RequestedRaffleWinner(uint256 indexed requestId);

    constructor(uint256 entranceFee, uint256 interval, address vrfCoordinator, bytes32 gasLane, uint256 subscriptionId, uint32 callbackGasLimit) VRFConsumerBaseV2Plus(vrfCoordinator){
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
        i_keyHash = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_raffleState = RaffleState.OPEN;   
    }

    function enterRaffle() external payable{
        // require(msg.value >= i_entranceFee, Raffle__SendMoreToEnterRaffle());
        if(msg.value<i_entranceFee){
            revert Raffle__SendMoreToEnterRaffle();
        }
        if(s_raffleState != RaffleState.OPEN){
            revert Raffle__RaffleNotOpen();
        }
        s_players.push(payable(msg.sender));
        emit RaffleEntered(msg.sender);
    }

    function checkUpkeep(bytes memory /*checkData*/) public view returns(bool upkeepNeeded, bytes memory /* performData */) {
        bool timeHasPassed = (block.timestamp - s_lastTimeStamp) >= i_interval;
        bool isOpen = s_raffleState == RaffleState.OPEN;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;
        upkeepNeeded = isOpen && hasBalance && hasPlayers && timeHasPassed;
        return (upkeepNeeded, hex"");
    }

    function performUpkeep() external {
        (bool upkeepNeeded,) = checkUpkeep(hex"");
        if(!upkeepNeeded){
            revert Raffle__UpKeepNotNeeded(address(this).balance, s_players.length, uint256(s_raffleState));
        }
        s_raffleState = RaffleState.CALCULATING;
        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient.RandomWordsRequest({
            keyHash: i_keyHash,
            subId: i_subscriptionId,
            requestConfirmations: REQUEST_CONFIRMATIONS,
            callbackGasLimit: i_callbackGasLimit,
            numWords: NUM_WORDS,
            extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: false}))
        });
        uint256 requestId = s_vrfCoordinator.requestRandomWords(request);
        emit RequestedRaffleWinner(requestId);
    }

    function fulfillRandomWords(uint256 /*requestId*/, uint256[] calldata randomWords) internal override {
        //Checks 
            // No checks in this function 
        
        //Effects (Internal contract changes)
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        emit WinnerPicked(s_recentWinner);

        //Interactions (External contract changes)
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        if(!success){
            revert Raffle__TransferFailed();
        }
    }

    function getEntranceFee() external view returns(uint256){
        return i_entranceFee;
    }

    function getRaffleState() external view returns(RaffleState){
        return s_raffleState;
    }

    function getPlayer(uint256 indexOfPlayer) external view returns(address){
        return s_players[indexOfPlayer];
    }

    function getLastTimeStamp() external view returns(uint256){
        return s_lastTimeStamp;
    }

    function getRecentWinner() external view returns(address){
        return s_recentWinner;
    }

    function getVrfCoordinator() external view returns(address){
        return address(s_vrfCoordinator);
    }
}
