#!/usr/bin/env python3
"""
MiniWeather HPC - Results Collection Script
Parses Slurm output logs and extracts performance metrics into CSV.
"""

import re
import csv
import os
import sys
from pathlib import Path
from datetime import datetime

RESULTS_DIR = Path(__file__).parent.parent / "results"


def parse_miniweather_output(log_content: str) -> dict:
    """Parse MiniWeather output for performance metrics."""
    metrics = {}
    
    # Parse time and GLUPS
    # Format: [PARALLEL] Time 0.605752 s, GLUPS: 0.0346206
    time_match = re.search(r'Time\s+([\d.]+)\s+s', log_content)
    glups_match = re.search(r'GLUPS:\s+([\d.]+)', log_content)
    
    if time_match:
        metrics['time_s'] = float(time_match.group(1))
    if glups_match:
        metrics['glups'] = float(glups_match.group(1))
    
    # Parse configuration
    # Format: [PARALLEL] Configuration: 2 ranks with OpenMP
    config_match = re.search(r'Configuration:\s+(\d+)\s+ranks', log_content)
    if config_match:
        metrics['ranks'] = int(config_match.group(1))
    
    # Parse timer breakdown
    interior_match = re.search(r'Interior:\s+([\d.]+)\s+s', log_content)
    halo_match = re.search(r'Halo:\s+([\d.]+)\s+s', log_content)
    boundary_match = re.search(r'Boundary:\s+([\d.e-]+)\s+s', log_content)
    
    if interior_match:
        metrics['interior_s'] = float(interior_match.group(1))
    if halo_match:
        metrics['halo_s'] = float(halo_match.group(1))
    if boundary_match:
        metrics['boundary_s'] = float(boundary_match.group(1))
    
    return metrics


def parse_slurm_output(log_path: Path) -> dict:
    """Parse a Slurm output file."""
    with open(log_path, 'r') as f:
        content = f.read()
    
    result = parse_miniweather_output(content)
    result['log_file'] = log_path.name
    
    # Extract job ID from filename (e.g., miniweather_12345.out)
    job_id_match = re.search(r'_(\d+)\.out', log_path.name)
    if job_id_match:
        result['job_id'] = job_id_match.group(1)
    
    return result


def collect_all_results(results_dir: Path) -> list:
    """Collect results from all Slurm output files."""
    results = []
    
    for log_file in results_dir.glob('*.out'):
        try:
            result = parse_slurm_output(log_file)
            if result.get('time_s'):  # Only include if we got valid data
                results.append(result)
                print(f"Parsed: {log_file.name}")
        except Exception as e:
            print(f"Warning: Could not parse {log_file.name}: {e}")
    
    return results


def save_results_csv(results: list, output_path: Path):
    """Save results to CSV."""
    if not results:
        print("No results to save")
        return
    
    # Get all unique keys
    fieldnames = set()
    for r in results:
        fieldnames.update(r.keys())
    fieldnames = sorted(fieldnames)
    
    with open(output_path, 'w', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(results)
    
    print(f"Saved {len(results)} results to: {output_path}")


def main():
    """Main entry point."""
    print("MiniWeather HPC - Results Collection")
    print(f"Results directory: {RESULTS_DIR}")
    print()
    
    if not RESULTS_DIR.exists():
        print(f"Error: Results directory does not exist: {RESULTS_DIR}")
        sys.exit(1)
    
    results = collect_all_results(RESULTS_DIR)
    
    if results:
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        output_path = RESULTS_DIR / f'collected_results_{timestamp}.csv'
        save_results_csv(results, output_path)
    else:
        print("No valid results found")


if __name__ == '__main__':
    main()
