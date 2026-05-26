#!/usr/bin/env python3
"""
MiniWeather Visualization Script

Generates visualizations of the 3D stencil field data:
- 2D slices (XY, XZ, YZ planes)
- 3D isosurface rendering
- Animation of time evolution
"""

import numpy as np
import matplotlib.pyplot as plt
from matplotlib import cm
from mpl_toolkits.mplot3d import Axes3D
import matplotlib.animation as animation
import argparse
import os

def generate_initial_field(nx, ny, nz, pattern='gaussian'):
    """Generate initial temperature/field data"""
    x = np.linspace(0, 1, nx)
    y = np.linspace(0, 1, ny)
    z = np.linspace(0, 1, nz)
    X, Y, Z = np.meshgrid(x, y, z, indexing='ij')
    
    if pattern == 'gaussian':
        # Gaussian hot spot in center
        cx, cy, cz = 0.5, 0.5, 0.5
        sigma = 0.15
        field = np.exp(-((X - cx)**2 + (Y - cy)**2 + (Z - cz)**2) / (2 * sigma**2))
    elif pattern == 'wave':
        # Sinusoidal wave pattern
        field = np.sin(2 * np.pi * X) * np.sin(2 * np.pi * Y) * np.sin(2 * np.pi * Z)
    elif pattern == 'random':
        # Random field with smoothing
        field = np.random.rand(nx, ny, nz)
    elif pattern == 'sphere':
        # Spherical temperature distribution
        r = np.sqrt((X - 0.5)**2 + (Y - 0.5)**2 + (Z - 0.5)**2)
        field = np.where(r < 0.3, 1.0, 0.0)
    else:
        # Linear gradient
        field = X + Y + Z
    
    return field

def apply_stencil(field, steps=1):
    """Apply 7-point stencil diffusion"""
    current = field.copy()
    for _ in range(steps):
        next_field = np.zeros_like(current)
        # Interior points only
        next_field[1:-1, 1:-1, 1:-1] = (
            current[0:-2, 1:-1, 1:-1] +  # i-1
            current[2:,   1:-1, 1:-1] +  # i+1
            current[1:-1, 0:-2, 1:-1] +  # j-1
            current[1:-1, 2:,   1:-1] +  # j+1
            current[1:-1, 1:-1, 0:-2] +  # k-1
            current[1:-1, 1:-1, 2:  ] +  # k+1
            4 * current[1:-1, 1:-1, 1:-1]
        ) / 10.0
        current = next_field
    return current

def plot_2d_slices(field, title="Field Visualization", save_path=None):
    """Plot 2D slices through the 3D field"""
    nx, ny, nz = field.shape
    
    fig, axes = plt.subplots(1, 3, figsize=(15, 4))
    fig.suptitle(title, fontsize=14, fontweight='bold')
    
    # XY slice (middle of Z)
    im0 = axes[0].imshow(field[:, :, nz//2].T, origin='lower', cmap='RdYlBu_r', aspect='auto')
    axes[0].set_xlabel('X')
    axes[0].set_ylabel('Y')
    axes[0].set_title(f'XY Plane (Z={nz//2})')
    plt.colorbar(im0, ax=axes[0], label='Temperature')
    
    # XZ slice (middle of Y)
    im1 = axes[1].imshow(field[:, ny//2, :].T, origin='lower', cmap='RdYlBu_r', aspect='auto')
    axes[1].set_xlabel('X')
    axes[1].set_ylabel('Z')
    axes[1].set_title(f'XZ Plane (Y={ny//2})')
    plt.colorbar(im1, ax=axes[1], label='Temperature')
    
    # YZ slice (middle of X)
    im2 = axes[2].imshow(field[nx//2, :, :].T, origin='lower', cmap='RdYlBu_r', aspect='auto')
    axes[2].set_xlabel('Y')
    axes[2].set_ylabel('Z')
    axes[2].set_title(f'YZ Plane (X={nx//2})')
    plt.colorbar(im2, ax=axes[2], label='Temperature')
    
    plt.tight_layout()
    
    if save_path:
        plt.savefig(save_path, dpi=150, bbox_inches='tight')
        print(f"Saved: {save_path}")
    
    return fig

def plot_3d_isosurface(field, threshold=0.5, save_path=None):
    """Plot 3D isosurface using scatter plot approximation"""
    nx, ny, nz = field.shape
    
    fig = plt.figure(figsize=(10, 8))
    ax = fig.add_subplot(111, projection='3d')
    
    # Find points above threshold
    x, y, z = np.where(field > threshold)
    values = field[x, y, z]
    
    # Subsample if too many points
    max_points = 5000
    if len(x) > max_points:
        idx = np.random.choice(len(x), max_points, replace=False)
        x, y, z, values = x[idx], y[idx], z[idx], values[idx]
    
    scatter = ax.scatter(x, y, z, c=values, cmap='hot', alpha=0.6, s=20)
    
    ax.set_xlabel('X')
    ax.set_ylabel('Y')
    ax.set_zlabel('Z')
    ax.set_title(f'3D Field (threshold > {threshold})')
    plt.colorbar(scatter, ax=ax, label='Temperature', shrink=0.6)
    
    if save_path:
        plt.savefig(save_path, dpi=150, bbox_inches='tight')
        print(f"Saved: {save_path}")
    
    return fig

def plot_contour_slices(field, save_path=None):
    """Plot contour slices at different Z levels"""
    nx, ny, nz = field.shape
    
    fig, axes = plt.subplots(2, 3, figsize=(14, 9))
    fig.suptitle('Temperature Contours at Different Z Levels', fontsize=14, fontweight='bold')
    
    z_levels = [0, nz//4, nz//2, 3*nz//4, nz-1]
    
    for idx, z_idx in enumerate(z_levels[:6]):
        row, col = idx // 3, idx % 3
        ax = axes[row, col]
        
        contour = ax.contourf(field[:, :, z_idx].T, levels=20, cmap='RdYlBu_r')
        ax.contour(field[:, :, z_idx].T, levels=10, colors='black', linewidths=0.5, alpha=0.5)
        ax.set_xlabel('X')
        ax.set_ylabel('Y')
        ax.set_title(f'Z = {z_idx}')
        plt.colorbar(contour, ax=ax)
    
    # Hide last subplot if odd number
    if len(z_levels) < 6:
        axes[1, 2].axis('off')
    
    plt.tight_layout()
    
    if save_path:
        plt.savefig(save_path, dpi=150, bbox_inches='tight')
        print(f"Saved: {save_path}")
    
    return fig

def create_evolution_animation(nx, ny, nz, steps, pattern='gaussian', save_path=None):
    """Create animation showing field evolution over time"""
    print(f"Creating animation with {steps} frames...")
    
    field = generate_initial_field(nx, ny, nz, pattern)
    
    fig, ax = plt.subplots(figsize=(8, 6))
    
    # Initial plot
    im = ax.imshow(field[:, :, nz//2].T, origin='lower', cmap='RdYlBu_r', 
                   vmin=0, vmax=1, aspect='auto')
    ax.set_xlabel('X')
    ax.set_ylabel('Y')
    title = ax.set_title(f'Temperature Field (Step 0)')
    plt.colorbar(im, ax=ax, label='Temperature')
    
    def update(frame):
        nonlocal field
        field = apply_stencil(field, steps=5)  # 5 stencil steps per frame
        im.set_array(field[:, :, nz//2].T)
        title.set_text(f'Temperature Field (Step {frame * 5})')
        return [im, title]
    
    anim = animation.FuncAnimation(fig, update, frames=steps, interval=100, blit=True)
    
    if save_path:
        if save_path.endswith('.gif'):
            anim.save(save_path, writer='pillow', fps=10)
        else:
            anim.save(save_path, writer='ffmpeg', fps=10)
        print(f"Saved animation: {save_path}")
    
    return anim

def plot_statistics(field, save_path=None):
    """Plot field statistics"""
    fig, axes = plt.subplots(2, 2, figsize=(12, 10))
    fig.suptitle('Field Statistics', fontsize=14, fontweight='bold')
    
    # Histogram
    axes[0, 0].hist(field.flatten(), bins=50, color='steelblue', edgecolor='black', alpha=0.7)
    axes[0, 0].set_xlabel('Temperature')
    axes[0, 0].set_ylabel('Frequency')
    axes[0, 0].set_title('Temperature Distribution')
    axes[0, 0].axvline(field.mean(), color='red', linestyle='--', label=f'Mean: {field.mean():.3f}')
    axes[0, 0].legend()
    
    # Profile along X (center line)
    nx, ny, nz = field.shape
    axes[0, 1].plot(field[:, ny//2, nz//2], 'b-', linewidth=2)
    axes[0, 1].set_xlabel('X index')
    axes[0, 1].set_ylabel('Temperature')
    axes[0, 1].set_title('Temperature Profile (X axis, center)')
    axes[0, 1].grid(True, alpha=0.3)
    
    # Profile along Y
    axes[1, 0].plot(field[nx//2, :, nz//2], 'g-', linewidth=2)
    axes[1, 0].set_xlabel('Y index')
    axes[1, 0].set_ylabel('Temperature')
    axes[1, 0].set_title('Temperature Profile (Y axis, center)')
    axes[1, 0].grid(True, alpha=0.3)
    
    # Profile along Z
    axes[1, 1].plot(field[nx//2, ny//2, :], 'r-', linewidth=2)
    axes[1, 1].set_xlabel('Z index')
    axes[1, 1].set_ylabel('Temperature')
    axes[1, 1].set_title('Temperature Profile (Z axis, center)')
    axes[1, 1].grid(True, alpha=0.3)
    
    plt.tight_layout()
    
    if save_path:
        plt.savefig(save_path, dpi=150, bbox_inches='tight')
        print(f"Saved: {save_path}")
    
    return fig

def main():
    parser = argparse.ArgumentParser(description='MiniWeather Field Visualization')
    parser.add_argument('-nx', type=int, default=64, help='Grid size in X')
    parser.add_argument('-ny', type=int, default=64, help='Grid size in Y')
    parser.add_argument('-nz', type=int, default=64, help='Grid size in Z')
    parser.add_argument('--pattern', choices=['gaussian', 'wave', 'random', 'sphere', 'linear'],
                        default='gaussian', help='Initial field pattern')
    parser.add_argument('--steps', type=int, default=0, help='Stencil diffusion steps to apply')
    parser.add_argument('--output', '-o', type=str, default='results', help='Output directory')
    parser.add_argument('--animate', action='store_true', help='Create evolution animation')
    parser.add_argument('--frames', type=int, default=50, help='Animation frames')
    args = parser.parse_args()
    
    # Create output directory
    os.makedirs(args.output, exist_ok=True)
    
    print(f"Generating {args.pattern} field: {args.nx}x{args.ny}x{args.nz}")
    
    # Generate field
    field = generate_initial_field(args.nx, args.ny, args.nz, args.pattern)
    
    # Apply diffusion if requested
    if args.steps > 0:
        print(f"Applying {args.steps} stencil diffusion steps...")
        field = apply_stencil(field, args.steps)
    
    # Generate visualizations
    print("\nGenerating visualizations...")
    
    # 2D slices
    plot_2d_slices(field, 
                   title=f'{args.pattern.title()} Field ({args.nx}³, {args.steps} steps)',
                   save_path=os.path.join(args.output, 'slices_2d.png'))
    
    # 3D isosurface
    threshold = field.max() * 0.3
    plot_3d_isosurface(field, threshold=threshold,
                       save_path=os.path.join(args.output, 'isosurface_3d.png'))
    
    # Contour slices
    plot_contour_slices(field,
                        save_path=os.path.join(args.output, 'contours.png'))
    
    # Statistics
    plot_statistics(field,
                    save_path=os.path.join(args.output, 'statistics.png'))
    
    # Animation (optional)
    if args.animate:
        create_evolution_animation(args.nx, args.ny, args.nz, args.frames, args.pattern,
                                   save_path=os.path.join(args.output, 'evolution.gif'))
    
    print(f"\n✓ All visualizations saved to: {args.output}/")
    print("\nField Statistics:")
    print(f"  Min: {field.min():.4f}")
    print(f"  Max: {field.max():.4f}")
    print(f"  Mean: {field.mean():.4f}")
    print(f"  Std: {field.std():.4f}")

if __name__ == '__main__':
    main()
