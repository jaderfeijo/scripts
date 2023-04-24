#!/bin/bash

if [ "$#" -lt 3 ]; then
	 echo "Usage: $0 output_dmg_file volume_name file1 [file2 file3 ...]"
	 exit 1
fi

output_dmg_file="$1"
volume_name="$2"
shift 2

temp_dir=$(mktemp -d)

for input_file in "$@"; do
	 cp "$input_file" "$temp_dir/"
done

# Prompt the user for the encryption password
echo -n "Enter the encryption password: "
read -s encryption_password
echo

# Create a compressed and encrypted DMG file
hdiutil create -srcfolder "$temp_dir" -volname "$volume_name" -encryption AES-256 -fs HFS+ -fsargs "-c c=64,a=16,e=16" -format UDBZ -imagekey zlib-level=9 -passphrase "$encryption_password" "$output_dmg_file"

# Clean up temporary directory
rm -rf "$temp_dir"