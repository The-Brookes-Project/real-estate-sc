# VerseProp Real-Estate Debt Management Platform

## Overview

The VerseProp Real-Estate Debt Management Platform is a cutting-edge blockchain solution designed to revolutionize the way real-estate debts are managed and financed. Utilizing the power of Ethereum blockchain and smart contracts, the platform offers a secure, transparent, and efficient means for initiating, funding, and settling overcollateralized real-estate loans. VerseProp spearheads the loan process by conducting thorough research on real-estate properties, assessing their market value, and determining the feasible amount for an overcollateralized loan offering. This project leverages Hardhat for development, testing, and deployment, ensuring a robust and streamlined workflow for developers.

## Key Features

- **Loan Origination and Funding**: Enables the collection of investments to fund real-estate debts once the loan amount is fully accumulated.
- **Interest Calculation and Payment**: Facilitates daily interest calculation on loans, ensuring accurate compensation for investors.
- **NFT-based Investment Representation**: Investors receive unique NFTs symbolizing their stake in the loan pool, which can be traded in secondary markets.
- **Transparent and Secure**: Leverages smart contracts for immutable transactions and state management, enhancing security and trust.

## Project Structure

The platform comprises four core smart contracts:

- `DebtAccessControl`: Manages access control, enabling secure interactions between contracts and allowing administrative operations.
- `DebtStorage`: Serves as the data repository for all debt and investment-related information, ensuring data persistence through contract upgrades via a proxy mechanism.
- `DebtNFT`: Handles the minting and burning of NFTs that represent investment stakes, with administrative functions to manage NFTs under exceptional circumstances.
- `DebtLogic`: Implements the platform's business logic, including validation, loan disbursement, interest calculation, and interactions with the DebtStorage contract.

## Getting Started

To get started with the VerseProp Real-Estate Debt Management Platform, follow these steps to set up your development environment.

### Installation

1. Install dependencies:

```sh
npm install
```

2. Compiling contracts:

```sh
npx hardhat compile
```

2. Compiling contracts:

```sh
npx hardhat test
```
