#!/usr/bin/env python3
"""
MiniWeather HPC - Results Plotting Script
Generates scaling and performance plots from CSV results.
"""

import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import os
import sys
from pathlib import Path

# Output settings
plt.style.use('seaborn-v0_8-whitegrid')
RESULTS_DIR = Path(__file__).parent.parent / "results"
FIGSIZE = (10, 6)
DPI = 150


def plot_strong_scaling(csv_path: str, output_dir: Path):
    """Plot strong scaling results."""
    df = pd.read_csv(csv_path)
    
    fig, axes = plt.subplots(1, 3, figsize=(15, 5))
    
    # 1. Time vs Ranks
    ax = axes[0]
    ax.plot(df['total_ranks'], df['time_s'], 'o-', linewidth=2, markersize=8)
    ax.set_xlabel('MPI Ranks')
    ax.set_ylabel('Time (s)')
    ax.set_title('Strong Scaling: Execution Time')
    ax.set_xscale('log', base=2)
    ax.set_yscale('log')
    ax.grid(True, alpha=0.3)
    
    # 2. Speedup
    ax = axes[1]
    t_base = df['time_s'].iloc[0]
    speedup = t_base / df['time_s']
    ideal_speedup = df['total_ranks']
    
    ax.plot(df['total_ranks'], speedup, 'o-', linewidth=2, markersize=8, label='Measured')
    ax.plot(df['total_ranks'], ideal_speedup, '--', color='gray', label='Ideal')
    ax.set_xlabel('MPI Ranks')
    ax.set_ylabel('Speedup')
    ax.set_title('Strong Scaling: Speedup')
    ax.set_xscale('log', base=2)
    ax.legend()
    ax.grid(True, alpha=0.3)
    
    # 3. Efficiency
    ax = axes[2]
    efficiency = speedup / df['total_ranks'] * 100
    ax.bar(range(len(df)), efficiency, tick_label=df['total_ranks'])
    ax.axhline(y=100, color='gray', linestyle='--', label='Ideal')
    ax.set_xlabel('MPI Ranks')
    ax.set_ylabel('Parallel Efficiency (%)')
    ax.set_title('Strong Scaling: Efficiency')
    ax.set_ylim(0, 120)
    ax.grid(True, alpha=0.3)
    
    plt.tight_layout()
    output_path = output_dir / 'strong_scaling.png'
    plt.savefig(output_path, dpi=DPI, bbox_inches='tight')
    plt.close()
    print(f"Saved: {output_path}")


def plot_weak_scaling(csv_path: str, output_dir: Path):
    """Plot weak scaling results."""
    df = pd.read_csv(csv_path)
    
    fig, axes = plt.subplots(1, 2, figsize=(12, 5))
    
    # 1. Time vs Ranks (should be constant ideally)
    ax = axes[0]
    ax.plot(df['total_ranks'], df['time_s'], 'o-', linewidth=2, markersize=8)
    ax.axhline(y=df['time_s'].iloc[0], color='gray', linestyle='--', label='Ideal')
    ax.set_xlabel('MPI Ranks')
    ax.set_ylabel('Time (s)')
    ax.set_title('Weak Scaling: Execution Time')
    ax.set_xscale('log', base=2)
    ax.legend()
    ax.grid(True, alpha=0.3)
    
    # 2. Efficiency
    ax = axes[1]
    t_base = df['time_s'].iloc[0]
    efficiency = t_base / df['time_s'] * 100
    ax.bar(range(len(df)), efficiency, tick_label=df['total_ranks'])
    ax.axhline(y=100, color='gray', linestyle='--', label='Ideal')
    ax.set_xlabel('MPI Ranks')
    ax.set_ylabel('Weak Scaling Efficiency (%)')
    ax.set_title('Weak Scaling: Efficiency')
    ax.set_ylim(0, 120)
    ax.grid(True, alpha=0.3)
    
    plt.tight_layout()
    output_path = output_dir / 'weak_scaling.png'
    plt.savefig(output_path, dpi=DPI, bbox_inches='tight')
    plt.close()
    print(f"Saved: {output_path}")


def plot_throughput(csv_path: str, output_dir: Path):
    """Plot GLUPS throughput."""
    df = pd.read_csv(csv_path)
    
    fig, ax = plt.subplots(figsize=FIGSIZE)
    
    ax.bar(range(len(df)), df['glups'], tick_label=df['total_ranks'])
    ax.set_xlabel('MPI Ranks')
    ax.set_ylabel('GLUPS (Giga Lattice Updates Per Second)')
    ax.set_title('Throughput vs MPI Ranks')
    ax.grid(True, alpha=0.3, axis='y')
    
    plt.tight_layout()
    output_path = output_dir / 'throughput.png'
    plt.savefig(output_path, dpi=DPI, bbox_inches='tight')
    plt.close()
    print(f"Saved: {output_path}")


def plot_roofline(peak_flops: float, peak_bw: float, measured_points: list, output_dir: Path):
    """
    Plot roofline model.
    
    Args:
        peak_flops: Peak FLOPS (e.g., 1e12 for 1 TFLOPS)
        peak_bw: Peak memory bandwidth (bytes/s, e.g., 200e9 for 200 GB/s)
        measured_points: List of (name, AI, FLOPS) tuples
                        AI = Arithmetic Intensity (FLOPS/byte)
    """
    fig, ax = plt.subplots(figsize=FIGSIZE)
    
    # Roofline
    ai_range = np.logspace(-2, 3, 100)
    ridge_point = peak_flops / peak_bw
    
    roofline = np.minimum(peak_flops, peak_bw * ai_range)
    
    ax.loglog(ai_range, roofline / 1e9, 'b-', linewidth=2, label='Roofline')
    ax.axvline(x=ridge_point, color='gray', linestyle='--', alpha=0.5)
    
    # Measured points
    colors = plt.cm.tab10(np.linspace(0, 1, len(measured_points)))
    for (name, ai, flops), color in zip(measured_points, colors):
        ax.scatter([ai], [flops / 1e9], s=100, c=[color], label=name, zorder=5)
    
    ax.set_xlabel('Arithmetic Intensity (FLOPS/Byte)')
    ax.set_ylabel('Performance (GFLOPS)')
    ax.set_title('Roofline Model')
    ax.legend()
    ax.grid(True, alpha=0.3)
    ax.set_xlim(0.01, 100)
    
    plt.tight_layout()
    output_path = output_dir / 'roofline.png'
    plt.savefig(output_path, dpi=DPI, bbox_inches='tight')
    plt.close()
    print(f"Saved: {output_path}")


def plot_timer_breakdown(csv_path: str, output_dir: Path):
    """Plot timer breakdown (interior, halo, boundary)."""
    # This assumes timer data is in CSV format
    # Adjust based on actual output format
    
    # Example data structure
    labels = ['Interior\nCompute', 'Halo\nExchange', 'Boundary', 'Other']
    
    # Placeholder - read from actual profiling output
    times = [0.38, 0.006, 0.0001, 0.22]  # Example from your test run
    
    fig, ax = plt.subplots(figsize=(8, 6))
    
    colors = ['#2ecc71', '#3498db', '#e74c3c', '#95a5a6']
    ax.pie(times, labels=labels, colors=colors, autopct='%1.1f%%', startangle=90)
    ax.set_title('Execution Time Breakdown')
    
    plt.tight_layout()
    output_path = output_dir / 'timer_breakdown.png'
    plt.savefig(output_path, dpi=DPI, bbox_inches='tight')
    plt.close()
    print(f"Saved: {output_path}")


def main():
    """Main entry point."""
    output_dir = RESULTS_DIR
    output_dir.mkdir(parents=True, exist_ok=True)
    
    print("MiniWeather HPC - Generating Plots")
    print(f"Output directory: {output_dir}")
    print()
    
    # Plot strong scaling if data exists
    strong_csv = output_dir / 'strong_scaling.csv'
    if strong_csv.exists():
        print("Processing strong scaling data...")
        plot_strong_scaling(str(strong_csv), output_dir)
        plot_throughput(str(strong_csv), output_dir)
    else:
        print(f"Warning: {strong_csv} not found")
    
    # Plot weak scaling if data exists
    weak_csv = output_dir / 'weak_scaling.csv'
    if weak_csv.exists():
        print("Processing weak scaling data...")
        plot_weak_scaling(str(weak_csv), output_dir)
    else:
        print(f"Warning: {weak_csv} not found")
    
    # Generate example roofline (adjust values for your hardware)
    print("Generating roofline plot (example)...")
    # Example: Intel Xeon (2 TFLOPS peak, 200 GB/s BW)
    plot_roofline(
        peak_flops=2e12,
        peak_bw=200e9,
        measured_points=[
            ('7-pt Stencil (naive)', 0.875, 50e9),
            ('7-pt Stencil (blocked)', 1.2, 80e9),
        ],
        output_dir=output_dir
    )
    
    # Timer breakdown
    print("Generating timer breakdown...")
    plot_timer_breakdown(None, output_dir)
    
    print()
    print("Done! Check results/ folder for PNG files.")


if __name__ == '__main__':
    main()
