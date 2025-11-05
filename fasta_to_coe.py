import os
import sys

def fasta_to_coe(fasta_file, coe_file):
    if not os.path.exists(fasta_file):
        raise FileNotFoundError(f"Input FASTA file not found: {fasta_file}")

    try:
        with open(fasta_file, 'r', encoding='utf-8') as f:
            lines = f.readlines()
    except OSError as e:
        raise OSError(f"Failed to open/read input file '{fasta_file}': {e}") from e

    hex_values = []  # collect all hex values

    for line in lines:
        line = line.strip()
        if not line:
            continue

        if line.startswith('>'):
            # Write '>' as hex
            hex_values.append(format(ord('>'), '02X'))
        else:
            # Convert sequence characters to hex
            for char in line:
                hex_values.append(format(ord(char), '02X'))

    # Join everything in one line, end with semicolon
    data = ','.join(hex_values) + ';'

    try:
        with open(coe_file, 'w', encoding='utf-8') as f:
            f.write("memory_initialization_radix=16;\n")
            f.write("memory_initialization_vector=\n")
            f.write(data)
            
        # Print file size after generation
        print(f"Generated file size: {os.path.getsize(coe_file)} bytes")
            
    except OSError as e:
        raise OSError(f"Failed to write output file '{coe_file}': {e}") from e

    return True

if __name__ == '__main__':
    try:
        fasta_to_coe('input.fasta', 'tesst.coe')
    except Exception as e:
        print(f"Failed to generate COE file: {e}")
        sys.exit(1)
    else:
        print("COE file generated: tesst.coe")