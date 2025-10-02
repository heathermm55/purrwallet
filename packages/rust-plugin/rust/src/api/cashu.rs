use nostr::prelude::*;
use nostr::nips::nip60::*;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::str::FromStr;
use ::url::Url;

/// Cashu proof structure
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CashuProof {
    pub id: String,
    pub amount: u64,
    pub secret: String,
    pub c: String,
}

/// Cashu wallet data
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CashuWallet {
    pub mint_url: String,
    pub proofs: Vec<CashuProof>,
    pub balance: u64,
}

impl CashuWallet {
    pub fn new(mint_url: String) -> Self {
        Self {
            mint_url,
            proofs: Vec::new(),
            balance: 0,
        }
    }

    pub fn add_proof(&mut self, proof: CashuProof) {
        self.proofs.push(proof);
        self.balance = self.proofs.iter().map(|p| p.amount).sum();
    }

    pub fn remove_proof(&mut self, proof_id: &str) -> bool {
        if let Some(pos) = self.proofs.iter().position(|p| p.id == proof_id) {
            self.proofs.remove(pos);
            self.balance = self.proofs.iter().map(|p| p.amount).sum();
            true
        } else {
            false
        }
    }
}

/// Wallet manager for handling multiple Cashu wallets
#[derive(Debug, Clone)]
pub struct WalletManager {
    pub wallets: HashMap<String, CashuWallet>,
}

impl WalletManager {
    pub fn new() -> Self {
        Self {
            wallets: HashMap::new(),
        }
    }

    pub fn add_wallet(&mut self, mint_url: String) -> Result<(), String> {
        if self.wallets.contains_key(&mint_url) {
            return Err("Wallet already exists".to_string());
        }
        self.wallets.insert(mint_url.clone(), CashuWallet::new(mint_url));
        Ok(())
    }

    pub fn remove_wallet(&mut self, mint_url: &str) -> bool {
        self.wallets.remove(mint_url).is_some()
    }

    pub fn get_wallet(&self, mint_url: &str) -> Option<&CashuWallet> {
        self.wallets.get(mint_url)
    }

    pub fn get_wallet_mut(&mut self, mint_url: &str) -> Option<&mut CashuWallet> {
        self.wallets.get_mut(mint_url)
    }

    pub fn get_total_balance(&self) -> u64 {
        self.wallets.values().map(|w| w.balance).sum()
    }

    pub fn get_all_balances(&self) -> HashMap<String, u64> {
        self.wallets.iter().map(|(url, wallet)| (url.clone(), wallet.balance)).collect()
    }
}

/// Create a new wallet manager
#[flutter_rust_bridge::frb(sync)]
pub fn create_wallet_manager() -> WalletManager {
    WalletManager::new()
}

/// Add a Cashu mint to wallet manager
#[flutter_rust_bridge::frb(sync)]
pub fn add_cashu_mint(manager: &mut WalletManager, mint_url: String) -> Result<(), String> {
    manager.add_wallet(mint_url)
}

/// Remove a Cashu mint from wallet manager
#[flutter_rust_bridge::frb(sync)]
pub fn remove_cashu_mint(manager: &mut WalletManager, mint_url: String) -> bool {
    manager.remove_wallet(&mint_url)
}

/// Get wallet balance for a specific mint
#[flutter_rust_bridge::frb(sync)]
pub fn get_wallet_balance(manager: &WalletManager, mint_url: String) -> Result<u64, String> {
    manager.get_wallet(&mint_url)
        .map(|w| w.balance)
        .ok_or_else(|| "Wallet not found".to_string())
}

/// Get all wallet balances as a simple list
#[flutter_rust_bridge::frb(sync)]
pub fn get_all_balances(manager: &WalletManager) -> Vec<(String, u64)> {
    manager.get_all_balances().into_iter().collect()
}

/// Get total balance across all wallets
#[flutter_rust_bridge::frb(sync)]
pub fn get_total_balance(manager: &WalletManager) -> u64 {
    manager.get_total_balance()
}

/// Add proof to a specific wallet
#[flutter_rust_bridge::frb(sync)]
pub fn add_proof_to_wallet(
    manager: &mut WalletManager,
    mint_url: String,
    proof: CashuProof,
) -> Result<(), String> {
    manager.get_wallet_mut(&mint_url)
        .ok_or_else(|| "Wallet not found".to_string())?
        .add_proof(proof);
    Ok(())
}

/// Remove proof from a specific wallet
#[flutter_rust_bridge::frb(sync)]
pub fn remove_proof_from_wallet(
    manager: &mut WalletManager,
    mint_url: String,
    proof_id: String,
) -> Result<bool, String> {
    manager.get_wallet_mut(&mint_url)
        .ok_or_else(|| "Wallet not found".to_string())?
        .remove_proof(&proof_id)
        .then_some(true)
        .ok_or_else(|| "Proof not found".to_string())
}

/// Create a new Cashu proof (placeholder implementation)
#[flutter_rust_bridge::frb(sync)]
pub fn create_cashu_proof(id: String, amount: u64, secret: String, c: String) -> CashuProof {
    CashuProof { id, amount, secret, c }
}

/// NIP-60 Wallet Event functions
/// Create a NIP-60 wallet event
#[flutter_rust_bridge::frb(sync)]
pub fn create_nip60_wallet_event(
    privkey: String,
    mints: Vec<String>,
    secret_key: String,
    public_key: String,
) -> Result<String, String> {
    let secret_key = SecretKey::from_str(&secret_key)
        .map_err(|e| format!("Invalid secret key: {}", e))?;
    let public_key = PublicKey::from_str(&public_key)
        .map_err(|e| format!("Invalid public key: {}", e))?;

    let mint_urls: Result<Vec<Url>, _> = mints.into_iter()
        .map(|mint| Url::parse(&mint))
        .collect();
    let mint_urls = mint_urls.map_err(|e| format!("Invalid mint URL: {}", e))?;

    let wallet_event = WalletEvent::new(privkey, mint_urls);
    let event_builder = wallet_event.to_event_builder(&secret_key, &public_key)
        .map_err(|e| format!("Failed to create wallet event: {}", e))?;

    // For now, return a placeholder since EventBuilder doesn't implement Serialize
    Ok("wallet_event_placeholder".to_string())
}

/// Parse a NIP-60 wallet event
#[flutter_rust_bridge::frb(sync)]
pub fn parse_nip60_wallet_event(
    event_content: String,
    secret_key: String,
    public_key: String,
) -> Result<(String, Vec<String>), String> {
    let secret_key = SecretKey::from_str(&secret_key)
        .map_err(|e| format!("Invalid secret key: {}", e))?;
    let public_key = PublicKey::from_str(&public_key)
        .map_err(|e| format!("Invalid public key: {}", e))?;

    let wallet_event = WalletEvent::from_encrypted_content(&event_content, &secret_key, &public_key)
        .map_err(|e| format!("Failed to parse wallet event: {}", e))?;

    let mints: Vec<String> = wallet_event.mints.into_iter()
        .map(|url| url.to_string())
        .collect();

    Ok((wallet_event.privkey, mints))
}

/// Create a NIP-60 token event
#[flutter_rust_bridge::frb(sync)]
pub fn create_nip60_token_event(
    mint_url: String,
    proofs: Vec<CashuProof>,
    del: Vec<String>,
    secret_key: String,
    public_key: String,
) -> Result<String, String> {
    let secret_key = SecretKey::from_str(&secret_key)
        .map_err(|e| format!("Invalid secret key: {}", e))?;
    let public_key = PublicKey::from_str(&public_key)
        .map_err(|e| format!("Invalid public key: {}", e))?;

    let mint_url = Url::parse(&mint_url)
        .map_err(|e| format!("Invalid mint URL: {}", e))?;

    let cashu_proofs: Vec<nostr::nips::nip60::CashuProof> = proofs.into_iter()
        .map(|p| nostr::nips::nip60::CashuProof {
            id: p.id,
            amount: p.amount,
            secret: p.secret,
            c: p.c,
        })
        .collect();

    let token_event = TokenEventData::new(mint_url, cashu_proofs);
    let event_builder = token_event.to_event_builder(&secret_key, &public_key)
        .map_err(|e| format!("Failed to create token event: {}", e))?;

    // For now, return a placeholder since EventBuilder doesn't implement Serialize
    Ok("token_event_placeholder".to_string())
}

/// Parse a NIP-60 token event
#[flutter_rust_bridge::frb(sync)]
pub fn parse_nip60_token_event(
    event_content: String,
    secret_key: String,
    public_key: String,
) -> Result<(String, Vec<CashuProof>, Vec<String>), String> {
    let secret_key = SecretKey::from_str(&secret_key)
        .map_err(|e| format!("Invalid secret key: {}", e))?;
    let public_key = PublicKey::from_str(&public_key)
        .map_err(|e| format!("Invalid public key: {}", e))?;

    let token_event = TokenEventData::from_encrypted_content(&event_content, &secret_key, &public_key)
        .map_err(|e| format!("Failed to parse token event: {}", e))?;

    let proofs: Vec<CashuProof> = token_event.proofs.into_iter()
        .map(|p| CashuProof {
            id: p.id,
            amount: p.amount,
            secret: p.secret,
            c: p.c,
        })
        .collect();

    Ok((token_event.mint.to_string(), proofs, Vec::new()))
}
