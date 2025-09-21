# ReputationAggregator

ReputationAggregator is a comprehensive smart contract system built on the Stacks blockchain that enables cross-platform reputation score aggregation and normalization. This contract allows multiple platforms to contribute reputation data for addresses, providing a unified and weighted reputation score that can be used across different applications and services.

## Features

- **Multi-Platform Integration**: Register and manage multiple reputation platforms with individual weights
- **Weighted Reputation Scoring**: Aggregate reputation scores using platform-specific weights for balanced assessment
- **Normalized Scoring System**: All reputation scores are normalized to a 0-100 scale for consistency
- **Platform Operator Management**: Authorize specific operators to submit reputation data for their platforms
- **Real-time Aggregation**: Automatic recalculation of aggregated scores when new data is submitted
- **Access Control**: Contract owner controls platform registration and operator authorization
- **Data Integrity**: Input validation ensures scores remain within valid ranges
- **Transparent Calculations**: All reputation calculations are performed on-chain

## Technical Specifications

- **Blockchain**: Stacks
- **Language**: Clarity 2.0
- **Epoch**: 2.5
- **Score Range**: 0-100 (uint)
- **Platform Weight Range**: 1-100 (uint)
- **Maximum Platforms**: 10 (configurable via fold operation)

## Installation

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) - Stacks smart contract development tool
- [Node.js](https://nodejs.org/) (if using additional tooling)

### Setup

1. Clone the repository:
```bash
git clone <repository-url>
cd ReputationAggregator
```

2. Navigate to the contract directory:
```bash
cd ReputationAggregator_contract
```

3. Install dependencies and run tests:
```bash
clarinet check
clarinet test
```

## Usage Examples

### Deploying the Contract

```bash
clarinet deploy --testnet
```

### Basic Contract Interactions

#### Register a New Platform
```clarity
;; Register a platform with weight 75
(contract-call? .ReputationAggregator register-platform "GitHub" u75)
```

#### Authorize Platform Operator
```clarity
;; Authorize an operator for platform ID 1
(contract-call? .ReputationAggregator authorize-platform-operator 'ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE u1)
```

#### Submit Reputation Score
```clarity
;; Submit a reputation score of 85 for an address
(contract-call? .ReputationAggregator submit-reputation-score
  'ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE
  u1
  u85
  u50)
```

#### Get Aggregated Reputation
```clarity
;; Get normalized reputation score for an address
(contract-call? .ReputationAggregator get-normalized-reputation 'ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE)
```

## Contract Functions Documentation

### Public Functions

#### `register-platform`
Registers a new reputation platform (owner only).
- **Parameters**: `name` (string-ascii 64), `weight` (uint 1-100)
- **Returns**: Platform ID (uint)
- **Access**: Contract owner only

#### `update-platform-status`
Activates or deactivates a platform (owner only).
- **Parameters**: `platform-id` (uint), `is-active` (bool)
- **Returns**: Success boolean
- **Access**: Contract owner only

#### `authorize-platform-operator`
Authorizes an operator to submit scores for a platform (owner only).
- **Parameters**: `operator` (principal), `platform-id` (uint)
- **Returns**: Success boolean
- **Access**: Contract owner only

#### `submit-reputation-score`
Submits a reputation score for an address on a specific platform.
- **Parameters**: `address` (principal), `platform-id` (uint), `score` (uint 0-100), `interactions` (uint)
- **Returns**: Success boolean
- **Access**: Contract owner or authorized platform operators

#### `calculate-aggregated-reputation`
Manually triggers reputation aggregation calculation for an address.
- **Parameters**: `address` (principal)
- **Returns**: Aggregated reputation data
- **Access**: Public

#### `transfer-ownership`
Transfers contract ownership to a new address (owner only).
- **Parameters**: `new-owner` (principal)
- **Returns**: Success boolean
- **Access**: Contract owner only

### Read-Only Functions

#### `get-platform`
Retrieves platform information by ID.
- **Parameters**: `platform-id` (uint)
- **Returns**: Platform data or none

#### `get-reputation-score`
Gets reputation score for an address on a specific platform.
- **Parameters**: `address` (principal), `platform-id` (uint)
- **Returns**: Score data or none

#### `get-aggregated-reputation`
Gets aggregated reputation data for an address.
- **Parameters**: `address` (principal)
- **Returns**: Aggregated data or none

#### `get-normalized-reputation`
Gets the normalized reputation score (0-100) for an address.
- **Parameters**: `address` (principal)
- **Returns**: Weighted score (uint) or error

#### `is-platform-operator`
Checks if an address is authorized as a platform operator.
- **Parameters**: `operator` (principal), `platform-id` (uint)
- **Returns**: Authorization status (bool)

#### `get-contract-owner`
Returns the current contract owner address.
- **Returns**: Owner principal

#### `get-platform-count`
Returns the total number of registered platforms.
- **Returns**: Platform count (uint)

## Deployment Guide

### Testnet Deployment

1. Configure your testnet settings in `settings/Testnet.toml`
2. Deploy using Clarinet:
```bash
clarinet deploy --testnet
```

### Mainnet Deployment

1. Configure your mainnet settings in `settings/Mainnet.toml`
2. Ensure thorough testing on testnet
3. Deploy to mainnet:
```bash
clarinet deploy --mainnet
```

### Post-Deployment Setup

1. Register initial platforms using `register-platform`
2. Authorize platform operators using `authorize-platform-operator`
3. Begin collecting reputation data from integrated platforms

## Security Notes

### Access Control
- Only the contract owner can register platforms and authorize operators
- Platform operators can only submit scores for their authorized platforms
- All score submissions are validated for range compliance (0-100)

### Data Validation
- Platform weights must be between 1-100
- Reputation scores must be between 0-100
- Only active platforms contribute to aggregated scores
- Platform existence is verified before operator authorization

### Potential Considerations
- **Centralization**: Contract owner has significant control over platform management
- **Platform Limits**: Current implementation supports up to 10 platforms (configurable)
- **Score Manipulation**: Ensure platform operators implement proper validation before submitting scores
- **Weight Distribution**: Consider the impact of platform weights on final aggregated scores

### Best Practices
- Regularly audit authorized operators
- Monitor for unusual scoring patterns
- Implement additional validation layers in integrated platforms
- Consider implementing time-based scoring decay for dynamic reputation systems
- Establish clear governance procedures for platform weight adjustments

## Error Codes

- `u100` - ERR_UNAUTHORIZED: Caller lacks required permissions
- `u101` - ERR_INVALID_PLATFORM: Platform is inactive or invalid
- `u102` - ERR_INVALID_SCORE: Score outside valid range (0-100)
- `u103` - ERR_PLATFORM_NOT_FOUND: Referenced platform does not exist
- `u104` - ERR_ADDRESS_NOT_FOUND: No reputation data found for address

## Contributing

1. Fork the repository
2. Create a feature branch
3. Implement changes with appropriate tests
4. Submit a pull request with detailed description

## License

This project is licensed under the terms specified in the repository license file.