# FPGA_phase_modulation
Repository for the VHDL code used for phase modulation on an ICE40 Ultra Plus FPGA.
For both implementations, the PLL is used to generate the desired frequency.
- For the 180 deg phase shift 12 MHz is used as reference to generate two 60 MHz signals. One and 0 rad and one a -90 rad
- For the 2pi/3 phase shifting 12 MHz is used to generate a 96 MHz clock that controls the processes
