# CrystalGardens - Ethereal Flora Exchange

A Clarity smart contract for cultivating, trading, and exchanging unique digital flora called "Crystal Blooms" on the Stacks blockchain.

## Overview

CrystalGardens is an NFT marketplace contract that enables users to mint botanical-themed NFTs, list them for trade, and exchange them with built-in royalty mechanisms for original creators.

## Features

- **Mint Crystal Blooms**: Create unique NFT specimens with custom essence descriptions and royalty percentages
- **Open Trading Posts**: List your blooms for sale at specified prices
- **Automated Royalties**: Original cultivators receive a percentage of all secondary sales
- **Guardian Management**: Contract ownership with transfer capabilities

## Contract Functions

### Public Functions

#### `cultivate`
Mints a new Crystal Bloom NFT.
```clarity
(cultivate (essence (string-ascii 256)) (tithe uint))
```
- `essence`: Description or metadata for the bloom (must be non-empty)
- `tithe`: Royalty percentage in basis points (0-1000, max 10%)
- Returns: Specimen ID of the newly minted bloom

#### `open-trade`
Lists a Crystal Bloom for sale.
```clarity
(open-trade (specimen-id uint) (exchange-value uint))
```
- `specimen-id`: ID of the bloom to list
- `exchange-value`: Sale price in microSTX
- Requires: Caller must own the bloom

#### `close-trade`
Removes a Crystal Bloom from the marketplace.
```clarity
(close-trade (specimen-id uint))
```
- `specimen-id`: ID of the bloom to delist
- Requires: Caller must be the one who listed it

#### `exchange`
Purchases a listed Crystal Bloom.
```clarity
(exchange (specimen-id uint))
```
- `specimen-id`: ID of the bloom to purchase
- Transfers STX to seller and royalties to original cultivator
- Transfers NFT ownership to buyer
- Automatically delists the bloom

#### `anoint-guardian`
Transfers contract guardianship to a new principal.
```clarity
(anoint-guardian (new-guardian principal))
```
- Requires: Caller must be current guardian
- Cannot transfer to burn address

### Read-Only Functions

#### `current-guardian`
Returns the current contract guardian principal.

#### `observe`
Retrieves metadata for a specific Crystal Bloom.
```clarity
(observe (specimen-id uint))
```
Returns: `{ guardian, cultivator, essence, tithe }`

#### `observe-trade`
Retrieves active trade information for a bloom.
```clarity
(observe-trade (specimen-id uint))
```
Returns: `{ exchange-value, trader }`

## Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| u100 | unauthorized-access | Caller lacks required permissions |
| u101 | not-guardian | Caller is not the NFT owner/trader |
| u102 | trade-not-active | No active trade for this specimen |
| u103 | offer-below-minimum | Exchange value must be greater than 0 |
| u104 | specimen-not-found | Bloom ID doesn't exist |
| u105 | essence-corrupted | Essence description is empty |
| u106 | tithe-too-high | Royalty percentage exceeds 10% |
| u107 | void-principal | Cannot use burn address |

## Data Structures

### NFT
- **Name**: `crystal-bloom`
- **Identifier**: `uint` (sequential IDs starting from 1)

### Maps

**flora-collection**: Stores bloom metadata
```clarity
{ specimen-id: uint } → { guardian: principal, cultivator: principal, essence: string-ascii 256, tithe: uint }
```

**trading-post**: Stores active listings
```clarity
{ specimen-id: uint } → { exchange-value: uint, trader: principal }
```

## Usage Example

```clarity
;; Cultivate a new bloom with 5% royalty
(contract-call? .crystal-gardens cultivate "Luminous Moonpetal" u500)
;; Returns: (ok u1)

;; List it for 1000 STX
(contract-call? .crystal-gardens open-trade u1 u1000000000)

;; Another user purchases it
;; 50 STX goes to original cultivator (5% royalty)
;; 950 STX goes to seller
(contract-call? .crystal-gardens exchange u1)
```

## Security Considerations

- Royalty percentage capped at 10% (1000 basis points)
- Burn address validation prevents accidental fund loss
- Only NFT owners can list their blooms for trade
- Only traders can delist their own offerings
