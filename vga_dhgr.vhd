library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity vga_dhgr is
	port (
		pR		: out std_logic;
		pG		: out std_logic;
		pB		: out std_logic;
		pI		: out std_logic;
		pHSYNC 	: out std_logic;
		pVSYNC	: out std_logic;
		
		pVaddr	: out std_logic_vector(14 downto 0);
		pVdata	: inout std_logic_vector(7 downto 0);
		pVwrite	: out std_logic;
		pVenable : out std_logic;
		
		pAaddr	: in std_logic_vector(15 downto 0);
		pAdata	: in std_logic_vector(7 downto 0);
		pArw	: in std_logic;
		pAq3	: in std_logic;
		pAphi0	: in std_logic;
		
		reset 	: in std_logic;
		clk		: in std_logic
		
);
end vga_dhgr;

architecture RTL of vga_dhgr is

	signal hcount : std_logic_vector(9 downto 0);
	signal vcount : std_logic_vector(9 downto 0);
	signal pcount : std_logic_vector(2 downto 0);

	signal vga_out : std_logic_vector(3 downto 0);

	signal vram_col : std_logic_vector(6 downto 0);
	signal vram_row : std_logic_vector(9 downto 0);
	signal vreg : std_logic_vector(7 downto 0);
	signal vram_write : std_logic_vector(2 downto 0);
	signal color : std_logic_vector(3 downto 0);
	signal store : std_logic;
	signal page : std_logic;
	signal aux : std_logic;
	signal hires : std_logic;
	signal page2 : std_logic;
	signal hc: std_logic;

	signal apple_addr : std_logic_vector(15 downto 0);
	signal apple_data : std_logic_vector(7 downto 0);
	signal apple_write : std_logic;
	
	constant H_ACTIVE_PIXEL_LIMIT : integer := 640;
	constant V_ACTIVE_LINE_LIMIT  : integer := 480;

	constant SCREEN_W : integer := 560;
	constant SCREEN_H : integer := 384;
	constant BORDER_W : integer := (H_ACTIVE_PIXEL_LIMIT - SCREEN_W) / 2;
	constant BORDER_H : integer := (V_ACTIVE_LINE_LIMIT - SCREEN_H) / 2;

	constant H_FPORCH_PIXEL_LIMIT : integer := SCREEN_W + BORDER_W + 16;
	constant H_SYNC_PIXEL_LIMIT   : integer := H_FPORCH_PIXEL_LIMIT + 96;
	constant H_BPORCH_PIXEL_LIMIT : integer := H_SYNC_PIXEL_LIMIT + 48 + BORDER_W;
	
	constant V_FPORCH_LINE_LIMIT  : integer := SCREEN_H + BORDER_H + 10;
	constant V_SYNC_LINE_LIMIT    : integer := V_FPORCH_LINE_LIMIT + 2;
	constant V_BPORCH_LINE_LIMIT  : integer := V_SYNC_LINE_LIMIT + 33 + BORDER_H;

begin
	pR <= vga_out(3);
	pG <= vga_out(2);
	pB <= vga_out(1);
	pI <= vga_out(0);
	pVenable <= '0';
	
process(pAq3, reset)
begin
	if (reset = '0') then
		page <= '0';
		aux <= '0';
		page2 <= '0';
	elsif (pAq3'event and pAq3 = '0' and pAphi0 = '1') then
		if pArw = '1' then
			case pAaddr is
				when X"C054" => page2 <= '0'; -- Page2 off
				when X"C055" => page2 <= '1'; -- Page2 on
				when X"C056" => hires <= '0'; -- HIRES off
				when X"C057" => hires <= '1'; -- HIRES on
				when others => null;
			end case;
		end if;
		if pArw = '0' then
			case pAaddr is
				when X"C000" => store <= '0'; -- 80STORE off
				when X"C001" => store <= '1'; -- 80STORE on
				when X"C004" => aux <= '0'; -- RAMWRT off
				when X"C005" => aux <= '1'; -- RAMWRT on
				when X"C054" => page <= '0'; -- Page2 off
				when X"C055" => page <= '1'; -- Page2 on
				when X"C056" => hires <= '0'; -- HIRES off
				when X"C057" => hires <= '1'; -- HIRES on
				when others => null;
			end case;
			apple_addr <= pAaddr - X"2000";
			apple_data <= pAdata;
			apple_write <= '1';
		else
			apple_write <= '0';
		end if;
	end if;
end process;

process(clk, reset)
begin
	if (reset = '0') then
		vram_write <= "000";
		pcount <= "000";
		pVwrite <= '1';
		pVdata <= (others => 'Z');
	elsif (clk'event and clk = '0') then
		if (pcount = "010") then
			color <= color(2 downto 0) & pVdata(0);
			vreg <= pVdata;
		else
			color <= color(2 downto 0) & vreg(1);
			vreg <= vreg(7) & '0' & vreg(6 downto 1);
		end if;
		if (pAphi0 = '1' and vram_write = "100") then
			vram_write <= "000";
		end if;
		if (pcount = "011") then
			if (pAphi0 = '0' and apple_write = '1' and 
				apple_addr(15) = '0' and apple_addr(14) = '0' and
				vram_write = "000") then
				vram_write <= "001";
			end if;
			if (store = '0') then
				pVaddr <= aux & apple_addr(13 downto 0);
			else
				if (page = '0' and hires = '0') then
					pVaddr <= aux & apple_addr(13 downto 0);
				elsif (page = '0' and hires = '1') then
					if (aux = '0') then
						pVaddr <= aux & apple_addr(13 downto 0);
					else
						pVaddr <= apple_addr(13) & apple_addr(13 downto 0);
					end if;
				elsif (page = '1' and hires = '0') then
					pVaddr <= aux & apple_addr(13 downto 0);
				else
					if (aux = '0') then
						pVaddr <= not apple_addr(13) & apple_addr(13 downto 0);
					else
						pVaddr <= aux & apple_addr(13 downto 0);
					end if;
				end if;
			end if;
		end if;
		if (vram_write = "001") then -- pcount = "100"
			pVwrite <= '0';
			vram_write <= "010";
		end if;
		if (vram_write = "010") then -- pcount = "101"
			pVdata <= apple_data;
			vram_write <= "011";
		end if;
		if (vram_write = "011") then -- pcount = "110"
			pVwrite <= '1';
			pVdata <= (others => 'Z');
			vram_write <= "100";
		end if;
		if (pcount = "000") then
			vram_row <= vcount(3 downto 1) & vcount(6 downto 4) &
				vcount(8 downto 7) & vcount(8 downto 7);
		end if;
		if (pcount = "001") then
			pVaddr <= (not vram_col(0) & page2 & vram_row & "000") + vram_col(6 downto 1);
			vram_col <= vram_col + 1;
		end if;
		if (hc = '1') then
			vram_col <= (others => '0');
			pcount <= "101";
			vreg <= (others => '0');
			color <= "0000";
		elsif (pcount = "110") then
			pcount <= "000";
		else
			pcount <= pcount + 1;
		end if;
	end if;
end process;

process(clk, reset)
begin
	if (reset = '0') then
		hcount <= (others => '0');
		vcount <= (others => '0');
	elsif clk'event and clk = '1' then
		if (conv_integer(hcount) = (H_BPORCH_PIXEL_LIMIT - 1)) then
			hcount <= (others => '0');
			if (conv_integer(vcount) = (V_BPORCH_LINE_LIMIT - 1)) then
				vcount <= (others => '0');
			else
				vcount <= vcount + 1;
			end if;
		else
			hcount <= hcount + 1;
		end if;
		
		if (conv_integer(vcount) < SCREEN_H and
			conv_integer(hcount) < SCREEN_W + 3) then
			if (hcount(1 downto 0) = "10") then
				case color is
					when "0000" => vga_out <= "0000"; -- Black
					when "0001" => vga_out <= "1000"; -- Magenta
					when "0010" => vga_out <= "1100"; -- Brown
					when "0011" => vga_out <= "1001"; -- Oragne
					when "0100" => vga_out <= "0100"; -- Dark Green
					when "0101" => vga_out <= "1110"; -- Gray 1
					when "0110" => vga_out <= "0101"; -- Green
					when "0111" => vga_out <= "1101"; -- Yellow
					when "1000" => vga_out <= "0010"; -- Dark Blue
					when "1001" => vga_out <= "1010"; -- Violet
					when "1010" => vga_out <= "0001"; -- Gray 2
					when "1011" => vga_out <= "1011"; -- Pink
					when "1100" => vga_out <= "0110"; -- Medium Blue
					when "1101" => vga_out <= "0011"; -- Light Blue
					when "1110" => vga_out <= "0111"; -- Aqua
					when "1111" => vga_out <= "1111"; -- White
					when others => null;
				end case;
			end if;
			if (hcount(1 downto 0) = "11") then
				case color is
					when "0000" => vga_out <= "0000"; -- Black
					when "0010" => vga_out <= "1000"; -- Magenta
					when "0100" => vga_out <= "1100"; -- Brown
					when "0110" => vga_out <= "1001"; -- Oragne
					when "1000" => vga_out <= "0100"; -- Dark Green
					when "1010" => vga_out <= "1110"; -- Gray 1
					when "1100" => vga_out <= "0101"; -- Green
					when "1110" => vga_out <= "1101"; -- Yellow
					when "0001" => vga_out <= "0010"; -- Dark Blue
					when "0011" => vga_out <= "1010"; -- Violet
					when "0101" => vga_out <= "0001"; -- Gray 2
					when "0111" => vga_out <= "1011"; -- Pink
					when "1001" => vga_out <= "0110"; -- Medium Blue
					when "1011" => vga_out <= "0011"; -- Light Blue
					when "1101" => vga_out <= "0111"; -- Aqua
					when "1111" => vga_out <= "1111"; -- White
					when others => null;
				end case;
			end if;
			if (hcount(1 downto 0) = "00") then
				case color is
					when "0000" => vga_out <= "0000"; -- Black
					when "0100" => vga_out <= "1000"; -- Magenta
					when "1000" => vga_out <= "1100"; -- Brown
					when "1100" => vga_out <= "1001"; -- Oragne
					when "0001" => vga_out <= "0100"; -- Dark Green
					when "0101" => vga_out <= "1110"; -- Gray 1
					when "1001" => vga_out <= "0101"; -- Green
					when "1101" => vga_out <= "1101"; -- Yellow
					when "0010" => vga_out <= "0010"; -- Dark Blue
					when "0110" => vga_out <= "1010"; -- Violet
					when "1010" => vga_out <= "0001"; -- Gray 2
					when "1110" => vga_out <= "1011"; -- Pink
					when "0011" => vga_out <= "0110"; -- Medium Blue
					when "0111" => vga_out <= "0011"; -- Light Blue
					when "1011" => vga_out <= "0111"; -- Aqua
					when "1111" => vga_out <= "1111"; -- White
					when others => null;
				end case;
			end if;
			if (hcount(1 downto 0) = "01") then
				case color is
					when "0000" => vga_out <= "0000"; -- Black
					when "1000" => vga_out <= "1000"; -- Magenta
					when "0001" => vga_out <= "1100"; -- Brown
					when "1001" => vga_out <= "1001"; -- Oragne
					when "0010" => vga_out <= "0100"; -- Dark Green
					when "1010" => vga_out <= "1110"; -- Gray 1
					when "0011" => vga_out <= "0101"; -- Green
					when "1011" => vga_out <= "1101"; -- Yellow
					when "0100" => vga_out <= "0010"; -- Dark Blue
					when "1100" => vga_out <= "1010"; -- Violet
					when "0101" => vga_out <= "0001"; -- Gray 2
					when "1101" => vga_out <= "1011"; -- Pink
					when "0110" => vga_out <= "0110"; -- Medium Blue
					when "1110" => vga_out <= "0011"; -- Light Blue
					when "0111" => vga_out <= "0111"; -- Aqua
					when "1111" => vga_out <= "1111"; -- White
					when others => null;
				end case;
			end if;
		else
			vga_out <= (others => '0');
		end if;

		case (conv_integer(hcount)) is
			when H_FPORCH_PIXEL_LIMIT => pHSYNC <= '0';
			when H_SYNC_PIXEL_LIMIT => pHSYNC <= '1';
			when (H_BPORCH_PIXEL_LIMIT - 3) => hc <= '1';
			when (H_BPORCH_PIXEL_LIMIT - 2) => hc <= '0';
			when others => null;
		end case;
		
		case (conv_integer(vcount)) is
			when V_FPORCH_LINE_LIMIT => pVSYNC <= '0';
			when V_SYNC_LINE_LIMIT => pVSYNC <= '1';
			when others => null;
		end case;
		
	end if;
end process;
	
end RTL;
