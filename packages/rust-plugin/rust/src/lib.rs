pub mod api;
mod frb_generated;

// Re-export API functions
pub use api::nostr::*;
pub use api::cashu::*;

#[cfg(test)]
mod tests {
    use super::api::nostr::*;
    use super::api::cashu::*;
    
    #[test]
    fn test_nostr_functions() {
        println!("Testing Nostr Rust functions...");
        
        // Test generate_keys
        let keys = generate_keys().unwrap();
        println!("✅ Generated keys successfully");
        
        // Test NIP-04 encryption/decryption
        let plaintext = "Hello, Nostr!";
        let encrypted = nip04_encrypt(plaintext.to_string(), keys.public_key.clone(), keys.private_key.clone()).unwrap();
        println!("✅ NIP-04 encryption successful");
        
        let decrypted = nip04_decrypt(encrypted, keys.public_key.clone(), keys.private_key.clone()).unwrap();
        assert_eq!(decrypted, plaintext);
        println!("✅ NIP-04 round-trip test passed!");
        
        // Test NIP-44 encryption/decryption
        let encrypted44 = nip44_encrypt(plaintext.to_string(), keys.public_key.clone(), keys.private_key.clone()).unwrap();
        println!("✅ NIP-44 encryption successful");
        
        let decrypted44 = nip44_decrypt(encrypted44, keys.public_key.clone(), keys.private_key.clone()).unwrap();
        assert_eq!(decrypted44, plaintext);
        println!("✅ NIP-44 round-trip test passed!");
        
        println!("All Nostr tests passed!");
    }

    #[test]
    fn test_cashu_functions() {
        println!("Testing Cashu Rust functions...");
        
        // Test wallet manager
        let mut manager = create_wallet_manager();
        println!("✅ Created wallet manager successfully");
        
        // Test adding mint
        let mint_url = "https://mint.cashu.space".to_string();
        add_cashu_mint(&mut manager, mint_url.clone()).unwrap();
        println!("✅ Added mint successfully");
        
        // Test getting balance
        let balance = get_wallet_balance(&manager, mint_url.clone()).unwrap();
        assert_eq!(balance, 0);
        println!("✅ Got wallet balance successfully");
        
        // Test creating proof
        let proof = create_cashu_proof(
            "test_proof_id".to_string(),
            1000,
            "test_secret".to_string(),
            "test_c".to_string(),
        );
        println!("✅ Created Cashu proof successfully");
        
        // Test adding proof to wallet
        add_proof_to_wallet(&mut manager, mint_url.clone(), proof).unwrap();
        println!("✅ Added proof to wallet successfully");
        
        // Test getting updated balance
        let new_balance = get_wallet_balance(&manager, mint_url).unwrap();
        assert_eq!(new_balance, 1000);
        println!("✅ Got updated wallet balance successfully");
        
        println!("All Cashu tests passed!");
    }
}
