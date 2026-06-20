//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import {BaseStressTest} from "./BaseStressTest.t.sol";


contract GasBenchmarkTest is BaseStressTest {

    modifier skipFork() {
        if (block.chainid != 31337) {
            return;
         }
         _;
    }

    struct GasBenchmark {
        uint256 players;
        uint256 enterGas;
        uint256 upkeepGas;
        uint256 fulfillGas;
    }
    function testGasEnterRaffle10Players() public skipFork {
        _enterPlayers(10);
    }

    function testGasEnterRaffle100Players() public skipFork {
        _enterPlayers(100);
    }

    function testGasEnterRaffle1000Players() public skipFork {
        _enterPlayers(1000);
    }

    function testGasPerformUpkeep10Players() public skipFork {

        _prepareLottery(10);

        raffle.performUpkeep();
    }

    function testGasPerformUpkeep100Players() public skipFork {

        _prepareLottery(100);

        raffle.performUpkeep();
    }

    function testGasPerformUpkeep1000Players() public skipFork {

        _prepareLottery(1000);

        raffle.performUpkeep();
    }

    function testGasFulfill10Players() public skipFork {

        _prepareLottery(10);

        uint256 requestId = _performUpkeep();

        _fulfillRandomWords(requestId);
    }

    function testGasFulfill100Players() public skipFork {

        _prepareLottery(100);

        uint256 requestId = _performUpkeep();

        _fulfillRandomWords(requestId);
    }

    function testGasFulfill1000Players() public skipFork {

        _prepareLottery(1000);

        uint256 requestId = _performUpkeep();

        _fulfillRandomWords(requestId);
    }
}