library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spi is
	generic (
		SPI_DBIT: INTEGER := 8;
		SPI_ABIT: INTEGER := 2
	);
	port(
		clk: in STD_LOGIC := '0';
		reset: in STD_LOGIC := '0';
		w_data: in STD_LOGIC_VECTOR(SPI_DBIT - 1 downto 0) := (others => 'X');
		w_adr: in STD_LOGIC_VECTOR(SPI_ABIT - 1 downto 0) := (others => 'X');
		tx_set_flag: in STD_LOGIC := '0';
		rx_clr_flag: in STD_LOGIC := '0';
		tx_empty: out STD_LOGIC := '1';
		rx_empty: out STD_LOGIC := '1';
		spi_sdi: out STD_LOGIC := '1';
		spi_clk: out STD_LOGIC := '0';
		spi_cs: out STD_LOGIC := '1'
	);
end spi;

architecture spi_impl of spi is

	component Buff is
		generic (
			DBIT: INTEGER := 10
		);
		port (
			clk: in STD_LOGIC;
			reset: in STD_LOGIC;
			clr_flag: in STD_LOGIC;
			set_flag: in STD_LOGIC;
			data_in: in STD_LOGIC_VECTOR((SPI_DBIT + SPI_ABIT) - 1 downto 0);
			data_out: out STD_LOGIC_VECTOR((SPI_DBIT + SPI_ABIT) - 1 downto 0);
			flag: out STD_LOGIC
		);
	end component Buff;
	
	component spi_transmitter  is
		generic (
			DBIT: INTEGER := 10
		);
		port (
			clk: in STD_LOGIC;
			reset: in STD_LOGIC;
			data_in: in STD_LOGIC_VECTOR(DBIT - 1 downto 0);
			tx_start: in STD_LOGIC;
			tx_done_tick: out STD_LOGIC;
			spi_sdi: out STD_LOGIC;
			spi_clk: out STD_LOGIC;
			spi_cs: out STD_LOGIC
		);
	end component spi_transmitter;

	signal wire_w_data: STD_LOGIC_VECTOR(SPI_DBIT + SPI_ABIT - 1 downto 0) := (others => 'X');
	signal wire_transfer_data: STD_LOGIC_VECTOR(SPI_DBIT + SPI_ABIT - 1 downto 0) := (others => 'X');
	signal wire_tx_clr_flag: STD_LOGIC := '0';
	signal wire_tx_start: STD_LOGIC := '0';
	signal wire_tx_set_flag: STD_LOGIC := '0';
	signal wire_spi_sdi: STD_LOGIC := '1';
	signal wire_spi_clk: STD_LOGIC := '0';
	signal wire_spi_cs: STD_LOGIC := '1';
	
begin
	
	process (tx_set_flag, reset)
	begin
		if (reset = '1') then
			wire_tx_set_flag <= '0';
		elsif(tx_set_flag = '0') then
			wire_tx_set_flag <= '0';
		elsif (tx_set_flag'event and tx_set_flag = '1') then
			wire_w_data <= STD_LOGIC_VECTOR(resize(UNSIGNED(w_adr & w_data), wire_w_data'length ));
			wire_tx_set_flag <= '1';
		end if;
	end process;
	
	tx_empty <= '0' when wire_tx_start = '1' OR wire_spi_cs = '0' else '1';
	
	spi_sdi <= wire_spi_sdi;
	spi_clk <= wire_spi_clk;
	spi_cs <= wire_spi_cs;
	
	tx_buff: Buff
		generic map (
			DBIT => SPI_DBIT + SPI_ABIT
		)
		port map (
			clk => clk,
			reset => reset,
			clr_flag => wire_tx_clr_flag,
			set_flag => wire_tx_set_flag,
			data_in => wire_w_data,
			data_out => wire_transfer_data,
			flag => wire_tx_start
		);

	spi_tx_inst: spi_transmitter
		generic map(
			DBIT => SPI_DBIT + SPI_ABIT
		)
		port map (
			clk => clk,
			reset => reset,
			data_in => wire_transfer_data,
			tx_start => wire_tx_start,
			tx_done_tick => wire_tx_clr_flag,
			spi_sdi => wire_spi_sdi,
			spi_clk => wire_spi_clk,
			spi_cs => wire_spi_cs
		);
		
end spi_impl;

configuration spi_cnf of spi is
	for spi_impl	
		for
			tx_buff: Buff use entity work.Buff(flag_buff);
		end for;
		for
			spi_tx_inst: spi_transmitter use entity work.spi_transmitter(spi_tx);
		end for;
	end for;
end configuration spi_cnf;