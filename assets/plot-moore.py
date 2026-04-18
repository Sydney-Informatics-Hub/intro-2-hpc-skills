import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.ticker as ticker
import numpy as np
from adjustText import adjust_text

# University of Sydney brand colours
PALETTE = {
    "charcoal": "#424242",
    "ochre":    "#E64626",
    "black":    "#0A0A0A",
    "white":    "#FFFFFF",
    "blue":     "#4E98D3",
    "green":    "#007E3B",
    "orange":   "#F9A134",
    "purple":   "#7F3F98",
}

df = pd.read_csv("transistor_counts.csv")
df = df.dropna(subset=["Transistor_Count", "Year"])
df["Transistor_Count"] = pd.to_numeric(df["Transistor_Count"], errors="coerce")
df["Year"] = pd.to_numeric(df["Year"], errors="coerce")
df = df.dropna()

# Moore's law reference line: doubles every 2 years from 1971 baseline
years_range = np.linspace(df["Year"].min(), df["Year"].max(), 300)
baseline = df.loc[df["Year"].idxmin(), "Transistor_Count"]
moores_line = baseline * 2 ** ((years_range - df["Year"].min()) / 2)

fig, ax = plt.subplots(figsize=(12, 7), layout="constrained")
fig.patch.set_facecolor(PALETTE["white"])
ax.set_facecolor(PALETTE["white"])

# Moore's law reference
ax.plot(
    years_range, moores_line,
    color=PALETTE["orange"], linewidth=1.8, linestyle="--",
    alpha=0.85, zorder=1, label="Moore's Law (doubles every 2 yrs)",
)

# Scatter dots
ax.scatter(
    df["Year"], df["Transistor_Count"],
    color=PALETTE["ochre"], edgecolors=PALETTE["charcoal"],
    linewidths=0.6, s=70, alpha=0.9, zorder=3,
)

ax.set_yscale("log")

# Annotate HPC landmark processors — set log scale BEFORE adjustText so it
# computes overlaps in display space correctly
landmarks = [
    "Itanium 2 Madison",          # powered early Top500 supercomputers
    "Xeon Westmere-EX (10-core)", # HPC cluster workhorse of the 2010s
    "AMD Threadripper 1950X",     # high core-count HPC workstations
    "AMD Zen 2 (7nm)",            # EPYC; powers Frontier (first exascale system)
    "AMD Zen 4 (5nm)",            # current-gen EPYC for HPC
    "Nvidia H100",                # GPU backbone of modern HPC/AI
    "Nvidia B100 (Blackwell)",    # next-gen HPC GPU
]
lm = df[df["Processor"].isin(landmarks)]
texts = [
    ax.text(
        row["Year"], row["Transistor_Count"], row["Processor"],
        fontsize=7.5, color=PALETTE["charcoal"], fontfamily="monospace", zorder=4,
    )
    for _, row in lm.iterrows()
]
adjust_text(
    texts,
    x=lm["Year"].values,
    y=lm["Transistor_Count"].values,
    ax=ax,
    expand=(1.5, 2.0),
    arrowprops=dict(
        arrowstyle="-",
        color=PALETTE["charcoal"],
        alpha=0.5,
        linewidth=0.8,
    ),
)
ax.yaxis.set_major_formatter(
    ticker.FuncFormatter(
        lambda x, _: (
            f"{x/1e9:.0f}B" if x >= 1e9
            else f"{x/1e6:.0f}M" if x >= 1e6
            else f"{x/1e3:.0f}K" if x >= 1e3
            else f"{x:.0f}"
        )
    )
)

ax.set_xlabel("Year", fontsize=12, color=PALETTE["charcoal"], labelpad=8)
ax.set_ylabel("Transistor Count", fontsize=12, color=PALETTE["charcoal"], labelpad=8)
ax.set_title(
    "Moore's Law: Transistor Counts Over Time",
    fontsize=15, fontweight="bold", color=PALETTE["charcoal"], pad=14,
)

ax.tick_params(colors=PALETTE["charcoal"], labelsize=10)
for spine in ax.spines.values():
    spine.set_edgecolor(PALETTE["charcoal"])
    spine.set_linewidth(0.8)

ax.grid(axis="y", color=PALETTE["charcoal"], alpha=0.15, linestyle="--", linewidth=0.7)
ax.grid(axis="x", color=PALETTE["charcoal"], alpha=0.08, linestyle="--", linewidth=0.7)

ax.legend(
    fontsize=9, framealpha=0.7,
    facecolor=PALETTE["white"], edgecolor=PALETTE["charcoal"],
    labelcolor=PALETTE["charcoal"],
)

plt.savefig("moore_law_dotplot.png", dpi=180, bbox_inches="tight",
            facecolor=PALETTE["white"])
plt.close()
print("Saved moore_law_dotplot.png")
