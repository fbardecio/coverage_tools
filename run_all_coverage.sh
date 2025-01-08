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
    main_library_badge=""
    if [ -f "coverage/lcov.info" ]; then
        genhtml coverage/lcov.info -o coverage/html --quiet

        echo "[INFO] Generating badge for the main library..."
        node -e "$(cat <<'EOF'
const lcov2badge = require("lcov2badge");
const fs = require("fs");

lcov2badge.badge("./coverage/lcov.info", function (err, svgBadge) {
  if (err) throw err;

  try {
    if (fs.existsSync("./coverage_badge.svg")) {
      fs.unlinkSync("./coverage_badge.svg");
    }
  } catch (err) {
    console.error(err);
  }

  fs.writeFileSync("./coverage_badge.svg", svgBadge);
});
EOF
)"
        if [ -f "./coverage_badge.svg" ]; then
            echo "[INFO] Badge generated successfully for the main library"
            main_library_badge="<img src=\"./coverage_badge.svg\" alt=\"Main Library Coverage\">"
        else
            echo "[ERROR] Failed to generate badge for the main library"
        fi

        # Calculate coverage percentage for the main library
        total_lines=$(grep -c '^DA:' coverage/lcov.info)
        covered_lines=$(grep -c '^DA:[0-9]*,[1-9][0-9]*' coverage/lcov.info)

        if (( total_lines > 0 )); then
            total_lines_app=$((total_lines_app + total_lines))
            covered_lines_app=$((covered_lines_app + covered_lines))
        fi
    else
        echo "[ERROR] Coverage data not found for the main library!"
    fi

    # Store coverage results
    coverage_results=("Main library: $main_library_badge")

    # Iterate over packages and calculate coverage for each
    echo "[INFO] Running coverage for all packages..."
    for dir in packages/*; do
        if [ -d "$dir" ]; then
            echo "[INFO] Running tests in $dir..."

            # Navigate to the package directory
            cd "$dir" || continue

            # Run tests with coverage
            flutter test --coverage

            # Generate HTML report and badge for the package
            package_badge=""
            if [ -f "coverage/lcov.info" ]; then
                genhtml coverage/lcov.info -o coverage/html --quiet

                echo "[INFO] Generating badge for $dir..."
                node -e "$(cat <<'EOF'
const lcov2badge = require("lcov2badge");
const fs = require("fs");

lcov2badge.badge("./coverage/lcov.info", function (err, svgBadge) {
  if (err) throw err;

  try {
    if (fs.existsSync("./coverage_badge.svg")) {
      fs.unlinkSync("./coverage_badge.svg");
    }
  } catch (err) {
    console.error(err);
  }

  fs.writeFileSync("./coverage_badge.svg", svgBadge);
});
EOF
)"
                if [ -f "./coverage_badge.svg" ]; then
                    echo "[INFO] Badge generated successfully for $dir"
                    package_name=$(basename "$dir")
                    package_badge="<img src=\"packages/$package_name/coverage_badge.svg\" alt=\"$package_name Coverage\">"
                    coverage_results+=("$package_name: $package_badge")
                else
                    echo "[ERROR] Failed to generate badge for $dir"
                fi

                total_lines=$(grep -c '^DA:' coverage/lcov.info)
                covered_lines=$(grep -c '^DA:[0-9]*,[1-9][0-9]*' coverage/lcov.info)

                if (( total_lines > 0 )); then
                    total_lines_app=$((total_lines_app + total_lines))
                    covered_lines_app=$((covered_lines_app + covered_lines))
                fi
            else
                echo "[WARN] No coverage data found for $dir"
            fi

            # Return to the root directory
            cd - > /dev/null || exit
        fi
    done

    # Calculate total coverage percentage for the app
    if (( total_lines_app > 0 )); then
        total_coverage=$(awk "BEGIN {printf \"%.2f\", ($covered_lines_app / $total_lines_app) * 100}")
    else
        total_coverage="N/A"
    fi

    # Print all coverage results
    echo "[INFO] Coverage Summary:"
    for result in "${coverage_results[@]}"; do
        echo "$result"
    done

    # Update README.md with the coverage results
new_content=$(printf "%s\n" "${coverage_results[@]}")

# Escape newlines in the new_content
escaped_new_content=$(echo "$new_content" | awk '{printf "%s\\n", $0}')

awk -v new_content="$escaped_new_content" '
    BEGIN {output = 1}
    /<!-- coverage:ignore -->/ {print $0; print new_content; output = 0}
    /^$/ {if (output == 0) output = 1}
    output
' README.md > README.tmp && mv README.tmp README.md

    # Open the main library report in a browser
    if [ -f "coverage/html/index.html" ]; then
        echo "[INFO] Opening main library coverage report..."
        open coverage/html/index.html
    else
        echo "[ERROR] Main library coverage report not found!"
    fi