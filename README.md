# Communication Systems — Discrete BPSK and AM-USB Transceivers

> Personal project. Final-year BEng Electrical Engineering, University of West London.
> Module: TC60056E Communications Systems.

Two analogue communication transceivers designed from first principles, simulated in SIMetrix, and (for BPSK) built on breadboard. Documents the full workflow from mathematical modelling through SPICE verification to functional hardware.

## What's in this repo

| Document | Subject | Key result |
|---|---|---|
| [`docs/AM_USB.md`](docs/AM_USB.md) | Upper Single Sideband AM transmitter and coherent receiver using the Hartley phase-shift method | **52 dB sideband suppression**, ~8 µV carrier leakage |
| [`docs/BPSK_TDM.md`](docs/BPSK_TDM.md) | Coherent BPSK transceiver carrying a 2 kbps TDM bitstream (two interleaved 1 kbps signals) on a 700 kHz carrier | **BER = 0/20** in both SIMetrix and on breadboard |

Each document is self-contained: theory, SIMetrix design notes, full waveform/FFT analysis, and (for BPSK) the breadboard build with oscilloscope captures.

## AM-USB highlights

A single-sideband modulator and coherent demodulator built around two centre-tapped-transformer double-balanced mixers (BAS70-04 Schottky diodes), four first-order RC ±45° phase-shift networks, and an LM6172 difference amplifier:

- Phase-shift (Hartley) method, $S_{USB}(t) = m(t)\cos(2\pi f_c t) - \hat{m}(t)\sin(2\pi f_c t)$
- 1 kHz message, 700 kHz carrier, USB at 701 kHz
- LSB suppressed to ~1 mV, residual ~52 dB below the wanted sideband
- Carrier leakage reduced from ~10 mV (single-secondary transformers) to ~8 µV after switching to centre-tapped topology
- Coherent demodulation recovers the message at full amplitude with predictable phase delay
- Phase-angle experiment at φ = 0°, 90°, 180° confirms SSB-AM behaviour: amplitude is preserved across all LO phase angles (within ~5%), distinguishing SSB from DSB-SC where amplitude would follow $\cos(\varphi)$

## BPSK with TDM highlights

A coherent BPSK transceiver carrying two independent 1 kbps NRZ signals interleaved into a single 2 kbps TDM stream:

- Two 1N4148 diode-ring mixers (modulator + product detector)
- 700 kHz carrier, 5 Vpp drive, 0° LO phase-locked via BNC T-splitter
- TL072 zero-crossing comparator for hard-decision bit slicing
- First-order RC LPF at fc ≈ 4.8 kHz removes the 1.4 MHz sum-frequency component
- **SIMetrix:** zero bit errors across all 20 TDM slots
- **Breadboard:** zero bit errors, matches simulation (BER = 0/20)
- Demonstrates BPSK's amplitude-insensitivity (rail-saturated stages don't degrade decoding because data is in carrier phase) and contrasts with SSB's phase-insensitivity from the AM-USB section

The breadboard reproduces the SIMetrix result exactly despite real-world impairments (parasitic capacitance, supply ripple, diode forward-voltage variation), validating that the diode-ring topology is robust at these signal levels.

## Tools and components

- **Simulation:** SIMetrix Intro 7.20 (SPICE)
- **Maths:** MATLAB
- **Hardware:** Tektronix AFG1022 (arbitrary waveform + carrier), Tektronix TDS 2022B oscilloscope, ±15 V dual lab supply, 830-point breadboard
- **Active devices:** LM6172 (high-GBW op-amp, AM-USB), TL072 (BPSK gain/comparator), BAS70-04 Schottky (AM-USB DBM), 1N4148 (BPSK diode rings), AD633 (alternative AM-USB breadboard build)

## Repo layout

```
communication-systems-project/
├── README.md
├── docs/
│   ├── AM_USB.md          # Section 1.1 to 1.7.3
│   └── BPSK_TDM.md        # Section 2.1 to 2.9
├── matlab/
│   ├── am_ssb_phase_shift.m   # DSP model: SSB phase-shift modulation, demod, phase experiment
│   └── bpsk_tdm.m             # DSP model: BPSK + TDM modulation, demod, demux, phase experiment
├── images/
│   ├── am_usb/             # spectra, schematics, waveforms, FFTs (DSP + SIMetrix)
│   └── bpsk/               # 29 figures: SIMetrix waveforms + breadboard photos and scope captures
└── simetrix/
    ├── am_usb/             # AM-USSB SIMetrix schematic (.sxsch) and SPICE netlist (.cir)
    └── bpsk/               # BPSK behavioural SPICE netlist (.cir)
```

## License

Coursework artefacts for personal portfolio use. Schematics, simulation files, and analysis are © Mustafa Yaqoobi 2026.
