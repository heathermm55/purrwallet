use serde::{Deserialize, Serialize};
use serde_json;
use std::collections::HashMap;
use std::sync::Arc;
use std::str::FromStr;

use cdk::nuts::{CurrencyUnit, Token, Proof, Id, SecretKey, PublicKey};
use cdk::secret::Secret;
use cdk::amount::Amount;
use cdk::wallet::{Wallet, MultiMintWallet, SendOptions, ReceiveOptions, MultiMintSendOptions};
// Note: Old Tor configuration API (TorPolicy, TorConfig, set_tor_config, get_tor_config) 
// has been removed. New implementation uses WalletBuilder::use_tor() instead.
use cdk::wallet::types::TransactionDirection;
use cdk::mint_url::MintUrl;
use cdk_sqlite::WalletSqliteDatabase;
use bip39::{Mnemonic, Language};
use rand::random;
use std::path::PathBuf;
use tokio::sync::RwLock;

/// Global MultiMintWallet instance
static MULTI_MINT_WALLET: RwLock<Option<Arc<MultiMintWallet>>> = RwLock::const_new(None);

// Tor is automatically used for .onion addresses when tor feature is enabled.


// execute_async function removed - no longer needed with async functions

/// Check if wallet database exists
fn wallet_database_exists(base_dir: &str, mint_url: &str) -> bool {
    let db_path = get_database_path(base_dir, mint_url);
    db_path.exists()
}

/// Get database path for wallet storage
fn get_database_path(base_dir: &str, mint_url: &str) -> PathBuf {
    // Create a simple path based on mint URL
    let db_name = format!("wallet_{}.db", mint_url.replace("://", "_").replace("/", "_"));
    PathBuf::from(base_dir)
        .join("wallet_data")
        .join(db_name)
}

/// Cashu proof structure for FFI
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CashuProof {
    pub id: String,
    pub amount: u64,
    pub secret: String,
    pub c: String,
}

/// Wallet information structure
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WalletInfo {
    pub mint_url: String,
    pub unit: String,
    pub balance: u64,
    pub active_keyset_id: String,
}

/// Transaction information structure
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TransactionInfo {
    pub id: String,
    pub direction: String, // "incoming" or "outgoing"
    pub amount: u64,
    pub fee: u64,
    pub memo: Option<String>,
    pub timestamp: u64,
    // Mint URL for this transaction
    #[serde(rename = "mintUrl")]
    pub mint_url: String,
    // Extended fields for transaction details
    #[serde(rename = "transactionType")]
    pub transaction_type: Option<String>,
    #[serde(rename = "lightningInvoice")]
    pub lightning_invoice: Option<String>,
    #[serde(rename = "ecashToken")]
    pub ecash_token: Option<String>,
    pub metadata: HashMap<String, String>,
}

/// Mint information structure for NUT-06
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MintInfo {
    pub name: Option<String>,
    pub version: Option<String>,
    pub description: Option<String>,
    pub description_long: Option<String>,
    pub contact: Option<Vec<ContactInfo>>,
    pub motd: Option<String>,
    pub icon_url: Option<String>,
    pub urls: Option<Vec<String>>,
    pub nuts: Option<Vec<String>>,
    pub public_key: Option<String>,
    pub additional_info: Option<String>,
}

/// Contact information structure
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ContactInfo {
    pub method: String,
    pub info: String,
}

/// Convert CDK Proof to CashuProof
impl From<Proof> for CashuProof {
    fn from(proof: Proof) -> Self {
        Self {
            id: proof.keyset_id.to_string(),
            amount: proof.amount.into(),
            secret: proof.secret.to_string(),
            c: proof.c.to_string(),
        }
    }
}

/// Convert CashuProof to CDK Proof
impl TryFrom<CashuProof> for Proof {
    type Error = String;

    fn try_from(cashu_proof: CashuProof) -> Result<Self, Self::Error> {
        let id = Id::from_str(&cashu_proof.id)
            .map_err(|e| format!("Invalid proof ID: {}", e))?;
        let amount = Amount::from(cashu_proof.amount);
        let secret_key = SecretKey::from_str(&cashu_proof.secret)
            .map_err(|e| format!("Invalid secret: {}", e))?;
        let secret = Secret::new(secret_key.to_secret_hex());
        let c = PublicKey::from_str(&cashu_proof.c)
            .map_err(|e| format!("Invalid C: {}", e))?;
            
        Ok(Proof {
            keyset_id: id,
            amount,
            secret,
            c,
            witness: None,
            dleq: None,
        })
    }
}

/// Initialize MultiMintWallet
pub async fn init_multi_mint_wallet(database_dir: String, seed_hex: String) -> Result<String, String> {
    let mut wallet_guard = MULTI_MINT_WALLET.write().await;
    
    if wallet_guard.is_some() {
        return Ok("MultiMintWallet already initialized".to_string());
    }

    // Set Tor data directories to use the same base directory as the wallet database
    // This ensures Tor data is stored in the app's data directory, not system temp
    let tor_cache_dir = PathBuf::from(&database_dir).join("tor_cache");
    let tor_data_dir = PathBuf::from(&database_dir).join("tor_data");
    
    // Create Tor directories if they don't exist
    std::fs::create_dir_all(&tor_cache_dir)
        .map_err(|e| format!("Failed to create Tor cache directory: {}", e))?;
    std::fs::create_dir_all(&tor_data_dir)
        .map_err(|e| format!("Failed to create Tor data directory: {}", e))?;
    
    // Set environment variables for Tor configuration
    // These will be used by TorAsync when initializing TorClientConfig
    let cache_path = tor_cache_dir.to_string_lossy().to_string();
    let data_path = tor_data_dir.to_string_lossy().to_string();
    std::env::set_var("ARTI_CACHE", &cache_path);
    std::env::set_var("ARTI_LOCAL_DATA", &data_path);

    // Parse seed from hex string
    let seed = parse_seed_from_hex(&seed_hex)?;
    let db_path = PathBuf::from(&database_dir).join("multi_mint_wallet.db");
    
    std::fs::create_dir_all(db_path.parent().unwrap())
        .map_err(|e| format!("Failed to create database directory: {}", e))?;
    
    let localstore = WalletSqliteDatabase::new(db_path.to_str().unwrap()).await
        .map_err(|e| format!("Failed to create SQLite store: {}", e))?;

    // Convert seed to [u8; 64] by extending if needed
    let seed_64: [u8; 64] = if seed.len() == 32 {
        // Extend 32-byte seed to 64 bytes by repeating
        let mut extended = [0u8; 64];
        extended[..32].copy_from_slice(&seed);
        extended[32..].copy_from_slice(&seed);
        extended
    } else if seed.len() == 64 {
        let mut seed_array = [0u8; 64];
        seed_array.copy_from_slice(&seed);
        seed_array
    } else {
        return Err(format!("Seed must be 32 or 64 bytes, got {}", seed.len()));
    };

    // Create MultiMintWallet with shared Tor transport to avoid multiple Tor instances
    // Note: MultiMintWallet now supports only one currency unit per instance
    #[cfg(all(feature = "tor", not(target_arch = "wasm32")))]
    let multi_mint_wallet = MultiMintWallet::new_with_tor(
        Arc::new(localstore),
        seed_64,
        CurrencyUnit::Sat, // Default to Sat unit
    ).await
    .map_err(|e| format!("Failed to create MultiMintWallet with Tor: {}", e))?;
    
    #[cfg(not(all(feature = "tor", not(target_arch = "wasm32"))))]
    let multi_mint_wallet = MultiMintWallet::new(
        Arc::new(localstore),
        seed_64,
        CurrencyUnit::Sat, // Default to Sat unit
    ).await
    .map_err(|e| format!("Failed to create MultiMintWallet: {}", e))?;

    *wallet_guard = Some(Arc::new(multi_mint_wallet));
    
    Ok("MultiMintWallet initialized successfully".to_string())
}

/// Parse seed from hex string (returns Vec<u8> to support both 32 and 64 byte seeds)
fn parse_seed_from_hex(seed_hex: &str) -> Result<Vec<u8>, String> {
    // Accept both 64-byte (128 hex chars) and 32-byte (64 hex chars) seeds
    let expected_lengths = [64, 128]; // 32 bytes or 64 bytes
    if !expected_lengths.contains(&seed_hex.len()) {
        return Err(format!("Seed must be 64 or 128 hex characters (32 or 64 bytes), got {}", seed_hex.len()));
    }

    // Parse hex string to bytes
    let seed_bytes = hex::decode(seed_hex)
        .map_err(|e| format!("Invalid hex string: {}", e))?;
    
    Ok(seed_bytes)
}

/// Load existing wallets from database
/// Note: This function is no longer needed as MultiMintWallet automatically loads wallets
async fn load_wallets_from_database(_localstore: &WalletSqliteDatabase, _seed: &[u8]) -> Result<Vec<Wallet>, String> {
    // MultiMintWallet now automatically loads wallets from database in its constructor
    // This function is kept for compatibility but returns empty vector
    Ok(Vec::new())
}

/// Add a mint to MultiMintWallet - defaults to sat unit
pub async fn add_mint(mint_url: String) -> Result<String, String> {
    let wallet_guard = MULTI_MINT_WALLET.read().await;
    let multi_mint_wallet = wallet_guard.as_ref()
        .ok_or("MultiMintWallet not initialized")?;

    // Normalize URL: convert https:// to http:// for .onion addresses
    // .onion addresses must use HTTP, not HTTPS
    let normalized_url = if mint_url.contains(".onion") && mint_url.starts_with("https://") {
        mint_url.replace("https://", "http://")
    } else {
        mint_url
    };

    let mint_url_parsed = MintUrl::from_str(&normalized_url)
        .map_err(|e| format!("Invalid mint URL: {}", e))?;
    
    // Check if wallet already exists
    if multi_mint_wallet.has_mint(&mint_url_parsed).await {
        return Ok("Mint already exists".to_string());
    }

    // Add mint - Tor is automatically used for .onion addresses
    multi_mint_wallet.add_mint(mint_url_parsed.clone()).await
        .map_err(|e| format!("Failed to add mint: {}", e))?;

    // Get the wallet after adding
    let wallet = multi_mint_wallet.get_wallet(&mint_url_parsed).await
        .ok_or("Failed to get wallet after adding")?;

    // Explicitly fetch and verify mint info is saved to database
    // This is critical: if mint info cannot be fetched, the mint should not be considered added
    let fetch_result = wallet.fetch_mint_info().await;
    
    let mint_info = match fetch_result {
        Ok(Some(info)) => info,
        Ok(None) => {
            // fetch_mint_info returned None, meaning connection failed
            // Rollback by removing the wallet from memory
            drop(wallet_guard);
            let mut wallet_guard_write = MULTI_MINT_WALLET.write().await;
            if let Some(multi_mint_wallet) = wallet_guard_write.as_ref() {
                multi_mint_wallet.remove_mint(&mint_url_parsed).await;
            }
            return Err("Failed to fetch mint info: Tor connection failed or mint is unreachable. Please check your network connection and try again.".to_string());
        }
        Err(e) => {
            // fetch_mint_info returned an error
            // Rollback by removing the wallet from memory
            drop(wallet_guard);
            let mut wallet_guard_write = MULTI_MINT_WALLET.write().await;
            if let Some(multi_mint_wallet) = wallet_guard_write.as_ref() {
                multi_mint_wallet.remove_mint(&mint_url_parsed).await;
            }
            return Err(format!("Failed to fetch mint info: {}", e));
        }
    };

    // Verify mint info was actually saved to database
    let saved_mint_info = wallet.localstore.get_mint(mint_url_parsed.clone()).await
        .map_err(|e| format!("Failed to verify mint info in database: {}", e))?;
    
    if saved_mint_info.is_none() {
        // Mint info was not saved, rollback
        drop(wallet_guard);
        let mut wallet_guard_write = MULTI_MINT_WALLET.write().await;
        if let Some(multi_mint_wallet) = wallet_guard_write.as_ref() {
            multi_mint_wallet.remove_mint(&mint_url_parsed).await;
        }
        return Err("Failed to save mint info to database".to_string());
    }

    // Load keysets for the newly added wallet
    wallet.load_mint_keysets().await
        .map_err(|e| format!("Failed to load keysets: {}", e))?;

    wallet.get_active_keyset().await
        .map_err(|e| format!("Failed to get active keyset: {}", e))?;

    Ok("Mint added successfully".to_string())
}

/// Remove a mint from MultiMintWallet - defaults to sat unit
pub async fn remove_mint(mint_url: String) -> Result<String, String> {
    let wallet_guard = MULTI_MINT_WALLET.read().await;
    let multi_mint_wallet = wallet_guard.as_ref()
        .ok_or("MultiMintWallet not initialized")?;

    let mint_url_parsed = MintUrl::from_str(&mint_url)
        .map_err(|e| format!("Invalid mint URL: {}", e))?;
    
    if !multi_mint_wallet.has_mint(&mint_url_parsed).await {
        return Err("Mint not found".to_string());
    }

    // Remove mint (removes from both memory and database)
    multi_mint_wallet.remove_mint(&mint_url_parsed).await;
    
    Ok("Mint removed successfully".to_string())
}

/// List all mints in MultiMintWallet

pub async fn list_mints() -> Result<Vec<String>, String> {

        let wallet_guard = MULTI_MINT_WALLET.read().await;
        let multi_mint_wallet = wallet_guard.as_ref()
            .ok_or("MultiMintWallet not initialized")?;

        let wallets = multi_mint_wallet.get_wallets().await;
        let mint_list: Vec<String> = wallets.iter()
            .map(|w| format!("{}:{}", w.mint_url, w.unit))
            .collect();

        Ok(mint_list)

}

/// Check if wallet exists

pub async fn wallet_exists(mint_url: String, database_dir: String) -> bool {
    wallet_database_exists(&database_dir, &mint_url)
}

/// Get wallet information (may make network requests for keyset info) - defaults to sat unit
pub async fn get_wallet_info(mint_url: String) -> Result<WalletInfo, String> {

        let mint_url_parsed = MintUrl::from_str(&mint_url)
            .map_err(|e| format!("Invalid mint URL: {}", e))?;

        // Use MultiMintWallet to get wallet info
        let wallet_guard = MULTI_MINT_WALLET.read().await;
        let multi_mint_wallet = wallet_guard.as_ref()
            .ok_or("MultiMintWallet not initialized")?;

        if !multi_mint_wallet.has_mint(&mint_url_parsed).await {
            return Err("Mint not found in wallet".to_string());
        }

        let wallet = multi_mint_wallet.get_wallet(&mint_url_parsed).await
            .ok_or("Failed to get wallet")?;

        let balance = wallet.total_balance().await
            .map_err(|e| format!("Failed to get balance: {}", e))?;

        // Get active keyset ID from mint info
        let active_keyset_id = wallet.get_active_keyset().await
            .map_err(|e| format!("Failed to get active keyset: {}", e))?
            .id.to_string();

        Ok(WalletInfo {
            mint_url: wallet.mint_url.to_string(),
            unit: wallet.unit.to_string(),
            balance: balance.into(),
            active_keyset_id,
        })

}

/// Get all transactions from all mints (fast, no network requests)
pub async fn get_all_transactions() -> Result<Vec<TransactionInfo>, String> {
    let wallet_guard = MULTI_MINT_WALLET.read().await;
    let multi_mint_wallet = wallet_guard.as_ref()
        .ok_or("MultiMintWallet not initialized")?;

    let transactions = multi_mint_wallet.list_transactions(None).await
        .map_err(|e| format!("Failed to get transactions: {}", e))?;

    let transaction_infos: Vec<TransactionInfo> = transactions
        .into_iter()
        .map(|tx| TransactionInfo {
            id: tx.id().to_string(),
            direction: match tx.direction {
                TransactionDirection::Incoming => "incoming",
                TransactionDirection::Outgoing => "outgoing",
            }.to_string(),
            amount: tx.amount.into(),
            fee: tx.fee.into(),
            memo: tx.memo,
            timestamp: tx.timestamp,
            mint_url: tx.mint_url.to_string(),
            // Extract transaction metadata
            transaction_type: tx.metadata.get("transaction_type").cloned(),
            lightning_invoice: tx.metadata.get("lightning_invoice").cloned(),
            ecash_token: tx.metadata.get("ecash_token").cloned(),
            metadata: tx.metadata,
        })
        .collect();

    Ok(transaction_infos)
}

/// Get all wallet balances from all mints (fast, no network requests)
pub async fn get_all_balances() -> Result<HashMap<String, u64>, String> {
    let wallet_guard = MULTI_MINT_WALLET.read().await;
    let multi_mint_wallet = wallet_guard.as_ref()
        .ok_or("MultiMintWallet not initialized")?;

    let mut balances = HashMap::new();
    
    // Get balances for all mints (MultiMintWallet now supports only one unit per instance)
    // Note: This wallet instance is for Sat unit only
    match multi_mint_wallet.get_balances().await {
        Ok(mint_balances) => {
            for (mint_url, amount) in mint_balances {
                let key = format!("{}:{}", mint_url, multi_mint_wallet.unit());
                balances.insert(key, amount.into());
            }
        }
        Err(_) => {
            // Continue if fails
        }
    }

    Ok(balances)
}

/// Extract supported NUTs from the Nuts struct
fn extract_supported_nuts(nuts: &cdk::nuts::Nuts) -> Vec<String> {
    let mut supported_nuts = Vec::new();

    // Always include basic NUTs that are present in the struct
    supported_nuts.push("NUT-04".to_string()); // Mint
    supported_nuts.push("NUT-05".to_string()); // Melt

    // Check each NUT field and add to list if supported
    if nuts.nut07.supported {
        supported_nuts.push("NUT-07".to_string());
    }
    if nuts.nut08.supported {
        supported_nuts.push("NUT-08".to_string());
    }
    if nuts.nut09.supported {
        supported_nuts.push("NUT-09".to_string());
    }
    if nuts.nut10.supported {
        supported_nuts.push("NUT-10".to_string());
    }
    if nuts.nut11.supported {
        supported_nuts.push("NUT-11".to_string());
    }
    if nuts.nut12.supported {
        supported_nuts.push("NUT-12".to_string());
    }
    if nuts.nut14.supported {
        supported_nuts.push("NUT-14".to_string());
    }
    if nuts.nut15.methods.len() > 0 {
        supported_nuts.push("NUT-15".to_string());
    }
    if nuts.nut17.supported.len() > 0 {
        supported_nuts.push("NUT-17".to_string());
    }
    if nuts.nut19.ttl.is_some() || nuts.nut19.cached_endpoints.len() > 0 {
        supported_nuts.push("NUT-19".to_string());
    }
    if nuts.nut20.supported {
        supported_nuts.push("NUT-20".to_string());
    }

    // Add auth NUTs if available
    // Note: auth feature is not enabled in purrwallet, so NUT-21 and NUT-22 are skipped
    // #[cfg(feature = "auth")]
    // {
    //     if nuts.nut21.is_some() {
    //         supported_nuts.push("NUT-21".to_string());
    //     }
    //     if nuts.nut22.is_some() {
    //         supported_nuts.push("NUT-22".to_string());
    //     }
    // }

    supported_nuts
}

/// Get mint information from NUT-06 endpoint - defaults to sat unit
pub async fn get_mint_info(mint_url: String) -> Result<MintInfo, String> {
    let mint_url_parsed = MintUrl::from_str(&mint_url)
        .map_err(|e| format!("Invalid mint URL: {}", e))?;

    // Use MultiMintWallet to get mint info
    let wallet_guard = MULTI_MINT_WALLET.read().await;
    let multi_mint_wallet = wallet_guard.as_ref()
        .ok_or("MultiMintWallet not initialized")?;

    if !multi_mint_wallet.has_mint(&mint_url_parsed).await {
        return Err("Mint not found in wallet".to_string());
    }

    let wallet = multi_mint_wallet.get_wallet(&mint_url_parsed).await
        .ok_or("Failed to get wallet")?;

    // Get mint info using the wallet's fetch_mint_info method
    let mint_info_result = wallet.fetch_mint_info().await
        .map_err(|e| format!("Failed to get mint info: {}", e))?;

    match mint_info_result {
        Some(info) => {
            // Convert CDK MintInfo to our FFI structure
            let contact_info = info.contact.map(|contacts| {
                contacts.into_iter().map(|c| ContactInfo {
                    method: c.method,
                    info: c.info,
                }).collect()
            });

            Ok(MintInfo {
                name: info.name,
                version: info.version.map(|v| v.to_string()),
                description: info.description,
                description_long: info.description_long,
                contact: contact_info,
                motd: info.motd,
                icon_url: info.icon_url,
                urls: info.urls,
                nuts: Some(extract_supported_nuts(&info.nuts)),
                public_key: None, // This would need to be extracted from keysets
                additional_info: None,
            })
        }
        None => Err("Mint info not available".to_string()),
    }
}

/// Send tokens using CDK MultiMintWallet API directly - defaults to sat unit

pub async fn send_tokens(mint_url: String, amount: u64, memo: Option<String>) -> Result<String, String> {
        let mint_url_parsed = MintUrl::from_str(&mint_url)
            .map_err(|e| format!("Invalid mint URL: {}", e))?;

        // Use the global MULTI_MINT_WALLET
        let wallet_guard = MULTI_MINT_WALLET.read().await;
        let multi_mint_wallet = wallet_guard.as_ref()
            .ok_or("MultiMintWallet not initialized")?;

        if !multi_mint_wallet.has_mint(&mint_url_parsed).await {
            return Err("Mint not found in wallet".to_string());
        }

        // Use CDK MultiMintWallet API directly
        let send_amount = Amount::from(amount);
        
        // Add metadata for transaction tracking (token will be added after generation)
        let mut metadata = HashMap::new();
        metadata.insert("transaction_type".to_string(), "ecash_send".to_string());
        
        let send_options = SendOptions {
            metadata,
            ..Default::default()
        };
        
        let multi_mint_send_options = MultiMintSendOptions {
            send_options,
            ..Default::default()
        };
        
        let prepared_send = multi_mint_wallet.prepare_send(mint_url_parsed, send_amount, multi_mint_send_options).await
            .map_err(|e| format!("Failed to prepare send: {}", e))?;

        let send_memo = memo.map(|m| cdk::wallet::SendMemo::for_token(&m));
        let token = prepared_send.confirm(send_memo).await
            .map_err(|e| format!("Failed to send: {}", e))?;

        let token_str = token.to_string();

        // Note: Token is generated after transaction is created, so we cannot
        // store it in the transaction metadata at this time. 
        // The token can still be retrieved from the token string returned to the user.

        Ok(token_str)
}

/// Receive tokens using CDK MultiMintWallet API directly - auto-detects mint URL from token

pub async fn receive_tokens(token: String) -> Result<u64, String> {
        // Parse token to get mint URL
        let cashu_token = Token::from_str(&token)
            .map_err(|e| format!("Failed to parse token: {}", e))?;

        let token_mint_url = cashu_token.mint_url()
            .map_err(|e| format!("Failed to get mint URL from token: {}", e))?;

        // Use the global MULTI_MINT_WALLET
        let wallet_guard = MULTI_MINT_WALLET.read().await;
        let multi_mint_wallet = wallet_guard.as_ref()
            .ok_or("MultiMintWallet not initialized")?;

        // If mint doesn't exist, add it automatically
        if !multi_mint_wallet.has_mint(&token_mint_url).await {
            // Add the mint automatically
            multi_mint_wallet.add_mint(token_mint_url.clone()).await
                .map_err(|e| format!("Failed to add mint automatically: {}", e))?;
        }

        // Get wallet for receiving
        let wallet = multi_mint_wallet.get_wallet(&token_mint_url).await
            .ok_or("Failed to get wallet")?;

        // Add metadata for transaction tracking
        let mut metadata = HashMap::new();
        metadata.insert("transaction_type".to_string(), "ecash_receive".to_string());
        metadata.insert("ecash_token".to_string(), token.clone());

        let receive_options = ReceiveOptions {
            metadata,
            ..Default::default()
        };
        let received_amount = wallet.receive(&token, receive_options).await
            .map_err(|e| format!("Failed to receive: {}", e))?;

        Ok(received_amount.into())
}

/// Create mint quote using CDK MultiMintWallet API directly - defaults to sat unit

pub async fn create_mint_quote(mint_url: String, amount: u64, description: Option<String>) -> Result<HashMap<String, String>, String> {
        let mint_url_parsed = MintUrl::from_str(&mint_url)
            .map_err(|e| format!("Invalid mint URL: {}", e))?;

        // Use the global MULTI_MINT_WALLET
        let wallet_guard = MULTI_MINT_WALLET.read().await;
        let multi_mint_wallet = wallet_guard.as_ref()
            .ok_or("MultiMintWallet not initialized")?;

        if !multi_mint_wallet.has_mint(&mint_url_parsed).await {
            return Err("Mint not found in wallet".to_string());
        }

        // Use CDK MultiMintWallet API directly
        let mint_amount = Amount::from(amount);
        let quote = multi_mint_wallet.mint_quote(&mint_url_parsed, mint_amount, description).await
            .map_err(|e| format!("Failed to create mint quote: {}", e))?;

        let mut result = HashMap::new();
        result.insert("quote_id".to_string(), quote.id);
        result.insert("request".to_string(), quote.request);
        result.insert("amount".to_string(), u64::from(quote.amount.unwrap_or(Amount::ZERO)).to_string());
        result.insert("unit".to_string(), quote.unit.to_string());

        Ok(result)
}

/// Get wallet proofs - defaults to sat unit

pub async fn get_wallet_proofs(mint_url: String) -> Result<Vec<CashuProof>, String> {
        let mint_url_parsed = MintUrl::from_str(&mint_url)
            .map_err(|e| format!("Invalid mint URL: {}", e))?;

        // Use the global MULTI_MINT_WALLET
        let wallet_guard = MULTI_MINT_WALLET.read().await;
        let multi_mint_wallet = wallet_guard.as_ref()
            .ok_or("MultiMintWallet not initialized")?;

        if !multi_mint_wallet.has_mint(&mint_url_parsed).await {
            return Err("Mint not found in wallet".to_string());
        }

        let wallet = multi_mint_wallet.get_wallet(&mint_url_parsed).await
            .ok_or("Failed to get wallet")?;

        let proofs = wallet.get_unspent_proofs().await
            .map_err(|e| format!("Failed to get proofs: {}", e))?;

        let cashu_proofs: Vec<CashuProof> = proofs.into_iter()
            .map(|p| p.into())
            .collect();

        Ok(cashu_proofs)
}

/// Parse Cashu token string

pub async fn parse_cashu_token(token: String) -> Result<HashMap<String, String>, String> {
    match Token::from_str(&token) {
        Ok(cashu_token) => {
            let mut token_data = HashMap::new();
            token_data.insert("mint_url".to_string(), 
                cashu_token.mint_url().map(|url| url.to_string()).unwrap_or_else(|_| "unknown".to_string()));
            // For now, we can't easily get proofs count without keysets, so we'll use a placeholder
            token_data.insert("proofs_count".to_string(), "unknown".to_string());
            // Calculate total amount from proofs if we had keysets
            token_data.insert("total_amount".to_string(), "unknown".to_string());
            Ok(token_data)
        }
        Err(e) => Err(format!("Failed to parse token: {}", e))
    }
}

/// Generate a new BIP39 mnemonic phrase (12 or 24 words)

pub async fn generate_mnemonic_phrase(word_count: u32) -> Result<String, String> {
    let _language = Language::English; // Default to English

    let mnemonic = match word_count {
        12 => {
            // Generate 128 bits (16 bytes) of entropy for 12 words
            let mut entropy = [0u8; 16];
            for i in 0..entropy.len() {
                entropy[i] = random::<u8>();
            }
            Mnemonic::from_entropy(&entropy)
                .map_err(|e| format!("Failed to generate 12-word mnemonic: {}", e))?
        },
        24 => {
            // Generate 256 bits (32 bytes) of entropy for 24 words
            let mut entropy = [0u8; 32];
            for i in 0..entropy.len() {
                entropy[i] = random::<u8>();
            }
            Mnemonic::from_entropy(&entropy)
                .map_err(|e| format!("Failed to generate 24-word mnemonic: {}", e))?
        },
        _ => return Err("Word count must be 12 or 24".to_string()),
    };

    Ok(mnemonic.to_string())
}

/// Convert mnemonic phrase to seed hex (64 hex characters)

pub async fn mnemonic_to_seed_hex(mnemonic_phrase: String) -> Result<String, String> {
    let mnemonic = Mnemonic::from_str(&mnemonic_phrase)
        .map_err(|e| format!("Invalid mnemonic phrase: {}", e))?;
    let seed = mnemonic.to_seed_normalized("");
    let seed_hex = hex::encode(seed);

    Ok(seed_hex)
}

/// Convert seed hex to mnemonic phrase (for verification/testing)

pub async fn seed_hex_to_mnemonic(seed_hex: String) -> Result<String, String> {
    // Parse seed hex
    let seed_bytes = hex::decode(&seed_hex)
        .map_err(|e| format!("Invalid hex: {}", e))?;

    // Determine word count based on seed length
    let word_count = match seed_bytes.len() {
        16 => 12, // 128 bits -> 12 words
        32 => 24, // 256 bits -> 24 words
        _ => return Err("Seed must be 16 or 32 bytes".to_string()),
    };

    // Convert entropy to mnemonic
    let entropy_array: [u8; 32] = {
        if seed_bytes.len() == 16 {
            let mut full_entropy = [0u8; 32];
            full_entropy[..16].copy_from_slice(&seed_bytes);
            // For 12 words, we keep only first 16 bytes
            [0u8; 32] // This approach is incorrect for bip39
        } else {
            let mut arr = [0u8; 32];
            arr.copy_from_slice(&seed_bytes);
            arr
        }
    };

    let mnemonic = if word_count == 12 {
        let entropy_16: [u8; 16] = {
            let mut arr = [0u8; 16];
            arr.copy_from_slice(&seed_bytes[..16]);
            arr
        };
        Mnemonic::from_entropy(&entropy_16)
            .map_err(|e| format!("Failed to convert 16-byte seed to mnemonic: {}", e))?
    } else {
        Mnemonic::from_entropy(&entropy_array)
            .map_err(|e| format!("Failed to convert 32-byte seed to mnemonic: {}", e))?
    };

    Ok(mnemonic.to_string())
}

/// Pay lightning invoice using wallet tokens - defaults to sat unit

pub async fn pay_invoice_for_wallet(mint_url: String, bolt11_invoice: String, max_fee_sats: Option<u64>) -> Result<String, String> {
        let mint_url_parsed = MintUrl::from_str(&mint_url)
            .map_err(|e| format!("Invalid mint URL: {}", e))?;

        // Use the global MULTI_MINT_WALLET
        let wallet_guard = MULTI_MINT_WALLET.read().await;
        let multi_mint_wallet = wallet_guard.as_ref()
            .ok_or("MultiMintWallet not initialized")?;

        if !multi_mint_wallet.has_mint(&mint_url_parsed).await {
            return Err("Mint not found in wallet".to_string());
        }

        // Get wallet for melting
        let wallet = multi_mint_wallet.get_wallet(&mint_url_parsed).await
            .ok_or("Failed to get wallet")?;

        // Convert max_fee_sats to Amount if provided
        // Note: max_fee is not currently used in melt_quote, but kept for future use
        let _max_fee = max_fee_sats.map(Amount::from);

        // First, get a melt quote for the invoice
        let quote = wallet.melt_quote(bolt11_invoice.clone(), None).await
            .map_err(|e| format!("Failed to get melt quote: {}", e))?;

        // Then, execute the melt using the quote ID
        let melted = wallet.melt(&quote.id).await
            .map_err(|e| format!("Failed to pay invoice: {}", e))?;

        // Return payment status
        Ok(melted.state.to_string())
}

/// Verify token matches p2pk conditions - defaults to sat unit

pub async fn verify_token_p2pk(mint_url: String, token: String, conditions: String) -> Result<bool, String> {
        let mint_url_parsed = MintUrl::from_str(&mint_url)
            .map_err(|e| format!("Invalid mint URL: {}", e))?;

        // Parse token
        let cashu_token = Token::from_str(&token)
            .map_err(|e| format!("Invalid token: {}", e))?;

        // Parse spending conditions (assuming JSON format)
        let spending_conditions: cdk::nuts::nut11::SpendingConditions = serde_json::from_str(&conditions)
            .map_err(|e| format!("Invalid spending conditions: {}", e))?;

        // Use the global MULTI_MINT_WALLET
        let wallet_guard = MULTI_MINT_WALLET.read().await;
        let multi_mint_wallet = wallet_guard.as_ref()
            .ok_or("MultiMintWallet not initialized")?;

        if !multi_mint_wallet.has_mint(&mint_url_parsed).await {
            return Err("Mint not found in wallet".to_string());
        }

        // Use CDK MultiMintWallet API directly (no longer needs WalletKey)
        match multi_mint_wallet.verify_token_p2pk(&cashu_token, spending_conditions).await {
            Ok(_) => Ok(true),
            Err(e) => Err(format!("Token verification failed: {}", e)),
        }
}

/// Verify all proofs in token have valid dleq proof - defaults to sat unit

pub async fn verify_token_dleq(mint_url: String, token: String) -> Result<bool, String> {
        let mint_url_parsed = MintUrl::from_str(&mint_url)
            .map_err(|e| format!("Invalid mint URL: {}", e))?;

        // Parse token
        let cashu_token = Token::from_str(&token)
            .map_err(|e| format!("Invalid token: {}", e))?;

        // Use the global MULTI_MINT_WALLET
        let wallet_guard = MULTI_MINT_WALLET.read().await;
        let multi_mint_wallet = wallet_guard.as_ref()
            .ok_or("MultiMintWallet not initialized")?;

        if !multi_mint_wallet.has_mint(&mint_url_parsed).await {
            return Err("Mint not found in wallet".to_string());
        }

        // Use CDK MultiMintWallet API directly (no longer needs WalletKey)
        match multi_mint_wallet.verify_token_dleq(&cashu_token).await {
            Ok(_) => Ok(true),
            Err(e) => Err(format!("DLEQ verification failed: {}", e)),
        }
}


/// Check all mint quotes and automatically mint if paid - defaults to sat unit

pub async fn check_mint_quote_status(mint_url: String) -> Result<String, String> {
    let mint_url_parsed = MintUrl::from_str(&mint_url)
        .map_err(|e| format!("Invalid mint URL: {}", e))?;

    // Use the global MULTI_MINT_WALLET
    let wallet_guard = MULTI_MINT_WALLET.read().await;
    let multi_mint_wallet = wallet_guard.as_ref()
        .ok_or("MultiMintWallet not initialized")?;

    if !multi_mint_wallet.has_mint(&mint_url_parsed).await {
        return Err("Mint not found in wallet".to_string());
    }

    // Use CDK MultiMintWallet API directly - check all quotes and auto-mint if paid
    let total_minted = multi_mint_wallet.check_all_mint_quotes(Some(mint_url_parsed)).await
        .map_err(|e| format!("Failed to check mint quotes: {}", e))?;

    Ok(u64::from(total_minted).to_string())
}

/// Check all mint quotes across all wallets and automatically mint if paid
pub async fn check_all_mint_quotes() -> Result<HashMap<String, String>, String> {
    let wallet_guard = MULTI_MINT_WALLET.read().await;
    let multi_mint_wallet = wallet_guard.as_ref()
        .ok_or("MultiMintWallet not initialized")?;

    let total_minted = multi_mint_wallet.check_all_mint_quotes(None).await
        .map_err(|e| format!("Failed to check mint quotes: {}", e))?;

    let mut result = HashMap::new();
    result.insert("total_minted".to_string(), u64::from(total_minted).to_string());
    result.insert("unit".to_string(), multi_mint_wallet.unit().to_string());
    Ok(result)
}

/// Check melt quote status for a specific mint URL - automatically checks all melt quotes
pub async fn check_melt_quote_status(mint_url: String) -> Result<String, String> {
    let mint_url_parsed = MintUrl::from_str(&mint_url)
        .map_err(|e| format!("Invalid mint URL: {}", e))?;

    // Use the global MULTI_MINT_WALLET
    let wallet_guard = MULTI_MINT_WALLET.read().await;
    let multi_mint_wallet = wallet_guard.as_ref()
        .ok_or("MultiMintWallet not initialized")?;

    if !multi_mint_wallet.has_mint(&mint_url_parsed).await {
        return Err("Mint not found in wallet".to_string());
    }

    // Get the wallet
    let _wallet = multi_mint_wallet.get_wallet(&mint_url_parsed).await
        .ok_or("Wallet not found")?;

    // todo: get all melt quotes
    
    Ok("0".to_string())
}

/// Check all melt quotes across all wallets and return completed count
pub async fn check_all_melt_quotes() -> Result<String, String> {
    let wallet_guard = MULTI_MINT_WALLET.read().await;
    let multi_mint_wallet = wallet_guard.as_ref()
        .ok_or("MultiMintWallet not initialized")?;

    let wallets = multi_mint_wallet.get_wallets().await;
    let mut total_completed_count = 0u64;

    // Iterate through all wallets and call check_melt_quote_status for each
    for wallet in wallets.iter() {
        let mint_url = wallet.mint_url.to_string();
        let result = check_melt_quote_status(mint_url).await
            .map_err(|e| format!("Failed to check melt quotes for {}: {}", wallet.mint_url, e))?;
        
        let completed_count = result.parse::<u64>()
            .map_err(|e| format!("Failed to parse completed count: {}", e))?;
        
        total_completed_count += completed_count;
    }

    Ok(total_completed_count.to_string())
}

/// Validate a mnemonic phrase
pub async fn validate_mnemonic_phrase(mnemonic_phrase: String) -> Result<bool, String> {
    match Mnemonic::from_str(&mnemonic_phrase) {
        Ok(_) => Ok(true),
        Err(_) => Ok(false),
    }
}

// Old Tor configuration API has been removed.
// New implementation automatically uses Tor for .onion addresses.
// To explicitly control Tor usage, use WalletBuilder::use_tor() when creating wallets.

/// Set Tor configuration (deprecated - Tor is now auto-detected for .onion addresses)
/// This function is kept for FFI compatibility but does nothing.
/// The policy parameter is ignored.
#[cfg(feature = "tor")]
pub async fn set_tor_config(_policy: bool) -> Result<(), String> {
    // Tor is now automatically used for .onion addresses
    Ok(())
}

/// Get current Tor configuration (deprecated)
#[cfg(feature = "tor")]
pub async fn get_tor_config() -> Result<(), String> {
    // Tor is now automatically used for .onion addresses
    Ok(())
}

/// Check if Tor is currently enabled (deprecated - always returns true if tor feature enabled)
#[cfg(feature = "tor")]
pub async fn is_tor_enabled() -> Result<bool, String> {
    // Tor is automatically used for .onion addresses when tor feature is enabled
    Ok(true)
}

/// Check if Tor is ready (deprecated - not available in new implementation)
#[cfg(feature = "tor")]
pub async fn is_tor_ready() -> Result<bool, String> {
    // Tor readiness checking is not available in the new implementation
    // Tor connections are made on-demand
    Ok(true)
}

/// Reinitialize MultiMintWallet with current Tor configuration (deprecated)
/// Tor is now automatically used for .onion addresses, no reinitialization needed.
#[cfg(feature = "tor")]
pub async fn reinitialize_with_tor_config(database_dir: String, seed_hex: String) -> Result<String, String> {
    // Clear existing wallet
    {
        let mut wallet_guard = MULTI_MINT_WALLET.write().await;
        *wallet_guard = None;
    }
    
    // Reinitialize - Tor will be automatically used for .onion addresses
    init_multi_mint_wallet(database_dir, seed_hex).await
}

/// Initialize MultiMintWallet with Tor configuration (deprecated)
/// Tor is now automatically used for .onion addresses, no special initialization needed.
/// The tor_config parameter is ignored.
#[cfg(feature = "tor")]
pub async fn init_multi_mint_wallet_with_tor(
    database_dir: String, 
    seed_hex: String, 
    _tor_config: Option<String>
) -> Result<String, String> {
    // Tor is automatically used for .onion addresses
    // Use the regular init function
    init_multi_mint_wallet(database_dir, seed_hex).await
}

/// Non-Tor fallback implementations to keep FFI stable
#[cfg(not(feature = "tor"))]
pub async fn set_tor_config(_policy: bool) -> Result<(), String> {
    Err("Tor feature not enabled".to_string())
}

#[cfg(not(feature = "tor"))]
pub async fn is_tor_ready() -> Result<bool, String> {
    Ok(false)
}

#[cfg(not(feature = "tor"))]
pub async fn get_tor_config() -> Result<(), String> {
    Err("Tor feature not enabled".to_string())
}

#[cfg(not(feature = "tor"))]
pub async fn is_tor_enabled() -> Result<bool, String> {
    Ok(false)
}

#[cfg(not(feature = "tor"))]
pub async fn reinitialize_with_tor_config(_database_dir: String, _seed_hex: String) -> Result<String, String> {
    Err("Tor feature not enabled".to_string())
}

#[cfg(not(feature = "tor"))]
pub async fn init_multi_mint_wallet_with_tor(
    database_dir: String, 
    seed_hex: String, 
    _tor_config: Option<String>
) -> Result<String, String> {
    // Fallback to regular init without Tor
    init_multi_mint_wallet(database_dir, seed_hex).await
}

/// Decode a bolt11 lightning invoice to extract amount and other info
pub async fn decode_bolt11_invoice(invoice: String) -> Result<String, String> {
    use cdk::lightning_invoice::Bolt11Invoice;
    
    let bolt11 = Bolt11Invoice::from_str(&invoice)
        .map_err(|e| format!("Failed to parse invoice: {}", e))?;
    
    // Extract amount in millisatoshis
    let amount_msat = bolt11.amount_milli_satoshis()
        .ok_or("Invoice does not contain an amount")?;
    
    // Convert to satoshis
    let amount_sats = amount_msat / 1000;
    
    // Get description if available
    let description = match bolt11.description() {
        cdk::lightning_invoice::Bolt11InvoiceDescriptionRef::Direct(desc) => desc.to_string(),
        cdk::lightning_invoice::Bolt11InvoiceDescriptionRef::Hash(_) => "Hash-based description".to_string(),
    };
    
    // Get expiry time
    let expiry = bolt11.expiry_time().as_secs();
    
    // Create result JSON
    let result = serde_json::json!({
        "amount_sats": amount_sats,
        "amount_msat": amount_msat,
        "description": description,
        "expiry_secs": expiry,
    });
    
    Ok(result.to_string())
}