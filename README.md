# Functional Gleba Map Colors

## Overview

This is a *Factorio* mod that adjusts map colors of Gleba terrain to represent function rather than appearance, making farmable land easier to distinguish from unfarmable land and water.

\*When applied to an existing game save, please wait a minute for the Gleba map to be regenerated in the background with the new colors.

## Features

- Configurable map colors for yumako and jellynet farmable ground
- Configurable map colors for highland, midland, lowland, shallow water, deep water, and any other tile type not covered
- Automatically interpolates map colors for medium fertility ground
- Extra contrast can be added between configurable agricultural stages
- Automatically adjusts map colors for trees to mildly contrast with chosen and calculated ground colors
- Configurable contrast in the main view between fertile and infertile wetlands and deep water

## Implementation

### Assumptions

- There are exactly two plants to farm on Gleba: yumako and jellynut.
- There are exactly three types of farmable ground for each plant with fixed tile names:
  - natural: `"natural-yumako-soil"`, `"natural-jellynut-soil"`
  - artificial: `"artificial-yumako-soil"`, `"artificial-jellynut-soil"`
  - overgrowth: `"overgrowth-yumako-soil"`, `"overgrowth-jellynut-soil"`
- These three types of farmable tiles follow a clear pattern of technological progression.
- The tile names of most non-farmable ground are prefixed with "highland-", "midland-", or "lowland-".
- All tiles that naturally appear on Gleba have their prototype's `subgroup` field set to either `""gleba-tiles"` or `"gleba-water-tiles"`.
- The only non-agricultural trees that grow exclusively amongst yumako trees are: `"funneltrunk"` and `"hairyclubnub"`.
- The only non-agricultural trees that grow exclusively amongst jellystem are: `"slipstack"` and `"lickmaw"`.
- The only non-agricultural trees that can grow amongst or near either yumako trees or jellystem are: `"water-cane"`, `"teflilly"`, and `"cuttlepop"`.
- All trees that appear on Gleba have their prototype's `autoplace.control` field set to `"gleba_plants"`.

If any other mods are active which violate one or more of these assumptions, some aspects of this mod may fail to work properly.

### Operation

The mod determines which tiles can have artificial or overgrowth soil placed on them, using that information to categorize tiles as high, medium, or low fertility. Settings let the player decide the color to use for the high and low fertility tiles. The color for medium fertility tiles is then interpolated automatically between those two endpoints. By default, this is exactly halfway between the high and low fertility colors, but by choosing a different agricultural stage and higher or lower contrast, the interpolated color can lean closer to either the high or low fertility color. If "overgrowth" is chosen as the agricultural stage, then even the low fertility color is interpolated somewhat toward the high fertility color, further contrasting all farmable ground of any teir from ground that is never farmable.

For non-agrigultural tiles, deep water and shallow water are determined by each tile prototype's collision layers. Highland, midland, and lowland tiles are determined by the prefix on the tile's name. Any other tile that occurs naturally on Gleba will be placed into the catch-all "other" category. In unmodded Space Age, this is only `"pit-rock"`.

Tree colors are adjusted to mildly contrast with the ground on which they occur. For those that occur exclusively amongst yumako tree or amongst jellynut trees, the color to contrast against is determined by a smart averaging of the high, medium, and low fertility colors for the relevant plant. For trees that occur amongst both, a color between both farmable soil types is chosen. For all other trees, the contrast color is based on an average of the highland, midland, and lowland tile colors. The mild contrast is achieved by shifting the hue a small amount, decreasing the vibrancy substantially, and for trees on non-agricultural ground, slightly decreasing their lightness. These behaviors are currently hard-coded and unconfigurable.

The Oklch color space is used for all interpolation, allowing for smoother transitions even when the source and target colors vary greatly in hue, lightness, or vibrancy.

Due to how the map is rendered in *Factorio*, changes to map colors are not automatically applied to parts of the map that have already been revealed. Therefore, adding this mod to a game already in progress will not instantly produce any visual changes to the Gleba map. This is overcome by automatically regenerating the Gleba map when the mod detects that it has been newly added or its settings have been altered since the last time the game save was used. It can take a minute to regenerate the full Gleba map, especially if a lot of it has already been explored.
