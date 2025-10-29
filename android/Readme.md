## google sign in for the android app:

Website link:   https://developers.google.com/android/guides/client-auth#windows
# MAC:

add sha1 manually:     cd android && ./gradlew signingReport
unzipping:     ./gradlew wrapper
building:   ./gradlew clean
key store password: Rahul123

Generating 2,048 bit RSA key pair and self-signed certificate (SHA256withRSA) with a validity of 10,000 days
        for: CN=rahul chowdary namala, OU=Unknown, O=Unknown, L=seattle, ST=washington, C=WA
[Storing release-keystore.jks]

rahulchowdary@Rahul-4 app % keytool -list -v -keystore release-keystore.jks -alias release
Enter keystore password:
Alias name: release
Creation date: Jan 23, 2025
Entry type: PrivateKeyEntry
Certificate chain length: 1
Certificate[1]:
Owner: CN=rahul chowdary namala, OU=Unknown, O=Unknown, L=seattle, ST=washington, C=WA
Issuer: CN=rahul chowdary namala, OU=Unknown, O=Unknown, L=seattle, ST=washington, C=WA
Serial number: ad4817de30d83f06
Valid from: Thu Jan 23 12:49:16 PST 2025 until: Mon Jun 10 13:49:16 PDT 2052
Certificate fingerprints:
         SHA1: 49:1E:34:8F:DA:C1:30:08:C2:A4:12:7F:34:60:BA:D7:47:45:FC:56
         SHA256: C3:B5:15:5F:EB:78:E1:7D:81:19:9F:D1:F8:97:C7:86:7A:59:AD:EC:3F:48:66:55:90:75:5D:A4:DD:7E:E6:15
Signature algorithm name: SHA256withRSA
Subject Public Key Algorithm: 2048-bit RSA key
Version: 3

Extensions:

#1: ObjectId: 2.5.29.14 Criticality=false
SubjectKeyIdentifier [
KeyIdentifier [
0000: BF 28 75 94 50 05 F7 39   6A 53 FF 27 B9 79 5B 4B  .(u.P..9jS.'.y[K
0010: 03 0C 69 69                                        ..ii
]
]

# windows:
To get the debug certificate fingerprint:

keytool -list -v \
-alias androiddebugkey -keystore %USERPROFILE%\.android\debug.keystore

for SHA1: ./gradlew signingReport