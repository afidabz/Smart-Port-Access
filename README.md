# 🚢 Smart Port Access

A blockchain-powered solution for tokenized shipping containers with automated port fee settlement. Built on Stacks blockchain using Clarity smart contracts.

## 📋 Overview

Smart Port Access revolutionizes port operations by:
- 📦 **Tokenizing shipping containers** as NFTs 
- 💰 **Automating fee settlement** when containers are unloaded
- 🔐 **Managing port authorization** and access control
- 📊 **Tracking container status** throughout the shipping lifecycle

## ✨ Features

- **Container NFTs**: Each shipping container becomes a unique non-fungible token
- **Multi-Status Tracking**: Containers progress through `loaded` → `in-transit` → `unloaded` states
- **Automated Payments**: Port fees are automatically deducted when containers are unloaded
- **Port Authorization**: Only authorized ports can mint containers and collect fees
- **User Deposits**: Shippers deposit STX tokens in advance for seamless fee payment
- **Emergency Recovery**: Contract owner can recover containers stuck in transit after 24 hours

## 🛠️ Usage

### For Port Operators

1. **Get Authorized** (contract owner only)
```clarity
(contract-call? .Smart-Port-Access authorize-port 'SP1HTBVD3JG9C05J7HBJTHGR0GGW7KX4KX73R3)
```

2. **Set Port Fees**
```clarity
(contract-call? .Smart-Port-Access set-port-fee 'SP1HTBVD3JG9C05J7HBJTHGR0GGW7KX4KX73R3 u1000000)
```

3. **Mint Container** (load at origin port)
```clarity
(contract-call? .Smart-Port-Access mint-container 
  'SP2PABAF9FTAJYNFZH93XENAJ8FVY99RRM50D2JG9 
  "Port of Los Angeles"
  "Port of Rotterdam" 
  "Electronics and machinery"
  u500000)
```

4. **Unload Container** (automatically settles fees)
```clarity
(contract-call? .Smart-Port-Access unload-container u1)
```

### For Shipping Companies

1. **Deposit Funds** for fee payments
```clarity
(contract-call? .Smart-Port-Access deposit-funds u2000000)
```

2. **Ship Container** (change status to in-transit)
```clarity
(contract-call? .Smart-Port-Access ship-container u1)
```

3. **Transfer Container** ownership
```clarity
(contract-call? .Smart-Port-Access transfer u1 
  'SP1HTBVD3JG9C05J7HBJTHGR0GGW7KX4KX73R3
  'SP2PABAF9FTAJYNFZH93XENAJ8FVY99RRM50D2JG9)
```

4. **Withdraw Unused Funds**
```clarity
(contract-call? .Smart-Port-Access withdraw-funds u1000000)
```

### Read-Only Functions

- **Check Container Info**
```clarity
(contract-call? .Smart-Port-Access get-container-info u1)
```

- **Check User Balance**
```clarity
(contract-call? .Smart-Port-Access get-user-balance 'SP1HTBVD3JG9C05J7HBJTHGR0GGW7KX4KX73R3)
```

- **Verify Port Authorization**
```clarity
(contract-call? .Smart-Port-Access is-port-authorized 'SP1HTBVD3JG9C05J7HBJTHGR0GGW7KX4KX73R3)
```

## 🏗️ Development

### Prerequisites
- [Clarinet](https://docs.hiro.so/stacks/clarinet) installed
- Node.js for testing

### Getting Started

1. **Clone the repository**
```bash
git clone https://github.com/your-username/Smart-Port-Access.git
cd Smart-Port-Access
```

2. **Check contract syntax**
```bash
clarinet check
```

3. **Run tests**
```bash
npm install
npm test
```

4. **Deploy to testnet**
```bash
clarinet integrate
```

## 📊 Contract Structure

### Data Maps
- `containers`: Core container information and metadata
- `authorized-ports`: Port authorization registry  
- `port-fees`: Fee amounts per port
- `user-balances`: STX deposits for fee payments

### Key Functions
- `mint-container`: Create new container NFT
- `ship-container`: Update status to in-transit  
- `unload-container`: Complete delivery and settle fees
- `deposit-funds` / `withdraw-funds`: Manage user balances
- `authorize-port` / `revoke-port-authorization`: Port management

## 🔒 Security Features

- **Access Control**: Only authorized ports can mint containers and collect fees
- **Owner Validation**: Only container owners can ship and transfer containers
- **Balance Checks**: Sufficient funds required before fee settlement
- **Emergency Recovery**: Stuck containers can be recovered after timeout period
- **Status Validation**: Containers must follow proper state transitions

## 🏷️ Error Codes

- `u100`: Owner-only function access denied
- `u101`: Not the token owner
- `u102`: Container not found  
- `u103`: Container already unloaded
- `u104`: Port not authorized
- `u105`: Insufficient balance
- `u106`: Container in transit (invalid operation)
- `u107`: Invalid status transition

## 📄 License

This project is open source and available under the MIT License.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality  
5. Submit a pull request

---

Built with ❤️ on the Stacks blockchain
