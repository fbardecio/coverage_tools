echo "[INFO] Running coverage for the main library..."

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "[ERROR] Node.js is not installed. Please install Node.js to proceed."
    exit 1
fi

# Detect platform (macOS or Linux)
case "$(uname)" in
    Darwin) sed_command="sed -i ''";;  # macOS
    *) sed_command="sed -i";;          # Linux
esac

# Initialize variables for total coverage calculation
total_lines_app=0
covered_lines_app=0

# Run tests for the main library with coverage
flutter test --coverage

# Generate HTML report and badge for the main library
coverage_results=()
if [ -f "coverage/lcov.info" ]; then
    genhtml coverage/lcov.info -o coverage/html --quiet

    echo "[INFO] Generating badge for the main library..."
    node -e "$(cat <<'EOF'
const lcov2badge = require("lcov2badge");
const fs = require("fs");

lcov2badge.badge("./coverage/lcov.info", function (err, svgBadge) {
  if (err) throw err;
  fs.writeFileSync("./coverage_badge.svg", svgBadge);
});
EOF
)"
    if [ -f "./coverage_badge.svg" ]; then
        echo "[INFO] Badge generated successfully for the main library"
        coverage_results+=("Main library: <img src=\"./coverage_badge.svg\" alt=\"Main Library Coverage\">")
    else
        echo "[ERROR] Failed to generate badge for the main library"
    fi

    total_lines=$(grep -c '^DA:' coverage/lcov.info)
    covered_lines=$(grep -c '^DA:[0-9]*,[1-9][0-9]*' coverage/lcov.info)

    if (( total_lines > 0 )); then
        total_lines_app=$((total_lines_app + total_lines))
        covered_lines_app=$((covered_lines_app + covered_lines))
    fi
else
    echo "[ERROR] Coverage data not found for the main library!"
fi

# Iterate over packages and calculate coverage for each
echo "[INFO] Running coverage for all packages..."
for dir in packages/*; do
    if [ -d "$dir" ]; then
        package_name=$(basename "$dir")
        echo "[INFO] Running tests in $package_name..."

        cd "$dir" || continue
        flutter test --coverage

        if [ -f "coverage/lcov.info" ]; then
            genhtml coverage/lcov.info -o coverage/html --quiet

            echo "[INFO] Generating badge for $package_name..."
            node -e "$(cat <<'EOF'
const lcov2badge = require("lcov2badge");
const fs = require("fs");

lcov2badge.badge("./coverage/lcov.info", function (err, svgBadge) {
  if (err) throw err;
  fs.writeFileSync("./coverage_badge.svg", svgBadge);
});
EOF
)"
            if [ -f "./coverage_badge.svg" ]; then
                echo "[INFO] Badge generated successfully for $package_name"
                coverage_results+=("$package_name: <img src=\"packages/$package_name/coverage_badge.svg\" alt=\"$package_name Coverage\">")
            else
                echo "[ERROR] Failed to generate badge for $package_name"
            fi

            total_lines=$(grep -c '^DA:' coverage/lcov.info)
            covered_lines=$(grep -c '^DA:[0-9]*,[1-9][0-9]*' coverage/lcov.info)

            if (( total_lines > 0 )); then
                total_lines_app=$((total_lines_app + total_lines))
                covered_lines_app=$((covered_lines_app + covered_lines))
            fi
        else
            echo "[WARN] No coverage data found for $package_name"
        fi

        cd - > /dev/null || exit
    fi
done

# Calculate total and total coverage
if (( total_lines_app > 0 )); then
    total_coverage=$(awk "BEGIN {printf \"%.2f\", ($covered_lines_app / $total_lines_app) * 100}")
else
    total_coverage="0.00"
fi

# Generate badge for the total coverage
echo "[INFO] Generating badge for total coverage..."
node -e "
const fs = require('fs');

const totalCoverage = process.argv[1];

// Define the SVG template with the increased width and adjusted percentage portion
const badgeTemplate = \`
<svg xmlns='http://www.w3.org/2000/svg' width='110' height='18'>>
  <linearGradient id='smooth' x2='0' y2='100%'>
    <stop offset='0' stop-color='#fff' stop-opacity='.7'/>
    <stop offset='.1' stop-color='#aaa' stop-opacity='.1'/>
    <stop offset='.9' stop-color='#000' stop-opacity='.3'/>
    <stop offset='1' stop-color='#000' stop-opacity='.5'/>
  </linearGradient>
  <rect rx='4' width='110' height='18' fill='#555'/> 
  <rect rx='4' x='63' width='47' height='18' fill='\${parseFloat(totalCoverage) > 0 ? '#11b0cc' : '#9f9f9f'}'/> 
  <rect x='63' width='4' height='18' fill='\${parseFloat(totalCoverage) > 0 ? '#11b0cc' : '#9f9f9f'}'/>  
  <rect rx='4' width='110' height='18' fill='url(#smooth)'/> 
  <g fill='#fff' text-anchor='middle' font-family='DejaVu Sans,Verdana,Geneva,sans-serif' font-size='11'>
    <text x='32' y='14' fill='#010101' fill-opacity='.3'>coverage</text> 
    <text x='32' y='13'>coverage</text>
    <text x='88' y='14' fill='#010101' fill-opacity='.3'>\${totalCoverage}%</text>
    <text x='88' y='13'>\${totalCoverage}%</text>
  </g>
</svg>
\`;

fs.writeFileSync('./total_coverage_badge.svg', badgeTemplate);
" "$total_coverage"

if [ -f "./total_coverage_badge.svg" ]; then
    echo "[INFO] Badge generated successfully for total coverage"
    coverage_results+=("Total coverage: <img src=\"./total_coverage_badge.svg\" alt=\"total Coverage\">")
else
    echo "[ERROR] Failed to generate badge for total coverage"
fi

# Print all coverage results
echo "[INFO] Coverage Summary:"
for result in "${coverage_results[@]}"; do
    echo "$result"
done
echo "Total Coverage: $total_coverage%"

# Update README.md: Replace existing coverage section properly
temp_file=$(mktemp)
found_marker=false
in_coverage_block=false

while IFS= read -r line; do
    if [[ "$line" == "<!-- coverage:ignore -->" ]]; then
        echo "$line" >> "$temp_file"
        found_marker=true
        in_coverage_block=true

        # Insert new coverage results
        for result in "${coverage_results[@]}"; do
            echo "$result" >> "$temp_file"
        done

        continue
    fi

    if [[ "$line" == "<!-- end-coverage:ignore -->" ]]; then
        in_coverage_block=false
    fi

    # Only write lines that are outside of the coverage block
    if [[ "$in_coverage_block" == false ]]; then
        echo "$line" >> "$temp_file"
    fi
done < README.md

# Replace README with the updated content
mv "$temp_file" README.md

# Open the main library report in a browser
if [ -f "coverage/html/index.html" ]; then
    echo "[INFO] Opening main library coverage report..."
    open coverage/html/index.html
else
    echo "[ERROR] Main library coverage report not found!"
fi
