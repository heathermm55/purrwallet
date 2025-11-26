use nostr::event::{EventBuilder, EventId, Kind, Tag};
use nostr::key::{Keys, PublicKey, SecretKey};
use nostr::nips::nip04;
use nostr::nips::nip19::{FromBech32, ToBech32};
use nostr::nips::nip44;
use nostr::secp256k1::schnorr::Signature;
use nostr::types::time::Timestamp;
use serde::{Deserialize, Serialize};
use std::str::FromStr;

#[derive(Debug, Serialize, Deserialize)]
pub struct NostrEvent {
    pub id: String,
    pub pubkey: String,
    pub created_at: u64,
    pub kind: u64,
    pub tags: Vec<Vec<String>>,
    pub content: String,
    pub sig: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct NostrKeys {
    pub public_key: String,
    pub private_key: String,
}

#[flutter_rust_bridge::frb(sync)]
pub fn generate_keys() -> Result<NostrKeys, String> {
    let keys = Keys::generate();
    Ok(NostrKeys {
        public_key: keys.public_key().to_hex(),
        private_key: keys.secret_key().to_secret_hex(),
    })
}

#[flutter_rust_bridge::frb(sync)]
pub fn get_public_key_from_private(private_key: String) -> Result<String, String> {
    let private_key =
        SecretKey::from_str(&private_key).map_err(|e| format!("Invalid private key: {}", e))?;

    let keys = Keys::new(private_key);
    Ok(keys.public_key().to_hex())
}

#[flutter_rust_bridge::frb(sync)]
pub fn nip04_encrypt(
    plaintext: String,
    public_key: String,
    private_key: String,
) -> Result<String, String> {
    let public_key =
        PublicKey::from_str(&public_key).map_err(|e| format!("Invalid public key: {}", e))?;
    let private_key =
        SecretKey::from_str(&private_key).map_err(|e| format!("Invalid private key: {}", e))?;

    let keys = Keys::new(private_key);
    let secret_key = keys.secret_key();
    let encrypted = nip04::encrypt(secret_key, &public_key, plaintext)
        .map_err(|e| format!("Encryption failed: {}", e))?;

    Ok(encrypted)
}

#[flutter_rust_bridge::frb(sync)]
pub fn nip04_decrypt(
    ciphertext: String,
    public_key: String,
    private_key: String,
) -> Result<String, String> {
    let public_key =
        PublicKey::from_str(&public_key).map_err(|e| format!("Invalid public key: {}", e))?;
    let private_key =
        SecretKey::from_str(&private_key).map_err(|e| format!("Invalid private key: {}", e))?;

    let keys = Keys::new(private_key);
    let secret_key = keys.secret_key();
    let decrypted = nip04::decrypt(secret_key, &public_key, ciphertext)
        .map_err(|e| format!("Decryption failed: {}", e))?;

    Ok(decrypted)
}

#[flutter_rust_bridge::frb(sync)]
pub fn nip44_encrypt(
    plaintext: String,
    public_key: String,
    private_key: String,
) -> Result<String, String> {
    let public_key =
        PublicKey::from_str(&public_key).map_err(|e| format!("Invalid public key: {}", e))?;
    let private_key =
        SecretKey::from_str(&private_key).map_err(|e| format!("Invalid private key: {}", e))?;

    let keys = Keys::new(private_key);
    let secret_key = keys.secret_key();
    let encrypted = nip44::encrypt(secret_key, &public_key, plaintext, nip44::Version::V2)
        .map_err(|e| format!("NIP-44 encryption failed: {}", e))?;

    Ok(encrypted)
}

#[flutter_rust_bridge::frb(sync)]
pub fn nip44_decrypt(
    ciphertext: String,
    public_key: String,
    private_key: String,
) -> Result<String, String> {
    let public_key =
        PublicKey::from_str(&public_key).map_err(|e| format!("Invalid public key: {}", e))?;
    let private_key =
        SecretKey::from_str(&private_key).map_err(|e| format!("Invalid private key: {}", e))?;

    let keys = Keys::new(private_key);
    let secret_key = keys.secret_key();
    let decrypted = nip44::decrypt(secret_key, &public_key, ciphertext)
        .map_err(|e| format!("NIP-44 decryption failed: {}", e))?;

    Ok(decrypted)
}

#[flutter_rust_bridge::frb(sync)]
pub fn sign_event(event_json: String, private_key: String) -> Result<String, String> {
    let private_key =
        SecretKey::from_str(&private_key).map_err(|e| format!("Invalid private key: {}", e))?;

    let keys = Keys::new(private_key);

    // Parse the event from JSON
    let mut event_data: serde_json::Value =
        serde_json::from_str(&event_json).map_err(|e| format!("Invalid JSON: {}", e))?;

    // Extract fields
    let pubkey = event_data["pubkey"]
        .as_str()
        .ok_or("Missing pubkey field")?;
    let created_at = event_data["created_at"]
        .as_u64()
        .ok_or("Missing or invalid created_at field")?;
    let kind = event_data["kind"]
        .as_u64()
        .ok_or("Missing or invalid kind field")?;
    let content = event_data["content"].as_str().unwrap_or("");

    // Parse tags
    let tags: Vec<Vec<String>> = event_data["tags"]
        .as_array()
        .ok_or("Missing or invalid tags field")?
        .iter()
        .map(|tag| {
            tag.as_array().ok_or("Invalid tag format").map(|arr| {
                arr.iter()
                    .map(|v| v.as_str().unwrap_or("").to_string())
                    .collect::<Vec<String>>()
            })
        })
        .collect::<Result<Vec<_>, _>>()
        .map_err(|_| "Invalid tags format")?;

    // Convert tags to nostr format
    let nostr_tags: Vec<Tag> = tags
        .into_iter()
        .map(|tag_vec| {
            let tag_strings: Vec<String> = tag_vec.into_iter().map(|s| s.to_string()).collect();
            Tag::parse(&tag_strings)
        })
        .collect::<Result<Vec<_>, _>>()
        .map_err(|e| format!("Invalid tags: {}", e))?;

    // Create and sign the event using EventBuilder
    let event = EventBuilder::new(Kind::from(kind as u16), content)
        .tags(nostr_tags)
        .custom_created_at(Timestamp::from(created_at))
        .sign_with_keys(&keys)
        .map_err(|e| format!("Failed to create and sign event: {}", e))?;

    // Convert back to JSON string
    let signed_event_json = serde_json::to_string(&event)
        .map_err(|e| format!("Failed to serialize signed event: {}", e))?;

    Ok(signed_event_json)
}

#[flutter_rust_bridge::frb(sync)]
pub fn verify_event(event: NostrEvent) -> Result<bool, String> {
    let event_id = EventId::from_str(&event.id).map_err(|e| format!("Invalid event ID: {}", e))?;
    let pubkey =
        PublicKey::from_str(&event.pubkey).map_err(|e| format!("Invalid public key: {}", e))?;
    let sig = Signature::from_str(&event.sig).map_err(|e| format!("Invalid signature: {}", e))?;

    // Convert tags back to nostr format
    let tags: Vec<Tag> = event
        .tags
        .into_iter()
        .map(|tag_vec| {
            let tag_strings: Vec<String> = tag_vec.into_iter().map(|s| s.to_string()).collect();
            Tag::parse(&tag_strings)
        })
        .collect::<Result<Vec<_>, _>>()
        .map_err(|e| format!("Invalid tags: {}", e))?;

    // Create the event for verification using EventBuilder
    let nostr_event = EventBuilder::new(Kind::from(event.kind as u16), event.content)
        .tags(tags)
        .custom_created_at(Timestamp::from(event.created_at))
        .sign_with_keys(&Keys::new(SecretKey::from_str(&event.pubkey).unwrap()))
        .unwrap();

    // Verify the signature
    Ok(nostr_event.verify().is_ok())
}

#[flutter_rust_bridge::frb(sync)]
pub fn greet(name: String) -> String {
    format!("Hello, {name}!")
}

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    // Default utilities - feel free to customize
    flutter_rust_bridge::setup_default_user_utils();
}

/// Convert secret key to nsec format
#[flutter_rust_bridge::frb(sync)]
pub fn secret_key_to_nsec(secret_key: String) -> Result<String, String> {
    let secret_key =
        SecretKey::from_str(&secret_key).map_err(|e| format!("Invalid secret key: {}", e))?;

    secret_key
        .to_bech32()
        .map_err(|e| format!("Failed to encode to nsec: {}", e))
}

/// Convert public key to npub format
#[flutter_rust_bridge::frb(sync)]
pub fn public_key_to_npub(public_key: String) -> Result<String, String> {
    let public_key =
        PublicKey::from_str(&public_key).map_err(|e| format!("Invalid public key: {}", e))?;

    public_key
        .to_bech32()
        .map_err(|e| format!("Failed to encode to npub: {}", e))
}

/// Convert nsec to secret key hex
#[flutter_rust_bridge::frb(sync)]
pub fn nsec_to_secret_key(nsec: String) -> Result<String, String> {
    let secret_key =
        SecretKey::from_bech32(&nsec).map_err(|e| format!("Failed to decode nsec: {}", e))?;

    Ok(secret_key.to_secret_hex())
}

/// Convert npub to public key hex
#[flutter_rust_bridge::frb(sync)]
pub fn npub_to_public_key(npub: String) -> Result<String, String> {
    let public_key =
        PublicKey::from_bech32(&npub).map_err(|e| format!("Failed to decode npub: {}", e))?;

    Ok(public_key.to_hex())
}

/// Generate keys and return both hex and bech32 formats
#[flutter_rust_bridge::frb(sync)]
pub fn generate_keys_with_bech32() -> Result<NostrKeysWithBech32, String> {
    let keys = generate_keys()?;

    let nsec = secret_key_to_nsec(keys.private_key.clone())?;
    let npub = public_key_to_npub(keys.public_key.clone())?;

    Ok(NostrKeysWithBech32 {
        private_key: keys.private_key,
        public_key: keys.public_key,
        nsec,
        npub,
    })
}

#[derive(Debug, Serialize, Deserialize)]
pub struct NostrKeysWithBech32 {
    pub private_key: String,
    pub public_key: String,
    pub nsec: String,
    pub npub: String,
}
