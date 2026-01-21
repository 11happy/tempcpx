#!/bin/bash
# CPX vs CP Benchmark - Multiple Real GitHub Repositories
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

BENCH_DIR="$HOME/cpx_multi_bench"
REPOS_DIR="$BENCH_DIR/repos"
CPX_PATH="$HOME/cpx/cpx"  # Full path to cpx

echo -e "${GREEN}=== CPX vs GNU cp — Multiple Real Repositories ===${NC}"
echo ""

# Check if cpx exists
if [ ! -x "$CPX_PATH" ]; then
    echo -e "${RED}Error: cpx not found at $CPX_PATH${NC}"
    exit 1
fi

# Check hyperfine
if ! command -v hyperfine &> /dev/null; then
    echo -e "${RED}Error: hyperfine not found. Install with: cargo install hyperfine${NC}"
    exit 1
fi

echo "Benchmark dir: $BENCH_DIR"
echo "CPU cores: $(nproc)"
echo ""

rm -rf "$BENCH_DIR"
mkdir -p "$REPOS_DIR"

# ----------------------------------------------------------------------------
# REPOSITORY LIST (Choose your size preference)
# ----------------------------------------------------------------------------

# OPTION 1: Small-Medium repos (~5-8 GB total, ~15-20 min)
# declare -A REPOS=(
#     ["react"]="https://github.com/facebook/react.git"
#     ["vue"]="https://github.com/vuejs/vue.git"
#     ["express"]="https://github.com/expressjs/express.git"
#     ["django"]="https://github.com/django/django.git"
#     ["flask"]="https://github.com/pallets/flask.git"
#     ["axios"]="https://github.com/axios/axios.git"
#     ["prettier"]="https://github.com/prettier/prettier.git"
#     ["webpack"]="https://github.com/webpack/webpack.git"
# )

# OPTION 2: Uncomment for larger repos (~15-25 GB total, ~45-60 min)
# declare -A REPOS=(
#     ["react"]="https://github.com/facebook/react.git"
#     ["vue"]="https://github.com/vuejs/vue.git"
#     ["tensorflow"]="https://github.com/tensorflow/tensorflow.git"
#     ["vscode"]="https://github.com/microsoft/vscode.git"
#     ["kubernetes"]="https://github.com/kubernetes/kubernetes.git"
#     ["django"]="https://github.com/django/django.git"
#     ["rust"]="https://github.com/rust-lang/rust.git"
#     ["node"]="https://github.com/nodejs/node.git"
# )

# OPTION 3: Uncomment for massive repos (~40+ GB total, 2+ hours)
declare -A REPOS=(
    ["linux"]="https://github.com/torvalds/linux.git"
    ["tensorflow"]="https://github.com/tensorflow/tensorflow.git"
    ["rust"]="https://github.com/rust-lang/rust.git"
    ["kubernetes"]="https://github.com/kubernetes/kubernetes.git"
    ["vscode"]="https://github.com/microsoft/vscode.git"
    ["node"]="https://github.com/nodejs/node.git"
    ["go"]="https://github.com/golang/go.git"
    ["chromium"]="https://github.com/chromium/chromium.git"
)

# ----------------------------------------------------------------------------
# CLONE REPOSITORIES
# ----------------------------------------------------------------------------
echo -e "${YELLOW}Cloning ${#REPOS[@]} repositories...${NC}"
echo ""

cd "$REPOS_DIR"

for name in "${!REPOS[@]}"; do
    url="${REPOS[$name]}"
    echo -e "${BLUE}Cloning $name...${NC}"
    if git clone --depth 1 "$url" "$name" 2>/dev/null; then
        size=$(du -sh "$name" | cut -f1)
        files=$(find "$name" -type f | wc -l)
        echo -e "${GREEN}✓ $name: $size ($files files)${NC}"
    else
        echo -e "${RED}✗ Failed to clone $name${NC}"
    fi
    echo ""
done

echo -e "${GREEN}Repository cloning complete!${NC}"
echo ""

# Show total dataset statistics
echo -e "${YELLOW}Dataset Statistics:${NC}"
total_size=$(du -sh "$REPOS_DIR" | cut -f1)
total_files=$(find "$REPOS_DIR" -type f | wc -l)
total_dirs=$(find "$REPOS_DIR" -type d | wc -l)
echo "Total size: $total_size"
echo "Total files: $total_files"
echo "Total directories: $total_dirs"
echo ""

# ----------------------------------------------------------------------------
# INDIVIDUAL REPOSITORY BENCHMARKS
# ----------------------------------------------------------------------------
echo -e "${YELLOW}Running individual repository benchmarks...${NC}"
echo ""

for name in "${!REPOS[@]}"; do
    if [ -d "$REPOS_DIR/$name" ]; then
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${BLUE}Benchmarking: $name${NC}"
        repo_size=$(du -sh "$REPOS_DIR/$name" | cut -f1)
        file_count=$(find "$REPOS_DIR/$name" -type f | wc -l)
        echo "Size: $repo_size | Files: $file_count"
        echo ""

        hyperfine \
          --warmup 0 \
          --runs 3 \
          --prepare "rm -rf $BENCH_DIR/dest_cp $BENCH_DIR/dest_cpx; sync" \
          --export-markdown "$BENCH_DIR/${name}_benchmark.md" \
          --export-json "$BENCH_DIR/${name}_benchmark.json" \
          "$CPX_PATH -r -j=16 $REPOS_DIR/$name $BENCH_DIR/dest_cpx" \
          "cp -r $REPOS_DIR/$name $BENCH_DIR/dest_cp"

        echo ""
    fi
done

# ----------------------------------------------------------------------------
# FULL DATASET BENCHMARK
# ----------------------------------------------------------------------------
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}Running FULL dataset benchmark (all repos at once)...${NC}"
echo "This will copy $total_size across $total_files files"
echo ""

hyperfine \
  --warmup 0 \
  --runs 3 \
  --prepare "rm -rf $BENCH_DIR/dest_cp $BENCH_DIR/dest_cpx; sync" \
  --export-markdown "$BENCH_DIR/full_dataset_benchmark.md" \
  --export-json "$BENCH_DIR/full_dataset_benchmark.json" \
  "$CPX_PATH -r -j=16 $REPOS_DIR $BENCH_DIR/dest_cpx" \
  "cp -r $REPOS_DIR $BENCH_DIR/dest_cp"

echo ""
echo -e "${GREEN}All benchmarks complete!${NC}"
echo ""

# ----------------------------------------------------------------------------
# GENERATE SUMMARY REPORT
# ----------------------------------------------------------------------------
echo -e "${YELLOW}Generating summary report...${NC}"

cat > "$BENCH_DIR/SUMMARY.md" << EOF
# CPX vs GNU cp - Real-World Benchmark Results

## Test Environment
- **CPU Cores:** $(nproc)
- **Date:** $(date)
- **cp Version:** $(cp --version | head -n1)
- **System:** $(uname -s) $(uname -r)

## Dataset Overview
- **Total Size:** $total_size
- **Total Files:** $total_files
- **Total Directories:** $total_dirs
- **Repositories Tested:** ${#REPOS[@]}

## Repositories

EOF

for name in "${!REPOS[@]}"; do
    if [ -d "$REPOS_DIR/$name" ]; then
        repo_size=$(du -sh "$REPOS_DIR/$name" | cut -f1)
        file_count=$(find "$REPOS_DIR/$name" -type f | wc -l)
        echo "- **$name:** $repo_size ($file_count files)" >> "$BENCH_DIR/SUMMARY.md"
    fi
done

echo "" >> "$BENCH_DIR/SUMMARY.md"
echo "---" >> "$BENCH_DIR/SUMMARY.md"
echo "" >> "$BENCH_DIR/SUMMARY.md"

# Add individual benchmark results
echo "## Individual Repository Results" >> "$BENCH_DIR/SUMMARY.md"
echo "" >> "$BENCH_DIR/SUMMARY.md"

for name in "${!REPOS[@]}"; do
    if [ -f "$BENCH_DIR/${name}_benchmark.md" ]; then
        echo "### $name" >> "$BENCH_DIR/SUMMARY.md"
        echo "" >> "$BENCH_DIR/SUMMARY.md"
        cat "$BENCH_DIR/${name}_benchmark.md" >> "$BENCH_DIR/SUMMARY.md"
        echo "" >> "$BENCH_DIR/SUMMARY.md"
    fi
done

# Add full dataset results
echo "---" >> "$BENCH_DIR/SUMMARY.md"
echo "" >> "$BENCH_DIR/SUMMARY.md"
echo "## Full Dataset Results (All Repos Combined)" >> "$BENCH_DIR/SUMMARY.md"
echo "" >> "$BENCH_DIR/SUMMARY.md"

if [ -f "$BENCH_DIR/full_dataset_benchmark.md" ]; then
    cat "$BENCH_DIR/full_dataset_benchmark.md" >> "$BENCH_DIR/SUMMARY.md"
fi

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Summary report: $BENCH_DIR/SUMMARY.md${NC}"
echo -e "${GREEN}All results: $BENCH_DIR${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Show quick preview of full dataset results
if [ -f "$BENCH_DIR/full_dataset_benchmark.md" ]; then
    echo -e "${YELLOW}Quick Preview - Full Dataset:${NC}"
    cat "$BENCH_DIR/full_dataset_benchmark.md"
    echo ""
fi

# ----------------------------------------------------------------------------
# CLEANUP PROMPT
# ----------------------------------------------------------------------------
read -p "Delete benchmark data (~$total_size × 3 copies)? (Y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    rm -rf "$BENCH_DIR"
    echo -e "${GREEN}Cleaned up benchmark data${NC}"
else
    echo -e "${YELLOW}Benchmark data preserved at: $BENCH_DIR${NC}"
    echo -e "${YELLOW}View results: cat $BENCH_DIR/SUMMARY.md${NC}"
fi

echo ""
echo -e "${GREEN}Done!${NC}"
