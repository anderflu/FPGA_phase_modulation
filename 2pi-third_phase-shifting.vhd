library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Clock_Modulator is
    Port (
        clk_12MHz  				: in  STD_LOGIC;
        reset      				: in  STD_LOGIC;
        modulated_signal  		: out STD_LOGIC;
		modulated_signal_neg  	: out STD_LOGIC
    );
end Clock_Modulator;


architecture Behavioral of Clock_Modulator is

	signal clk_96MHz		 		: std_logic := '0';
    signal mod_sig  				: std_logic := '0';
	
	-- Signals to create the output clock signal
	constant PLL_output			: integer := 96; -- MHz
	constant output_freq			: integer := 2;  -- MHz
	constant default_high		: integer := PLL_output/output_freq/3;
	constant default_low			: integer := 2*PLL_output/output_freq/3;
	signal high_time         		: integer := default_high;  -- High for 2 cycles of 96 MHz (1/3 duty cycle)
	signal low_time          	: integer := default_low;  -- Low for 4 cycles of 96 MHz (2/3 duty cycle)
	signal counter_96MHz     	: integer range 0 to PLL_output/output_freq := 0;

	
	-- Signals to keep track of the modulation timing   
	constant mod_period   		: integer := 120000; -- Modulation frequency = 96MHz /(2*120000) = 400Hz
	signal mod_counter			: integer range 0 to 2*mod_period - 1:= 0;
    signal mod_state      		: integer range 0 to 1 := 0;    
	signal trigger_phase_shift	: std_logic := '0';
	signal new_step				: std_logic := '0';
	
	-- Signals to keep track of steps during the phase shift	
    constant step_number      	: integer := 32/output_freq; -- Number of steps in a complete phase shift
    signal current_step       	: integer range 0 to step_number:= 0; -- Current step in the phase shift process
    constant step_length      	: integer := 23300/step_number; -- Number of 96MHz cycles for each step of the phase shift
    signal step_counter       	: integer range 0 to step_length - 1 := 0;  -- Counter for step length
	

component PLL_ARCH is
    port(
        ref_clk_i	: in std_logic;
        rst_n_i		: in std_logic;
        outcore_o	: out std_logic
    );
end component;

	
begin

PLL_inst: PLL_ARCH port map(
    ref_clk_i=> clk_12MHz,
    rst_n_i=> reset,
    outcore_o=> clk_96MHz
);


    clock : process(clk_96MHz, reset)
    begin
        if reset = '0' then
			counter_96MHz <= 0;
            mod_counter <= 0;
            mod_sig <= '0';
			trigger_phase_shift <= '0';
            mod_state <= 0;
            high_time <= default_high;
            low_time <= default_low;
			trigger_phase_shift <= '0';
			step_counter <= 0;
			current_step <= 0;
			new_step <= '0';
        elsif rising_edge(clk_96MHz) then
			-- Generate the signal to be modulated
            if counter_96MHz = high_time + low_time - 1 then
				mod_sig <= '0';
				counter_96MHz <= 0;
				if trigger_phase_shift = '1' and new_step = '1' then
					low_time <= default_low + (mod_state * 2 - 1);
					new_step <= '0';
				else
					low_time <= default_low;
				end if;
				if current_step = step_number then
					current_step <= 0;
					trigger_phase_shift <= '0';
					step_counter <= 0;
				end if;
            elsif counter_96MHz = low_time - 1 then
				mod_sig <= '1';
				counter_96MHz <= counter_96MHz + 1;
            else
                counter_96MHz <= counter_96MHz + 1;
            end if;
			-- Controls when the modulation should occur
			if mod_counter = mod_period - 1 then	-- Clock cycles between each phase shift
				mod_counter <= 0;
				trigger_phase_shift <= '1';				-- Trig rate 400 Hz
				mod_state <= 1 - mod_state;
			else
                mod_counter <= mod_counter + 1;
            end if;
			-- Step count controller
			if trigger_phase_shift = '1' then
				if step_counter = step_length - 1 then -- Should trigger every 75us/(number of steps)
					step_counter <= 0;
					new_step <= '1';
					current_step <= current_step + 1;
				else
					step_counter <= step_counter + 1;
				end if;
			else
				step_counter <= 0;
			end if;
        end if;
    end process;
	

    modulated_signal <= mod_sig;
end Behavioral;
