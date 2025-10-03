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
        
        // Test creating wallet
        let mint_url = "https://8333.space".to_string();
        let unit = "sat".to_string();
        let result = create_wallet(mint_url.clone(), unit.clone());
        println!("✅ Created wallet: {:?}", result);
        
        // Test getting wallet balance
        let balance = get_wallet_balance(mint_url.clone(), unit.clone()).unwrap();
        println!("✅ Got wallet balance: {} sats", balance);
        
        // Test getting wallet info
        let info = get_wallet_info(mint_url.clone(), unit.clone()).unwrap();
        println!("✅ Got wallet info: {:?}", info);
        
        // Test creating proof
        let proof = create_cashu_proof(
            "test_proof_id".to_string(),
            1000,
            "test_secret".to_string(),
            "test_c".to_string(),
        );
        println!("✅ Created Cashu proof successfully");
        
        // Test validating proof
        let is_valid = validate_cashu_proof(proof).unwrap();
        println!("✅ Validated proof: {}", is_valid);
        
        println!("All Cashu tests passed!");
    }
}
