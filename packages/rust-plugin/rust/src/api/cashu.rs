use serde::{Deserialize, Serialize};
use serde_json;
use std::collections::HashMap;
use std::sync::Arc;
use std::str::FromStr;

use cdk::nuts::{CurrencyUnit, Token, Proof, Id, SecretKey, PublicKey, ProofsMethods};
use cdk::secret::Secret;
use cdk::amount::{Amount, SplitTarget};
use cdk::wallet::{Wallet, MultiMintWallet, SendOptions, ReceiveOptions, WalletBuilder};
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
            match WalletBuilder::new()
                .mint_url(mint_url.clone())
                .unit(unit.clone())
                .localstore(Arc::new(localstore.clone()))
                .seed(seed)
                .build()
            {
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

/// Add a mint to MultiMintWallet

pub async fn add_mint(mint_url: String, unit: String) -> Result<String, String> {
        let wallet_guard = MULTI_MINT_WALLET.read().await;
        let multi_mint_wallet = wallet_guard.as_ref()
            .ok_or("MultiMintWallet not initialized")?;

        let currency_unit = match unit.as_str() {
            "sat" => CurrencyUnit::Sat,
            "usd" => CurrencyUnit::Usd,
            "eur" => CurrencyUnit::Eur,
            _ => return Err("Unsupported currency unit".to_string()),
        };

        let mint_url_parsed = MintUrl::from_str(&mint_url)
            .map_err(|e| format!("Invalid mint URL: {}", e))?;
        let wallet_key = WalletKey::new(mint_url_parsed, currency_unit.clone());
        
        // Check if wallet already exists
        if multi_mint_wallet.has(&wallet_key).await {
            return Ok("Mint already exists".to_string());
        }

        // Create and add wallet
        let wallet = multi_mint_wallet.create_and_add_wallet(&mint_url, currency_unit.clone(), None).await
            .map_err(|e| format!("Failed to create wallet: {}", e))?;

        // Try to get mint info and keysets
        wallet.get_mint_info().await
            .map_err(|e| format!("Failed to get mint info: {}", e))?;

        wallet.load_mint_keysets().await
            .map_err(|e| format!("Failed to load keysets: {}", e))?;

        wallet.get_active_mint_keyset().await
            .map_err(|e| format!("Failed to get active keyset: {}", e))?;

        Ok("Mint added successfully".to_string())

}

/// Remove a mint from MultiMintWallet

pub async fn remove_mint(mint_url: String, unit: String) -> Result<String, String> {

        let wallet_guard = MULTI_MINT_WALLET.read().await;
        let multi_mint_wallet = wallet_guard.as_ref()
            .ok_or("MultiMintWallet not initialized")?;

        let currency_unit = match unit.as_str() {
            "sat" => CurrencyUnit::Sat,
            "usd" => CurrencyUnit::Usd,
            "eur" => CurrencyUnit::Eur,
            _ => return Err("Unsupported currency unit".to_string()),
        };

        let mint_url_parsed = MintUrl::from_str(&mint_url)
            .map_err(|e| format!("Invalid mint URL: {}", e))?;
        let wallet_key = WalletKey::new(mint_url_parsed.clone(), currency_unit);
        
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

/// Create a new CDK Wallet
pub async fn create_wallet(mint_url: String, unit: String, database_dir: String) -> Result<String, String> {
    // Check if wallet already exists
    if wallet_database_exists(&database_dir, &mint_url) {
        return Ok("Wallet already exists".to_string());
    }

    let seed = random::<[u8; 32]>();
    let currency_unit = match unit.as_str() {
        "sat" => CurrencyUnit::Sat,
        "usd" => CurrencyUnit::Usd,
        "eur" => CurrencyUnit::Eur,
        _ => return Err("Unsupported currency unit".to_string()),
    };

    let db_path = get_database_path(&database_dir, &mint_url);
    std::fs::create_dir_all(db_path.parent().unwrap())
        .map_err(|e| format!("Failed to create database directory: {}", e))?;

    let localstore = WalletSqliteDatabase::new(db_path.to_str().unwrap()).await
        .map_err(|e| format!("Failed to create SQLite store: {}", e))?;

    let wallet = Wallet::new(
        &mint_url,
        currency_unit,
        Arc::new(localstore),
        &seed,
        None,
    ).map_err(|e| format!("Failed to create wallet: {}", e))?;

    // Get mint info to validate connection
    wallet.get_mint_info().await
        .map_err(|e| format!("Failed to get mint info: {}", e))?;

    Ok("Wallet created successfully".to_string())
}



/// Get wallet information quickly (without network requests)
pub async fn get_wallet_info_fast(mint_url: String, unit: String) -> Result<WalletInfo, String> {

        let mint_url_parsed = MintUrl::from_str(&mint_url)
            .map_err(|e| format!("Invalid mint URL: {}", e))?;

        let currency_unit = match unit.as_str() {
            "sat" => CurrencyUnit::Sat,
            "usd" => CurrencyUnit::Usd,
            "eur" => CurrencyUnit::Eur,
            _ => return Err("Unsupported currency unit".to_string()),
        };

        // Use MultiMintWallet to get wallet info
        let wallet_guard = MULTI_MINT_WALLET.read().await;
        let multi_mint_wallet = wallet_guard.as_ref()
            .ok_or("MultiMintWallet not initialized")?;

        let wallet_key = WalletKey::new(mint_url_parsed, currency_unit);
        
        if !multi_mint_wallet.has(&wallet_key).await {
            return Err("Mint not found in wallet".to_string());
        }

        let wallet = multi_mint_wallet.get_wallet(&wallet_key).await
            .ok_or("Failed to get wallet")?;

        let balance = wallet.total_balance().await
            .map_err(|e| format!("Failed to get balance: {}", e))?;

        // Use cached keyset info or default (no network request)
        let active_keyset_id = "cached_keyset".to_string();

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

/// Get mint information from NUT-06 endpoint
pub async fn get_mint_info(mint_url: String, unit: String) -> Result<MintInfo, String> {
    let mint_url_parsed = MintUrl::from_str(&mint_url)
        .map_err(|e| format!("Invalid mint URL: {}", e))?;

    let currency_unit = match unit.as_str() {
        "sat" => CurrencyUnit::Sat,
        "usd" => CurrencyUnit::Usd,
        "eur" => CurrencyUnit::Eur,
        _ => return Err("Unsupported currency unit".to_string()),
    };

    // Use MultiMintWallet to get mint info
    let wallet_guard = MULTI_MINT_WALLET.read().await;
    let multi_mint_wallet = wallet_guard.as_ref()
        .ok_or("MultiMintWallet not initialized")?;

    let wallet_key = WalletKey::new(mint_url_parsed, currency_unit);

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

/// Send tokens

pub async fn send_tokens(mint_url: String, unit: String, amount: u64, memo: Option<String>) -> Result<String, String> {

        let mint_url_parsed = MintUrl::from_str(&mint_url)
            .map_err(|e| format!("Invalid mint URL: {}", e))?;

        let currency_unit = match unit.as_str() {
            "sat" => CurrencyUnit::Sat,
            "usd" => CurrencyUnit::Usd,
            "eur" => CurrencyUnit::Eur,
            _ => return Err("Unsupported currency unit".to_string()),
        };

        // Use the global MULTI_MINT_WALLET
        let wallet_guard = MULTI_MINT_WALLET.read().await;
        let multi_mint_wallet = wallet_guard.as_ref()
            .ok_or("MultiMintWallet not initialized")?;

        let wallet_key = WalletKey::new(mint_url_parsed, currency_unit);
        
        if !multi_mint_wallet.has(&wallet_key).await {
            return Err("Mint not found in wallet".to_string());
        }

        let wallet = multi_mint_wallet.get_wallet(&wallet_key).await
            .ok_or("Failed to get wallet")?;

        let send_amount = Amount::from(amount);
        let send_options = SendOptions::default();
        
        let prepared_send = wallet.prepare_send(send_amount, send_options).await
            .map_err(|e| format!("Failed to prepare send: {}", e))?;

        let send_memo = memo.map(|m| cdk::wallet::SendMemo::for_token(&m));
        let token = wallet.send(prepared_send, send_memo).await
            .map_err(|e| format!("Failed to send: {}", e))?;

        Ok(token.to_string())

}

/// Receive tokens

pub async fn receive_tokens(mint_url: String, unit: String, token: String, _memo: Option<String>) -> Result<u64, String> {

        let mint_url_parsed = MintUrl::from_str(&mint_url)
            .map_err(|e| format!("Invalid mint URL: {}", e))?;

        let currency_unit = match unit.as_str() {
            "sat" => CurrencyUnit::Sat,
            "usd" => CurrencyUnit::Usd,
            "eur" => CurrencyUnit::Eur,
            _ => return Err("Unsupported currency unit".to_string()),
        };

        // Use the global MULTI_MINT_WALLET
        let wallet_guard = MULTI_MINT_WALLET.read().await;
        let multi_mint_wallet = wallet_guard.as_ref()
            .ok_or("MultiMintWallet not initialized")?;

        let wallet_key = WalletKey::new(mint_url_parsed, currency_unit);
        
        if !multi_mint_wallet.has(&wallet_key).await {
            return Err("Mint not found in wallet".to_string());
        }

        let wallet = multi_mint_wallet.get_wallet(&wallet_key).await
            .ok_or("Failed to get wallet")?;

        let _cashu_token = Token::from_str(&token)
            .map_err(|e| format!("Failed to parse token: {}", e))?;

        let receive_options = ReceiveOptions::default();
        let received_amount = wallet.receive(&token, receive_options).await
            .map_err(|e| format!("Failed to receive: {}", e))?;

        Ok(received_amount.into())

}

/// Create mint quote

pub async fn create_mint_quote(mint_url: String, unit: String, amount: u64) -> Result<HashMap<String, String>, String> {

        let mint_url_parsed = MintUrl::from_str(&mint_url)
            .map_err(|e| format!("Invalid mint URL: {}", e))?;

        let currency_unit = match unit.as_str() {
            "sat" => CurrencyUnit::Sat,
            "usd" => CurrencyUnit::Usd,
            "eur" => CurrencyUnit::Eur,
            _ => return Err("Unsupported currency unit".to_string()),
        };

        // Use the global MULTI_MINT_WALLET
        let wallet_guard = MULTI_MINT_WALLET.read().await;
        let multi_mint_wallet = wallet_guard.as_ref()
            .ok_or("MultiMintWallet not initialized")?;

        let wallet_key = WalletKey::new(mint_url_parsed, currency_unit);
        
        if !multi_mint_wallet.has(&wallet_key).await {
            return Err("Mint not found in wallet".to_string());
        }

        let wallet = multi_mint_wallet.get_wallet(&wallet_key).await
            .ok_or("Failed to get wallet")?;

        let mint_amount = Amount::from(amount);
        let quote = wallet.mint_quote(mint_amount, None).await
            .map_err(|e| format!("Failed to create mint quote: {}", e))?;

        let mut result = HashMap::new();
        result.insert("quote_id".to_string(), quote.id);
        result.insert("request".to_string(), quote.request);
        result.insert("amount".to_string(), u64::from(quote.amount).to_string());
        result.insert("unit".to_string(), quote.unit.to_string());

        Ok(result)

}

/// Check mint quote status

pub async fn check_mint_quote_status(mint_url: String, unit: String, quote_id: String) -> Result<String, String> {

        let mint_url_parsed = MintUrl::from_str(&mint_url)
            .map_err(|e| format!("Invalid mint URL: {}", e))?;

        let currency_unit = match unit.as_str() {
            "sat" => CurrencyUnit::Sat,
            "usd" => CurrencyUnit::Usd,
            "eur" => CurrencyUnit::Eur,
            _ => return Err("Unsupported currency unit".to_string()),
        };

        // Use the global MULTI_MINT_WALLET
        let wallet_guard = MULTI_MINT_WALLET.read().await;
        let multi_mint_wallet = wallet_guard.as_ref()
            .ok_or("MultiMintWallet not initialized")?;

        let wallet_key = WalletKey::new(mint_url_parsed, currency_unit);
        
        if !multi_mint_wallet.has(&wallet_key).await {
            return Err("Mint not found in wallet".to_string());
        }

        let wallet = multi_mint_wallet.get_wallet(&wallet_key).await
            .ok_or("Failed to get wallet")?;

        let status = wallet.mint_quote_state(&quote_id).await
            .map_err(|e| format!("Failed to check quote status: {}", e))?;

        Ok(status.state.to_string())

}

/// Mint tokens from quote

pub async fn mint_from_quote(mint_url: String, unit: String, quote_id: String) -> Result<u64, String> {

        let mint_url_parsed = MintUrl::from_str(&mint_url)
            .map_err(|e| format!("Invalid mint URL: {}", e))?;

        let currency_unit = match unit.as_str() {
            "sat" => CurrencyUnit::Sat,
            "usd" => CurrencyUnit::Usd,
            "eur" => CurrencyUnit::Eur,
            _ => return Err("Unsupported currency unit".to_string()),
        };

        // Use the global MULTI_MINT_WALLET
        let wallet_guard = MULTI_MINT_WALLET.read().await;
        let multi_mint_wallet = wallet_guard.as_ref()
            .ok_or("MultiMintWallet not initialized")?;

        let wallet_key = WalletKey::new(mint_url_parsed, currency_unit);
        
        if !multi_mint_wallet.has(&wallet_key).await {
            return Err("Mint not found in wallet".to_string());
        }

        let wallet = multi_mint_wallet.get_wallet(&wallet_key).await
            .ok_or("Failed to get wallet")?;

        let split_target = SplitTarget::default();
        let minted_proofs = wallet.mint(&quote_id, split_target, None).await
            .map_err(|e| format!("Failed to mint: {}", e))?;

        // Calculate total amount from minted proofs
        let total_amount: u64 = minted_proofs.iter()
            .map(|proof| u64::from(proof.amount))
            .sum();

        Ok(total_amount)

}

/// Get wallet proofs

pub async fn get_wallet_proofs(mint_url: String, unit: String) -> Result<Vec<CashuProof>, String> {

        let mint_url_parsed = MintUrl::from_str(&mint_url)
            .map_err(|e| format!("Invalid mint URL: {}", e))?;

        let currency_unit = match unit.as_str() {
            "sat" => CurrencyUnit::Sat,
            "usd" => CurrencyUnit::Usd,
            "eur" => CurrencyUnit::Eur,
            _ => return Err("Unsupported currency unit".to_string()),
        };

        // Use the global MULTI_MINT_WALLET
        let wallet_guard = MULTI_MINT_WALLET.read().await;
        let multi_mint_wallet = wallet_guard.as_ref()
            .ok_or("MultiMintWallet not initialized")?;

        let wallet_key = WalletKey::new(mint_url_parsed, currency_unit);
        
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


/// Create a new Cashu proof (helper function)

pub async fn create_cashu_proof(id: String, amount: u64, secret: String, c: String) -> CashuProof {
    CashuProof { id, amount, secret, c }
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

/// Validate Cashu proof

pub async fn validate_cashu_proof(proof: CashuProof) -> Result<bool, String> {
    // Basic validation - check if all fields are non-empty
    if proof.id.is_empty() || proof.secret.is_empty() || proof.c.is_empty() {
        return Ok(false);
    }

    // Try to convert to CDK Proof to validate format
    match Proof::try_from(proof) {
        Ok(_) => Ok(true),
        Err(_) => Ok(false),
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

/// Validate a mnemonic phrase

pub async fn validate_mnemonic_phrase(mnemonic_phrase: String) -> Result<bool, String> {
    match Mnemonic::from_str(&mnemonic_phrase) {
        Ok(_) => Ok(true),
        Err(_) => Ok(false),
    }
}

/// Create a lightning invoice for receiving payment

pub async fn create_lightning_invoice(
    mint_url: String,
    amount: u64,
    memo: Option<String>,
) -> Result<String, String> {
        
        let mint_url_parsed = MintUrl::from_str(&mint_url)
            .map_err(|e| format!("Invalid mint URL '{}': {}", mint_url, e))?;

        // Use the global MULTI_MINT_WALLET
        let wallet_guard = MULTI_MINT_WALLET.read().await;
        let multi_mint_wallet = wallet_guard.as_ref()
            .ok_or("MultiMintWallet not initialized")?;

        let wallet_key = WalletKey::new(mint_url_parsed, CurrencyUnit::Sat);
        
        if !multi_mint_wallet.has(&wallet_key).await {
            return Err("Mint not found in wallet".to_string());
        }

        let wallet_instance = multi_mint_wallet.get_wallet(&wallet_key).await
            .ok_or("Failed to get wallet")?;

        // Create mint quote for lightning invoice
        let mint_amount = Amount::from(amount);
        
        let quote = wallet_instance.mint_quote(mint_amount, memo).await
            .map_err(|e| format!("Failed to get mint quote: {}", e))?;

        // Return both the invoice request and the quote ID for tracking
        let response = serde_json::json!({
            "invoice": quote.request,
            "quote_id": quote.id,
            "amount": amount
        });

        Ok(response.to_string())

}

/// Check if a lightning invoice has been paid

pub async fn check_lightning_invoice_status(
    mint_url: String,
    quote_id: String,
) -> Result<bool, String> {
        
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

        let wallet_instance = multi_mint_wallet.get_wallet(&wallet_key).await
            .ok_or("Failed to get wallet")?;

        // Check quote status using the correct CDK API
        let quote_response = wallet_instance.mint_quote_state(&quote_id).await
            .map_err(|e| format!("Failed to check quote status: {}", e))?;
        
        // Return true if the quote is paid
        let is_paid = matches!(quote_response.state, cdk::nuts::MintQuoteState::Paid);
        
        Ok(is_paid)

}

/// Mint tokens from a paid lightning invoice

pub async fn mint_from_lightning_invoice(
    mint_url: String,
    quote_id: String,
) -> Result<String, String> {
        
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

        let wallet_instance = multi_mint_wallet.get_wallet(&wallet_key).await
            .ok_or("Failed to get wallet")?;

        // Ensure mint info and keysets are loaded before minting
        wallet_instance.get_mint_info().await
            .map_err(|e| format!("Failed to get mint info: {}", e))?;
        
        wallet_instance.load_mint_keysets().await
            .map_err(|e| format!("Failed to load mint keysets: {}", e))?;

        // Check if quote is paid
        match wallet_instance.localstore.get_mint_quote(&quote_id).await {
            Ok(Some(quote)) => {
                if !matches!(quote.state, cdk::nuts::MintQuoteState::Paid) {
                    return Err(format!("Quote is not paid yet, state: {:?}", quote.state));
                }
            },
            Ok(None) => return Err("Quote not found in database".to_string()),
            Err(e) => return Err(format!("Failed to get quote from database: {}", e)),
        }

        // Mint tokens from the paid quote
        let proofs = wallet_instance.mint(&quote_id, cdk::amount::SplitTarget::default(), None).await
            .map_err(|e| format!("Failed to mint from quote: {}", e))?;

        let total_amount = proofs.total_amount()
            .map_err(|e| format!("Failed to calculate total amount: {}", e))?;
        
        // Return success message with token count and amount
        Ok(format!("Successfully minted {} tokens, total amount: {}", proofs.len(), total_amount))

}