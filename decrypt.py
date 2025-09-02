import json
import subprocess

# Load JSON file
with open("outputs.json", "r") as f:
    data = json.load(f)

# List of lab vm info entries
vm_entries = data["lab_vm_access_info"]["value"]

def decrypt_pgp(encrypted_text):
    """Decrypt Base64 PGP encrypted text by adding ASCII armor headers."""
    pgp_message = f"""-----BEGIN PGP MESSAGE-----

{encrypted_text}

-----END PGP MESSAGE-----"""

    try:
        proc = subprocess.run(
            ['gpg', '--decrypt'],
            input=pgp_message.encode(),
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=True
        )
        return proc.stdout.decode().strip()
    except subprocess.CalledProcessError as e:
        print(f"Decryption failed: {e.stderr.decode()}")
        return None


# Decrypt all aws_console_password fields
for entry in vm_entries:
    encrypted_password = entry.get("aws_console_password")
    if encrypted_password:
        decrypted_password = decrypt_pgp(encrypted_password)
        if decrypted_password:
            entry["aws_console_password"] = decrypted_password
        else:
            print(f"Failed to decrypt password for {entry.get('instance_name')}")

# Save updated JSON with decrypted passwords
with open("outputs_decrypted.json", "w") as f:
    json.dump(data, f, indent=2)

print("Decrypted output saved in outputs_decrypted.json")