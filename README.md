# 🧬 BioData Exchange Marketplace

> **Revolutionizing biotech research through decentralized data sharing** 🚀

A smart contract marketplace where biotechnology laboratories can tokenize anonymized datasets and provide controlled access through multiple monetization models including subscriptions, per-use payments, and staking mechanisms.

## 🎯 Problem Statement

- 🏢 Genomic and biotech research data is trapped in corporate silos
- 🔒 Researchers struggle to access critical datasets for breakthrough discoveries  
- 💰 Current systems favor large corporations over independent researchers
- ⚡ Slow collaboration hinders medical advancement

## 💡 Solution

Our marketplace enables:
- 📊 **Dataset Tokenization**: Convert research data into tradeable digital assets
- 🔐 **Smart Access Control**: Automated permissions via Clarity contracts
- 💳 **Multiple Payment Models**: Choose from subscription, pay-per-use, or staking
- 🤝 **Revenue Sharing**: Fair compensation for data providers
- 🌐 **Decentralized**: No single point of control or failure

## ⚡ Core Features

### 🏪 Dataset Marketplace
- Register datasets with metadata and pricing
- Secure hash-based data verification
- Owner-controlled activation/deactivation

### 💰 Flexible Access Models
- **Pay-per-Access**: Single-use dataset downloads
- **Subscriptions**: Time-based unlimited access
- **Staking**: Stake STX tokens to earn access rights + rewards

### 🛡️ Security & Governance
- Platform fee management (capped at 20%)
- Minimum staking requirements
- Revenue tracking and distribution

## 🚀 Getting Started

### Prerequisites
- [Clarinet](https://docs.hiro.so/stacks/clarinet) installed
- [Node.js](https://nodejs.org/) for testing

### Installation

```bash
git clone https://github.com/YourUsername/BioData-Exchange-Marketplace.git
cd BioData-Exchange-Marketplace
npm install
```

### Running Tests

```bash
npm test
```

### Deploying Locally

```bash
clarinet integrate
```

## 📋 Contract Functions

### 🔧 Core Functions

#### `register-dataset`
Register a new dataset in the marketplace
```clarity
(register-dataset title description data-hash price-per-access subscription-price)
```

#### `purchase-access`
Buy single-access to a dataset
```clarity
(purchase-access dataset-id)
```

#### `purchase-subscription`
Buy time-based subscription access
```clarity
(purchase-subscription dataset-id duration-blocks)
```

#### `stake-for-access`
Stake STX tokens to gain access + earn rewards
```clarity
(stake-for-access dataset-id amount)
```

### 📊 Query Functions

#### `get-dataset`
Retrieve dataset information
```clarity
(get-dataset dataset-id)
```

#### `has-access`
Check if user has access to dataset
```clarity
(has-access user dataset-id)
```

#### `calculate-subscription-cost`
Calculate subscription pricing
```clarity
(calculate-subscription-cost dataset-id duration-blocks)
```

## 💼 Usage Examples

### 🔬 For Data Providers (Labs/Researchers)

1. **Register Your Dataset**
```clarity
;; Register a genomics dataset
(contract-call? .biodata-marketplace register-dataset 
  "COVID-19 Genomic Sequences" 
  "Anonymized genomic data from 1000+ patients"
  0x1234... 
  u1000000 
  u500000)
```

2. **Manage Your Revenue**
- Track downloads and earnings
- Deactivate datasets when needed
- Receive automatic payments

### 🧪 For Data Consumers (Researchers)

1. **Browse Available Datasets**
```clarity
;; Check dataset details
(contract-call? .biodata-marketplace get-dataset u1)
```

2. **Choose Your Access Model**

**One-time Purchase:**
```clarity
(contract-call? .biodata-marketplace purchase-access u1)
```

**Subscription (30 days):**
```clarity
(contract-call? .biodata-marketplace purchase-subscription u1 u4320)
```

**Staking (earn while accessing):**
```clarity
(contract-call? .biodata-marketplace stake-for-access u1 u5000000)
```

## 🏗️ Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Data Provider │───▶│  Smart Contract  │◀───│  Data Consumer  │
│     (Lab)       │    │   Marketplace    │    │  (Researcher)   │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
  📊 Register Data        🔐 Access Control       💰 Payment/Staking
  💰 Earn Revenue        📈 Revenue Tracking     📊 Access Data
  🛡️ Data Control       ⚖️  Platform Fees        🏆 Earn Rewards
```

## 🔒 Security Features

- ✅ **Owner Authorization**: Only dataset owners can deactivate their data
- ✅ **Payment Validation**: All payments verified before access granted
- ✅ **Stake Requirements**: Minimum staking amounts prevent spam
- ✅ **Fee Limits**: Platform fees capped at 20%
- ✅ **Access Control**: Multi-layered permission system

## 🌟 Roadmap

- [ ] 🔍 Advanced search and filtering
- [ ] 📈 Analytics dashboard for providers
- [ ] 🤖 AI-powered data matching
- [ ] 🌐 Cross-chain compatibility
- [ ] 📱 Mobile application
- [ ] 🏛️ DAO governance implementation

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- 🧬 The biotech research community
- 🌟 Stacks ecosystem contributors  
- 🔬 Open science advocates

---

**⚡ Accelerating medical breakthroughs through decentralized collaboration** 

Built with ❤️ for the future of biotech research
