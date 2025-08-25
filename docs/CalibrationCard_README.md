# Calibration Card

- Print on A4. Left-top: 50x50 mm solid black square.
- Center QR content: `SQUARE_50MM`.
- Hold phone 30–50 cm from the card. Ensure the square width in camera is ~140–220 px.
- The app scans QR and measures the bounding width to compute scale: `scale = 50.0 / px` (mm/px).
- After success: badge shows `已标定(mm)` and units become mm.

Common issues: glare/overexposure/tilt; ensure square edges are visible and flat.
