#!/bin/bash
# run_lwk_analysis.sh
# Run PLINK IBD + KING on the LWK (Luhya) 1000 Genomes dataset
# Data is pre-processed into PLINK binary format — no VCF conversion needed
set -e

DATA_DIR=~/public/ps2/ibd
RESULTS_DIR=~/cse284-relative-finding/results
KING=~/king
LWK_BFILE=$DATA_DIR/ps2_ibd.lwk     # shared prefix for .bed/.bim/.fam

mkdir -p $RESULTS_DIR

echo "=== Step 1: Check data dimensions ==="
echo "Samples (.fam):"
wc -l $LWK_BFILE.fam
echo "Variants (.bim):"
wc -l $LWK_BFILE.bim
echo ""

echo "=== Step 2: Run PLINK --genome (IBD) on LWK data ==="
echo "Timing PLINK..."
START=$(date +%s)
plink --bfile $LWK_BFILE \
      --genome \
      --min 0.1 \
      --out $RESULTS_DIR/lwk.ibd
END=$(date +%s)
PLINK_TIME=$((END-START))
echo "PLINK took $PLINK_TIME seconds"
echo ""

echo "=== Step 3: Run KING --related on LWK data ==="
echo "Timing KING --related..."
START=$(date +%s)
$KING -b $LWK_BFILE.bed \
      --related --degree 2 \
      --prefix $RESULTS_DIR/lwk_king_related
END=$(date +%s)
KING_RELATED_TIME=$((END-START))
echo "KING --related took $KING_RELATED_TIME seconds"
echo ""

echo "=== Step 4: Run KING --ibdseg on LWK data ==="
echo "Timing KING --ibdseg..."
START=$(date +%s)
$KING -b $LWK_BFILE.bed \
      --ibdseg \
      --prefix $RESULTS_DIR/lwk_king_ibdseg
END=$(date +%s)
KING_IBDSEG_TIME=$((END-START))
echo "KING --ibdseg took $KING_IBDSEG_TIME seconds"
echo ""

echo "=== Step 5: Check outputs ==="
echo "--- PLINK IBD output ---"
wc -l $RESULTS_DIR/lwk.ibd.genome 2>/dev/null || echo "  No output file"
echo "Top hits (PI_HAT sorted):"
# Print header + top 10 rows sorted by PI_HAT descending (col 10)
awk 'NR==1 || NR>1' $RESULTS_DIR/lwk.ibd.genome 2>/dev/null \
  | sort -k10 -rn \
  | head -11 \
  || true
echo ""

echo "--- KING --related output ---"
ls -la $RESULTS_DIR/lwk_king_related* 2>/dev/null || echo "  No output files"
echo "Close relatives (degree <= 2):"
head -20 $RESULTS_DIR/lwk_king_related.kin0 2>/dev/null || true
echo ""

echo "--- KING --ibdseg output ---"
ls -la $RESULTS_DIR/lwk_king_ibdseg* 2>/dev/null || echo "  No output files"
head -10 $RESULTS_DIR/lwk_king_ibdseg.seg 2>/dev/null || true
echo ""

echo ""
echo "=== RUNTIME SUMMARY ==="
echo "PLINK --genome:  $PLINK_TIME seconds"
echo "KING --related:  $KING_RELATED_TIME seconds"
echo "KING --ibdseg:   $KING_IBDSEG_TIME seconds"
echo ""
echo "Data: 1000 Genomes Phase 3, LWK population (ps2 preprocessed)"