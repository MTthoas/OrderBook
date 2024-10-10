# OrderBook - Solidity Smart Contract

## Introduction

Ce projet contient un contrat intelligent **OrderBook** écrit en Solidity qui permet la gestion d'ordres d'achat et de vente de tokens basés sur le standard ERC20. L'objectif est de créer un carnet d'ordres décentralisé, où les utilisateurs peuvent placer des ordres d'achat et de vente de tokens et les faire correspondre automatiquement si possible.

## Fonctionnalités principales

- **Placer un ordre d'achat** : Un utilisateur peut placer un ordre d'achat en spécifiant un prix et une quantité. Si un ordre de vente correspond est disponible, l'achat est automatiquement exécuté.
- **Placer un ordre de vente** : Un utilisateur peut placer un ordre de vente en spécifiant un prix et une quantité. Si un ordre d'achat correspond est disponible, la vente est automatiquement exécutée.
- **Matching d'ordres** : Le contrat essaye de faire correspondre automatiquement les ordres d'achat et de vente basés sur le prix et la disponibilité des tokens dans le carnet d'ordres.
- **Consultation du carnet d'ordres** : Vous pouvez récupérer les ordres d'achat et de vente par prix.

## Structure du contrat

### Variables importantes

- `tradeToken`: L'adresse du token échangé (ERC20).
- `baseToken`: L'adresse du token de base utilisé pour l'achat et la vente (ERC20).
- `buyOrders`: Mapping pour stocker les ordres d'achat en fonction du prix.
- `sellOrders`: Mapping pour stocker les ordres de vente en fonction du prix.
- `minSellPrice`: Le prix minimum parmi les ordres de vente.
- `maxBuyPrice`: Le prix maximum parmi les ordres d'achat.

### Méthodes principales

#### `PlaceBuyOrder(uint256 price, uint256 amount)`
- Permet à un utilisateur de placer un ordre d'achat.
- **Vérifications** :
  - L'utilisateur a donné une autorisation (allowance) suffisante.
  - L'utilisateur possède assez de `baseToken` pour l'achat.
- Si un ordre de vente correspondant est trouvé, il est exécuté.

#### `PlaceSellOrder(uint256 price, uint256 amount)`
- Permet à un utilisateur de placer un ordre de vente.
- **Vérifications** :
  - L'utilisateur a donné une autorisation (allowance) suffisante pour transférer les `tradeToken`.
  - Si un ordre d'achat correspondant est trouvé, il est exécuté.

#### `matchBuyOrder(uint256 price, uint256 amount)`
- Fonction interne qui essaie de faire correspondre un ordre d'achat avec les ordres de vente disponibles.

#### `matchSellOrder(uint256 price, uint256 amount)`
- Fonction interne qui essaie de faire correspondre un ordre de vente avec les ordres d'achat disponibles.

### Méthodes utilitaires

- `getBuyOrders(uint256 price)`: Récupère tous les ordres d'achat pour un prix donné.
- `getSellOrders(uint256 price)`: Récupère tous les ordres de vente pour un prix donné.
- `getMinSellPrice()`: Récupère le prix minimum d'un ordre de vente.
- `getMaxBuyPrice()`: Récupère le prix maximum d'un ordre d'achat.

## Exemple de fonctionnement

1. **Placer un ordre d'achat** :
   - Un utilisateur veut acheter 5 tokens `TKN` au prix de 2 `BASE` par token. Il envoie un ordre d'achat via `PlaceBuyOrder(2 * 10**18, 5 * 10**18)`.
   - Le contrat vérifie si un ordre de vente correspondant est disponible.
   - Si disponible, l'ordre d'achat est automatiquement exécuté, transférant des `tradeToken` à l'acheteur et des `baseToken` au vendeur.

2. **Placer un ordre de vente** :
   - Un utilisateur veut vendre 5 tokens `TKN` au prix de 2 `BASE` par token. Il envoie un ordre de vente via `PlaceSellOrder(2 * 10**18, 5 * 10**18)`.
   - Si un ordre d'achat correspondant existe, il est automatiquement exécuté.

3. **Correspondance des ordres** :
   - Le contrat tente de faire correspondre les ordres d'achat et de vente dès que possible. Si un ordre ne trouve pas de correspondance, il est ajouté au carnet d'ordres.

## Conclusion

Ce contrat permet de gérer un carnet d'ordres pour deux tokens ERC20 avec des fonctionnalités basiques de correspondance d'ordres. Il assure également la sécurité des fonds grâce à des vérifications d'autorisation et des protections contre la ré-entrance.

