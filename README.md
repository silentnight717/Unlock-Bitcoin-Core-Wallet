# Unlock-Bitcoin-Core-Wallet
Unlocks Bitcoin Core BerkelyDB wallets by compiling a special pattern inside the encrypted password.
## Introduction
[Bitcoin Core](https://bitcoin.org/en/bitcoin-core/wallet) wallets are very well encrypted and are very difficult to crack. Bitcoin Core itself uses AES-256-CBC on its wallets, a strong encryption that would take a very long time to bruteforce with current computing power. These wallets have also evolved over time, becoming much more secure, and therefore much harder to crack. However, there is a small loophole that I recently discovered. A loophole that allows you to unlock any Bitcoin Core wallet that is in the BerkelyDB database format without having to bruteforce it (SQLite wallets will not work). That's why I created this project. Let's get started.
## Explanation & Demonstration
The `ckey` identifier inside the wallet.dat file means the encrypted private key itself. It stands for `Crypted key`. This private key is used directly to unlock the wallet and spend the funds. Because it's encrypted, there are very few chances to decrypt it without the correct AES key.

![ckey](https://github.com/silentnight717/Unlock-Bitcoin-Core-Wallet/blob/main/assets/ckey.png)

So, I designed a script to extract this private key. It searches the entire wallet.dat file and extracts all private keys from it in their raw encrypted state. Then, they are displayed in hexadecimal format.

![extract_ckey](https://github.com/silentnight717/Unlock-Bitcoin-Core-Wallet/blob/main/assets/extract_ckey.gif) 

Once you have received the private key, you can analyze it using the **ckey_analyzer.rb** script and check if it is correct.

![ckey_analyzer](https://github.com/silentnight717/Unlock-Bitcoin-Core-Wallet/blob/main/assets/ckey_analyzer.gif)

If your private key is in order, then you can try to bruteforce it with the **bruteforce_ckey.rb** script. Keep in mind that it can take a very long time if you are working with a weaker processor, designed before 2023. Furthermore, I do not guarantee anyone that it will be 100% successful.

![bruteforce_ckey](https://github.com/silentnight717/Unlock-Bitcoin-Core-Wallet/blob/main/assets/bruteforce_ckey.gif)

Now we move on to the next step. With the private key, you can't do anything in the Bitcoin Core console. If you want to import it, you have to enter the password first. Additionally, the private key needs to be decrypted in order to import it. The next step is to extract the password from the wallet.dat file. You can do this using the **extract_password.rb** script. It extracts the password set by the user in a raw encrypted format, and also displays its correspondence in hexadecimal format.

![extract_password](https://github.com/silentnight717/Unlock-Bitcoin-Core-Wallet/blob/main/assets/extract_password.gif)

Then, you can check this one too:

![password_analyzer](https://github.com/silentnight717/Unlock-Bitcoin-Core-Wallet/blob/main/assets/password_analyzer.gif)

It’s time to compile the new password that will unlock your wallet. All you need to do is copy the hexadecimal representation of your password and place it in the **compile_password.rb** script. This script takes your password, converts it back to its original state, and then adds four special components in a pattern that has been proven to unlock the wallet in the Bitcoin Core console. These four components are control characters: `(EM)`, `(SYN)`, `(DLE)`, and `(DC3)`. They are mixed with the raw encrypted password in the specific pattern, and the entire result is placed in the console after the walletpassphrase command.

![compile_password](https://github.com/silentnight717/Unlock-Bitcoin-Core-Wallet/blob/main/assets/compile_password.gif)

## Requirements
* base32
* base58

Install them using gem: 
```
gem install base32 base58
```
## How to use
Well, these scripts are mostly intended for Linux terminals, but they can be run from any machine which has Ruby installed and supports ANSI colors. Just run ruby and put the script name.

Example: 
```
ruby ckey_analyzer.rb
```

## Updates
- [X] extract_ckey.rb now has an usage
- [X] ckeys are extracted in a clean format, without padding 
- [X] [bruteforce_ckey.rb](https://github.com/silentnight717/Unlock-Bitcoin-Core-Wallet/blob/main/bruteforce_ckey.rb) has become available
- [X] a new script has been created: [password_analyzer.rb](https://github.com/silentnight717/Unlock-Bitcoin-Core-Wallet/blob/main/password_analyzer.rb)
- [X] the scripts support disabling colors, using the `-dc` argument
- [X] new design updates
- [X] minor code improvements

## Contact
You can contact me at the email silentnight58070@proton.me for any questions. Don't open issues unless you're very sure of the problem. **compile_password.rb** script is not for free. 
