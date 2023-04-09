#!/bin/env sh

# Check if input file is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 input_file.md"
    exit 1
fi

# Check if input file exists
if [ ! -f "$1" ]; then
    echo "Input file not found: $1"
    exit 1
fi

# Set output file name
input_file="$1"
output_file="${input_file%.md}.org"

# Function to convert date string to org-mode format
convert_date() {
    local input_date="$1"
    local output_date

    if date --version >/dev/null 2>&1; then
        # GNU date command (Linux)
        output_date=$(date -d "$input_date" +"[%Y-%m-%d %a %H:%M]")
    else
        # BSD date command (macOS)
        output_date=$(date -j -f "%d %B %Y %I:%M:%S %p" "$input_date" +"[%Y-%m-%d %a %H:%M]")
    fi

    echo "$output_date"
}

# Start the conversion process
{
    line_number=1

    while IFS= read -r line; do
        if [[ $line_number -eq 1 ]]; then
            # First line (title with "#+title:")
            echo "#+title:${line#\#}"
        elif [[ $line_number -eq 2 ]]; then
            # Second line (author with "#+author:" and without "#")
            echo "#+author:${line//[#]/}"
        else
            case "$line" in
                \#\ *)
                    echo "*${line#\#}"
                    ;;
                \#\#\ *)
                    echo "*${line#\#\#}"
                    ;;
                \#\#\#\ *)
                    # Check for a date after the "@"
                    if [[ "$line" =~ @\ (.*) ]]; then
                        # Extract the date and reformat it for org-mode
                        org_date=$(convert_date "${BASH_REMATCH[1]}")
                        # Replace the date in the line
                        line="${line/@ ${BASH_REMATCH[1]}/$org_date}"
                    fi
                    echo "**${line#\#\#\#}"
                    ;;
                *)
                    echo "$line"
                    ;;
            esac
        fi

        ((line_number++))
    done
} < "$input_file" > "$output_file"

echo "Conversion complete. Output file: $output_file"
