# FPGA_phase_modulation
Repository for the VHDL code used for phase modulation on an ICE40 Ultra Plus FPGA.
For both implementations, the PLL is used to generate the desired frequency.
- For the 180 deg phase shift, a 12 MHz clock is used as reference to generate two 60 MHz signals. One at 0 rad and one switching between 0 and +/-90 rad
- For the 2pi/3 phase shifting, a 12 MHz clock is used to generate a 96 MHz clock that generates the carrier signal and controls the phase modulation
