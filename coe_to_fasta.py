import os
import sys

def coe_to_fasta(coe_file, fasta_file):
    if not os.path.exists(coe_file):
        raise FileNotFoundError(f"Input COE file not found: {coe_file}")

    try:
        with open(coe_file, 'r', encoding='utf-8') as f:
            lines = f.readlines()
    except OSError as e:
        raise OSError(f"Failed to open/read input file '{coe_file}': {e}") from e

    # Find the line with hex values
    data_line = ''
    for line in lines:
        if line.startswith('memory_initialization'):
            continue
        if line.strip().endswith(';'):
            data_line = line.strip()[:-1]  # Remove semicolon
            break

    if not data_line:
        raise ValueError("No valid data found in COE file")

    # Convert hex values back to characters
    hex_values = data_line.split(',')
    sequence = ''
    
    try:
        for hex_val in hex_values:
            char = chr(int(hex_val, 16))
            sequence += char
    except ValueError as e:
        raise ValueError(f"Invalid hex value in COE file: {e}") from e

    try:
        with open(fasta_file, 'w', encoding='utf-8') as f:
            f.write(sequence)
            
        # Print file size after generation    
        print(f"Generated file size: {os.path.getsize(fasta_file)} bytes")
            
    except OSError as e:
        raise OSError(f"Failed to write output file '{fasta_file}': {e}") from e

    return True

if __name__ == '__main__':
    try:
        coe_to_fasta('tesst.coe', 'output.fasta')
    except Exception as e:
        print(f"Failed to generate FASTA file: {e}")
        sys.exit(1)
    else:
        print("FASTA file generated: output.fasta")
