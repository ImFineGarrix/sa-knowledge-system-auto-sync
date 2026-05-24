# Security / Data Protection Defaults

Use these defaults when APIs expose sensitive personal, financial, or internal data.

## Transport

- HTTPS only.
- TLS 1.2 or newer.
- No credentials in query string.

## Secrets

- Real secrets must be sent through a secure channel, not in spec files.
- Commit `.env.example`, never commit real `.env`.
- Use placeholders in documents and Postman collections.

## Field Encryption Pattern

For Java/Spring systems, default encryption suggestion:

```text
Algorithm: AES/GCM/NoPadding
IV: 12 random bytes per encryption
Tag: 128 bits
Output: Base64(IV || CipherText || GCMTag)
```

## Sensitive Field Handling

Document for each sensitive field:

- Whether the DB value is encrypted.
- Whether the API response value is encrypted or masked.
- Whether the field can be logged.
- Which key or integration party can decrypt it.

## Default Sensitive Categories

- Personal identifier
- Phone
- Email
- Address
- Financial amount/limit
- Interest rate
- Token/API key/password/secret

