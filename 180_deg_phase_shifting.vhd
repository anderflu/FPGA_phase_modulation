library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity my_module is
    port (
	i_clock					: in std_logic;			-- 12 MHz clock
	reset					: in std_logic;	
	reference_clk_out			: out std_logic;
	shifting_clk_out			: out std_logic;
	o_LED0					: out std_logic;
	o_LED1					: out std_logic
    );
end entity my_module;

architecture behavioral of my_module is

	-- signals in/out of PLL
    signal lock_o: std_logic;
    signal port_A_o: std_logic;
    signal port_A_glob: std_logic;
	signal port_B_o: std_logic;
    signal port_B_glob: std_logic;
	signal PLL_out : std_logic;
	
	-- Modulation controller	
	constant delay_short : integer := 1800;
	constant delay : integer := 30000/2 - delay_short-1;
	signal mod_count : integer range 0 to delay;
	signal toggle : std_logic := '0';
	
	-- HSOSC parameters
	signal ENCLKHF : std_logic := '1';
    signal CLKHF_POWERUP : std_logic := '1';
    signal CLKHF : std_logic;
	signal speed_clk : std_logic;
	
	-- State machine parameters
	type state_type is (S_backward, S_middle_f, S_forward, S_middle_b);
	signal state, next_state : state_type := S_backward;


component mod_pll is
    port(
        ref_clk_i: in std_logic;
        rst_n_i: in std_logic;
        lock_o: out std_logic;
        outcore_o: out std_logic;
        outglobal_o: out std_logic;
        outcoreb_o: out std_logic;
        outglobalb_o: out std_logic
    );
end component;

-- Define HSOSC and its ports
component HSOSC
	generic (
		CLKHF_DIV : string := "0b00"  -- Default value, gives 48 MHz
	);
	port (
		CLKHFEN	: in std_logic;
		CLKHFPU	: in std_logic;
		CLKHF	: out std_logic
	);
end component;


begin

-- Istantiate PLL
modulation_PLL: mod_pll port map(
    ref_clk_i=> i_clock,
    rst_n_i=> reset,
	lock_o=> lock_o,
    outcore_o=> port_A_o,
    outglobal_o=> port_A_glob,
	outcoreb_o=> port_B_o,
    outglobalb_o=> port_B_glob
);

-- Instantiate HSOSC
OSCInst: HSOSC
	generic map (
		CLKHF_DIV => "0b10" -- Number of times 48 MHz clock is divided by 2
	)
	port map (
		CLKHFEN => ENCLKHF,
		CLKHFPU => CLKHF_POWERUP,
		CLKHF => CLKHF
	);


--State machne controller
SM_controller : process(CLKHF)
begin
	if rising_edge(CLKHF) then
		if (state = S_middle_b or state = S_middle_f) then
			if mod_count = 0 then
				mod_count <= delay;
				state <= next_state;
			else
				mod_count <= mod_count - 1;
			end if;
		else
			if mod_count = 0 then
				mod_count <= delay_short;
				state <= next_state;
			else
				mod_count <= mod_count - 1;
			end if;
		end if;
	end if;
end process;


--State machine to control the shifting output
phase_shifter_SM : process(CLKHF)
begin
	case state is
		when S_backward =>
			shifting_clk_out <= port_B_glob;
			next_state <= S_middle_f;
		when S_middle_f =>
			shifting_clk_out <= port_A_o;
			next_state <= S_forward;
		when S_forward =>
			shifting_clk_out <= not port_B_glob;
			next_state <= S_middle_b;
		when S_middle_b =>
			shifting_clk_out <= port_A_o;
			next_state <= S_backward;
	end case;
end process;

	
	reference_clk_out <= port_A_o;
	o_LED0 <= not lock_o;	-- LED0 on if locked
	o_LED1 <= lock_o;		-- LED1 on if not locked

end behavioral;
