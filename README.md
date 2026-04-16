# fastqc-quality-plot

A Bash script that generates per-base sequence quality box-whisker plots from FastQC zip output using gnuplot.

---

## What It Does

Takes one or more FastQC `.zip` files as input, extracts per-base quality data, and produces a PNG box-whisker plot for each sample — styled similarly to FastQC's own quality plots (green/yellow/red quality zones, IQR boxes, median line, mean line).

---

## Requirements

- `bash`
- `unzip`
- `gnuplot` (with pngcairo terminal support)
- FastQC output zip files (`*_fastqc.zip`)

Install gnuplot on Ubuntu/Debian:

```bash
sudo apt-get install gnuplot
```

---

## Usage

```bash
chmod +x generate_quality_plot.sh
./generate_quality_plot.sh file1_fastqc.zip file2_fastqc.zip ...
```

### Example

```bash
./generate_quality_plot.sh sample1_fastqc.zip sample2_fastqc.zip
```

This will produce:
- `sample1_quality_plot.png`
- `sample2_quality_plot.png`
- `quality_plot_log_YYYYMMDD_HHMMSS.log`

---

## Output

Each PNG shows:

| Plot Element | Description |
|---|---|
| Yellow boxes | Interquartile range (Q1–Q3), whiskers at 10th–90th percentile |
| Red line | Median quality score |
| Blue dashed line | Mean quality score |
| Green background | High quality zone (Phred ≥ 28) |
| Yellow background | Acceptable quality zone (Phred 20–28) |
| Red background | Low quality zone (Phred < 20) |

Y-axis range: 0–42 (Phred scale)

---

## FastQC Data Column Reference

The script reads `Per base sequence quality` from `fastqc_data.txt`:

```
Col 1  Base position label (e.g. "1", "2-3", "75-76")
Col 2  Mean
Col 3  Median
Col 4  Lower Quartile (Q1)
Col 5  Upper Quartile (Q3)
Col 6  10th Percentile (whisker low)
Col 7  90th Percentile (whisker high)
```

---

## Error Handling

- Skips files that don't exist with a warning logged.
- Skips files where quality data cannot be extracted from the zip.
- Logs all activity with timestamps to a datestamped log file.
- Cleans up temporary `.tmp` files after each sample.

---

## Notes

- The script uses `$0` as the x-axis variable so binned positions like `75-76` plot without gaps.
- Tested with FastQC v0.11+ output format.
- Log file is created in the current working directory.
