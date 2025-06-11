# Passpolicy
# Created by SS-343
Generates a hashcat mask, hashcat rule, and filters wordlist based on input password policy

Usage: $0 -mi <min_len> [-ma <max_len>] -c <aA1!> [-w wordlist.txt] [-o output_dir] [-r low|med|high]

Options:
  -mi <num>     Minimum password length (required)
  -ma <num>     Maximum password length (optional; default: same as min)
  -c  <chars>   Character classes (required):
                  a = lowercase
                  A = uppercase
                  1 = digits
                  ! = special characters
  -w <file>     Input wordlist (default: rockyou.txt)
  -o <dir>      Output directory (default: current directory)
  -r <level>    Rule strength: low | med | high (default: med)
  -h, --help    Show this help message
