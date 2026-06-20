# 🎰 Smart Contract Lottery (Chainlink VRF v2.5 + Foundry)

> A decentralized, provably fair lottery built with **Solidity**, **Foundry**, **Chainlink VRF v2.5**, and an extensive **testing & benchmarking framework**.

<p align="center">
  <img src="https://img.shields.io/badge/Solidity-0.8.13-blue.svg"/>
  <img src="https://img.shields.io/badge/Foundry-Forge-orange"/>
  <img src="https://img.shields.io/badge/Chainlink-VRF%20v2.5-blue"/>
  <img src="https://img.shields.io/badge/License-MIT-green"/>
</p>

---

# 📖 Overview

This project implements a **fully decentralized lottery** where players can enter by paying an entrance fee. After a predefined time interval, a winner is selected using **Chainlink VRF v2.5**, ensuring cryptographically secure and unbiased randomness.

Unlike traditional lottery examples, this project focuses heavily on **software engineering practices**, including:

* Unit Testing
* Stress Testing
* Gas Benchmarking
* Performance Analysis
* Chainlink VRF Integration
* Automation Simulation
* Statistical Randomness Validation (Work In Progress)

The objective was not only to build a lottery, but also to explore how a production-quality smart contract should be tested and analyzed.

---

# ✨ Features

* 🎲 Provably Fair Winner Selection using Chainlink VRF v2.5
* ⏱️ Time-based Lottery Rounds
* 💰 Automatic Prize Distribution
* 🔒 Reentrancy-safe Winner Payout
* 🔄 Multiple Consecutive Lottery Rounds
* 🧪 Extensive Unit Testing
* 🚀 Stress Testing with Hundreds and Thousands of Players
* ⛽ Gas Benchmarking
* 🧱 Modular Test Framework
* ⚙️ Foundry Scripts for Deployment & Interaction
* 🔗 Compatible with Local Anvil Network and Sepolia Testnet

---

# 🛠 Tech Stack

| Category         | Technology         |
| ---------------- | ------------------ |
| Language         | Solidity           |
| Framework        | Foundry            |
| Oracle           | Chainlink VRF v2.5 |
| Local Blockchain | Anvil              |
| Testing          | Forge              |
| Scripting        | Foundry Scripts    |
| Deployment       | Foundry            |
| Network          | Sepolia            |

---

# 📂 Project Structure

```text
.
├── broadcast/
├── script/
│   ├── DeployRaffle.s.sol
│   ├── HelperConfig.s.sol
│   └── Interactions.s.sol
│
├── src/
│   └── Raffle.sol
│
├── test/
│   ├── unit/
│   │   └── RaffleTest.t.sol
│   │
│   ├── integration/
│   │   └── (coming soon)
│   │
│   └── stress/
│       ├── BaseStressTest.t.sol
│       ├── RaffleStressTest.t.sol
│       ├── GasBenchmarkTest.t.sol
│       ├── MonteCarloTest.t.sol (WIP)
│       ├── PerformanceLimitTest.t.sol (Planned)
│       ├── ChaosTest.t.sol (Planned)
│       └── InvariantTest.t.sol (Planned)
│
└── README.md
```

---

# 🧠 How It Works

```text
Players Enter Lottery
          │
          ▼
Lottery Collects Entry Fees
          │
          ▼
Time Interval Expires
          │
          ▼
performUpkeep()
          │
          ▼
Chainlink VRF Request
          │
          ▼
Random Number Generated
          │
          ▼
Winner Selected
          │
          ▼
Prize Sent Automatically
          │
          ▼
Lottery Resets
```

---

# 🔐 Chainlink VRF Flow

```text
performUpkeep()

        │

        ▼

requestRandomWords()

        │

        ▼

Chainlink VRF

        │

        ▼

fulfillRandomWords()

        │

        ▼

Winner Selected

        │

        ▼

Prize Distributed
```

---

# ⚡ Getting Started

## Clone Repository

```bash
git clone https://github.com/abhijeetmishra2104/smart-contract-lottery.git

cd smart-contract-lottery
```

---

## Install Dependencies

```bash
forge install
```

---

## Build

```bash
forge build
```

---

## Run Tests

```bash
forge test
```

---

## Run With Verbose Logs

```bash
forge test -vvvv
```

---

# 🚀 Deployment

Deploy to a local Anvil node

```bash
forge script script/DeployRaffle.s.sol \
--broadcast
```

Deploy to Sepolia

```bash
forge script script/DeployRaffle.s.sol \
--rpc-url $SEPOLIA_RPC_URL \
--account <ACCOUNT_NAME> \
--broadcast
```

---

# 🎮 Enter the Lottery

```bash
forge script script/EnterRaffle.s.sol \
--rpc-url $SEPOLIA_RPC_URL \
--account player1 \
--broadcast
```

Repeat for additional players.

---

# 🧪 Testing

## Unit Tests

```bash
forge test --match-path test/unit/*
```

Covers:

* Constructor
* Entering Lottery
* Invalid Payments
* Raffle State
* performUpkeep()
* fulfillRandomWords()
* Prize Distribution

---

## Stress Tests

```bash
forge test --match-path test/stress/RaffleStressTest.t.sol
```

Current stress scenarios include:

* 10 Players
* 100 Players
* 1000 Players
* Multiple Consecutive Lottery Rounds
* Lottery Reset Verification
* Winner Validation

---

## Gas Benchmarking

```bash
forge test \
--match-path test/stress/GasBenchmarkTest.t.sol \
--gas-report
```

Benchmarks:

* enterRaffle()
* performUpkeep()
* fulfillRandomWords()

Across multiple player counts.

---

# 📊 Upcoming Statistical Analysis

One of the primary goals of this repository is to validate the fairness of Chainlink VRF through statistical testing.

Planned experiments include:

* Monte Carlo Simulations
* Winner Distribution Analysis
* Mean & Variance Calculation
* Standard Deviation
* Chi-Square Goodness of Fit Test
* Histogram Generation
* CSV Export for Data Visualization

---

# 🏗 Testing Philosophy

Instead of writing only unit tests, this repository adopts a layered testing strategy.

```text
Unit Tests
      │
      ▼
Stress Tests
      │
      ▼
Gas Benchmarking
      │
      ▼
Monte Carlo Simulation
      │
      ▼
Performance Analysis
      │
      ▼
Chaos Testing
      │
      ▼
Invariant Testing
```

This approach aims to verify not only correctness, but also scalability, efficiency, and robustness.

---

# 📈 Future Roadmap

* [ ] Monte Carlo Simulation Framework
* [ ] Chi-Square Randomness Validation
* [ ] CSV Export for Simulation Results
* [ ] Automatic Graph Generation
* [ ] Performance Limit Discovery
* [ ] Chaos Testing
* [ ] Invariant Testing
* [ ] GitHub Actions CI Pipeline
* [ ] Coverage Reports

---

# 📚 What I Learned

This project provided hands-on experience with:

* Solidity Smart Contract Development
* Chainlink VRF v2.5 Integration
* Chainlink Automation Concepts
* Foundry Scripting
* Foundry Cheatcodes
* Smart Contract Testing
* Stress Testing Methodologies
* Gas Benchmarking
* Performance Engineering
* Modular Test Architecture

---

# 🤝 Contributing

Contributions, suggestions, and improvements are always welcome.

If you'd like to improve the project:

1. Fork the repository
2. Create a new branch
3. Commit your changes
4. Open a Pull Request

---

# 📄 License

This project is licensed under the MIT License.

---

# 👨‍💻 Author

**Abhijeet Mishra**

B.Tech, Electronics & Communication Engineering
Indian Institute of Information Technology, Bhagalpur

* GitHub: https://github.com/abhijeetmishra2104
* LinkedIn: https://www.linkedin.com/in/abhijeet-mishra-abhi2104/

---

<p align="center">
⭐ If you found this project useful, consider giving it a star!
</p>
