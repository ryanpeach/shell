#!/bin/bash

# Define the Dockerfile
DOCKERFILE="Dockerfile"

# Extract the sorted and to sort sections
before_sorted_section=$(sed -n '1,/# =\+ Sorted =\+/p' "$DOCKERFILE" | sed '$d')
echo "================================================================================"
echo "before_sorted_section"
echo "$before_sorted_section"

sorted_section=$(sed -n '/# =\+ Sorted =\+/,/# =\+ END: Sorted =\+/p' "$DOCKERFILE")
echo "================================================================================"
echo "sorted_section"
echo "$sorted_section"

to_sort_section=$(sed -n '/# =\+ To Sort =\+/,/# =\+ END: To Sort =\+/p' "$DOCKERFILE")
echo "================================================================================"
echo "to_sort_section"
echo "$to_sort_section"

after_to_sort_section=$(sed -n '/# =\+ END: To Sort =\+/,$p' "$DOCKERFILE" | sed '1d')
echo "================================================================================"
echo "after_to_sort_section"
echo "$after_to_sort_section"

# Cut off first and last line of each section
sorted_section=$(echo "$sorted_section" | sed '1d;$d')
echo "================================================================================"
echo "sorted_section"
echo "$sorted_section"
to_sort_section=$(echo "$to_sort_section" | sed '1d;$d')
echo "================================================================================"
echo "to_sort_section"
echo "$to_sort_section"

# Combine the sorted and to sort sections, extract only the lines with "RUN emerge", and sort them
combined_sorted_section=$(echo -e "$sorted_section\n$to_sort_section" | sort | sed '/^\s*$/d')
echo "================================================================================"
echo "combined_sorted_section"
echo "$combined_sorted_section"

# If the combined section is empty, print a warning and exit
if [ -z "$combined_sorted_section" ]; then
    echo "Warning: No emerge commands found to sort."
    exit 1
fi

echo "$before_sorted_section" > "$DOCKERFILE"
echo "" >> "$DOCKERFILE"
echo "# ======= Sorted ========" >> "$DOCKERFILE"
echo "$combined_sorted_section" >> "$DOCKERFILE"
echo "# ======= END: Sorted ========" >> "$DOCKERFILE"
echo "" >> "$DOCKERFILE"
echo "# ======= To Sort =========" >> "$DOCKERFILE"
echo "" >> "$DOCKERFILE"
echo "# ======= END: To Sort =========" >> "$DOCKERFILE"
echo "$after_to_sort_section" >> "$DOCKERFILE"
