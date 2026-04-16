#!/bin/bash

# ============================================================
# generate_quality_plot.sh
# Generates per-base sequence quality box-whisker plots
# from FastQC zip files using gnuplot.
#
# Usage: ./generate_quality_plot.sh file1_fastqc.zip file2_fastqc.zip ...
# ============================================================

LOGFILE="quality_plot_log_$(date +%Y%m%d_%H%M%S).log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOGFILE"
}

# ── Input validation ──────────────────────────────────────
if [ $# -eq 0 ]; then
    log "Error: No files specified."
    log "Usage: $0 file1_fastqc.zip file2_fastqc.zip ..."
    exit 1
fi

log "Script started. Processing $# file(s)."

# ── Main loop ─────────────────────────────────────────────
for ZIP_FILE in "$@"; do

    # Check file exists
    if [ ! -f "$ZIP_FILE" ]; then
        log "Warning: File '$ZIP_FILE' not found. Skipping..."
        continue
    fi

    # Derive sample name and output filenames
    BASENAME=$(basename "$ZIP_FILE" | sed 's/_fastqc\.zip//; s/\.zip//')
    TEMP_DATA="${BASENAME}_temp.tmp"
    OUTPUT_IMG="${BASENAME}_quality_plot.png"

    log "Processing: $ZIP_FILE"

    # ── Step 1: Extract quality data from zip ────────────
    unzip -p "$ZIP_FILE" "*/fastqc_data.txt" | \
        awk '/^>>Per base sequence quality/,/^>>END_MODULE/' | \
        grep -v ">>" | \
        grep -v "#" > "$TEMP_DATA"

    # ── Step 2: Validate extracted data ──────────────────
    if [ ! -s "$TEMP_DATA" ]; then
        log "Error: Could not extract quality data from '$ZIP_FILE'. Skipping..."
        rm -f "$TEMP_DATA"
        continue
    fi

    log "Data extracted successfully. Generating plot..."

    # ── Step 3: Generate plot with gnuplot ────────────────
    # FastQC column layout:
    #   Col 1: Base position label (e.g. "1", "2-3", "10-14")
    #   Col 2: Mean
    #   Col 3: Median
    #   Col 4: Lower Quartile (Q1)
    #   Col 5: Upper Quartile (Q3)
    #   Col 6: 10th Percentile (whisker low)
    #   Col 7: 90th Percentile (whisker high)

    gnuplot <<EOF
        set terminal pngcairo size 1200,600 enhanced font 'Arial,10'
        set output '${OUTPUT_IMG}'

        set title "Per-base Sequence Quality: ${BASENAME}" font 'Arial,12'
        set xlabel "Base Position"
        set ylabel "Quality Score (Phred)"
        set yrange [0:42]
        set xtics rotate by -45 scale 0.5 font ",8"
        set ytics 0,5,42
        set grid ytics lc rgb "#cccccc" lw 1 lt 0
        set border 3
        set tics nomirror
        set offsets 1, 1, 0, 0
        set key top right

        # Quality color zones (FastQC style: green/yellow/red)
        set object 1 rect from graph 0, first 28 to graph 1, first 42 \
            fc rgb "#e0ffe0" fs solid 1.0 noborder behind
        set object 2 rect from graph 0, first 20 to graph 1, first 28 \
            fc rgb "#fffac8" fs solid 1.0 noborder behind
        set object 3 rect from graph 0, first 0  to graph 1, first 20 \
            fc rgb "#ffe0e0" fs solid 1.0 noborder behind

        set boxwidth 0.8
        set style fill solid 0.9 border lc rgb "black"

        # Plot:
        #   1. Candlestick boxes  — Q1 to Q3 (yellow), whiskers at 10th–90th percentile
        #   2. Median line        — Col 3 (red, bold)
        #   3. Mean line          — Col 2 (blue, dashed)
        #
        # (\$0) is used as x so bins like "75-76" plot without gaps
        plot '${TEMP_DATA}' \
            using (\$0):4:6:7:5:xticlabels(1) \
            with candlesticks lt rgb "yellow" lw 1 title 'IQR (10th–90th)' whiskerbars, \
            '' using (\$0):3:3:3:3 \
            with candlesticks lt rgb "red" lw 2.5 title 'Median', \
            '' using (\$0):2 \
            with lines lt rgb "blue" lw 1.5 dt 2 title 'Mean'
EOF

    # ── Step 4: Confirm output and clean up ───────────────
    if [ -f "$OUTPUT_IMG" ]; then
        log "Plot saved: $OUTPUT_IMG"
    else
        log "Error: Plot generation failed for $BASENAME."
    fi

    rm -f "$TEMP_DATA"
    log "Finished: $BASENAME."
    echo "---"

done

log "All files processed. Log saved to: $LOGFILE"
