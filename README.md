# Unlock-Bitcoin-Core-Wallet
Unlocks Bitcoin Core BerkelyDB wallets by compiling a special pattern inside the encrypted password
## Introduction
Bitcoin Core wallets are very well encrypted and they can hardly be broken at all. Bitcoin Core itself uses AES-256-CBC on its wallets which is a powerful encryption that would take a very long time to bruteforce with toaday's computational power. Also, these wallets have evolved over time, becoming much safer, so much harder to break. But there is a small loophole that I recently discovered. A loophole that allows you to unlock any Bitcoin Core wallet that is in BerkelyDB database format without having to bruteforce it. (SQLite wallets will not work) That's why I created this project. Let's start.
## Explanation
The "ckey" identifier inside the wallet dat file means the encrypted private key itself. It stands for compressed key. This private key is used directly to unlock the wallet and spend the funds. Because it's encrypted, there are very few chances to decrypt it.

![ckey](https://github.com/silentnight717/Unlock-Bitcoin-Core-Wallet/blob/main/assets/ckey.png)

So I designed a script to extract this private key. It searches the entire wallet dat file and extracts all private keys from it in their raw encrypted state. Then they are displayed in hexadecimal format.

![extract_ckey](https://github.com/silentnight717/Unlock-Bitcoin-Core-Wallet/blob/main/assets/extract_ckey.gif) 

Once you have received the private key, you can analyze it using the ckey_analyzer.rb script and check if it is correct.

![ckey_analyzer](https://github.com/silentnight717/Unlock-Bitcoin-Core-Wallet/blob/main/assets/ckey_analyzer.gif)

If your private key is in order, then you can try to bruteforce it with the bruteforce_ckey.rb script. Keep in mind that it can take a very long time if you work with a weaker processor that was designed before 2023. In addition to that, I do not assure anyone that it will be 100% successful. After all it is AES-256-CBC encryption which is very strong.

![bruteforce_ckey](https://github.com/silentnight717/Unlock-Bitcoin-Core-Wallet/blob/main/assets/bruteforce_ckey.gif)

Now we move to the next step. With the private key, you can't do anything in the console from Bitcoin Core. If you want to import it, you must first enter the password. And besides that, the private key must be decrypted to import it. The next step is to extract the password from the wallet dat file. You can achieve this using the extract_password.rb script. It extracts the password set by user in a raw encrypted format also displaying its correspondence in hexadecimal format.

![extract_password](https://github.com/silentnight717/Unlock-Bitcoin-Core-Wallet/blob/main/assets/extrtact_password.gif)

Time has come to compile the new password that will unlock the wallet. All you have to do is copy the hexadecimal representation of the password and place it in the compile_password.rb script. This script takes the password, converts it into the original state and then adds four special components in a pattern that has been proved to unlock the wallet in the Bitcoin Core console. These four components are control characters: (EM), (SYN), (DLE), and (DC3). They are mixed with the raw encrypted password in the specific pattern and all the result is placed in the console after the walletpassphrase command. 

![compile_password](https://github.com/silentnight717/Unlock-Bitcoin-Core-Wallet/blob/main/assets/compile_password.gif)

## How to use
Well, these scripts are mostly intended for Linux terminals, but they can be run from any machine that has Ruby and ANSI colors installed. Just run ruby and put the script name.
Example: ruby ckey_analyzer.rb  
## Contact
You can contact me at the email silentnight1010100@gmail.com for any questions. Don't open issues unless you're very sure of the problem. Compile password script and bruteforce ckey script not for free. 
