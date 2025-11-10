library ieee;
use ieee.std_logic_textio.all;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;  -- optional if using textio, but report is enough here

entity tb_single_rom is
end tb_single_rom;

architecture behavior of tb_single_rom is

  -- Component Declaration (same ports as ROM IP)
  component blk_mem_gen_1
    port (
      clka  : in std_logic;
      ena   : in std_logic;
      addra : in std_logic_vector(14 downto 0);
      douta : out std_logic_vector(7 downto 0)
    );
  end component;

  -- Signal Declarations
  signal clka   : std_logic := '0';
  signal ena    : std_logic := '0';
  signal addra  : std_logic_vector(14 downto 0) := (others => '0');
  signal douta  : std_logic_vector(7 downto 0) := (others => '0');

  constant clk_period : time := 10 ns;

begin

  -- Instantiate ROM
  uut: blk_mem_gen_1
    port map (
      clka  => clka,
      ena   => ena,
      addra => addra,
      douta => douta
    );

  -- Clock generation process
  clk_process : process
  begin
    while true loop
      clka <= '0';
      wait for clk_period/2;
      clka <= '1';
      wait for clk_period/2;
    end loop;
  end process;

  -- Stimulus process
  stim_proc: process
  begin
    wait for 20 ns;  -- small delay before enabling ROM
    ena <= '1';

    -- read all 8 memory locations
    for i in 0 to 26623 loop
      addra <= std_logic_vector(to_unsigned(i, 15));
      wait for clk_period * 2;

      -- print output to terminal
      report " | Dec: " & integer'image(to_integer(unsigned(douta)));
    end loop;

    wait;  -- stop simulation
  end process;

end behavior;
