# FASTA to COE Converter

This project provides a Python script to convert DNA sequence files in FASTA format into COE (Coefficient) files for memory initialization in FPGA designs.

## Files

- `fasta_to_coe.py` – Converts a FASTA file to a COE file.
- `another_file.py` – [Brief description of what this file does.]

## Usage

1. Place your input FASTA file (e.g., `input.fasta`) in the project directory.
2. Run the script:

   ```bash
   python fasta_to_coe.py
   ```

3. The output COE file (e.g., `tesst.coe`) will be generated in the same directory.

## Requirements

- Python 3.1

## Example

Input FASTA:
```
>Example
ACGT
```

Output COE:
```
memory_initialization_radix=16;
memory_initialization_vector=
3E,41,43,47,54;
```
