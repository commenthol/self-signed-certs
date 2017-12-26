# Self Signed Certificates

> Generate self signed ssl certificates with your own root CA certificate

This project provides some scripts to setup a root CA to sign single domain or multi-domain (wildcard) certificates.

- `root_ca.sh` : creates root CA certificate
- `site.sh` : creates single-domain certificate
- `star.sh` : creates multi-domain certificate

## Requires

- openssl ~= (OpenSSL 1.0.2g  1 Mar 2016)

## Howto

### root CA

1. Edit `[req_distinguished_name]` in `root_ca.ini` to match your needs. Check `man req` for information on fields.
2. Run `./root_ca.sh`

### single domain

1. Edit `[req_distinguished_name]` in `site.ini` to match your needs. Check `man req` for information on fields.
2. Change domain in `site.ini`. You need to change `CN = <host>` as well as entry in `subjectAltName = DNS:<host>`
3. Run `./site.sh`

### multi domain (wildcard)

1. Edit `[req_distinguished_name]` in `star.ini` to match your needs. Check `man req` for information on fields.
2. Change domain in `star.ini`. You need to change `CN = <host>` as well as entries in `[alt_names]` to match your sub-domains.
3. Run `./star.sh`

## Testing

1. Get [`node`](https://nodejs.org).
2. Import `root_ca.crt` in Browser and/or OS:
   - _Chrome_ : Type in Url "chrome://settings/certificates" > Tab:Authorities > Button:Import > Select `root_ca.crt` > Trust this cert for indent. websites
     Use "chrome://flags/#show-cert-link" to see certificate details from Url-Pane.
   - _Firefox_ : Type in Url "about:preferences#privacy" > Section:Certificates > Button:View Certificates > Tab:Authorities > Button:Import... > Select `root_ca.crt` > Trust this cert for indent. websites
   - _macOS_ : Double click on `root_ca.crt` > Keychain opens > Choose Keychain: **System** > Button:Add 
    Select in Tab:Keychains **System** and double-click on `AA Certification` cert. Fold:Trust > Change:When using this certificate:**Always Trust**.
   - _Ubunutu_ : 
     ```
     sudo cp root_ca.crt /usr/local/share/ca-certificates
     sudo update-ca-certificates
     ```
3. Add some entries in your `/etc/hosts` file. E.g.:
   ````
   127.0.0.1    aa.aa
   127.0.0.2    one.aa.aa
   127.0.0.3    two.test.aa
   ````
4. Start HTTPS server with:
   1. `node test/https.js site` for single site
   2. Browse <https://aa.aa:8443>
   3. `node test/https.js star` for multi domain
   4. Browse <https://aa.aa:8443>
   5. Browse <https://one.aa.aa:8443>
   6. Browse <https://two.test.aa:8443>
   6. Browse <https://localhost:8443>

## License

- Unlicense https://unlicense.org
