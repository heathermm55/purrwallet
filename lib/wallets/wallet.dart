/// PurrWallet - Cashu Wallet Services
/// 
/// This library provides comprehensive wallet services for managing Cashu tokens,
/// including mint management, proof handling, transaction history, and Lightning
/// invoice processing.

library purrwallet_wallet;

// Core services
export 'services/wallet_manager.dart';
export 'services/mint_service.dart';
export 'services/proof_service.dart';
export 'services/history_service.dart';

// Data models
export 'models/proof.dart';
export 'models/mint_info.dart';
export 'models/keyset_info.dart';
export 'models/history_entry.dart';
export 'models/invoice.dart';

// Re-export common types
export 'models/history_entry.dart' show HistoryType;
export 'models/invoice.dart' show InvoiceState;
export 'services/mint_service.dart' show MintStatus, MintStatusType;
export 'services/proof_service.dart' show ProofsSummary;
export 'services/history_service.dart' show TransactionStats, MintStats;
