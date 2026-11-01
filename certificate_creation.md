Since your domain is registered with GoDaddy, use DNS validation. This works even if your website is not yet live.

## 1. Install Certbot

On Ubuntu:

```
sudo apt update
sudo apt install certbot -y
```

## 2. Request the certificate

```
sudo certbot certonly \
  --manual \
  --preferred-challenges dns \
  -d app.ubaids.store
```

Certbot will display a DNS TXT record similar to:

```
Name:
_acme-challenge.app.ubaids.store

Value:
<unique-token-provided-by-certbot>
```

In GoDaddy DNS, add:

| Field | Value                  |
| ----- | ---------------------- |
| Type  | TXT                    |
| Name  | `_acme-challenge.app`  |
| Value | Token shown by Certbot |
| TTL   | 600 seconds or default |

Wait for DNS propagation, then verify from another terminal:

```
dig TXT _acme-challenge.app.ubaids.store +short
```

Once the expected token appears, return to Certbot and press Enter.

Important: Keep Certbot running while you add and verify the TXT record. Do not remove the TXT record until validation completes.

## 3. Get your certificate and private key

After successful validation, Certbot generates these files:

```
sudo ls -l /etc/letsencrypt/live/app.ubaids.store/
```

Your required files are:

| File            | Description                             |
| --------------- | --------------------------------------- |
| `fullchain.pem` | Public certificate + intermediate chain |
| `privkey.pem`   | Private key                             |
| `cert.pem`      | Domain certificate only                 |
| `chain.pem`     | Intermediate CA certificate             |

The main files you need are:

```
/etc/letsencrypt/live/app.ubaids.store/fullchain.pem
/etc/letsencrypt/live/app.ubaids.store/privkey.pem
```

## 4. Verify the certificate

```
sudo openssl x509 \
  -in /etc/letsencrypt/live/app.ubaids.store/cert.pem \
  -noout -subject -issuer -dates
```

Check that the certificate covers your domain:

```
sudo openssl x509 \
  -in /etc/letsencrypt/live/app.ubaids.store/cert.pem \
  -noout -ext subjectAltName
```

## 5. Important for your AWS ALB

These are the actual publicly trusted certificate and private key files. However, an AWS ALB does not accept PEM files directly through its listener configuration; the certificate must be imported into a supported AWS certificate store before attaching it to the ALB.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://docs.aws.amazon.com\&sz=32)

Elastic Load Balancing+1



Also, certificates issued using Certbot's manual DNS method do not automatically renew. Let's Encrypt certificates are typically valid for 90 days, so you will need to renew them manually or configure automated DNS validation.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://certbot.eff.org\&sz=32)

Certbot+1



For your domain, the result is: a trusted certificate for `app.ubaids.store` and its matching private key, generated and stored outside ACM.
