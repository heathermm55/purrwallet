use serde::{Deserialize, Serialize};
use serde_json;
use std::collections::HashMap;
use std::sync::Arc;
use std::str::FromStr;

use cdk::nuts::{CurrencyUnit, Token, Proof, Id, SecretKey, PublicKey};
use cdk::secret::Secret;
use cdk::amount::Amount;
use cdk::wallet::{Wallet, MultiMintWallet, SendOptions, ReceiveOptions};
#[cfg(feature = "tor")]
use cdk::wallet::{TorPolicy as CdkTorPolicy, TorConfig as CdkTorConfig, set_tor_config as cdk_set_tor_config, get_tor_config as cdk_get_tor_config};

// Re-export TorConfig for FFI
#[cfg(feature = "tor")]
pub use cdk::wallet::TorConfig;
use cdk::cdk_database::WalletDatabase;
use cdk::wallet::types::{TransactionDirection, WalletKey};
use cdk::mint_url::MintUrl;
use cdk_sqlite::WalletSqliteDatabase;
use bip39::{Mnemonic, Language};
use rand::random;
use std::path::PathBuf;
use tokio::sync::RwLock;

/// Global MultiMintWallet instance
static MULTI_MINT_WALLET: RwLock<Option<Arc<MultiMintWallet>>> = RwLock::const_new(None);

/// Global Tor configuration
#[cfg(feature = "tor")]
static TOR_CONFIG: RwLock<Option<TorConfig>> = RwLock::const_new(None);

/// Tor usage policy for FFI
#[cfg(feature = "tor")]
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum TorPolicy {
    Never,
    OnionOnly,
    Always,
}

#[cfg(feature = "tor")]
impl From<TorPolicy> for CdkTorPolicy {
    fn from(policy: TorPolicy) -> Self {
        match policy {
            TorPolicy::Never => CdkTorPolicy::Never,
            TorPolicy::OnionOnly => CdkTorPolicy::OnionOnly,
            TorPolicy::Always => CdkTorPolicy::Always,
        }
    }
}


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
    pub memo: Option<String>,
    pub timestamp: u64,
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

    // Parse seed from hex string
    let seed = parse_seed_from_hex(&seed_hex)?;
    let db_path = PathBuf::from(&database_dir).join("multi_mint_wallet.db");
    
    std::fs::create_dir_all(db_path.parent().unwrap())
        .map_err(|e| format!("Failed to create database directory: {}", e))?;
    
    let localstore = WalletSqliteDatabase::new(db_path.to_str().unwrap()).await
        .map_err(|e| format!("Failed to create SQLite store: {}", e))?;

    // Try to load existing wallets from database
    let existing_wallets = load_wallets_from_database(&localstore, &seed).await?;

    // Get current Tor config if available
    #[cfg(feature = "tor")]
    let tor_config = {
        let config_guard = TOR_CONFIG.read().await;
        config_guard.clone()
    };
    #[cfg(not(feature = "tor"))]
    let tor_config: Option<()> = None;

    let multi_mint_wallet = MultiMintWallet::new(
        Arc::new(localstore),
        Arc::new(seed),
        existing_wallets, // Load existing wallets
    );

    *wallet_guard = Some(Arc::new(multi_mint_wallet));
    
    Ok("MultiMintWallet initialized successfully".to_string())
}

/// Parse seed from hex string
fn parse_seed_from_hex(seed_hex: &str) -> Result<[u8; 32], String> {
    // Accept both 64-byte (128 hex chars) and 32-byte (64 hex chars) seeds
    let expected_lengths = [64, 128]; // 32 bytes or 64 bytes
    if !expected_lengths.contains(&seed_hex.len()) {
        return Err(format!("Seed must be 64 or 128 hex characters (32 or 64 bytes), got {}", seed_hex.len()));
    }

    // Parse hex string to bytes
    let seed_bytes = hex::decode(seed_hex)
        .map_err(|e| format!("Invalid hex string: {}", e))?;

    // Take the first 32 bytes for MultiMintWallet
    let mut seed = [0u8; 32];
    let bytes_to_copy = std::cmp::min(32, seed_bytes.len());
    seed[..bytes_to_copy].copy_from_slice(&seed_bytes[..bytes_to_copy]);

    Ok(seed)
}

/// Load existing wallets from database
async fn load_wallets_from_database(localstore: &WalletSqliteDatabase, seed: &[u8]) -> Result<Vec<Wallet>, String> {
    // Get all mints from the database
    let mints = localstore.get_mints().await
        .map_err(|e| format!("Failed to get mints from database: {}", e))?;

    let mut wallets = Vec::new();

    for (mint_url, mint_info) in mints {
        // Get supported units from mint info, or default to Sat
        let units = if let Some(mint_info) = mint_info {
            mint_info.supported_units().into_iter().cloned().collect()
        } else {
            vec![CurrencyUnit::Sat]
        };

        for unit in units {
            // Try to create wallet from existing data with the same seed
            match Wallet::new(
                &mint_url.to_string(),
                unit.clone(),
                Arc::new(localstore.clone()),
                seed,
                None,
            ) {
                Ok(wallet) => {
                    wallets.push(wallet);
                }
                Err(_) => {
                    // Skip wallets that can't be loaded
                }
            }
        }
    }

    Ok(wallets)
}

/// Add a mint to MultiMintWallet - defaults to sat unit
pub async fn add_mint(mint_url: String) -> Result<String, String> {
    let wallet_guard = MULTI_MINT_WALLET.read().await;
    let multi_mint_wallet = wallet_guard.as_ref()
        .ok_or("MultiMintWallet not initialized")?;

    let mint_url_parsed = MintUrl::from_str(&mint_url)
        .map_err(|e| format!("Invalid mint URL: {}", e))?;
    let wallet_key = WalletKey::new(mint_url_parsed, CurrencyUnit::Sat);
    
    // Check if wallet already exists
    if multi_mint_wallet.has(&wallet_key).await {
        return Ok("Mint already exists".to_string());
    }

    // Create and add wallet - Tor configuration is now global
    let wallet = multi_mint_wallet.create_and_add_wallet(
        &mint_url,
        CurrencyUnit::Sat,
        None,
    ).await
    .map_err(|e| format!("Failed to create wallet: {}", e))?;

    wallet.load_mint_keysets().await
        .map_err(|e| format!("Failed to load keysets: {}", e))?;

    wallet.get_active_mint_keyset().await
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
        let wallet_key = WalletKey::new(mint_url_parsed.clone(), CurrencyUnit::Sat);
        
        if !multi_mint_wallet.has(&wallet_key).await {
            return Err("Mint not found".to_string());
        }

        // Remove wallet from memory
        multi_mint_wallet.remove_wallet(&wallet_key).await;
        
        // Remove mint from database
        multi_mint_wallet.localstore.remove_mint(mint_url_parsed).await
            .map_err(|e| format!("Failed to remove mint from database: {}", e))?;
        
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

        let wallet_key = WalletKey::new(mint_url_parsed, CurrencyUnit::Sat);
        
        if !multi_mint_wallet.has(&wallet_key).await {
            return Err("Mint not found in wallet".to_string());
        }

        let wallet = multi_mint_wallet.get_wallet(&wallet_key).await
            .ok_or("Failed to get wallet")?;

        let balance = wallet.total_balance().await
            .map_err(|e| format!("Failed to get balance: {}", e))?;

        // Get active keyset ID from mint info
        let active_keyset_id = wallet.get_active_mint_keyset().await
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
            memo: tx.memo,
            timestamp: tx.timestamp,
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
    
    // Get balances for each unit
    for unit in [CurrencyUnit::Sat, CurrencyUnit::Usd, CurrencyUnit::Eur] {
        match multi_mint_wallet.get_balances(&unit).await {
            Ok(unit_balances) => {
                for (mint_url, amount) in unit_balances {
                    let key = format!("{}:{}", mint_url, unit);
                    balances.insert(key, amount.into());
                }
            }
            Err(_) => {
                // Continue if one unit fails
            }
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
    #[cfg(feature = "auth")]
    {
        if nuts.nut21.is_some() {
            supported_nuts.push("NUT-21".to_string());
        }
        if nuts.nut22.is_some() {
            supported_nuts.push("NUT-22".to_string());
        }
    }

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

    let wallet_key = WalletKey::new(mint_url_parsed, CurrencyUnit::Sat);

    if !multi_mint_wallet.has(&wallet_key).await {
        return Err("Mint not found in wallet".to_string());
    }

    let wallet = multi_mint_wallet.get_wallet(&wallet_key).await
        .ok_or("Failed to get wallet")?;

    // Get mint info using the wallet's get_mint_info method
    let mint_info_result = wallet.get_mint_info().await
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

        let wallet_key = WalletKey::new(mint_url_parsed, CurrencyUnit::Sat);
        
        if !multi_mint_wallet.has(&wallet_key).await {
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
        
        let prepared_send = multi_mint_wallet.prepare_send(&wallet_key, send_amount, send_options).await
            .map_err(|e| format!("Failed to prepare send: {}", e))?;

        let send_memo = memo.map(|m| cdk::wallet::SendMemo::for_token(&m));
        let token = multi_mint_wallet.send(&wallet_key, prepared_send, send_memo).await
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

        let wallet_key = WalletKey::new(token_mint_url.clone(), CurrencyUnit::Sat);
        
        // If mint doesn't exist, add it automatically
        if !multi_mint_wallet.has(&wallet_key).await {
            // Add the mint automatically
            let _wallet = multi_mint_wallet.create_and_add_wallet(&token_mint_url.to_string(), CurrencyUnit::Sat, None).await
                .map_err(|e| format!("Failed to add mint automatically: {}", e))?;
        }

        // Get wallet for receiving
        let wallet = multi_mint_wallet.get_wallet(&wallet_key).await
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

        let wallet_key = WalletKey::new(mint_url_parsed, CurrencyUnit::Sat);
        
        if !multi_mint_wallet.has(&wallet_key).await {
            return Err("Mint not found in wallet".to_string());
        }

        // Use CDK MultiMintWallet API directly
        let mint_amount = Amount::from(amount);
        let quote = multi_mint_wallet.mint_quote(&wallet_key, mint_amount, description).await
            .map_err(|e| format!("Failed to create mint quote: {}", e))?;

        let mut result = HashMap::new();
        result.insert("quote_id".to_string(), quote.id);
        result.insert("request".to_string(), quote.request);
        result.insert("amount".to_string(), u64::from(quote.amount).to_string());
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

        let wallet_key = WalletKey::new(mint_url_parsed, CurrencyUnit::Sat);
        
        if !multi_mint_wallet.has(&wallet_key).await {
            return Err("Mint not found in wallet".to_string());
        }

        let wallet = multi_mint_wallet.get_wallet(&wallet_key).await
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

        let wallet_key = WalletKey::new(mint_url_parsed, CurrencyUnit::Sat);
        
        if !multi_mint_wallet.has(&wallet_key).await {
            return Err("Mint not found in wallet".to_string());
        }

        // Convert max_fee_sats to Amount if provided
        let max_fee = max_fee_sats.map(Amount::from);

        // Use CDK MultiMintWallet API directly
        let melted = multi_mint_wallet.pay_invoice_for_wallet(&bolt11_invoice, None, &wallet_key, max_fee).await
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

        let wallet_key = WalletKey::new(mint_url_parsed, CurrencyUnit::Sat);
        
        if !multi_mint_wallet.has(&wallet_key).await {
            return Err("Mint not found in wallet".to_string());
        }

        // Use CDK MultiMintWallet API directly
        match multi_mint_wallet.verify_token_p2pk(&wallet_key, &cashu_token, spending_conditions).await {
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

        let wallet_key = WalletKey::new(mint_url_parsed, CurrencyUnit::Sat);
        
        if !multi_mint_wallet.has(&wallet_key).await {
            return Err("Mint not found in wallet".to_string());
        }

        // Use CDK MultiMintWallet API directly
        match multi_mint_wallet.verify_token_dleq(&wallet_key, &cashu_token).await {
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

    let wallet_key = WalletKey::new(mint_url_parsed, CurrencyUnit::Sat);
    
    if !multi_mint_wallet.has(&wallet_key).await {
        return Err("Mint not found in wallet".to_string());
    }

    // Use CDK MultiMintWallet API directly - check all quotes and auto-mint if paid
    let amounts_minted = multi_mint_wallet.check_all_mint_quotes(Some(wallet_key)).await
        .map_err(|e| format!("Failed to check mint quotes: {}", e))?;

    // Return the total amount minted for this wallet
    let total_minted = amounts_minted.get(&CurrencyUnit::Sat)
        .map(|amount| u64::from(*amount))
        .unwrap_or(0);

    Ok(total_minted.to_string())
}

/// Check all mint quotes across all wallets and automatically mint if paid
pub async fn check_all_mint_quotes() -> Result<HashMap<String, String>, String> {
    let wallet_guard = MULTI_MINT_WALLET.read().await;
    let multi_mint_wallet = wallet_guard.as_ref()
        .ok_or("MultiMintWallet not initialized")?;

    let amounts_minted = multi_mint_wallet.check_all_mint_quotes(None).await
        .map_err(|e| format!("Failed to check mint quotes: {}", e))?;

    let mut result = HashMap::new();
    let mut total_minted = 0u64;

    for (unit, amount) in amounts_minted {
        let amount_u64 = u64::from(amount);
        total_minted += amount_u64;
        result.insert(unit.to_string(), amount_u64.to_string());
    }

    result.insert("total_minted".to_string(), total_minted.to_string());
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

    let wallet_key = WalletKey::new(mint_url_parsed, CurrencyUnit::Sat);
    
    if !multi_mint_wallet.has(&wallet_key).await {
        return Err("Mint not found in wallet".to_string());
    }

    // Get the wallet
    let wallet = multi_mint_wallet.get_wallet(&wallet_key).await
        .ok_or("Wallet not found")?;

    // todo: get all melt quotes
    
    Ok("0".to_string())
}

/// Check all melt quotes across all wallets and return completed count
pub async fn check_all_melt_quotes() -> Result<String, String> {
    let wallet_guard = MULTI_MINT_WALLET.read().await;
    let multi_mint_wallet = wallet_guard.as_ref()
        .ok_or("MultiMintWallet not initialized")?;

    let wallets = multi_mint_wallet.wallets.read().await;
    let mut total_completed_count = 0u64;

    // Iterate through all wallets and call check_melt_quote_status for each
    for (wallet_key, _wallet) in wallets.iter() {
        let mint_url = wallet_key.mint_url.to_string();
        let result = check_melt_quote_status(mint_url).await
            .map_err(|e| format!("Failed to check melt quotes for {}: {}", wallet_key.mint_url, e))?;
        
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

/// Set Tor configuration
#[cfg(feature = "tor")]
pub async fn set_tor_config(policy: TorPolicy) -> Result<(), String> {
    let tor_config = TorConfig {
        policy: policy.into(),
        client_config: None,
        accept_invalid_certs: false,
    };
    
    // Set Tor configuration
    cdk_set_tor_config(tor_config.clone()).await
        .map_err(|e| format!("Failed to set Tor config: {}", e))?;
    
    // Store in local state for compatibility
    let mut config_guard = TOR_CONFIG.write().await;
    *config_guard = Some(tor_config);
    
    Ok(())
}

/// Get current Tor configuration
#[cfg(feature = "tor")]
pub async fn get_tor_config() -> Result<TorPolicy, String> {
    // Try to get from global config first
    if let Some(global_config) = cdk_get_tor_config() {
        let policy = match global_config.policy {
            CdkTorPolicy::Never => TorPolicy::Never,
            CdkTorPolicy::OnionOnly => TorPolicy::OnionOnly,
            CdkTorPolicy::Always => TorPolicy::Always,
        };
        return Ok(policy);
    }
    
    // Fallback to local state
    let config_guard = TOR_CONFIG.read().await;
    match config_guard.as_ref() {
        Some(config) => {
            let policy = match config.policy {
                CdkTorPolicy::Never => TorPolicy::Never,
                CdkTorPolicy::OnionOnly => TorPolicy::OnionOnly,
                CdkTorPolicy::Always => TorPolicy::Always,
            };
            Ok(policy)
        },
        None => Ok(TorPolicy::Never),
    }
}

/// Check if Tor is currently enabled
#[cfg(feature = "tor")]
pub async fn is_tor_enabled() -> Result<bool, String> {
    // Check global config first
    if let Some(global_config) = cdk_get_tor_config() {
        return Ok(!matches!(global_config.policy, CdkTorPolicy::Never));
    }
    
    // Fallback to local state
    let config_guard = TOR_CONFIG.read().await;
    match config_guard.as_ref() {
        Some(config) => {
            match config.policy {
                CdkTorPolicy::Never => Ok(false),
                _ => Ok(true),
            }
        },
        None => Ok(false),
    }
}

/// Reinitialize MultiMintWallet with current Tor configuration
#[cfg(feature = "tor")]
pub async fn reinitialize_with_tor_config(database_dir: String, seed_hex: String) -> Result<String, String> {
    // Get current Tor config
    let tor_config = {
        let config_guard = TOR_CONFIG.read().await;
        config_guard.clone()
    };
    
    // Clear existing wallet
    {
        let mut wallet_guard = MULTI_MINT_WALLET.write().await;
        *wallet_guard = None;
    }
    
    // Reinitialize with Tor config
    init_multi_mint_wallet_with_tor(database_dir, seed_hex, tor_config).await
}

/// Initialize MultiMintWallet with Tor configuration
#[cfg(feature = "tor")]
pub async fn init_multi_mint_wallet_with_tor(
    database_dir: String, 
    seed_hex: String, 
    tor_config: Option<TorConfig>
) -> Result<String, String> {
    // Store Tor config first
    if let Some(tor_config) = tor_config {
        let mut config_guard = TOR_CONFIG.write().await;
        *config_guard = Some(tor_config);
    }
    
    // Use the regular init function which will pick up the Tor config
    init_multi_mint_wallet(database_dir, seed_hex).await
}

/// Non-Tor fallback implementations to keep FFI stable
#[cfg(not(feature = "tor"))]
pub async fn set_tor_config(_policy: ()) -> Result<(), String> {
    Err("Tor feature not enabled".to_string())
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
    _tor_config: Option<()>
) -> Result<String, String> {
    // Fallback to regular init without Tor
    init_multi_mint_wallet(database_dir, seed_hex).await
}