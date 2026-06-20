// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {BaseStressTest} from "./BaseStressTest.t.sol";


contract RaffleStressTest is BaseStressTest {
    modifier skipFork() {
        if (block.chainid != 31337) {
            return;
         }
         _;
    }
    
    function test10PlayersCanEnter() public skipFork {
        _enterPlayers(SMALL);

        for (uint256 i = 0; i < SMALL; i++) {
            address expectedPlayer =
                makeAddr(string.concat("player", vm.toString(i)));

            assertEq(
                raffle.getPlayer(i),
                expectedPlayer
            );
        }
    }

    function testLotteryWorksWith100Players() public skipFork {
        StressResult memory result =
            _runLottery(MEDIUM);

        _assertLotterySuccess(result, MEDIUM);
    }

    function testLotteryWorksWith1000Players() public skipFork {
        StressResult memory result =
            _runLottery(LARGE);

        _assertLotterySuccess(result, LARGE);
    }

    function testWinnerAlwaysBelongsToPlayers() public skipFork {
        StressResult memory result =
            _runLottery(250);

        assertTrue(
            _winnerIsPlayer(result.winner, 250)
        );
    }

    function testLotteryAlwaysResets() public skipFork {
        StressResult memory result =
            _runLottery(50);

        _assertLotterySuccess(result, 50);
    }

    function testMultipleConsecutiveLotteries() public skipFork {
        uint256 rounds = 5;

        for (uint256 i = 0; i < rounds; i++) {

            StressResult memory result =
                _runLottery(MEDIUM);

            _assertLotterySuccess(result, MEDIUM);
        }
    }
}