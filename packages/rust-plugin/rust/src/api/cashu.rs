use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::sync::Arc;
use std::str::FromStr;

use cdk::nuts::{CurrencyUnit, Token, Proof, Id, SecretKey, PublicKey};
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
use std::fs;
use tokio::sync::RwLock;

/// Global MultiMintWallet instance
static MULTI_MINT_WALLET: RwLock<Option<Arc<MultiMintWallet>>> = RwLock::const_new(None);

/// Execute async operation with a new runtime
fn execute_async<F, R>(f: F) -> Result<R, String>
where
    F: std::future::Future<Output = Result<R, String>> + Send,
    R: Send,
{
    let rt = tokio::runtime::Runtime::new()
        .map_err(|e| format!("Failed to create runtime: {}", e))?;
    rt.block_on(f)
}

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
#[flutter_rust_bridge::frb(sync)]
pub fn init_multi_mint_wallet(database_dir: String, seed_hex: String) -> Result<String, String> {
    execute_async(async {
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
        let existing_wallets = load_wallets_from_database(&localstore).await?;

        let multi_mint_wallet = MultiMintWallet::new(
            Arc::new(localstore),
            Arc::new(seed),
            existing_wallets, // Load existing wallets
        );

        *wallet_guard = Some(Arc::new(multi_mint_wallet));
        
        Ok("MultiMintWallet initialized successfully".to_string())
    })
}

/// Parse seed from hex string
fn parse_seed_from_hex(seed_hex: &str) -> Result<[u8; 32], String> {
    if seed_hex.len() != 128 {
        return Err("Seed must be 128 hex characters (64 bytes)".to_string());
    }
    
    // BIP39 generates 64-byte seed, but we need 32-byte seed for MultiMintWallet
    // Take the first 32 bytes (first 64 hex characters)
    let mut seed = [0u8; 32];
    for (i, chunk) in seed_hex.as_bytes().chunks(2).enumerate() {
        if i >= 32 {
            break;
        }
        let hex_str = std::str::from_utf8(chunk)
            .map_err(|_| "Invalid hex string")?;
        seed[i] = u8::from_str_radix(hex_str, 16)
            .map_err(|_| "Invalid hex character")?;
    }
    
    Ok(seed)
}

/// Load existing wallets from database
async fn load_wallets_from_database(localstore: &WalletSqliteDatabase) -> Result<Vec<Wallet>, String> {
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
            // Try to create wallet from existing data
            match WalletBuilder::new()
                .mint_url(mint_url.clone())
                .unit(unit.clone())
                .localstore(Arc::new(localstore.clone()))
                .build()
            {
                Ok(wallet) => {
                    wallets.push(wallet);
                    println!("Loaded existing wallet for mint: {} with unit: {:?}", mint_url, unit);
                }
                Err(e) => {
                    println!("Could not load wallet for mint {}: {}", mint_url, e);
                }
            }
        }
    }

    Ok(wallets)
}

/// Load existing wallets from database
#[flutter_rust_bridge::frb(sync)]
pub fn load_existing_wallets() -> Result<String, String> {
    execute_async(async {
        let wallet_guard = MULTI_MINT_WALLET.read().await;
        let multi_mint_wallet = wallet_guard.as_ref()
            .ok_or("MultiMintWallet not initialized")?;

        // Get all mints from the database
        let mints = multi_mint_wallet.localstore.get_mints().await
            .map_err(|e| format!("Failed to get mints from database: {}", e))?;

        let mut loaded_count = 0;
        
        for (mint_url, mint_info) in mints {
            // Get supported units from mint info, or default to Sat
            let units = if let Some(mint_info) = mint_info {
                mint_info.supported_units().into_iter().cloned().collect()
            } else {
                vec![CurrencyUnit::Sat]
            };

            for unit in units {
                let wallet_key = WalletKey::new(mint_url.clone(), unit.clone());
                
                // Check if wallet already exists
                if !multi_mint_wallet.has(&wallet_key).await {
                    // Create wallet from existing data
                    match multi_mint_wallet.create_and_add_wallet(&mint_url.to_string(), unit.clone(), None).await {
                        Ok(_) => {
                            loaded_count += 1;
                            println!("Loaded existing wallet for mint: {} with unit: {:?}", mint_url, unit);
                        }
                        Err(e) => {
                            println!("Could not load wallet for mint {}: {}", mint_url, e);
                        }
                    }
                }
            }
        }

        Ok(format!("Loaded {} existing wallets", loaded_count))
    })
}

/// Add a mint to MultiMintWallet
#[flutter_rust_bridge::frb(sync)]
pub fn add_mint(mint_url: String, unit: String) -> Result<String, String> {
    execute_async(async {
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
        multi_mint_wallet.create_and_add_wallet(&mint_url, currency_unit, None).await
            .map_err(|e| format!("Failed to create wallet: {}", e))?;

        Ok("Mint added successfully".to_string())
    })
}

/// Remove a mint from MultiMintWallet
#[flutter_rust_bridge::frb(sync)]
pub fn remove_mint(mint_url: String, unit: String) -> Result<String, String> {
    execute_async(async {
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
        let wallet_key = WalletKey::new(mint_url_parsed, currency_unit);
        
        if !multi_mint_wallet.has(&wallet_key).await {
            return Err("Mint not found".to_string());
        }

        multi_mint_wallet.remove_wallet(&wallet_key).await;
        Ok("Mint removed successfully".to_string())
    })
}

/// List all mints in MultiMintWallet
#[flutter_rust_bridge::frb(sync)]
pub fn list_mints() -> Result<Vec<String>, String> {
    execute_async(async {
        let wallet_guard = MULTI_MINT_WALLET.read().await;
        let multi_mint_wallet = wallet_guard.as_ref()
            .ok_or("MultiMintWallet not initialized")?;

        let wallets = multi_mint_wallet.get_wallets().await;
        let mint_list: Vec<String> = wallets.iter()
            .map(|w| format!("{}:{}", w.mint_url, w.unit))
            .collect();

        Ok(mint_list)
    })
}

/// Check if wallet exists
#[flutter_rust_bridge::frb(sync)]
pub fn wallet_exists(mint_url: String, database_dir: String) -> bool {
    wallet_database_exists(&database_dir, &mint_url)
}

/// Create a new CDK Wallet
#[flutter_rust_bridge::frb(sync)]
pub fn create_wallet(mint_url: String, unit: String, database_dir: String) -> Result<String, String> {
    let rt = tokio::runtime::Runtime::new().map_err(|e| format!("Failed to create runtime: {}", e))?;
    
    rt.block_on(async {
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
    })
}

/// Get wallet balance
#[flutter_rust_bridge::frb(sync)]
pub fn get_wallet_balance(mint_url: String, unit: String, database_dir: String) -> Result<u64, String> {
    let rt = tokio::runtime::Runtime::new().map_err(|e| format!("Failed to create runtime: {}", e))?;
    
    rt.block_on(async {
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

        let balance = wallet.total_balance().await
            .map_err(|e| format!("Failed to get balance: {}", e))?;

        Ok(balance.into())
    })
}

/// Get wallet information
#[flutter_rust_bridge::frb(sync)]
pub fn get_wallet_info(mint_url: String, unit: String, database_dir: String) -> Result<WalletInfo, String> {
    let rt = tokio::runtime::Runtime::new().map_err(|e| format!("Failed to create runtime: {}", e))?;
    
    rt.block_on(async {
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

        let balance = wallet.total_balance().await
            .map_err(|e| format!("Failed to get balance: {}", e))?;

        // Try to get active keyset, but provide a default if it fails
        let active_keyset_id = match wallet.get_active_mint_keyset().await {
            Ok(keyset) => keyset.id.to_string(),
            Err(_) => "default_keyset".to_string(),
        };

        Ok(WalletInfo {
            mint_url: wallet.mint_url.to_string(),
            unit: wallet.unit.to_string(),
            balance: balance.into(),
            active_keyset_id,
        })
    })
}

/// Send tokens
#[flutter_rust_bridge::frb(sync)]
pub fn send_tokens(mint_url: String, unit: String, amount: u64, memo: Option<String>, database_dir: String) -> Result<String, String> {
    let rt = tokio::runtime::Runtime::new().map_err(|e| format!("Failed to create runtime: {}", e))?;
    
    rt.block_on(async {
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

        let send_amount = Amount::from(amount);
        let send_options = SendOptions::default();
        
        let prepared_send = wallet.prepare_send(send_amount, send_options).await
            .map_err(|e| format!("Failed to prepare send: {}", e))?;

        let send_memo = memo.map(|m| cdk::wallet::SendMemo::for_token(&m));
        let token = wallet.send(prepared_send, send_memo).await
            .map_err(|e| format!("Failed to send: {}", e))?;

        Ok(token.to_string())
    })
}

/// Receive tokens
#[flutter_rust_bridge::frb(sync)]
pub fn receive_tokens(mint_url: String, unit: String, token: String, memo: Option<String>, database_dir: String) -> Result<u64, String> {
    let rt = tokio::runtime::Runtime::new().map_err(|e| format!("Failed to create runtime: {}", e))?;
    
    rt.block_on(async {
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

        let cashu_token = Token::from_str(&token)
            .map_err(|e| format!("Failed to parse token: {}", e))?;

        let receive_options = ReceiveOptions::default();
        let received_amount = wallet.receive(&token, receive_options).await
            .map_err(|e| format!("Failed to receive: {}", e))?;

        Ok(received_amount.into())
    })
}

/// Create mint quote
#[flutter_rust_bridge::frb(sync)]
pub fn create_mint_quote(mint_url: String, unit: String, amount: u64, database_dir: String) -> Result<HashMap<String, String>, String> {
    let rt = tokio::runtime::Runtime::new().map_err(|e| format!("Failed to create runtime: {}", e))?;
    
    rt.block_on(async {
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

        let mint_amount = Amount::from(amount);
        let quote = wallet.mint_quote(mint_amount, None).await
            .map_err(|e| format!("Failed to create mint quote: {}", e))?;

        let mut result = HashMap::new();
        result.insert("quote_id".to_string(), quote.id);
        result.insert("request".to_string(), quote.request);
        result.insert("amount".to_string(), u64::from(quote.amount).to_string());
        result.insert("unit".to_string(), quote.unit.to_string());

        Ok(result)
    })
}

/// Check mint quote status
#[flutter_rust_bridge::frb(sync)]
pub fn check_mint_quote_status(mint_url: String, unit: String, quote_id: String, database_dir: String) -> Result<String, String> {
    let rt = tokio::runtime::Runtime::new().map_err(|e| format!("Failed to create runtime: {}", e))?;
    
    rt.block_on(async {
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

        let status = wallet.mint_quote_state(&quote_id).await
            .map_err(|e| format!("Failed to check quote status: {}", e))?;

        Ok(status.state.to_string())
    })
}

/// Mint tokens from quote
#[flutter_rust_bridge::frb(sync)]
pub fn mint_from_quote(mint_url: String, unit: String, quote_id: String, database_dir: String) -> Result<u64, String> {
    let rt = tokio::runtime::Runtime::new().map_err(|e| format!("Failed to create runtime: {}", e))?;
    
    rt.block_on(async {
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

        let split_target = SplitTarget::default();
        let minted_proofs = wallet.mint(&quote_id, split_target, None).await
            .map_err(|e| format!("Failed to mint: {}", e))?;

        // Calculate total amount from minted proofs
        let total_amount: u64 = minted_proofs.iter()
            .map(|proof| u64::from(proof.amount))
            .sum();

        Ok(total_amount)
    })
}

/// Get wallet proofs
#[flutter_rust_bridge::frb(sync)]
pub fn get_wallet_proofs(mint_url: String, unit: String, database_dir: String) -> Result<Vec<CashuProof>, String> {
    let rt = tokio::runtime::Runtime::new().map_err(|e| format!("Failed to create runtime: {}", e))?;
    
    rt.block_on(async {
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

        let proofs = wallet.get_unspent_proofs().await
            .map_err(|e| format!("Failed to get proofs: {}", e))?;

        let cashu_proofs: Vec<CashuProof> = proofs.into_iter()
            .map(|p| p.into())
            .collect();

        Ok(cashu_proofs)
    })
}

/// Get wallet transactions
#[flutter_rust_bridge::frb(sync)]
pub fn get_wallet_transactions(mint_url: String, unit: String, database_dir: String) -> Result<Vec<TransactionInfo>, String> {
    let rt = tokio::runtime::Runtime::new().map_err(|e| format!("Failed to create runtime: {}", e))?;
    
    rt.block_on(async {
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

        let transactions = wallet.list_transactions(None).await
            .map_err(|e| format!("Failed to get transactions: {}", e))?;

        let transaction_infos: Vec<TransactionInfo> = transactions.into_iter()
            .map(|tx| TransactionInfo {
                id: tx.id().to_string(),
                direction: match tx.direction {
                    TransactionDirection::Incoming => "incoming".to_string(),
                    TransactionDirection::Outgoing => "outgoing".to_string(),
                },
                amount: tx.amount.into(),
                memo: tx.memo,
                timestamp: tx.timestamp,
            })
            .collect();

        Ok(transaction_infos)
    })
}

/// Create a new Cashu proof (helper function)
#[flutter_rust_bridge::frb(sync)]
pub fn create_cashu_proof(id: String, amount: u64, secret: String, c: String) -> CashuProof {
    CashuProof { id, amount, secret, c }
}

/// Parse Cashu token string
#[flutter_rust_bridge::frb(sync)]
pub fn parse_cashu_token(token: String) -> Result<HashMap<String, String>, String> {
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
#[flutter_rust_bridge::frb(sync)]
pub fn validate_cashu_proof(proof: CashuProof) -> Result<bool, String> {
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
#[flutter_rust_bridge::frb(sync)]
pub fn generate_mnemonic_phrase(word_count: u32) -> Result<String, String> {
    let language = Language::English; // Default to English
    
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
#[flutter_rust_bridge::frb(sync)]
pub fn mnemonic_to_seed_hex(mnemonic_phrase: String) -> Result<String, String> {
    let mnemonic = Mnemonic::from_str(&mnemonic_phrase)
        .map_err(|e| format!("Invalid mnemonic phrase: {}", e))?;
    let seed = mnemonic.to_seed_normalized("");
    Ok(hex::encode(seed))
}

/// Convert seed hex to mnemonic phrase (for verification/testing)
#[flutter_rust_bridge::frb(sync)]
pub fn seed_hex_to_mnemonic(seed_hex: String) -> Result<String, String> {
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
#[flutter_rust_bridge::frb(sync)]
pub fn validate_mnemonic_phrase(mnemonic_phrase: String) -> Result<bool, String> {
    match Mnemonic::from_str(&mnemonic_phrase) {
        Ok(_) => Ok(true),
        Err(_) => Ok(false),
    }
}