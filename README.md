# Passpolicy
Generates a hashcat mask, hashcat rule, and filters wordlist based on input password policy
 | Option         | Description                                                                                                                 
| -------------- | ---------------------------------------------------------------------------------------------------------------------------
| `-mi <num>`    | Minimum password length (**required**)                                                                                     
| `-ma <num>`    | Maximum password length (optional; default: same as `-mi`)                                                                  
| `-c <chars>`   | Character classes (**required**):<br>• `a` = lowercase<br>• `A` = uppercase<br>• `1` = digits<br>• `!` = special characters 
| `-w <file>`    | Input wordlist (default: `rockyou.txt`)                                                                                     
| `-o <dir>`     | Output directory (default: current directory)                                                                              
| `-r <level>`   | Rule strength: `low`, `med`, `high` (default: `med`)                                                                       
| `-h`, `--help` | Show help message                                                                                                        
